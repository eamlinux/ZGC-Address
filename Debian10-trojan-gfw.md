### 安装编译环境
```
sudo apt -y install build-essential cmake libboost-system-dev libboost-program-options-dev libssl-dev default-libmysqlclient-dev
```
### 拉取源码并编译
```
git clone https://github.com/trojan-gfw/trojan.git
cd trojan/
mkdir build
cd build/
cmake ..
make
sudo mv trojan /usr/local/bin/
sudo chown root:root /usr/local/bin/trojan
sudo chmod 0755 /usr/local/bin/trojan
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/trojan
```
### systemd ...sudo nano /etc/systemd/system/trojan.service...
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
