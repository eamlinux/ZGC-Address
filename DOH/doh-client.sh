
wget -c https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
tar xf go1.19.2.linux-amd64.tar.gz
sudo mv go /usr/local/
sudo ln -snf /usr/local/go/bin/* /usr/local/bin/
sudo apt install binutils -y

git clone https://github.com/m13253/dns-over-https.git
make
strip -s doh-client/doh-client
sudo cp doh-client/doh-client /usr/local/bin/

## /etc/systemd/system/doh-client.service
[Unit]
Description=DNS-over-HTTPS Client
Documentation=https://github.com/m13253/dns-over-https
After=network.target
Before=nss-lookup.target
Wants=nss-lookup.target

[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/doh-client -conf /opt/doh-client.conf
LimitNOFILE=1048576
Restart=always
RestartSec=3
Type=simple
User=nobody

[Install]
WantedBy=multi-user.target


## /etc/dnsmasq.conf
no-hosts
server=127.0.0.1#53353
proxy-dnssec
no-resolv
domain-needed
bogus-priv
dnssec
cache-size=512
no-poll


## /etc/dhcp/dhclient-enter-hooks.d/nodnsupdate

#!/bin/sh
make_resolv_conf(){
    :
}

sudo chmod +x /etc/dhcp/dhclient-enter-hooks.d/nodnsupdate

## /etc/resolv.conf

nameserver 127.0.0.1


## /opt/doh-client.conf

listen = [
    "127.0.0.1:53353",
    "[::1]:53353",
]

[upstream]

upstream_selector = "random"

[[upstream.upstream_ietf]]
    url = "https://dns.google/dns-query"
    weight = 50
	
[others]
bootstrap = [

    # Google's resolver, bad ECS, good DNSSEC
    "8.8.8.8:53",
    "8.8.4.4:53",

]

passthrough = [
    "captive.apple.com",
    "connectivitycheck.gstatic.com",
    "detectportal.firefox.com",
    "msftconnecttest.com",
    "nmcheck.gnome.org",

    "pool.ntp.org",
    "time.apple.com",
    "time.asia.apple.com",
    "time.euro.apple.com",
    "time.nist.gov",
    "time.windows.com",
]

# Timeout for upstream request in seconds
timeout = 30

no_cookies = true
no_ecs = false
no_ipv6 = false
no_user_agent = false
verbose = false
