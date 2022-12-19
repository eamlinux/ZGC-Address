## 安装UFW
```bash
sudo apt install binutils curl ufw unzip wget git -y
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo "y" | sudo ufw enable
sudo ufw logging off
sudo ufw reload
```
## 修改连接数
```
echo '* soft nofile 51200
* hard nofile 51200
* soft nproc 51200
* hard nproc 51200

root soft nofile 51200
root hard nofile 51200
root soft nproc 51200
root hard nproc 51200' | sudo tee -a /etc/security/limits.conf
```
## 利用UFW开启BBR
```
echo 'net/core/default_qdisc=fq
net/ipv4/tcp_congestion_control=bbr' | sudo tee -a /etc/ufw/sysctl.conf
```
## 安装V2ray
```
wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip -d v2ray v2ray-linux-64.zip
sudo mv v2ray/v2ray /usr/local/bin/

sudo tee /etc/systemd/system/v2ray@.service > /dev/null <<EOF
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray run -config /opt/v2ray/%i.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
```
## 建立用户
```
# sudo useradd -r -M -s /sbin/nologin v2ray
sudo useradd -r -m -s /sbin/nologin caddy
sudo mkdir -p /opt/v2ray
sudo mkdir -p /opt/caddy
```
## 安装caddy
```
wget https://github.com/caddyserver/caddy/releases/latest/download/caddy_2.6.2_linux_amd64.tar.gz
tar xf caddy_2.6.2_linux_amd64.tar.gz
sudo mv caddy /usr/local/bin/
sudo chown root:root /usr/local/bin/caddy
sudo chmod 0755 /usr/local/bin/caddy
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
sudo mkdir -p /opt/caddy

sudo mkdir -p /var/www/html
sudo git clone https://github.com/HFIProgramming/mikutap.git /var/www/html
sudo chown -R caddy. /var/www/html

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
ExecReload=/usr/local/bin/caddy reload --config /opt/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateDevices=yes
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
```
## 建立Caddyfile
```
sudo tee /opt/caddy/Caddyfile > /dev/null <<EOF
{
  order reverse_proxy before map
  admin off
  log {
    output discard
  }
  servers :443 {
    protocols h1 h2 h3
  }
  default_sni xx.yy
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

  @GRPC {
    protocol grpc
    path /pathname/*
  }
  reverse_proxy @GRPC 127.0.0.1:10000 {
    flush_interval -1
    header_up X-Real-IP {remote_host}
    transport http {
      versions h2c
    }
  }

  @xxyy {
    host xx.yy
  }
  route @xxyy {
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Content-Type-Options nosniff
      X-Frame-Options SAMEORIGIN
      Referrer-Policy no-referrer-when-downgrade
    }
    reverse_proxy localhost:9000 {
      header_up X-Real-IP {remote_host}
    }
    file_server {
      root /var/www/html
    }
  }
}
EOF
```
## 开机启动
```
sudo systemctl daemon-reload
sudo systemctl enable --now caddy
```
