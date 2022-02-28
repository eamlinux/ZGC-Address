## 编译环境
```
sudo apt install binutils iptables build-essential automake autoconf libtool m4 liblz4-tool liblz4-dev liblzo2-dev libssl-dev libpam0g-dev libcmocka-dev pkg-config libpkcs11-helper1-dev libsystemd-dev -y
wget https://swupdate.openvpn.org/community/releases/openvpn-2.5.5.tar.gz
wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
```
## 编译openvpn
```
tar xf openvpn-2.5.5.tar.gz
cd openvpn-2.5.5/
nano cf.sh
chmod +x cf.sh
./cf.sh
make
strip -s src/openvpn/openvpn
sudo mv src/openvpn/openvpn /usr/sbin/openvpn
sudo chown root:root /usr/sbin/openvpn
sudo chmod 0755 /usr/sbin/openvpn
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/openvpn
```
> ```cf.sh```内容
```
#!/bin/sh
./configure --enable-async-push=no \
            --enable-comp-stub=no \
            --enable-crypto-ofb-cfb=yes \
            --enable-debug=yes \
            --enable-def-auth=yes \
            --enable-dependency-tracking=no \
            --enable-dlopen=unknown \
            --enable-dlopen-self=unknown \
            --enable-dlopen-self-static=unknown \
            --enable-fast-install=needless \
            --enable-fragment=yes \
            --enable-iproute2=no \
            --enable-libtool-lock=yes \
            --enable-lz4=yes \
            --enable-lzo=yes \
            --enable-maintainer-mode=no \
            --enable-management=yes \
            --enable-multihome=yes \
            --enable-option-checking=no \
            --enable-pam-dlopen=no \
            --enable-pedantic=no \
            --enable-pf=yes \
            --enable-pkcs11=yes \
            --enable-plugin-auth-pam=yes \
            --enable-plugin-down-root=yes \
            --enable-plugins=yes \
            --enable-port-share=yes \
            --enable-selinux=no \
            --enable-shared=yes \
            --enable-shared-with-static-runtimes=no \
            --enable-silent-rules=no \
            --enable-small=no \
            --enable-static=yes \
            --enable-strict=no \
            --enable-strict-options=no \
            --enable-systemd=yes \
            --enable-werror=no \
            --enable-win32-dll=yes \
            --enable-x509-alt-username=yes \
            --with-aix-soname=aix \
            --with-crypto-library=openssl \
            --with-gnu-ld=yes \
            --with-mem-check=no \
            --with-sysroot=no
```
## 证书与Server配置
```
sudo mkdir -p /opt/easy-rsa /opt/openvpn
sudo tar zxf ./EasyRSA-3.0.8.tgz --strip-components=1 --directory /opt/easy-rsa
cd /opt/easy-rsa/
sudo nano vars
sudo ./easyrsa init-pki
sudo ./easyrsa --batch build-ca nopass
sudo ./easyrsa build-server-full server_001 nopass
sudo ./easyrsa build-client-full client001 nopass
sudo ./easyrsa gen-crl
sudo openvpn --genkey secret /opt/openvpn/tls-crypt.key
sudo cp pki/ca.crt pki/private/ca.key pki/issued/server_001.crt pki/private/server_001.key pki/crl.pem /opt/openvpn
sudo chmod 644 /opt/openvpn/crl.pem
cd /opt/openvpn/
sudo nano /opt/openvpn/server.conf
sudo mkdir -p /opt/openvpn/ccd /opt/openvpn/log
```
> ```VARS```内容
```
set_var EASYRSA_OPENSSL        "openssl"
set_var EASYRSA_REQ_COUNTRY    "CN"
set_var EASYRSA_REQ_PROVINCE   "GuangDong"
set_var EASYRSA_REQ_CITY       "DongGuan"
set_var EASYRSA_REQ_ORG        "Sa Inc."
set_var EASYRSA_REQ_EMAIL      "1744@qq.com"
set_var EASYRSA_REQ_OU         "Sa"
set_var EASYRSA_ALGO           ec
set_var EASYRSA_CURVE          secp384r1
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    3650
set_var EASYRSA_DIGEST         "sha384"
set_var EASYRSA_REQ_CN         "server_001"
set_var EASYRSA_CRL_DAYS       3650
```
> ```Server.conf```内容
```
port 23456
proto udp
dev tun0
dev-type tun
user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
topology subnet
server 10.11.12.0 255.255.255.0
;ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 1.0.0.1"
push "dhcp-option DNS 1.1.1.1"
push "redirect-gateway def1 bypass-dhcp"
dh none
ecdh-curve secp384r1
tls-crypt tls-crypt.key
crl-verify crl.pem
ca ca.crt
cert server_001.crt
key server_001.key
auth SHA384
cipher AES-256-GCM
data-ciphers AES-256-GCM
tls-server
tls-version-min 1.3
tls-ciphersuites TLS_AES_256_GCM_SHA384
client-config-dir ccd
status log/status.log
verb 3
duplicate-cn
explicit-exit-notify 1
sndbuf 0
rcvbuf 0
```
## 防火墙配置
```
sudo nano /opt/openvpn/add-bridge.sh
```
> 内容
```
#!/bin/sh
IF=eth0
TunIF=tun0

iptables -t nat -I POSTROUTING 1 -s 10.11.12.0/24 -o ${IF} -j MASQUERADE
iptables -I INPUT 1 -i ${TunIF} -j ACCEPT
iptables -I FORWARD 1 -i ${IF} -o ${TunIF} -j ACCEPT
iptables -I FORWARD 1 -i ${TunIF} -o ${IF} -j ACCEPT
iptables -I INPUT 1 -i ${IF} -p udp --dport 23456 -j ACCEPT
```
```
sudo nano /opt/openvpn/remove-bridge.sh
```
> 内容
```
#!/bin/sh
IF=eth0
TunIF=tun0

iptables -t nat -D POSTROUTING -s 10.11.12.0/24 -o ${IF} -j MASQUERADE
iptables -D INPUT -i ${TunIF} -j ACCEPT
iptables -D FORWARD -i ${IF} -o ${TunIF} -j ACCEPT
iptables -D FORWARD -i ${TunIF} -o ${IF} -j ACCEPT
iptables -D INPUT -i ${IF} -p udp --dport 23456 -j ACCEPT
```
> 权限
```
sudo chmod +x /opt/openvpn/{add-bridge.sh,remove-bridge.sh}
sudo chmod 700 /opt/openvpn/{add-bridge.sh,remove-bridge.sh}
```
### Set eth0
```
nano /etc/default/grub
```
> 修改内容
```
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
```
## 开机启动脚本
```
sudo tee /etc/systemd/system/openvpn@.service > /dev/null <<EOF
[Unit]
Description=OpenVPN service for %I
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
PrivateTmp=true
WorkingDirectory=/opt/openvpn
ExecStart=/usr/sbin/openvpn --status %t/openvpn-server/status-%i.log --status-version 2 --suppress-timestamps --config %i.conf
ExecStartPost=/opt/openvpn/add-bridge.sh
ExecStopPost=/opt/openvpn/remove-bridge.sh
CapabilityBoundingSet=CAP_IPC_LOCK CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW CAP_SETGID CAP_SETUID CAP_SYS_CHROOT CAP_DAC_OVERRIDE CAP_AUDIT_WRITE
LimitNPROC=10
DeviceAllow=/dev/null rw
DeviceAllow=/dev/net/tun rw
ProtectSystem=true
ProtectHome=true
KillMode=process
RestartSec=5s
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```
> 开机启动  
```
sudo systemctl daemon-reload
sudo systemctl enable --now openvpn@server
```  

## 客户端配置
```sh
client
proto udp
remote xx.xx.xx.xx 23456
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
explicit-exit-notify
sndbuf 0
rcvbuf 0
verify-x509-name server_001 name
auth SHA384
auth-nocache
cipher AES-256-GCM
data-ciphers AES-256-GCM
tls-client
tls-version-min 1.3
tls-ciphersuites TLS_AES_256_GCM_SHA384
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns
verb 3
<ca>
# /opt/openvpn/ca.crt
</ca>
<cert>
# /opt/easy-rsa/pki/issued/client001.crt
</cert>
<key>
# /opt/easy-rsa/pki/private/client001.key
</key>
<tls-crypt>
# /opt/openvpn/tls-crypt.key
</tls-crypt>
```
> 2
```
sudo tee ./client.ovpn > /dev/null <<EOF
client
proto udp
remote xx.xx.xx.xx 23456
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
explicit-exit-notify
sndbuf 0
rcvbuf 0
verify-x509-name server_001 name
auth SHA384
auth-nocache
cipher AES-256-GCM
data-ciphers AES-256-GCM
tls-client
tls-version-min 1.3
tls-ciphersuites TLS_AES_256_GCM_SHA384
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns
verb 3
<ca>
$(cat /opt/openvpn/ca.crt)
</ca>
<cert>
$(cat /opt/easy-rsa/pki/issued/client001.crt | awk '/BEGIN/,/END/')
</cert>
<key>
$(cat /opt/easy-rsa/pki/private/client001.key)
</key>
<tls-crypt>
$(cat /opt/openvpn/tls-crypt.key)
</tls-crypt>
EOF
```
```
echo 'net.ipv4.ip_forward=1' >/etc/sysctl.d/99-openvpn.conf
```
