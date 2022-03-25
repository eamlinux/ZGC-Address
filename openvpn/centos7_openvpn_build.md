## 准备编译环境  
```bash
yum install -y epel-release sudo nano wget curl unzip
yum install -y pkcs11-helper lzo-devel pam-devel.x86_64 gcc gcc-c++ lz4-devel
yum install -y make gcc perl-core pcre-devel wget zlib-devel
yum autoremove -y openssl openssl-devel
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
