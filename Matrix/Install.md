## 安装podman
```
source /etc/os-release
wget http://downloadcontent.opensuse.org/repositories/home:/alvistack/Debian_$VERSION_ID/Release.key -O alvistack_key
cat alvistack_key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/alvistack.gpg  >/dev/null

echo "deb http://downloadcontent.opensuse.org/repositories/home:/alvistack/Debian_$VERSION_ID/ /" | sudo tee  /etc/apt/sources.list.d/alvistack.list

sudo apt update
sudo apt -y install podman uidmap dbus-user-session dbus-x11 slirp4netns libpam-systemd podman-aardvark-dns podman-netavark podman-docker
sudo reboot
```
## 安装Postgresql
```
podman network create --subnet 192.168.188.0/24 network01

podman run \
--name postgres \
--network network01 \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-p 5432:5432 \
-v /home/podman/pgdata:/var/lib/postgresql/data \
-e POSTGRES_PASSWORD=my_password \
-e LANG=C.UTF-8 \
-d postgres:alpine
```
## 建立数据库
```
podman exec -it postgres psql -U postgres
## 建立用户
CREATE USER dbuser WITH password 'dbuser_password';
## 有些特殊要求的数据库，如指定语言'C'
CREATE DATABASE matrixdb
ENCODING 'UTF8'
LC_COLLATE='C'
LC_CTYPE='C'
template=template0
OWNER dbuser;

## 正常数据库
CREATE DATABASE userdb ENCODING 'UTF8' OWNER dbuser;
```
## 生成 Synapse 配置文件
```
podman run -it --rm \
-v /home/podman/matrix-synapse/data/:/data/ \
-e SYNAPSE_SERVER_NAME=xxyy.top \
-e SYNAPSE_REPORT_STATS=no \
matrixdotorg/synapse:latest \
generate
```
## 安装运行matrix
```
podman run \
--name synapse \
--network network01 \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-v /home/podman/matrix-synapse/data/:/data/ \
-p 8008:8008 \
-p 8009:8009 \
-p 8448:8448 \
-d matrixdotorg/synapse:latest
```
## 配置数据库连接
```
database:
  name: psycopg2
  txn_limit: 10000
  args:
    user: dbuser
    password: db_password
    database: matrixdb
    host: postgres
    port: 5432
    cp_min: 5
    cp_max: 10
```
## 生成开机启动
```
podman generate systemd --files --name --new synapse
mkdir -p .config/systemd/user/
mv container-synapse.service ~/.config/systemd/user/
systemctl --user enable container-synapse.service --now
```
- --new: new选项指示Podman配置systemd服务，以便在服务启动时创建容器，并在服务停止时删除。在这种模式下，容器是临时的，通常需要持久存储来保存数据。
- 没有--new选项，Podman 配置服务启动和停止现有的容器，而不删除。

## 创建用户
```
podman exec -it synapse \
register_new_matrix_user http://localhost:8008 \
-c /data/homeserver.yaml

## New user localpart [root]: leamnet
## Password:
## Confirm password:
## Make admin [no]: yes
## Sending registration request...
## Success!

## podman exec -it synapse \
## register_new_matrix_user http://localhost:8008 \
## -c /data/homeserver.yaml \
## -a -u 用户 \
## -p 密码
```

## 安装管理面板
```
podman run \
--name synapse-admin \
-p 8998:80 \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-d awesometechnologies/synapse-admin:latest
##或者
wget https://github.com/Awesome-Technologies/synapse-admin/releases/download/0.8.7/synapse-admin-0.8.7-dirty.tar.gz
tar xf synapse-admin-0.8.7-dirty.tar.gz
mv synapse-admin-0.8.7-dirty synapse-admin
sudo mv synapse-admin /opt/
sudo chown -R caddy:caddy /opt/synapse-admin

##caddy2
    file_server {
      root /opt/synapse-admin
    }
#podman generate systemd --files --name $synapse-admin
#sudo mv container-synapse-admin.service /usr/lib/systemd/user/
#systemctl --user enable --now container-synapse-admin
```
## Turn
```
podman run \
--name coturn \
--network host \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-v /home/podman/coturn/turnserver.conf:/etc/turnserver.conf:ro \
-v /home/podman/coturn:/etc/coturn \
-d coturn/coturn:latest "-c /etc/turnserver.conf"

podman run \
--name coturn \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-p 3478:3478 \
-p 3478:3478/udp \
-p 31000-49000:31000-49000/udp \
-v /home/podman/coturn/turnserver.conf:/etc/turnserver.conf:ro \
-v /home/podman/coturn:/etc/coturn \
-d coturn/coturn:latest "-c /etc/turnserver.conf"
```
### turnserver.conf
```
external-ip=公网ip
listening-port=3478
# tls-listening-port=5349
min-port=31000
max-port=49000
fingerprint
# lt-cred-mech # 使用用户密码才启用
# user=user:password
use-auth-secret
static-auth-secret="$(pwgen -s 64 1)"
realm=turn.example.org
# cert=/etc/coturn/certs/cert.pem
# pkey=/etc/coturn/private/privkey.pem
log-file=stdout
no-software-attribute
pidfile="/etc/coturn/turnserver.pid"
# no-stun
no-cli
no-tcp-relay #voip使用的是udp，禁止tcp中继
denied-peer-ip=10.0.0.0-10.255.255.255 #禁止访问内网ip
denied-peer-ip=192.168.0.0-192.168.255.255
denied-peer-ip=172.16.0.0-172.31.255.255
# allowed-peer-ip=10.0.0.1 #服务器本地 ip
user-quota=12 #每个视频通话 4 个流，因此 12 个流 = 每个用户同时进行 3 个中继通话。
total-quota=1200
```
## 配置 synapse
### turn
```yaml
turn_uris:
  # - "turns:turn.example.org?transport=udp"
  # - "turns:turn.example.org?transport=tcp"
  - "turn:turn.example.org?transport=udp"
  - "turn:turn.example.org?transport=tcp"
turn_shared_secret: "$(pwgen -s 64 1)"
turn_user_lifetime: 86400000
turn_allow_guests: True
# turn_allow_guests: false
```
