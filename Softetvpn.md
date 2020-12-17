## Debian10系统下安装部署

### 安装编译环境
```
sudo apt -y install cmake gcc g++ libncurses5-dev libreadline-dev libssl-dev make zlib1g-dev curl git net-tools lsof htop libsodium-dev build-essential
```
### 拉取Softether源码编译
```
git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git
cd SoftEtherVPN
git submodule init && git submodule update
```
#### 修改Cmakelist解决```libraries: libcedar.so: cannot open shared object file: No such file or directory```错误
```
vi CMakeLists.txt
```
-------------------------------------------------修改部分----------------------------------------------------------------
#### 把内容
```
if(UNIX)
  include(GNUInstallDirs)
 
  include(CheckIncludeFile)
  Check_Include_File(sys/auxv.h HAVE_SYS_AUXV)
  if(EXISTS "/lib/systemd/system")
    set(CMAKE_INSTALL_SYSTEMD_UNITDIR "/lib/systemd/system" CACHE STRING "Where to install systemd unit files")
  endif()
endif()
```
#### 变成
```
if(UNIX)
  include(GNUInstallDirs)
  set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
 
  include(CheckIncludeFile)
  Check_Include_File(sys/auxv.h HAVE_SYS_AUXV)
  if(EXISTS "/lib/systemd/system")
    set(CMAKE_INSTALL_SYSTEMD_UNITDIR "/lib/systemd/system" CACHE STRING "Where to install systemd unit files")
  endif()
endif()
```
-----------------------------------------------------END----------------------------------------------------------------
### 进行编译
```
./configure --disable-documentation
make -C build
sudo make -C build install
```
### 编辑Softether启动文件
```
/lib/systemd/system/softether-vpnserver.service
```
#### 添加部分内容
```
[Unit]
Description=SoftEther VPN Server
After=network.target auditd.service
ConditionPathExists=!/usr/local/libexec/softether/vpnserver/do_not_run

[Service]
Type=forking
TasksMax=16777216
EnvironmentFile=-/usr/local/libexec/softether/vpnserver
ExecStart=/usr/local/libexec/softether/vpnserver/vpnserver start
ExecStop=/usr/local/libexec/softether/vpnserver/vpnserver stop

ExecStartPost=/bin/sleep 05
ExecStartPost=/bin/bash /usr/local/iptables.sh
ExecStartPost=/bin/sleep 03
ExecStartPost=/bin/systemctl start dnsmasq.service

KillMode=process
Restart=on-failure

# Hardening
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
ReadOnlyDirectories=/
ReadWriteDirectories=-/usr/local/libexec/softether/vpnserver
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYSLOG CAP_SETUID

[Install]
WantedBy=multi-user.target

```
#### 激活启动项
```
sudo systemctl enable softether-vpnserver
```
### 安装dnsmasq作为dhcp分配
```
sudo apt install dnsmasq
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf_bk
sudo nano /etc/dnsmasq.conf

-----------------------添加内容-----------------------------
interface=tap_soft
except-interface=ens3
#port=0
listen-address=192.168.30.1
bind-interfaces
dhcp-range=tap_soft,192.168.30.10,192.168.30.200,720h
dhcp-option=tap_soft,3,192.168.30.1
dhcp-authoritative
enable-ra
expand-hosts
strict-order
dhcp-no-override
domain-needed
dnssec
bogus-priv
stop-dns-rebind
rebind-localhost-ok
#dns-forward-max=300
no-poll
server=127.0.0.1#53453
proxy-dnssec
no-resolv
dhcp-option=option:dns-server,192.168.30.1
#dhcp-option=option6:dns-server,[2a00:5a60::ad2:0ff],[2a00:5a60::ad1:0ff]
cache-size=10000
neg-ttl=80000
local-ttl=3600
dhcp-option=23,64
dhcp-option=vendor:MSFT,2,1i
dhcp-option=44,192.168.30.1
dhcp-option=45,192.168.30.1
dhcp-option=46,8
dhcp-option=47
read-ethers
log-facility=/var/log/dnsmasq.log
log-async=5

#log-dhcp
#quiet-dhcp6
#dhcp-option=3,192.168.30.1
-------------------------END---------------------------
```
### 编辑防火墙转发脚本```/usr/local/iptables.sh```
```
#!/bin/bash
/sbin/ifconfig tap_soft 192.168.30.1
iptables -t nat -A POSTROUTING -s 192.168.30.0/24 -j SNAT --to-source 172.17.51.162
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -s 192.168.30.0/24 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 192.168.30.0/24 -m state --state NEW -j ACCEPT
iptables -A FORWARD -s 192.168.30.0/24 -m state --state NEW -j ACCEPT
```
### 禁止dnsmasq开机启动，由softether控制
```
sudo systemctl disable dnsmasq
```
```
wget -c https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.tgz
tar xf cloudflared-stable-linux-amd64.tgz

curl https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.tgz | sudo tar xzC /usr/local/bin/
```
sudo apt install ufw && /etc/ufw/sysctl.conf
```
# Uncomment this to allow this host to route packets between interfaces
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
etc/default/ufw
```
DEFAULT_FORWARD_POLICY="ACCEPT"
sudo nano /etc/modules
iptable_nat
ip6table_nat
```
```
#/etc/sysctl.conf
#```
#net.core.default_qdisc=fq
#net.ipv4.tcp_congestion_control=bbr

#net.core.somaxconn=4096
#net.ipv4.conf.all.send_redirects = 0
#net.ipv4.conf.all.accept_redirects = 1
#net.ipv4.conf.all.rp_filter = 1
#net.ipv4.conf.default.send_redirects = 1
#net.ipv4.conf.default.proxy_arp = 0
#```
```

/etc/systemd/system/cloudflared.service
```
[Unit]
Description=Cloudflare DNS over HTTPS proxy
After=network.target
Before=nss-lookup.target
Wants=nss-lookup.target

[Service]
User=cloudflared
ExecStart=/usr/local/bin/cloudflared --no-autoupdate --logfile /var/log/cloudflared/cloudflared.log --config /usr/local/etc/cloudflared/config.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
sudo systemctl enable cloudflared

sudo mkdir -p /usr/local/etc/cloudflared
sudo nano /usr/local/etc/cloudflared/config.yml
```
proxy-dns: true
proxy-dns-port: 53453
proxy-dns-upstream:
 - https://1.1.1.1/dns-query
 - https://1.0.0.1/dns-query
 ```
 ```
 useradd -r -M -s /usr/sbin/nologin cloudflared
 mkdir -p /var/log/cloudflared
 sudo chown -R cloudflared:cloudflared /var/log/cloudflared
 sudo chown -R cloudflared:cloudflared /usr/local/etc/cloudflared
 ```
 ## for use vps os
```
sudo systemctl stop unattended-upgrades
sudo systemctl disable unattended-upgrades
sudo systemctl stop rdnssd
sudo systemctl disable rdnssd
sudo systemctl stop resolvconf
sudo systemctl disable resolvconf
sudo apt purge --auto-remove resolvconf rdnssd
sudo rm -rf /lib/resolvconf
```
使用 DHCP 钩子
sudo nano /etc/dhcp/dhclient-enter-hooks.d/nodnsupdate
```
#!/bin/sh
make_resolv_conf(){
    :
}
```
sudo chmod +x /etc/dhcp/dhclient-enter-hooks.d/nodnsupdate
 && 
sudo nano /etc/resolv.conf
```
nameserver 127.0.0.1
```
#sudo systemctl enable cloudflared && 
sudo systemctl daemon-reload
 && 
sudo /usr/local/bin/vpnserver start
# 用管理端登陸設置密碼，並添加一個soft網橋
sudo /usr/local/bin/vpnserver stop


sudo tzselect

#4

#9

#1

sudo rm /etc/localtime

sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

sudo nano /etc/locale.gen

#修改zh_CN系列，按地區設置 ，美國不用設置 

sudo locale-gen

sudo dpkg-reconfigure locales

##中国区

sudo nano /etc/default/locale
```
LANG="zh_CN.UTF-8"
LANGUAGE="zh_CN:zh"
```

sudo reboot



