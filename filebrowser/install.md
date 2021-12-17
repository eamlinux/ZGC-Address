### Install Sqlite3
```
sudo apt install wget sudo nano curl sqlite3 acl -y
```
### Install filebrowser
```
wget -c -t5 https://github.com/filebrowser/filebrowser/releases/download/v2.19.0/linux-amd64-filebrowser.tar.gz
tar zxf linux-amd64-filebrowser.tar.gz
chmod +x filebrowser
sudo mv filebrowser /usr/local/bin/
sudo chown root:root /usr/local/bin/filebrowser
sudo chmod 0755 /usr/local/bin/filebrowser
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/filebrowser
sudo mkdir -p /opt/fileserver/userdir
```
### Config filebrowser
#### config.json
```
sudo tee /opt/fileserver/config.json > /dev/null <<EOF
{
    "address":"127.0.0.1",
    "database":"/opt/fileserver/server.db",
    "log":"/opt/fileserver/log/filebrowser.log",
    "port":9000,
    "root":"/opt/fileserver/userdir",
    "username":"admin"
}
EOF
```
#### filebrowser.service
```
sudo tee /etc/systemd/system/filebrowser.service > /dev/null <<EOF
[Unit]
Description=Filebrowser Client Service
After=network.target

[Service]
User=nobody
Group=nogroup
ExecStart=/usr/local/bin/filebrowser --config /opt/fileserver/config.json
ExecReload=/usr/local/bin/filebrowser reload --config /opt/fileserver/config.json
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
```
### ACL
```
sudo setfacl -R -m u:nobody:rwx /opt/fileserver
```
### Systemctl Start
```
sudo systemctl daemon-reload
sudo systemctl enable --now filebrowser
```

### Caddy2 reverse_proxy
```
echo 'web.tk {
    encode gzip
    reverse_proxy localhost:9000
	
    log {
        output discard
    }

    tls {
        protocols tls1.3
        curves x25519
        key_type p384
        alpn h2
    }

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options nosniff
        X-Frame-Options SAMEORIGIN
        Referrer-Policy no-referrer-when-downgrade
    }

    handle_errors {
        respond "404 Not Found"
    }
	
    @grpc {
        protocol grpc
        path  /pathname/*
    }
    reverse_proxy @grpc h2c://127.0.0.1:10086 {
        header_up X-Real-IP {remote_host}
    }
}' | sudo tee /opt/caddy/Caddyfile
```