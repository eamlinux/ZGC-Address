## Debian10系统
```
sudo apt update
sudo apt upgrade
sudo apt install libsodium-dev wget unzip
```
## 安装V2ray
```
wget -c https://github.com/v2ray/v2ray-core/releases/download/v4.21.3/v2ray-linux-64.zip
unzip v2ray-linux-64.zip
```
sudo cp systemd/v2ray.service /etc/systemd/system/

sudo nano /etc/systemd/system/v2ray.service
[Unit]
Description=V2Ray Service
After=network.target
Wants=network.target

[Service]
User=nobody
Type=simple
PIDFile=/home/eamlinux/v2ray/v2ray.pid
ExecStart=/home/eamlinux/v2ray/v2ray -config /home/eamlinux/v2ray/config.json
Restart=on-failure
# Don't restart in the case of configuration error
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target


cat /proc/sys/kernel/random/uuid
```
{
  "inbounds": [
{
  "port": 8443,
  "listen": "0.0.0.0",
  "protocol": "vmess",
  "settings": {
    "clients": [
      {
        "id": "8d138d8d-aaaa-4634-b82b-33785cefc099",
        "alterId": 64
      }
    ]
  },
  "streamSettings": {
    "network": "tcp",
    "security": "tls",
    "tlsSettings": {
      "serverName": "pr02.leam.ml",
      "allowInsecure": true,
      "certificates": [
        {
          "certificateFile": "/home/eamlinux/.acme.sh/pr02.leam.ml_ecc/pr02.leam.ml.cer",
          "keyFile": "/home/eamlinux/.acme.sh/pr02.leam.ml_ecc/pr02.leam.ml.key"
        }
      ]
    },
    "tcpSettings": {
      "type": "none"
    }
  },
  "tag": "",
  "sniffing": {
    "enabled": true,
    "destOverride": [
      "http",
      "tls"
    ]
  }
 }
],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
```
