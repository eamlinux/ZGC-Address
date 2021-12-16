## git clone
```
sudo apt -y install cmake gcc g++ make libncurses5-dev libssl-dev libsodium-dev libreadline-dev zlib1g-dev pkg-config
git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git
cd SoftEtherVPN
git submodule init && git submodule update
./configure
make -C build

strip -s build/vpn* build/lib*

sudo mkdir /opt/vpnserver
sudo mv build/{hamcore.se2,libcedar.so,libmayaqua.so,vpncmd,vpnserver} /opt/vpnserver/

cd /opt/vpnserver
sudo ln -s /opt/vpnserver/lib* /usr/local/lib/
sudo ldconfig
sudo ./vpnserver
```
## systemd
```
sudo nano /etc/systemd/system/vpnserver.service

[Unit]
Description=SoftEther VPN Server
After=network.target auditd.service
ConditionPathExists=!/opt/vpnserver/do_not_run

[Service]
Type=forking
EnvironmentFile=-/opt/vpnserver
ExecStart=/opt/vpnserver/vpnserver start
ExecStop=/opt/vpnserver/vpnserver stop
ExecStartPost=/bin/sleep 05
ExecStartPost=/opt/vpnserver/add-bridge.sh
ExecStopPost=/opt/vpnserver/remove-bridge.sh
KillMode=process
Restart=on-failure

# Hardening
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
ReadOnlyDirectories=/
ReadWriteDirectories=-/opt/vpnserver
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYS_ADMIN CAP_SETUID

[Install]
WantedBy=multi-user.target
```
## iptables
```
/opt/vpnserver/add-bridge.sh

#!/bin/bash
IF=ens5
VPNIF=tap_soft

ip addr add 192.168.30.1/24 dev ${VPNIF}
iptables -A FORWARD -i ${VPNIF} -j ACCEPT
iptables -t nat -A POSTROUTING -o ${IF} -j MASQUERADE



/opt/vpnserver/remove-bridge.sh

#!/bin/bash
IF=ens5
VPNIF=tap_soft

ip addr del 192.168.30.1/24 dev ${VPNIF}
iptables -D FORWARD -i ${VPNIF} -j ACCEPT
iptables -t nat -D POSTROUTING -o ${IF} -j MASQUERADE
```
## /etc/dnsmasq.conf
```
interface=tap_soft
bind-interfaces
port=0
dhcp-range=tap_soft,192.168.30.10,192.168.30.254,24h
dhcp-option=tap_soft,3,192.168.30.1
dhcp-option=option:dns-server,180.76.76.76,223.5.5.5
dhcp-authoritative
dhcp-no-override
```

## dnsmasq.service
```
[Unit]
Description=dnsmasq - A lightweight DHCP and caching DNS server
After=vpnserver.service

[Service]
Type=forking
PIDFile=/run/dnsmasq/dnsmasq.pid
ExecStartPre=/etc/init.d/dnsmasq checkconfig
ExecStart=/etc/init.d/dnsmasq systemd-exec
ExecStartPost=/etc/init.d/dnsmasq systemd-start-resolvconf
ExecStop=/etc/init.d/dnsmasq systemd-stop-resolvconf


ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
```
## 优化
```
sudo apt install curl ufw -y
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo "y" | sudo ufw enable
sudo ufw logging off
sudo ufw reload
```
## limits
```
echo '* soft nofile 51200
* hard nofile 51200
* soft nproc 51200
* hard nproc 51200

root soft nofile 51200
root hard nofile 51200
root soft nproc 51200
root hard nproc 51200' | sudo tee -a /etc/security/limits.conf
```
## Uncomment this to allow this host to route packets between interfaces
```
net/ipv4/ip_forward=1
net/ipv6/conf/default/forwarding=1
net/ipv6/conf/all/forwarding=1

net/core/default_qdisc=fq
net/ipv4/tcp_congestion_control=bbr
net/core/somaxconn=4096
net/ipv4/conf/all/send_redirects=0
net/ipv4/conf/all/rp_filter=1
net/ipv4/conf/default/send_redirects=1
net/ipv4/conf/default/proxy_arp=0
net/ipv4/conf/all/accept_redirects=1
```
