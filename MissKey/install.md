# 使用docker构建misskey去中心化微博实例
## 安装`docker`及`docker-compose`
```sh
curl -L https://get.docker.com | sh
wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64
chmod +x docker-compose-linux-x86_64
sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
sudo mkdir /opt/misskey
cd /opt/misskey
```
## 新建misskey的`docker-compose.yml`，内容如下：

```yaml
version: "3"

services:
  web:
    restart: always
    image: misskey/misskey:latest
    container_name: misskey_web
    links:
      - db
      - redis
    ports:
      - "127.0.0.1:3000:3000"
    networks:
      - internal_network
      - external_network
    volumes:
      - ./files:/misskey/files
      - ./config:/misskey/.config:ro

  redis:
    restart: always
    image: redis:latest
    container_name: misskey_redis
    networks:
      - internal_network
    volumes:
      - ./redis:/data

  db:
    restart: always
    image: postgres:12.2-alpine
    container_name: misskey_db
    networks:
      - internal_network
    env_file:
      - ./config/docker.env
    volumes:
      - ./db:/var/lib/postgresql/data

networks:
  internal_network:
    internal: true
  external_network:
```

## 添加配置文件
```
mkdir config
nano config/default.yml
```
### `default.yml`的内容，根据自己的实情更改
```
url: https://example.tld/
port: 3000
db:
  host: db
  port: 5432
  db: misskey
  user: misskey-user
  pass: misskey-pass

  # Whether disable Caching queries
  #disableCache: true

  # Extra Connection options
  #extra:
  #  ssl: true

redis:
  host: redis
  port: 6379
  #family: 0  # 0=Both, 4=IPv4, 6=IPv6
  #pass: example-pass
  #prefix: example-prefix
  #db: 1

#   ┌─────────────────────────────┐
#───┘ Elasticsearch configuration └─────────────────────────────

#elasticsearch:
#  host: localhost
#  port: 9200
#  ssl: false
#  user:
#  pass:

#   ┌───────────────┐
#───┘ ID generation └───────────────────────────────────────────

# You can select the ID generation method.
# You don't usually need to change this setting, but you can
# change it according to your preferences.

# Available methods:
# aid ... Short, Millisecond accuracy
# meid ... Similar to ObjectID, Millisecond accuracy
# ulid ... Millisecond accuracy
# objectid ... This is left for backward compatibility

# ONCE YOU HAVE STARTED THE INSTANCE, DO NOT CHANGE THE
# ID SETTINGS AFTER THAT!

id: 'aid'

#   ┌─────────────────────┐
#───┘ Other configuration └─────────────────────────────────────

# Whether disable HSTS
#disableHsts: true

# Number of worker processes
#clusterLimit: 1

# Job concurrency per worker
# deliverJobConcurrency: 128
# inboxJobConcurrency: 16

# Job rate limiter
# deliverJobPerSec: 128
# inboxJobPerSec: 16

# Job attempts
# deliverJobMaxAttempts: 12
# inboxJobMaxAttempts: 8

# IP address family used for outgoing request (ipv4, ipv6 or dual)
#outgoingAddressFamily: ipv4

# Syslog option
#syslog:
#  host: localhost
#  port: 514

# Proxy for HTTP/HTTPS
#proxy: http://127.0.0.1:3128

#proxyBypassHosts: [
#  'example.com',
#  '192.0.2.8'
#]

# Proxy for SMTP/SMTPS
#proxySmtp: http://127.0.0.1:3128   # use HTTP/1.1 CONNECT
#proxySmtp: socks4://127.0.0.1:1080 # use SOCKS4
#proxySmtp: socks5://127.0.0.1:1080 # use SOCKS5

# Media Proxy
#mediaProxy: https://example.com/proxy

# Proxy remote files (default: false)
#proxyRemoteFiles: true

# Sign to ActivityPub GET request (default: false)
signToActivityPubGet: true

#allowedPrivateNetworks: [
#  '127.0.0.1/32'
#]

# Upload or download file size limits (bytes)
#maxFileSize: 262144000
```

### 创建`docker.env`
```
nano config/docker.env
```
```
# db settings
POSTGRES_PASSWORD=misskey-pass
POSTGRES_USER=misskey-user
POSTGRES_DB=misskey
```
## 进行数据库初始化
```
docker-compose run --rm web yarn run init
```
## 启动实例容器
```
docker-compose up -d
```
设置完反代，或才直接打开网站，设置一个账号登陆后，使用以下命令设置为管理员
```
docker-compose run --rm web node built/tools/mark-admin @username
```

## 更新实例，注意不要用`docker-compose stop`来停止容器，等待容器停止可能会很长时间
```
cd /opt/misskey
docker-compose pull
docker-compose up -d
```
## 数据清理：
```
docker system prune
```
输入`y`并回车确认即可.

## 定时更新和清理，只要把以下命令加入`crontab`即可
```
docker-compose -f /opt/misskey/docker-compose.yml pull
docker-compose -f /opt/misskey/docker-compose.yml up -d
docker system prune -f
```
