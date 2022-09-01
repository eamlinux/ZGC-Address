# 系统要求：Debian10
## 更新系统，安装防火墙
```
sudo apt update
sudo apt upgrade -y
sudo apt install binutils git curl ufw libsodium-dev -y
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw logging off
sudo ufw reload
sudo useradd -r -m -s /sbin/nologin caddy
```
## 校准时间***中国时区***
```
sudo rm /etc/localtime
sudo ln -snf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
```

## 更改系统最大文件数
```
sudo nano /etc/security/limits.conf

加入：
* soft nofile 51200
* hard nofile 51200
* soft nproc 51200
* hard nproc 51200

root soft nofile 51200
root hard nofile 51200
root soft nproc 51200
root hard nproc 51200
```
## 开启bbr
```
sudo nano /etc/ufw/sysctl.conf
```
#### 添加内容
```
net/core/default_qdisc=fq
net/ipv4/tcp_congestion_control=bbr
```
## 安装GO环境
```
wget -c https://go.dev/dl/go1.19.linux-amd64.tar.gz
tar xf go1.19.linux-amd64.tar.gz
sudo mv go /usr/local/
sudo ln -snf /usr/local/go/bin/* /usr/local/bin/
go version
```
## 编译安装Caddy2
```
git clone --depth=1 https://github.com/caddyserver/caddy.git
cd caddy/cmd/caddy/
env CGO_ENABLED=0 go build -o ./caddy -ldflags "-s -w"
sudo mv caddy /usr/local/bin/
sudo chown root:root /usr/local/bin/caddy
sudo chmod 0755 /usr/local/bin/caddy
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
```
## 设置caddy2开机启动服务
```
sudo nano /etc/systemd/system/caddy.service

加入以下内容：

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
```
### 创建Caddy2 H2c配置文件
```
sudo mkdir /opt/caddy/
sudo nano /opt/caddy/Caddyfile
```
#### 加入以下内容：
```
xxxxx.com {
encode zstd gzip
root * /var/www/html
file_server

tls xxx@xxxxx.com {
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

reverse_proxy /xxxxx 127.0.0.1:8443 {
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
```
## 安装v2ray
```
cd ~
git clone --depth=1 https://github.com/v2fly/v2ray-core.git
cd v2ray-core/main
env CGO_ENABLED=0 go build -o $HOME/v2ray -ldflags "-s -w"
cd ~
cd v2ray-core/infra/control/main
env CGO_ENABLED=0 go build -o $HOME/v2ctl -tags confonly -ldflags "-s -w"
cd ~
sudo mv $HOME/v2ray $HOME/v2ctl /usr/local/bin/
```
#### 伪装
```
sudo mkdir -p /var/www/html
sudo git clone https://github.com/HFIProgramming/mikutap.git /var/www/html
sudo chown -R caddy. /var/www/html
```
#### 配置开机启动
```
sudo nano /etc/systemd/system/v2ray.service
```
#### 加入以下内容：
```
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=caddy
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray -config /opt/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
```
或者
```
[Unit]
Description=V2Ray Service
After=network.target
Wants=network.target

[Service]
User=caddy
Type=simple
PIDFile=/opt/v2ray/v2ray.pid
ExecStart=/usr/local/bin/v2ray -config /opt/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
```
#### 生成UUID,记住它，下面要用
```
cat /proc/sys/kernel/random/uuid
\\ 或者
v2ctl uuid
```
#### 创建V2ray配置文件
```
sudo mkdir /opt/v2ray
sudo nano /opt/v2ray/config.json
```
###### 加入以下内容：
```
{
  "log": {"loglevel": "none"},
  "inbounds": [
    {
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      },
      "port": "8443",
      "listen": "127.0.0.1",
      "tag": "vmess-in",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {"id": "$UUID","alterId": 0},
          {"id": "$UUID","alterId": 0},
          {"id": "$UUID","alterId": 0}
        ]
      },
      "streamSettings": {
        "network": "h2",
        "security": "none",
        "httpSettings": {
          "path": "/xxx?xx=xxx",
          "host": ["daemon.com"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "block"
    }
  ],
  "dns": {
    "servers": [
      "https://cloudflare-dns.com/dns-query",
      "https://dns.google/dns-query"
    ]
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "inboundTag": ["vmess-in"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "outboundTag": "block",
        "protocol": ["bittorrent"]
      }
    ]
  }
}
```
## 启动系统
```
sudo systemctl daemon-reload
sudo systemctl start v2ray
sudo systemctl start caddy
sudo systemctl enable v2ray
sudo systemctl enable caddy
sudo systemctl status v2ray
sudo systemctl status caddy
```
到此，全部完成，使用```v2rayn或者v2rayng```就可以愉快的使用了。
