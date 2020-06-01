### 编译trojan-go
```
git clone --depth=1 https://github.com/p4gefau1t/trojan-go.git
cd trojan-go/
env CGO_ENABLED=0 go build -o $HOME/trojan-god -ldflags "-s -w" -tags "router server auth_mysql auth_redis relay cert other"
sudo mv $HOME/trojan-god /usr/local/bin/trojan-go
sudo chown root:root /usr/local/bin/trojan-go
sudo chmod 0755 /usr/local/bin/trojan-go
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/trojan-go
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
ExecStart=/usr/local/bin/trojan-go -config /opt/trojan-go/config.json
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
```
### 配置文件```/opt/trojan-go/config.json```
```
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "your_password"
    ],
    "ssl": {
        "cert": "your_cert.crt",
        "key": "your_key.key"
    }
}
```
