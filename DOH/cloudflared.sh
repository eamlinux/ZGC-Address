## cloudflared
wget https://github.com/cloudflare/cloudflared/releases/download/2021.3.6/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
mv cloudflared-linux-amd64 cloudflared
sudo mv cloudflared /usr/local/bin/

echo "[Unit]
Description=Cloudflare DNS over HTTPS proxy
After=network.target
Before=nss-lookup.target
Wants=nss-lookup.target

[Service]
User=caddy
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/cloudflared --no-autoupdate --logfile /dev/null --config /opt/cloudflared/config.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/cloudflared.service

## config.yml
sudo mkdir /opt/cloudflared

echo "proxy-dns: true
proxy-dns-port: 53
proxy-dns-upstream:
 - https://cloudflare-dns.com/dns-query
 - https://dns.google/dns-query
 - https://doh.opendns.com/dns-query" | sudo tee /opt/cloudflared/config.yml
