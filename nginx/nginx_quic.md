## 安装编译环境
```
sudo apt install build-essential libpcre3 libpcre3-dev zlib1g-dev libgd-dev libperl-dev libxslt1-dev libxml2-dev libgeoip-dev cmake
```
## 安装cargo
```
curl https://sh.rustup.rs -sSf | sh
source ~/.profile
```
## 拉取quic path
```
wget -c http://nginx.org/download/nginx-1.19.2.tar.gz
tar xf nginx-1.19.2.tar.gz
cd nginx-1.19.2
wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
wget https://www.zlib.net/zlib-1.2.11.tar.gz
git clone --recursive https://github.com/cloudflare/quiche
patch -p01 < quiche/extras/nginx/nginx-1.16.patch
```
## cf.sh
```
#!/bin/sh
./configure --prefix=/etc/nginx \
            --sbin-path=/usr/local/bin/nginx \
            --modules-path=/etc/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=www-data \
            --group=www-data \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_v3_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=./pcre-8.44 \
            --with-pcre-jit \
            --with-zlib=./zlib-1.2.11 \
            --with-openssl=./quiche/deps/boringssl \
            --with-quiche=./quiche \
            --with-debug
```
编译即可！
