#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear
echo
echo "#############################################################"
echo "# One click Install ShadowsocksR Server                     #"
echo "# System Required: Debian 9.0+                              #"
echo "# Github: https://github.com/shadowsocksrr/shadowsocksr     #"
echo "#############################################################"
echo

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

# Get public IP address
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

get_char(){
    SAVEDSTTY='stty -g'
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

# Pre-installation settings
pre_install(){
    # Set ShadowsocksR config password
    echo "Please enter password for ShadowsocksR:"
    read -p "(Default password: As123456):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="As123456"
    echo
    echo "----------------------------"
    echo "password = ${shadowsockspwd}"
    echo "----------------------------"
    echo
    # Set ShadowsocksR config port
    while true
    do
    dport=$(shuf -i 9000-19999 -n 1)
    echo -e "Please enter a port for ShadowsocksR [1000-65535]"
    read -p "(Default port: ${dport}):" shadowsocksport
    [ -z "${shadowsocksport}" ] && shadowsocksport=${dport}
    expr ${shadowsocksport} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksport} -ge 1000 ] && [ ${shadowsocksport} -le 65535 ] && [ ${shadowsocksport:0:999} != 0 ]; then
            echo
            echo "-------------------------"
            echo "port = ${shadowsocksport}"
            echo "-------------------------"
            echo
            break
        fi
    fi
    echo -e "[${red}Error${plain}] Please enter a correct number [1000-65535]"
    done

    # Set shadowsocksR config stream ciphers
    while true
    do
    shadowsockscipher=chacha20-ietf
    echo
    echo "-----------------------------"
    echo "cipher = ${shadowsockscipher}"
    echo "-----------------------------"
    echo
    break
    done

    # Set shadowsocksR config protocol
    while true
    do
    shadowsockprotocol=auth_aes128_sha1
    echo
    echo "--------------------------------"
    echo "protocol = ${shadowsockprotocol}"
    echo "--------------------------------"
    echo
    break
    done
	
    while true
    do
    shadowsockprotocol_param=#
    echo
    echo "--------------------------------------"
    echo "protocol = ${shadowsockprotocol_param}"
    echo "--------------------------------------"
    echo
    break
    done

    # Set shadowsocksR config obfs
    while true
    do
    shadowsockobfs=tls1.2_ticket_auth
    echo
    echo "------------------------"
    echo "obfs = ${shadowsockobfs}"
    echo "------------------------"
    echo
    break
    done
	
	while true
    do
    shadowsockobfs_param=ajax.microsoft.com
    echo
    echo "------------------------------"
    echo "obfs = ${shadowsockobfs_param}"
    echo "------------------------------"
    echo
    break
    done

    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char='get_char'
	apt -y install libsodium-dev git
}

# Install ShadowsocksR
install(){
git clone https://github.com/shadowsocksrr/shadowsocksr.git
mv shadowsocksr/shadowsocks /usr/local/
cat > /etc/systemd/system/ssr.service <<-EOF
[Unit]
Description=SSR Proxy
After=network-online.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/shadowsocks/server.py -c /usr/local/shadowsocks/config.json

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ssr

        clear
        echo
        echo -e "Congratulations, ShadowsocksR server install completed!"
        echo -e "Your Server IP        : \033[41;37m $(get_ip) \033[0m"
        echo -e "Your Server Port      : \033[41;37m ${shadowsocksport} \033[0m"
        echo -e "Your Password         : \033[41;37m ${shadowsockspwd} \033[0m"
        echo -e "Your Protocol         : \033[41;37m ${shadowsockprotocol} \033[0m"
		    echo -e "Your protocol_param   : \033[41;37m ${shadowsockprotocol_param} \033[0m"
        echo -e "Your obfs             : \033[41;37m ${shadowsockobfs} \033[0m"
		    echo -e "Your obfs_param       : \033[41;37m ${shadowsockobfs_param} \033[0m"
        echo -e "Your Encryption Method: \033[41;37m ${shadowsockscipher} \033[0m"
        echo
        echo "Enjoy it!"
        echo
}

# Config ShadowsocksR
config_shadowsocks(){
    cat > /usr/local/shadowsocks/config.json <<-EOF
{
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "local_address":"127.0.0.1",
    "local_port":1080,
    "port_password":{
        "${shadowsocksport}":"${shadowsockspwd}"
    },
    "timeout":120,
    "method":"chacha20-ietf",
    "protocol":"auth_aes128_sha1",
    "protocol_param":"#",
    "obfs":"tls1.2_ticket_auth",
    "obfs_param":"ajax.microsoft.com",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
ln -snf /usr/bin/python3.7 /usr/bin/python
systemctl start ssr
}

# Uninstall ShadowsocksR
uninstall_shadowsocksr(){
    printf "Are you sure uninstall ShadowsocksR? (y/n)"
    printf "\n"
    read -p "(Default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
    systemctl stop ssr
		systemctl disable ssr
		rm -f /etc/systemd/system/ssr.service
		rm -rf /usr/local/shadowsocks
        echo "ShadowsocksR uninstall success!"
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}

# Install ShadowsocksR
install_shadowsocksr(){
    pre_install
    install
    config_shadowsocks	
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall)
        ${action}_shadowsocksr
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: `basename $0` [install|uninstall]"
        ;;
esac
