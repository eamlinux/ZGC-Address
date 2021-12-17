## /opt/vpnclient/dhclient.sh
```
#!/bin/bash
sleep 5
/opt/vpnclient/vpncmd /client localhost /cmd AccountConnect vpn20
sleep 3
dhclient vpn_vpn
```

## /etc/systemd/system/dhcpsoftetherclient.service
```
[Unit]
Description=Softether VPN Client DHCP
After=vpnclient.service

[Service]
Type=oneshot
User=root
ExecStart=/bin/bash /opt/vpnclient/dhclient.sh
WorkingDirectory=/opt/vpnclient
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
