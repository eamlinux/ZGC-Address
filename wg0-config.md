## 生成公钥和私钥
```
wg genkey | tee sprivatekey | wg pubkey > spublickey
wg genkey | tee cprivatekey | wg pubkey > cpublickey
```
## 创建conf文件，```eth0```改成自己服务器的网卡名
```
cat > wg0.conf <<-EOF
[Interface]
PrivateKey = $(cat sprivatekey)
Address = 10.0.0.1/24 
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 443
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $(cat cpublickey)
AllowedIPs = 10.0.0.2/32
EOF
```
##### 客户端，```$ServerIP```改成自己的服务器IP
```
cat > client.conf <<-EOF
[Interface]
PrivateKey = $(cat cprivatekey)
Address = 10.0.0.2/24 
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $(cat spublickey)
Endpoint = $ServerIP:443
AllowedIPs = 0.0.0.0/0, ::0/0
PersistentKeepalive = 25
EOF
```
