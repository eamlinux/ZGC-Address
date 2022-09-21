## debian10下安装
```bash
sudo apt install binutils git curl ufw libsodium-dev unzip -y
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo "y" | sudo ufw enable
sudo ufw logging off
sudo ufw reload
sudo useradd -r -m -s /sbin/nologin caddy
sudo mkdir -p /opt/caddy /opt/v2ray
```
```shell
echo '* soft nofile 51200
* hard nofile 51200
* soft nproc 51200
* hard nproc 51200

root soft nofile 51200
root hard nofile 51200
root soft nproc 51200
root hard nproc 51200' | sudo tee -a /etc/security/limits.conf
```
```shell
echo 'net/core/default_qdisc=fq
net/ipv4/tcp_congestion_control=bbr' | sudo tee -a /etc/ufw/sysctl.conf
```
```bash
wget https://github.com/caddyserver/caddy/releases/latest/download/caddy_2.6.0_linux_amd64.tar.gz
tar xf caddy_2.6.0_linux_amd64.tar.gz
sudo mv caddy /usr/local/bin/
sudo chown root:root /usr/local/bin/caddy
sudo chmod 0755 /usr/local/bin/caddy
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
```
```shell
echo '[Unit]
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
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/caddy.service
```
```bash
sudo mkdir -p /var/www/html
sudo git clone https://github.com/HFIProgramming/mikutap.git /var/www/html
sudo chown -R caddy. /var/www/html
```
```bash
wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip -d v2ray v2ray-linux-64.zip
sudo mv v2ray/v2ray /usr/local/bin/
```
```shell
echo '[Unit]
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
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/v2ray@.service
```
```bash
sudo tee /opt/v2ray/trojan.json > /dev/null <<EOF
{
  "log": {
    "loglevel": "none"
  },
  "inbounds": [{
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    },
    "listen": "127.0.0.1",
    "port": 10000,
    "protocol": "trojan",
    "tag": "tro",
    "settings": {
      "clients": [{
        "password": "passone",
        "email": "abcdef@gmail.com"
      },
      {
        "password": "passtow",
        "email": "zxcvbn@gmail.com"
      }]
    },
    "streamSettings": {
      "network": "grpc",
      "security": "none",
      "grpcSettings": {
        "serviceName": "pathname",
        "multiMode": true
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {},
    "tag": "direct"
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [{
      "type": "field",
      "inboundTag": ["tro"],
      "outboundTag": "direct"
    },{
      "type": "field",
      "outboundTag": "blocked",
      "protocol": ["bittorrent"]
    }]
  },
  "dns": {
    "servers": [
      "https://dns.google/dns-query",
      "https://cloudflare-dns.com/dns-query",
      "1.1.1.1",
      "8.8.8.8"
    ]
  }
}
EOF
```
```shell
sudo tee /opt/v2ray/vless.json > /dev/null <<EOF
{
  "log": {"loglevel": "none"},
  "inbounds": [{
    "port": 10086,
    "listen": "127.0.0.1",
    "tag": "vless-in",
    "protocol": "vless",
    "settings": {
      "decryption": "none",
      "clients": [
        {"id": "$(v2ctl uuid)","level": 0},
        {"id": "$(v2ctl uuid)","level": 0}
      ]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/ws"
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {},
    "tag": "direct"
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }],
  "routing": {
    "domainStrategy": "AsIs",
    "rules":[
      {
        "type": "field",
        "inboundTag": ["vless-in"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  },
  "dns": {
    "servers": [
      "https://cloudflare-dns.com/dns-query",
      "https://dns.google/dns-query"
    ]
  }
}
EOF
```
CaddyFile
```shell
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
