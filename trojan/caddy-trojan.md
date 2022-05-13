## 安装golang  
```
wget -c https://go.dev/dl/go1.18.2.linux-amd64.tar.gz
tar xf go1.18.2.linux-amd64.tar.gz
sudo mv go /usr/local/
sudo ln -snf /usr/local/go/bin/* /usr/local/bin/
```
## 下载xcaddy  
```
wget https://github.com/caddyserver/xcaddy/releases/download/v0.3.0/xcaddy_0.3.0_linux_amd64.tar.gz
tar xf xcaddy_0.3.0_linux_amd64.tar.gz
```
## 编译 caddy-trojan  
```
./xcaddy build --with github.com/imgk/caddy-trojan
## ./xcaddy build --with github.com/caddyserver/transform-encoder --with github.com/imgk/caddy-trojan

strip -s caddy
sudo mv caddy /usr/local/bin/
sudo chown root:root /usr/local/bin/caddy
sudo chmod 0755 /usr/local/bin/caddy
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy

sudo useradd -r -m -s /sbin/nologin caddy
sudo mkdir -p /opt/caddy
```
> 或者
```
git clone https://github.com/imgk/caddy-trojan.git
cd caddy-trojan/
env CGO_ENABLED=0 go build -v -o ./caddy -ldflags="-w -s" -trimpath
```
## 添加开机启动  
```
sudo tee /etc/systemd/system/caddy.service > /dev/null <<EOF
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
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
```
## ~~添加配置,请使用末尾的最新配置~~
```
sudo tee /opt/caddy/Caddyfile > /dev/null <<EOF
{
  order trojan before map
  admin off
  log {
    output discard
  }
  default_sni xx.yy
  servers :443 {
    listener_wrappers {
      trojan
    }
    protocol {
      allow_h2c
    }
  }
}

:443, xx.yy {
  encode {
    gzip 6
  }

  tls {
    protocols tls1.3
    curves x25519
    alpn h2 http/1.1
  }

  trojan {
    user password1 password2
    connect_method
    websocket
  }

  @host {
    host xx.yy
  }

  route @host {
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Content-Type-Options nosniff
      X-Frame-Options SAMEORIGIN
      Referrer-Policy no-referrer-when-downgrade
    }
    file_server {
      root /var/www/html
    }
  }
}
EOF
```
## 添加网站  
```
sudo mkdir -p /var/www/html
sudo git clone https://github.com/HFIProgramming/mikutap.git /var/www/html
sudo chown -R caddy. /var/www/html
```
## 添加开机服务
```
sudo systemctl daemon-reload
sudo systemctl enable --now caddy
```
## 最新配置：
```
sudo tee /opt/caddy/Caddyfile > /dev/null <<EOF
{
  order trojan before map
  admin off
  log {
    output discard
  }
  servers :443 {
    listener_wrappers {
      trojan
    }
    protocol {
      allow_h2c
      experimental_http3
    }
  }
  trojan {
    caddy
    no_proxy
    users password1 password2
  }
}

:443, xx.yy {
  encode {
    gzip 6
  }

  tls {
    protocols tls1.3
    curves x25519
    alpn h2
  }

  @host {
    host xx.yy
  }

  route @host {
    trojan {
      connect_method
      websocket
    }
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Content-Type-Options nosniff
      X-Frame-Options SAMEORIGIN
      Referrer-Policy no-referrer-when-downgrade
    }
    file_server {
      root /var/www/html
    }
  }
}
EOF
```
