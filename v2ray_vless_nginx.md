## v2ray.conf
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
            "listen": "0.0.0.0",
            "port": 443,
            "tag": "vless-in",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "", // 生成的UUID
                        "level": 0
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "alpn": "h2",
                        "dest": 80
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "serverName": "xxx.com", // 域名
                    "alpn": [
                        "h2"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/path/xxx.crt",
                            "keyFile": "/path/xxx.key"
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
            "https://dns.google/dns-query"
        ]
    },
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "inboundTag": [
                  "vless-in"
                ],
                "outboundTag": "direct"
            },
            {
                "type": "field",
                "outboundTag": "blocked",
                "protocol": [
                    "bittorrent"
                ]
            }
        ]
    }
}
```
## nginx.conf
```
server {
    listen 127.0.0.1:80 default_server http2;
    server_name xxx.com;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
      root /var/www/html;
      index  index.html index.php;
    }
}

server {
    listen 127.0.0.1:80 http2;
    server_name $ServerIP;
    return 301 https://xxx.com$request_uri;
}

server {
    listen 0.0.0.0:80;
    listen [::]:80;
    server_name _;
    return 301 https://xxx.com$request_uri;
}
```
## v2ray.service
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
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```
## nginx.service
```
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
User=caddy
# PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/local/bin/nginx -t -c /opt/nginx/nginx.conf
ExecStart=/usr/local/bin/nginx -c /opt/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```
