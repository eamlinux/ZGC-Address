apt install build-essential wget nano git binutils qrencode resolvconf

git clone https://github.com/WireGuard/wireguard-tools.git
cd wireguard-tools/src
make
strip -s wg
sudo cp ./wg /usr/local/bin/
sudo cp ./wg-quick/linux.bash /usr/local/bin/wg-quick
sudo mkdir -p /etc/wireguard
cd /etc/wireguard

nano /etc/systemd/system/wg-quick@.service


[Unit]
Description=WireGuard via wg-quick(8) for %I
After=network-online.target nss-lookup.target
Wants=network-online.target nss-lookup.target
PartOf=wg-quick.target
Documentation=man:wg-quick(8)
Documentation=man:wg(8)
Documentation=https://www.wireguard.com/
Documentation=https://www.wireguard.com/quickstart/
Documentation=https://git.zx2c4.com/wireguard-tools/about/src/man/wg-quick.8
Documentation=https://git.zx2c4.com/wireguard-tools/about/src/man/wg.8

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/wg-quick up %i
ExecStop=/usr/local/bin/wg-quick down %i
ExecReload=/bin/bash -c 'exec /usr/local/bin/wg syncconf %i <(exec /usr/local/bin/wg-quick strip %i)'
Environment=WG_ENDPOINT_RESOLUTION_RETRIES=infinity

[Install]
WantedBy=multi-user.target



wg genkey | tee sprivatekey | wg pubkey > spublickey
wg genkey | tee cprivatekey | wg pubkey > cpublickey

cat > wg0.conf <<-EOF
[Interface]
PrivateKey = $(cat sprivatekey)
Address = 10.0.0.1/24 
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE
ListenPort = 485
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $(cat cpublickey)
AllowedIPs = 10.0.0.2/32
EOF

cat > client.conf <<-EOF
[Interface]
PrivateKey = $(cat cprivatekey)
Address = 10.0.0.2/24 
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $(cat spublickey)
Endpoint = $ip:485
AllowedIPs = 0.0.0.0/0, ::0/0
PersistentKeepalive = 25
EOF


sudo systemctl daemon-reload
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0
cat client.conf | qrencode -o - -t UTF8
