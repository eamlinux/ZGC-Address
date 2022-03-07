## 安装编译环境
```
sudo apt install build-essential libpcre3 libpcre3-dev zlib1g-dev libgd-dev libperl-dev libxslt1-dev libxml2-dev libgeoip-dev -y
```
## 下载nginx最新版
```
wget -c http://nginx.org/download/nginx-1.21.6.tar.gz
tar xf nginx-1.21.6.tar.gz
cd nginx-1.21.6
```
## 添加功能
```
git clone https://github.com/PhilipHazel/pcre2/releases/download/pcre2-10.39/pcre2-10.39.tar.gz
wget https://www.zlib.net/zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.1.1m.tar.gz
ls *.tar.gz | xargs -n1 tar xzf
```
## 创建CF.sh
```
#!/bin/sh
./configure --prefix=/opt/nginx \
            --sbin-path=/usr/local/bin/nginx \
            --modules-path=/opt/nginx/modules \
            --conf-path=/opt/nginx/nginx.conf \
            --error-log-path=/opt/nginx/log/error.log \
            --pid-path=/opt/nginx/run/nginx.pid \
            --lock-path=/opt/nginx/run/nginx.lock \
            --user=www-data \
            --group=www-data \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
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
            --http-log-path=/opt/nginx/log/access.log \
            --http-client-body-temp-path=/opt/nginx/cache/client_temp \
            --http-proxy-temp-path=/opt/nginx/cache/proxy_temp \
            --http-fastcgi-temp-path=/opt/nginx/cache/fastcgi_temp \
            --http-uwsgi-temp-path=/opt/nginx/cache/uwsgi_temp \
            --http-scgi-temp-path=/opt/nginx/cache/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=./pcre2-10.39 \
            --with-pcre-jit \
            --with-zlib=./zlib-1.2.11 \
            --with-openssl=./openssl-1.1.1m \
            --with-openssl-opt='enable-ec_nistp_64_gcc_128 no-ssl2 no-ssl3 no-comp no-idea no-dtls no-dtls1 no-shared no-psk no-srp no-ec2m no-weak-ssl-ciphers enable-tls1_3 -DOPENSSL_NO_HEARTBEATS -fstack-protector-strong' \
            --with-debug
```
