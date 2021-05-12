sudo tee /opt/v2ray/gun.json > /dev/null <<EOF
{
  "log": {"loglevel": "none"},
  "inbounds": [{
    "sniffing": {
      "enabled": true,
      "destOverride": ["http","tls"]
    },
    "protocol": "vless",
    "listen": "127.0.0.1",
    "port": "10086",
    "tag": "vless-gun",
    "settings": {
      "decryption":"none",
      "clients": [
        {"id": "$(v2ctl uuid)"}
      ]
    },
    "streamSettings": {
      "network": "gun",
      "security": "none",
      "grpcSettings": {
        "serviceName": "GunService"
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
    "tag": "block"
  }],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [{
      "type": "field",
      "inboundTag": ["vless-gun"],
      "outboundTag": "direct"
    },{
      "type": "field",
      "outboundTag": "block",
      "protocol": ["bittorrent"]
    }]
  },
  "dns": {
    "servers": [
      "https://cloudflare-dns.com/dns-query",
      "https://dns.google/dns-query"
    ]
  }
}
EOF
