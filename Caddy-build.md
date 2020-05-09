## Go环境
```
wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz
tar xf go1.14.2.linux-amd64.tar.gz
sudo mv go /usr/local/
sudo ln -snf /usr/local/go/bin/* /usr/local/bin/
sudo apt install binutils -y
sudo apt install git -y
```
### Caddy V1
```
git clone -b v1 https://github.com/caddyserver/caddy.git
nano caddy/caddy/caddymain/run.go

_ "github.com/caddyserver/forwardproxy"

cd caddy/caddy
go build .
##  env CGO_ENABLED=0 go build -o ./caddy -ldflags "-s -w"
##  env CGO_ENABLED=0 GO111MODULE=on go build -o ./caddy -ldflags "-s -w"
strip -s caddy
sudo mv caddy /usr/local/bin/
sudo chown root:root /usr/local/bin/caddy
sudo chmod 0755 /usr/local/bin/caddy
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
sudo nano /etc/systemd/system/caddy.service
```
#### Archlinux V1
```
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
StartLimitIntervalSec=14400
StartLimitBurst=10

[Service]
Restart=on-abnormal
User=www-data
Group=www-data
Environment=CADDYPATH=/etc/ssl/caddy
EnvironmentFile=-/etc/caddy/envfile
ExecStart=/usr/local/bin/caddy -log stdout -log-timestamps=false -agree=true -conf=/opt/caddy/Caddyfile -root=/var/tmp
ExecReload=/bin/kill -USR1 $MAINPID

KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

LimitNOFILE=1048576
LimitNPROC=512

PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/etc/ssl/caddy
#ReadWriteDirectories=/etc/ssl/caddy
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
LockPersonality=true

[Install]
WantedBy=multi-user.target
```

#### Archlinux V2
```
[Unit]
Description=Caddy Web Server
Documentation=https://caddyserver.com/docs/
After=network.target

[Service]
User=http
Group=http
ExecStart=/usr/bin/caddy run --config /etc/caddy/Caddyfile --resume --environ
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512

# Hardening options
PrivateTmp=true
ProtectSystem=strict
PrivateDevices=true
ProtectHome=true
ReadWritePaths=/var/lib/caddy /var/log/caddy
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
LockPersonality=true


[Install]
WantedBy=multi-user.target
```
```sudo nano /opt/caddy/Caddyfile```
#### Caddy V1
```
xxx.com {
  gzip
  root /var/www/html/xxx
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
  proxy /xxx localhost:10086 {
    transparent
    websocket
    header_upstream -Origin
  }
}
```

#### 转发配置
```
forwardproxy {
basicauth user password
hide_ip
hide_via
}
```

##### Debian  V1版
```
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=on-abnormal
User=www-data
Group=www-data
Environment=CADDYPATH=/etc/ssl/caddy
EnvironmentFile=-/etc/caddy/envfile
ExecStart=/usr/local/bin/caddy -log stdout -log-timestamps=false -agree=true -conf=/opt/caddy/Caddyfile -root=/var/tmp
ExecReload=/bin/kill -USR1 $MAINPID
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512

[Install]
WantedBy=multi-user.target
```


##### Debian V2.0版
```
[Unit]
Description=Caddy Web Server
Documentation=https://caddyserver.com/docs/
After=network.target

[Service]
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --config /opt/caddy/Caddyfile --resume --environ
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


#### Caddy V2.0 Caddyfile
```
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

reverse_proxy /api localhost:10086 {
    # header_up Host {http.request.host}
     header_up Host {http.reverse_proxy.upstream.hostport}
     header_up X-Real-IP {http.request.remote}
     header_up X-Forwarded-For {http.request.remote}
     header_up X-Forwarded-Port {http.request.port}
     header_up X-Forwarded-Proto {http.request.scheme}
     header_up Connection {http.request.header.Connection}
     header_up Upgrade {http.request.header.Upgrade}
  }
}
```
#### 创建用户caddy
```
sudo useradd -r -m -s /sbin/nologin caddy
```
