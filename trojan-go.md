### 编译trojan-go
```
git clone --depth=1 https://github.com/p4gefau1t/trojan-go.git
cd trojan-go/
env CGO_ENABLED=0 go build -o $HOME/trojan-god -ldflags "-s -w" -tags "router server auth_mysql auth_redis relay cert other"
sudo mkdir /opt/trojan-go
sudo mv $HOME/trojan-god /opt/trojan-go/trojan-go
sudo chown root:root /opt/trojan-go/trojan-go
sudo chmod 0755 /opt/trojan-go/trojan-go
sudo setcap CAP_NET_BIND_SERVICE=+eip /opt/trojan-go/trojan-go
sudo wget -O /opt/trojan-go/geosite.dat https://github.com/v2ray/domain-list-community/releases/latest/download/dlc.dat
sudo wget -O /opt/trojan-go/geoip.dat https://github.com/v2ray/geoip/releases/latest/download/geoip.dat
```
### 设置systemd
```
sudo nano /etc/systemd/system/trojan-go.service

// 内容：

[Unit]
Description=Trojan-Go - An unidentifiable mechanism that helps you bypass GFW
Documentation=https://github.com/p4gefau1t/trojan-go
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/opt/trojan-go/trojan-go -config /opt/trojan-go/config.json
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23
## AmbientCapabilities=CAP_NET_BIND_SERVICE
## CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```
### 配置文件```/opt/trojan-go/config.json```
```json
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443,
  "remote_addr": "xxxx.com",
  "remote_port": 80,
  "log_level": 1,
  "log_file": "",
  "password": [
    "passwd1",
    "passwd2"
],
  "buffer_size": 32,
  "dns": [
    "1.0.0.1",
    "8.8.4.4",
    "tcp://1.1.1.1",
    "dot://1.1.1.1"
  ],
  "disable_http_check": false,
  "ssl": {
    "verify": true,
    "verify_hostname": true,
    "cert": "xxx.crt",
    "key": "xxx.key",
    "key_password": "",
    "cipher": "",
    "cipher_tls13": "",
    "curves": "",
    "prefer_server_cipher": false,
    "sni": "xxxx.com",
    "alpn": [
      "http/1.1",
      "h2"
    ],
    "session_ticket": true,
    "reuse_session": true,
    "plain_http_response": "",
    "fallback_port": 1234,
    "fingerprint": "firefox",
    "serve_plain_text": false
  },
  "tcp": {
    "no_delay": true,
    "keep_alive": true,
    "reuse_port": false,
    "prefer_ipv4": false,
    "fast_open": false,
    "fast_open_qlen": 20
  },
  "mux": {
    "enabled": true,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "router": {
    "enabled": false,
    "bypass": [],
    "proxy": [],
    "block": [],
    "default_policy": "proxy",
    "domain_strategy": "as_is",
    "geoip": "/opt/trojan-go/geoip.dat",
    "geosite": "/opt/trojan-go/geosite.dat"
  },
  "websocket": {
    "enabled": true,
    "path": "/xxxx.xx",
    "hostname": "xxxx.com",
    "obfuscation_password": "xx@xx.xx",
    "double_tls": true,
    "ssl": {
      "verify": true,
      "verify_hostname": true,
      "cert": "xxx.crt",
      "key": "xxx.key",
      "key_password": "",
      "prefer_server_cipher": false,
      "sni": "lau.leam.ml",
      "session_ticket": true,
      "reuse_session": true,
      "plain_http_response": "",
      "key_log": ""
    }
  },
  "transport_plugin": {
    "enabled": false,
    "type": "",
    "command": "",
    "plugin_option": "",
    "arg": [],
    "env": []
  },
  "forward_proxy": {
    "enabled": false,
    "proxy_addr": "",
    "proxy_port": 0,
    "username": "",
    "password": ""
  },
  "mysql": {
    "enabled": false,
    "server_addr": "localhost",
    "server_port": 3306,
    "database": "",
    "username": "",
    "password": "",
    "check_rate": 60
  },
  "redis": {
    "enabled": false,
    "server_addr": "localhost",
    "server_port": 6379,
    "password": ""
  },
  "api": {
    "enabled": false,
    "api_addr": "",
    "api_port": 0,
    "api_tls": false,
    "ssl": {
      "cert": "",
      "key": "",
      "key_password": "",
      "client_cert": []
    }
  }
}
```

#### 配置证书
```
cd /opt/trojan-go
\\ 申请证书
sudo ./trojan-go -autocert request

\\重置证书
sudo ./trojan-go -autocert renew
```

### Caddy v1
```
http://xxx.xx:80 {
  gzip
  root /var/www/html
  timeouts none
  tls xxx@xxx.xx {
  protocols tls1.3
  curves x25519
  h2
 }

header / {
    Strict-Transport-Security "max-age=31536000;"
    X-XSS-Protection "1; mode=block"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
 }
}
```
