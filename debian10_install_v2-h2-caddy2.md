## 系统要求：Debian10
#### 更新系统，安装防火墙
```
sudo apt update
sudo apt upgrade -y
sudo apt install binutils git curl ufw libsodium-dev -y
```
#### 校准时间***中国时区***
```
sudo rm /etc/localtime
sudo ln -snf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
```
##### 开启bbr
```
sudo nano /etc/ufw/sysctl.conf
```
###### 添加内容
```
net/core/default_qdisc=fq
net/ipv4/tcp_congestion_control=bbr
```
#### 安装GO环境
```
wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz
tar xf go1.14.2.linux-amd64.tar.gz
sudo mv go /usr/local/
sudo ln -snf /usr/local/go/bin/* /usr/local/bin/
go version
```
#### 编译安装Caddy2
```
git clone https://github.com/caddyserver/caddy.git
cd caddy/cmd/caddy/
env CGO_ENABLED=0 go build -o ./caddy -ldflags "-s -w"
sudo mv caddy /usr/local/bin/
sudo chown root:root /usr/local/bin/caddy
sudo chmod 0755 /usr/local/bin/caddy
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
```
##### 设置caddy2开机启动服务
```
sudo nano /etc/systemd/system/caddy.service
```
###### caddy2 systemd
```
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
###### 配置文件```/opt/caddy/Caddyfile```
```json
xxx.com {
encode zstd gzip
root * /var/www/html
file_server browse

tls xxx@xxx.com {
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

reverse_proxy /xxx.html https://127.0.0.1:10086 {
     header_up Host {http.request.host}
     header_up X-Real-IP {http.request.remote}
     header_up X-Forwarded-For {http.request.remote}
     header_up X-Forwarded-Port {http.request.port}
     header_up X-Forwarded-Proto {http.request.scheme}
     # header_up X-Forwarded-Proto "https"
     header_up Connection {http.request.header.Connection}
     header_up Upgrade {http.request.header.Upgrade}
transport https {
	tls
	tls_client_auth <cert_file> <key_file>
	# tls_insecure_skip_verify
	# tls_timeout <duration>
	# tls_trusted_ca_certs <pem_files...>
	# keepalive [off|<duration>]
	# keepalive_idle_conns <max_count>
    }
  }
}
```
#### 安装v2ray
```
cd ~
git clone https://github.com/v2ray/v2ray-core.git
cd v2ray-core/main
env CGO_ENABLED=0 go build -o $HOME/v2ray -ldflags "-s -w"
cd ~
cd v2ray-core/infra/control/main
env CGO_ENABLED=0 go build -o $HOME/v2ctl -tags confonly -ldflags "-s -w"
cd ~
sudo mv $HOME/v2ray $HOME/v2ctl /usr/local/bin/
```
##### 配置开机启动
```
sudo nano /etc/systemd/system/v2ray.service
```
###### 启动配置
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
###### 配置v2ray文件```/opt/v2ray/config.json```
```json
{
  "inbounds": [
    {
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      },
      "port": "<Port>", \\端口
      "listen": "127.0.0.1",
      "tag": "vmess-in",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "<UUID>", \\uuid
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "h2",
        "security": "tls",
        "httpSettings": {
          "path": "<H2 Path>",
          "host": [
            "<Host>"
          ]
        },
        "tlsSettings": {
          "serverName": "<Host>",
          "certificates": [
            {
              "certificateFile": "<Path to cert>",
              "keyFile": "<Path to key>"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": { },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": { },
      "tag": "blocked"
    }
  ],
  "dns": {
    "servers": [
      "https://cloudflare-dns.com/dns-query",
      "https://dns.google/dns-query",
      "1.1.1.1",
      "1.0.0.1",
      "8.8.8.8",
      "8.8.4.4"
    ]
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "vmess-in"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "outboundTag": "block",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  }
}
```
cat /proc/sys/kernel/random/uuid
