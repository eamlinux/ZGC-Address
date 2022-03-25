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
## Configuer配置  
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
            with_sysroot=no
```
