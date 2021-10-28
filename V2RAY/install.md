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
wget https://github.com/caddyserver/caddy/releases/download/v2.4.5/caddy_2.4.5_linux_amd64.tar.gz
tar xf caddy_2.4.5_linux_amd64.tar.gz
sudo mv caddy /usr/local/bin/
sudo chown root:root /usr/local/bin/caddy
sudo chmod 0755 /usr/local/bin/caddy
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
```
```shell
echo '[Unit]
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
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/caddy.service
```
```shell
echo 'web.me {
    encode zstd gzip
    root * /var/www/html
    file_server
    log {
        output discard
    }
    tls {
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
    handle_errors {
        respond "404 Not Found"
    }
    @websocket1 {
        path /path1
        header Connection *Upgrade*
        header Upgrade websocket
    }
    @websocket2 {
        path /path2
        header Connection *Upgrade*
        header Upgrade websocket
    }
    reverse_proxy @websocket1 localhost:10086
    reverse_proxy @websocket2 localhost:10000
}' | sudo tee /opt/caddy/Caddyfile
```
```bash
sudo mkdir -p /var/www/html
sudo git clone https://github.com/HFIProgramming/mikutap.git /var/www/html
sudo chown -R caddy. /var/www/html
```
```bash
wget https://github.com/v2fly/v2ray-core/releases/download/v4.41.1/v2ray-linux-64.zip
unzip -d v2ray v2ray-linux-64.zip
sudo mv v2ray/v2ctl v2ray/v2ray /usr/local/bin/
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
ExecStart=/usr/local/bin/v2ray -config /opt/v2ray/%i.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/v2ray@.service
```
```shell
sudo tee /opt/v2ray/vless.json > /dev/null <<EOF
{
  "log": {"loglevel": "none"},
  "inbounds": [{
    "port": 8443,
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
