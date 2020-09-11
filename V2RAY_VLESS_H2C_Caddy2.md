## V2rayconfig
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
            "listen": "127.0.0.1",
            "port": 4443,
            "tag": "vless-in",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "", // 填写UUID
                        "level": 0
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "h2",
                "security": "none",
                "httpSettings": {
                    "path": "/v2ray?P=10240", // H2C的PATH路径
                    "host": [
                        "web.com" // 填写域名
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
        "domainStrategy": "UseIP",
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
                "outboundTag": "block",
                "protocol": [
                    "bittorrent"
                ]
            }
        ]
    }
}
```

## Caddyfile
```
## 填写域名
web.com {
encode zstd gzip
## 网站路径
root * /var/www/html
file_server

tls admin@web.com {
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

reverse_proxy /v2ray?P=10240 127.0.0.1:4443 {
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
