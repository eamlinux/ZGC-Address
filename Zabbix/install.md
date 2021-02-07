## Debian10 + mariadb server + nginx + php + Zabbix 5.2
```
wget https://repo.zabbix.com/zabbix/5.2/debian/pool/main/z/zabbix-release/zabbix-release_5.2-1+debian10_all.deb
sudo dpkg -i zabbix-release_5.2-1+debian10_all.deb
sudo apt update
sudo apt install php7.3-fpm mariadb-server nginx-full
sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-agent2
sudo mysql_secure_installation
sudo mysql -u root -p
> create database zabbix character set utf8 collate utf8_bin;
> create user zabbixuser@localhost identified by 'password';
> grant all privileges on zabbix.* to zabbixuser@localhost;
> flush privileges;
> quit;
```
### Database
```
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbixuser -p zabbix
```
### nginx
```
sudo nano /etc/nginx/conf.d/zabbix.conf
```
```
server {
        listen          80;
        server_name     example.com;

        root    /usr/share/zabbix;

        index   index.php;

        location = /favicon.ico {
                log_not_found   off;
        }

        location / {
                try_files       $uri $uri/ =404;
        }

        location /assets {
                access_log      off;
                expires         10d;
        }

        location ~ /\.ht {
                deny            all;
        }

        location ~ /(api\/|conf[^\.]|include|locale) {
                deny            all;
                return          404;
        }

        location ~ [^/]\.php(/|$) {
                fastcgi_pass    unix:/var/run/php/zabbix.sock;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_index   index.php;

                fastcgi_param   DOCUMENT_ROOT   /usr/share/zabbix;
                fastcgi_param   SCRIPT_FILENAME /usr/share/zabbix$fastcgi_script_name;
                fastcgi_param   PATH_TRANSLATED /usr/share/zabbix$fastcgi_script_name;

                include fastcgi_params;
                fastcgi_param   QUERY_STRING    $query_string;
                fastcgi_param   REQUEST_METHOD  $request_method;
                fastcgi_param   CONTENT_TYPE    $content_type;
                fastcgi_param   CONTENT_LENGTH  $content_length;

                fastcgi_intercept_errors        on;
                fastcgi_ignore_client_abort     off;
                fastcgi_connect_timeout         60;
                fastcgi_send_timeout            180;
                fastcgi_read_timeout            180;
                fastcgi_buffer_size             128k;
                fastcgi_buffers                 4 256k;
                fastcgi_busy_buffers_size       256k;
                fastcgi_temp_file_write_size    256k;
        }
}
```
### PHP
```
sudo nano /etc/php/7.3/fpm/pool.d/zabbix.conf
```
```
[zabbix]
user = www-data
group = www-data

listen = /var/run/php/zabbix.sock
listen.owner = acme ##systemd的nginx用户相同
listen.allowed_clients = 127.0.0.1

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/sessions/

php_value[max_execution_time] = 300
php_value[memory_limit] = 128M
php_value[post_max_size] = 16M
php_value[upload_max_filesize] = 2M
php_value[max_input_time] = 300
php_value[max_input_vars] = 10000
; php_value[date.timezone] = Europe/Riga
```
### zabbix server
```
sudo nano /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBUser=zabbixuser
DBPassword=password
```
#### font
scp windows font ```simkai.ttf``` to linux /home/user
```
sudo mv simkai.ttf /usr/share/zabbix/fonts/
sudo chown -R root:root /usr/share/zabbix/fonts/
sudo chmod 0755 /usr/share/zabbix/fonts/simkai.ttf
ls -l /usr/share/zabbix/fonts/
sudo rm -f /etc/alternatives/zabbix-frontend-font
sudo ln -s /usr/share/zabbix/fonts/simkai.ttf /etc/alternatives/zabbix-frontend-font
```
### restart
```
sudo systemctl restart zabbix-server zabbix-agent2 nginx php7.3-fpm
```
