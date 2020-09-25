#!/bin/bash

function blue(){
    echo -e "\033[34m\033[01m $1 \033[0m"
}
function green(){
    echo -e "\033[32m\033[01m $1 \033[0m"
}
function red(){
    echo -e "\033[31m\033[01m $1 \033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m $1 \033[0m"
}
function bred(){
    echo -e "\033[31m\033[01m\033[05m $1 \033[0m"
}
function byellow(){
    echo -e "\033[33m\033[01m\033[05m $1 \033[0m"
}

check_if_running_as_root() {
    # If you want to run as another user, please modify $UID to be owned by this user
    if [[ "$UID" -ne '0' ]]; then
        echo "error: 请用root用户运行!"
        exit 1
    fi
}

rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))
}

caddy_install(){
green "添加域名，一定要是A记录解析到本服务器ip的域名"
read -p "请输入你的域名：" daemon
apt update -y && apt upgrade -y
apt install binutils git curl libsodium-dev -y
useradd -r -m -s /sbin/nologin caddy
cd /tmp/
wget -c https://golang.org/dl/go1.15.2.linux-amd64.tar.gz
tar xf go1.15.2.linux-amd64.tar.gz
mv go /usr/local/
ln -snf /usr/local/go/bin/* /usr/local/bin/
cd /tmp/
git clone --depth=1 https://github.com/caddyserver/caddy.git
cd caddy/cmd/caddy/
env CGO_ENABLED=0 go build -o ./caddy -ldflags "-s -w"
mv caddy /usr/local/bin/
chown root:root /usr/local/bin/caddy
chmod 0755 /usr/local/bin/caddy
setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
cat >> /etc/systemd/system/caddy.service <<-EOF
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target

[Service]
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /opt/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /opt/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
mkdir /opt/caddy/
green "添加V2ray的PATH路径，如"/ray"，一定要添加斜杠"
read -p "请输入PATH：" path
cat >> /opt/caddy/Caddyfile <<-EOF
$daemon {
encode zstd gzip
root * /var/www/html
file_server

tls admin@$daemon {
    protocols tls1.3
    curves x25519
    alpn h2
}

header {
        Strict-Transport-Security max-age=31536000;
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        Referrer-Policy no-referrer-when-downgrade
}

reverse_proxy $path 127.0.0.1:8443 {
     header_up Host {http.request.host}
     header_up X-Real-IP {http.request.remote}
     header_up X-Forwarded-For {http.request.remote}
     header_up X-Forwarded-Port {http.request.port}
     header_up X-Forwarded-Proto {http.request.scheme}
     header_up Connection {http.request.header.Connection}
     header_up Upgrade {http.request.header.Upgrade}
     transport http {
         versions h2c
    }
  }
}
EOF
mkdir -p /var/www/html
git clone https://github.com/HFIProgramming/mikutap.git /var/www/html
chown -R caddy. /var/www/html
systemctl daemon-reload
systemctl start caddy
systemctl enable caddy
green "caddy安装完成，打开域名：$daemon，测试是否访问正常"
}

#开始菜单
start_menu(){
    clear
    green " ===================================="
    green " 安装caddy web                       "
    green " ===================================="
    echo
    green " 1. 安装caddy2"
    yellow " 0. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    caddy_install
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 2s
    start_menu
    ;;
    esac
}

start_menu
