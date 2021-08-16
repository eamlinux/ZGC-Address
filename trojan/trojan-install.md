# Debian10系统

## 安装trojan
```
wget -c https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
tar xf trojan-1.16.0-linux-amd64.tar.xz
cd trojan
sudo mv trojan /usr/local/bin/
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/trojan
```
## 生成trojan服务
```
cat > trojan.service << EOF
[Unit]
Description=trojan
Documentation=man:trojan(1) https://trojan-gfw.github.io/trojan/config https://trojan-gfw.github.io/trojan/
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service

[Service]
Type=simple
StandardError=journal
User=acme
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/trojan /opt/trojan/server.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF
```
## 激活trojan开机自启
```
sudo mv trojan.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable trojan
```
## 生成证书：
```
sudo apt install socat ufw curl
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/socat
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
sudo ufw default deny
sudo ufw reload
sudo useradd -r -m -s /bin/bash acme
sudo su -l acme
curl  https://get.acme.sh | sh
exit
sudo su -l acme
acme.sh --set-default-ca  --server  letsencrypt
acme.sh --issue -d 你的域名 --keylength ec-384 --standalone
# acme.sh --issue -d domain.com -w /var/www/html --keylength ec-384 --server letsencrypt
# acme.sh --issue -d domain.com -d www.domain.com -d dev.domain.com -w /var/www/html --keylength ec-384 --server letsencrypt
mkdir cert
acme.sh --install-cert -d 你的域名 --key-file /home/acme/cert/private.key --fullchain-file /home/acme/cert/certificate.crt --ecc
acme.sh --upgrade --auto-upgrade
exit
```
## 建立trojan配置
```
sudo mkdir -p /opt/trojan
sudo nano /opt/trojan/server.json
```
#### 版配置内容，根据你的实际情况更改
```json
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "passwd1",
        "passwd2"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/etc/ssl/xxx.crt",
        "key": "/etc/ssl/xxx.key",
        "key_password": "",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "h2"
        ],
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
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
```
## 安装nginx伪装
```
sudo apt install nginx-full
```
#### 配置nginx高防
```
sudo rm /etc/nginx/sites-enabled/default
sudo nano /etc/nginx/sites-available/xxx

///内容如下：

server {
    listen 127.0.0.1:80 default_server http2;
    server_name 你的域名;
    location / {
        proxy_pass https://www.ietf.org;
    }
}

server {
    listen 127.0.0.1:80 http2;
    server_name 主机外网IP;
    return 301 https://你的域名$request_uri;
}

server {
    listen 0.0.0.0:80;
    listen [::]:80;
    server_name _;
    return 301 https://你的域名$request_uri;
}

///内容分隔

sudo ln -s /etc/nginx/sites-available/xxx /etc/nginx/sites-enabled/
sudo systemctl restart nginx
sudo systemctl start trojan
```
## windows客户端配置
```json
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "你的域名",
    "remote_port": 443,
    "password": [
        "服务器中设置的其中一个密码"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "sni": "",
        "alpn": [
            "h2"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
```

##### 其中有什么坑我也不知道，肯定是小坑，自己填一下，不难。
  
