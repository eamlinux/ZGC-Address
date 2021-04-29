sudo tee /opt/v2ray/vmgrpc.json > /dev/null <<EOF
{
  "log": {"loglevel": "none"},
  "inbounds": [{
    "sniffing": {
      "enabled": true,
      "destOverride": ["http","tls"]
    },
    "port": "10086",
    "listen": "127.0.0.1",
    "tag": "vmess-grpc",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {"id": "$(v2ctl uuid)","alterId": 0},
        {"id": "$(v2ctl uuid)","alterId": 0}
      ]
    },
    "streamSettings": {
      "network": "grpc",
      "grpcSettings": {
        "serviceName": "pathname"
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
      "inboundTag": ["vmess-grpc"],
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
