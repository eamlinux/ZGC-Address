sudo tee ./client.ovpn > /dev/null <<EOF
client
proto udp
remote xx.xx.xx.xx 23456
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
explicit-exit-notify
sndbuf 0
rcvbuf 0
verify-x509-name server_001 name
auth SHA384
auth-nocache
cipher AES-256-GCM
data-ciphers AES-256-GCM
tls-client
tls-version-min 1.3
tls-ciphersuites TLS_AES_256_GCM_SHA384
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns
verb 3
<ca>
$(cat /opt/openvpn/ca.crt)
</ca>
<cert>
$(cat /opt/easy-rsa/pki/issued/client001.crt)
</cert>
<key>
$(cat /opt/easy-rsa/pki/private/client001.key)
</key>
<tls-crypt>
$(cat /opt/openvpn/tls-crypt.key)
</tls-crypt>
EOF
