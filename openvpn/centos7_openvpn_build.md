## 准备编译环境  
```bash
yum autoremove -y openssl openssl-devel
yum install -y epel-release
yum install -y pkcs11-helper lzo-devel pam-devel.x86_64 gcc gcc-c++ lz4-devel make perl-core pcre-devel wget zlib-devel systemd-devel nano sudo wget curl unzip
ldconfig
```
## 更新OpenSSL
```
wget https://ftp.openssl.org/source/openssl-1.1.1n.tar.gz
tar -xzvf openssl-1.1.1n.tar.gz
cd openssl-1.1.1n
./config enable-tls1_3 --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic -Wl,-rpath=/usr/local/ssl/lib -Wl,--enable-new-dtags
make
make test
make install
ldconfig
```
> 或者
```
cd ~
git clone git://git.openssl.org/openssl.git
cd openssl/
./config enable-tls1_3 --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic -Wl,-rpath=/usr/local/ssl/lib -Wl,--enable-new-dtags
make
make test
make install
ldconfig
openssl version -a
```
## 编译Openvpn  
```
wget https://swupdate.openvpn.org/community/releases/openvpn-2.5.6.tar.gz
tar xf openvpn-2.5.6.tar.gz
cd openvpn-2.5.6
nano cf.sh
chmod +x cf.sh
./conf.sh
make
strip -s src/openvpn/openvpn
sudo mv src/openvpn/openvpn /usr/sbin/openvpn
sudo chown root:root /usr/sbin/openvpn
sudo chmod 0755 /usr/sbin/openvpn
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/openvpn
```
> CF.sh配置  
```
#!/bin/sh
./configure enable_async_push=yes \
            enable_comp_stub=no \
            enable_crypto_ofb_cfb=yes \
            enable_debug=yes \
            enable_def_auth=yes \
            enable_dependency_tracking=no \
            enable_dlopen=unknown \
            enable_dlopen_self=unknown \
            enable_dlopen_self_static=unknown \
            enable_fast_install=yes \
            enable_fragment=yes \
            enable_iproute2=no \
            enable_libtool_lock=yes \
            enable_lz4=yes \
            enable_lzo=yes \
            enable_management=yes \
            enable_multihome=yes \
            enable_pam_dlopen=no \
            enable_pedantic=no \
            enable_pf=yes \
            enable_pkcs11=no \
            enable_plugin_auth_pam=yes \
            enable_plugin_down_root=yes \
            enable_plugins=yes \
            enable_port_share=yes \
            enable_selinux=yes \
            enable_shared=yes \
            enable_shared_with_static_runtimes=no \
            enable_silent_rules=yes \
            enable_small=no \
            enable_static=yes \
            enable_strict=no \
            enable_strict_options=no \
            enable_systemd=yes \
            enable_werror=no \
            enable_win32_dll=yes \
            enable_x509_alt_username=yes \
            with_aix_soname=aix \
            with_crypto_library=openssl \
            with_gnu_ld=yes \
            with_mem_check=no \
            with_sysroot=no \
            --disable-dco
```
## 创建证书  
```
sudo mkdir -p /opt/easy-rsa /opt/openvpn
wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
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
sudo mkdir -p /opt/openvpn/ccd /opt/openvpn/log
sudo nano /opt/openvpn/server.conf
```
> VARS内容
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
> server.conf
```
port 23456
proto udp
dev tun0
dev-type tun
user nobody
group nobody
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
