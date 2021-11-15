apt -y update  
apt -y install curl git nginx-full libnginx-mod-stream wget  
rm -rf /usr/bin/v2ray /var/log/v2ray /etc/v2ray /etc/systemd/system/v2ray.service  
systemctl daemon-reload  
nano /etc/nginx/nginx.conf  
```
stream {
        map $ssl_preread_server_name $user_xray {
                web.tk xtls;
        }
        upstream xtls {
                server 127.0.0.1:10086;
        }
        server {
                listen 443      reuseport;
                listen [::]:443 reuseport;
                proxy_pass      $user_xray;
                ssl_preread     on;
        }
}
```

cd /var/www/html  
git clone https://github.com/tusenpo/FlappyFrog.git flappyfrog  
```
sudo apt install socat ufw
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
acme.sh --issue -d web.tk --keylength ec-384 --standalone --server letsencrypt
```
nano /etc/nginx/conf.d/fallback.conf  
```
server {
        listen 80;
        server_name web.tk;
        if ($host = web.tk) {
                return 301 https://$host$request_uri;
        }
        return 404;
}

server {
        listen 127.0.0.1:8433;
        server_name web.tk;
        index index.html;
        root /var/www/html/flappyfrog;
}
```
wget https://github.com/XTLS/Xray-core/releases/download/v1.4.5/Xray-linux-64.zip 
unzip -d xray Xray-linux-64.zip 
sudo mv xray/xray /usr/local/bin/ 
```
cat > /etc/systemd/system/xray@.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=acme
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /opt/xray/%i.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
```
cat /proc/sys/kernel/random/uuid
```
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "listen": "127.0.0.1",
            "port": 10086,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "7f46753a-6a4b-4284-94c0-760340f96f1e",
                        "flow": "xtls-rprx-direct",
                        "level": 0
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": "8433"
                    }
                 ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "acme/.acme.sh/xxx.cer",
                            "keyFile": "acme/.acme.sh/xxx.key"
                        }
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
```
