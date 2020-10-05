### 安装编译环境
```
sudo apt -y install build-essential cmake libboost-system-dev libboost-program-options-dev libssl-dev
```
### 拉取源码并编译
```
git clone --depth=1 https://github.com/trojan-gfw/trojan.git
cd trojan/
mkdir build
cd build/
cmake .. -DENABLE_MYSQL=OFF -DENABLE_NAT=OFF -DENABLE_TLS13_CIPHERSUITES=ON
make
sudo mv trojan /usr/local/bin/
sudo chown root:root /usr/local/bin/trojan
sudo chmod 0755 /usr/local/bin/trojan
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/trojan
```
### systemd ```sudo nano /etc/systemd/system/trojan.service```
```
[Unit]
Description=trojan
Documentation=man:trojan(1) https://trojan-gfw.github.io/trojan/config https://trojan-gfw.github.io/trojan/
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service

[Service]
Type=simple
StandardError=journal
User=caddy
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/trojan /opt/trojan/config.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
```
### server.json
```
sudo mkdir /opt/trojan
sudo nano /opt/trojan/config.json
```
#### 具体内容根据自己需要修改
```json
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "password1",
        "password2"
    ],
    "log_level": 5,
    "ssl": {
        "cert": "/path/to/certificate.crt",
        "key": "/path/to/private.key",
        "key_password": "",
        "cipher": false,
        "cipher_tls13": "TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": ["h2"],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
```
#### Caddy v1 file
```
http://web.cc:80 {
  gzip
  root /var/www/html
  tls 123@123.cc {
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
}
```

### NGINX
```
server {
    listen 127.0.0.1:80 default_server http2;
    server_name web.com;
    location / {
      root /var/www/html;
      index index.html index.htm;
    }
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}

server {
    listen 127.0.0.1:80 http2;
    server_name $server ip;
    return 301 https://web.com$request_uri;
}

server {
    listen 0.0.0.0:80 http2;
    listen [::]:80;
    server_name _;
    return 301 https://web.com$request_uri;
}
```
至此就可以使用了。
