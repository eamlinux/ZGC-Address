一，安装podman

    1，导入apt key
sudo apt update
sudo apt install gnupg
source /etc/os-release
wget http://downloadcontent.opensuse.org/repositories/home:/alvistack/Debian_$VERSION_ID/Release.key -O alvistack_key
cat alvistack_key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/alvistack.gpg  >/dev/null
  2，添加podman安装源：
echo "deb http://downloadcontent.opensuse.org/repositories/home:/alvistack/Debian_$VERSION_ID/ /" | sudo tee  /etc/apt/sources.list.d/alvistack.list
  3，安装podman及所需插件
sudo apt update
sudo apt -y install podman uidmap dbus-user-session dbus-x11 slirp4netns libpam-systemd podman-aardvark-dns podman-netavark podman-docker
sudo reboot

二，配置podman

    1，添加国内docker镜像加速
$ sudo nano /etc/containers/registries.conf
    1.1，在打开的配置中添加如下代码：
# unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.m.daocloud.io"
    2，添加一个普通用户作为无根用户【如：podman】，并将其加入subuid和subgid中
sudo useradd -r -m -s /bin/bash podman
echo "podman:100000:65536" | sudo tee -a /etc/subuid
echo "podman:100000:65536" | sudo tee -a /etc/subgid
    3，设定无根用户podman无需登陆也能开机启动无根容器
sudo loginctl enable-linger podman
    4，切换到无根用户podman并解决运行容器里命令出现"Failed to connect to bus: 找不到介质"的问题
sudo su -l podman
nano .bashrc

# 在当前用户目录下编辑.bashrc，在最后面添加如下内容：

export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

$ source .bashrc
    5，重置podman，使用能正常使用aardvark-dns

$ podman system reset --force

三，容器相关示例，均在podman无根用户下进行

    1，创建桥接网络network01，并指定ip段为192.168.188.0/24
$ podman network create --subnet 192.168.188.0/24 network01

    2，在容器中运行数据库postgresql
        2.1， 创建数据配置和储存映射卷
$ mkdir -p /home/podman/pgdata
        2.2，拉取postgresql并运行容器
$ podman run \
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

#说明：
#  --name 运行的容器名，可自行更改
#  --network 之前创建的桥接网络名，可使用"podman network ls"查看，podman默认网络除外
#  --log-driver 日志格式
#  --log-opt 最大日志容量及最大日志记录数
#  -p 端口映射
#  -v 映射数据卷
#  -e POSTGRES_PASSWORD  指定数据库用户postgres的密码，自行修改
#  -e LANG 使用建议的C.UTF-8，能很好的支持中文
#  -d postgres:alpine 数据库镜像，要指定版本可自行搜索更改


  3，容器运行pgadmin4来管理posgresql数据库
$ podman run \
--name pgadmin4 \
--network network01 \
-p 5433:80 \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-e PGADMIN_DEFAULT_EMAIL=mail_user@mail.com \
-e PGADMIN_DEFAULT_PASSWORD=my_password \
-d dpage/pgadmin4:latest

# 注意事项：
# --network 跟postgres容器在一个子网，容器间网络可直接用容器名进行通信访问
# -p 5433:80 把容器里80端口映射到宿主机的5433端口，由于linux限制，无根容器默认不支持小1024的端口值，除非更改限制
# -e 的mail地址和password自行更改，pgadmin4 登陆需要

  4，添加开机启动
podman generate systemd --files --name postgres
podman generate systemd --files --new --name pgadmin4     ## --new 标志表示 Podman 将在服务启动时创建容器，在服务关闭时删除容器。
mkdir -p .config/systemd/user/
mv *.service ~/.config/systemd/user/
systemctl --user enable container-postgres.service
systemctl --user enable container-pgadmin4.service

  5, 查看容器通信
$ cat /run/user/1000/containers/networks/aardvark-dns/network01  ## 查看容器网络的ip分配及dns解析
    5.1，测试容器通信
$ podman exec -it postgres ping pgadmin4  ## 容器互通测试
$ podman exec -it postgres ping host.containers.internal   ## host.containers.internal代表宿主机
  6，在postgers容器中添加数据库及用户密码
$ podman exec -it postgres psql -U postgres

CREATE USER dbuser WITH password 'dbuser_password';
CREATE DATABASE userdb ENCODING 'UTF8' OWNER dbuser;

## 有些特殊要求的数据库，如指定语言'C'
CREATE DATABASE matrixdb
ENCODING 'UTF8'
LC_COLLATE='C'
LC_CTYPE='C'
template=template0
OWNER matrixuser;
收集资料不易，欢迎指正。
