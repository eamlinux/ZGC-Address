## 系统要求：Debian10
#### 更新系统，安装防火墙
```
sudo apt update
sudo apt upgrade -y
sudo apt install binutils git curl ufw libsodium-dev -y
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming
sudo ufw default allow outgoing
### sudo ufw default deny
sudo ufw enable
sudo ufw reload
sudo useradd -r -m -s /sbin/nologin caddy
```
#### 校准时间***中国时区***
```
sudo rm /etc/localtime
sudo ln -snf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
```

#### 更改系统最大文件数
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
wget -c https://dl.google.com/go/go1.14.6.linux-amd64.tar.gz
tar xf go1.14.6.linux-amd64.tar.gz
sudo mv go /usr/local/
sudo ln -snf /usr/local/go/bin/* /usr/local/bin/
go version
```
#### 编译Caddy1
```
git clone -b v1 --depth=1 https://github.com/caddyserver/caddy.git
nano caddy/caddy/caddymain/run.go

_ "github.com/caddyserver/forwardproxy"

cd caddy/caddy
env CGO_ENABLED=0 go build -o ./caddy -ldflags "-s -w"
sudo mv caddy /usr/local/bin/
sudo chown root:root /usr/local/bin/caddy
sudo chmod 0755 /usr/local/bin/caddy
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
```
#### 设置Caddy1 Systemd启动
```
sudo nano /etc/systemd/system/caddy.service

//加入以下内容：

[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
StartLimitIntervalSec=14400
StartLimitBurst=10

[Service]
Restart=on-abnormal
User=caddy
Group=caddy
Environment=CADDYPATH=/etc/ssl/caddy
ExecStart=/usr/local/bin/caddy -log stdout -log-timestamps=false -agree=true -conf=/opt/caddy/Caddyfile -root=/dev/null
ExecReload=/bin/kill -USR1 $MAINPID
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
PrivateDevices=false
ProtectHome=true
ProtectSystem=full
ReadWritePaths=/etc/ssl/caddy
ReadWriteDirectories=/etc/ssl/caddy
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target

------------------------------------------------
sudo mkdir /etc/ssl/caddy
sudo chown -R caddy. /etc/ssl/caddy
```

#### 编译安装Caddy2
```
git clone --depth=1 https://github.com/caddyserver/caddy.git
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
###### Caddy配置文件
```
sudo mkdir /opt/caddy/
sudo nano /opt/caddy/Caddyfile

加入以下内容：
## ws
-------------------------------------
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

reverse_proxy /xxx.html localhost:8443 {
     header_up Host {http.request.host}
     header_up X-Real-IP {http.request.remote}
     header_up X-Forwarded-For {http.request.remote}
     header_up X-Forwarded-Port {http.request.port}
     header_up X-Forwarded-Proto {http.request.scheme}
     header_up Connection {http.request.header.Connection}
     header_up Upgrade {http.request.header.Upgrade}
  }
}
--------------------------------------------------------------
## Caddy v1--h2
xxx.com {
  gzip
  root /var/www/html
  tls xxx@xxx.com {
  protocols tls1.3
  curves x25519
  alpn h2
  }
  header / {
    Strict-Transport-Security "max-age=31536000;"
    X-XSS-Protection "1; mode=block"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
  }
  proxy /xxxx https://127.0.0.1:8443 {
        insecure_skip_verify
        header_upstream Host {host}
        header_upstream X-Real-IP {remote}
        header_upstream X-Forwarded-For {remote}
        header_upstream X-Forwarded-Port {server_port}
        header_upstream X-Forwarded-Proto "https"
  }
}
-----------------------------------------------------------
### Caddy1 H2 WS

http://xxx.com {
    redir https://xxx.com{uri}
}

https://xxx.com {
  gzip
  root /var/www/html
  tls xxx@xxx.com {
  protocols tls1.3
  curves x25519
  alpn h2
  }

  header / {
    Strict-Transport-Security "max-age=31536000;"
    X-XSS-Protection "1; mode=block"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
  }

  proxy /xxx/xxx https://127.0.0.1:8443 {
        insecure_skip_verify
        header_upstream Host {host}
        header_upstream X-Real-IP {remote}
        header_upstream X-Forwarded-For {remote}
        header_upstream X-Forwarded-Port {server_port}
        header_upstream X-Forwarded-Proto "https"
 }
  proxy /ws localhost:65432 {
    transparent
    websocket
    header_upstream -Origin
  }
}

#### 正向代理

xxx.tk {
  gzip
  root /var/www/html
  tls xxx@xxx.tk {
  protocols tls1.3
  curves x25519
  alpn h2
  }
  header / {
    Strict-Transport-Security "max-age=31536000;"
    X-XSS-Protection "1; mode=block"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
  }
  proxy /xxx localhost:9443 {
    transparent
    websocket
    header_upstream -Origin
  }
forwardproxy {
    basicauth user passwd
    probe_resistance xxxx.xxx
    ports     80 443
    hide_ip
    hide_via
 }
}
```
#### 安装v2ray
```
cd ~
git clone --depth=1 https://github.com/v2ray/v2ray-core.git
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
##### 配置开机启动
```
sudo nano /etc/systemd/system/v2ray.service


加入以下内容：

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
###### 生成UUID,记住它，下面要用
```
cat /proc/sys/kernel/random/uuid
```
###### V2ray配置文件
```
sudo mkdir /opt/v2ray
sudo nano /opt/v2ray/config.json
```
###### 加入以下内容：
####### WS
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
      "port": "8443",
      "listen": "127.0.0.1",
      "tag": "vmess-in",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/xxx.html"
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
      "https://dns.google/dns-query"
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
####### h2
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
      "port": "8443", //端口跟Caddy配置里的转发的相同，像上面的"8443"端口
      "listen": "127.0.0.1",
      "tag": "vmess-in",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "xxx-xxxxx-xxxxx-xxxxx-xxxx", //填写上面生成的UUID
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "h2",
        "security": "tls",
        "httpSettings": {
          "path": "/xxx.html", //文件路径，跟caddy配置里的相同
          "host": [
            "xxx.com" //你的域名
          ]
        },
        "tlsSettings": {
          "serverName": "xxx.com", //你的域名
          "certificates": [
            {
              "certificateFile": "<Path to cert>", //caddy生成的证书crt
              "keyFile": "<Path to key>"  //caddy生成的证书key
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
#### 启动系统
```
sudo systemctl daemon-reload
sudo systemctl enable v2ray
sudo systemctl enable caddy
sudo systemctl status v2ray
sudo systemctl status caddy
```
## H2C
#### v2ray
```
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
      "port": "8443",
      "listen": "127.0.0.1",
      "tag": "vmess-in",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "xxx-xxxxx-xxxxx-xxxxx-xxxx",
            "alterId": 32
          }
        ]
      },
      "streamSettings": {
        "network": "h2c",
        "security": "none",
        "httpSettings": {
          "path": "/xxx.html",
          "host": [
            "xxx.com"
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
      "localhost"
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
#### caddy2
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

reverse_proxy /xxxxx {
     to http://127.0.0.1:8443
     header_up Host {http.request.host}
     header_up X-Real-IP {http.request.remote}
     header_up X-Forwarded-For {http.request.remote}
     header_up X-Forwarded-Port {http.request.port}
     header_up X-Forwarded-Proto {http.request.scheme}
     header_up Connection {http.request.header.Connection}
     header_up Upgrade {http.request.header.Upgrade}
     transport http {
         versions h2c 2
    }
  }
}
```

