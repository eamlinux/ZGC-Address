set root=(hd0)
chainloader +1
boot


## grub.conf

default 0
timeout 5
title           Debian GNU/Linux, kernel 4.19.0-10-amd64
root            (hd0,0)
kernel          /boot/vmlinuz-4.19.0-10-amd64 root=/dev/vda1 ro net.ifnames=0 biosdevname=0
initrd          /boot/initrd.img-4.19.0-10-amd64

title           Debian GNU/Linux, kernel 4.19.0-10-amd64 (single-user mode)
root            (hd0,0)
kernel          /boot/vmlinuz-4.19.0-10-amd64 root=/dev/vda1 ro net.ifnames=0 biosdevname=0 single
initrd          /boot/initrd.img-4.19.0-10-amd64

title           Debian GNU/Linux, kernel 4.19.0-5-amd64
root            (hd0,0)
kernel          /boot/vmlinuz-4.19.0-5-amd64 root=/dev/vda1 ro net.ifnames=0 biosdevname=0
initrd          /boot/initrd.img-4.19.0-5-amd64

title           Debian GNU/Linux, kernel 4.19.0-5-amd64 (single-user mode)
root            (hd0,0)
kernel          /boot/vmlinuz-4.19.0-5-amd64 root=/dev/vda1 ro net.ifnames=0 biosdevname=0 single
initrd          /boot/initrd.img-4.19.0-5-amd64

## grub.cfg

chainloader +1
boot

## network

###### if grub=cfg
auto lo
iface lo inet loopback

auto ens3
iface ens3 inet static
        address 10.0.0.11
        netmask 255.255.255.0
        broadcast 10.0.0.255
        network 10.0.0.0
        gateway  10.0.0.1

auto ens3:1
iface ens3:1 inet static
        address 127.0.0.2
        netmask 255.255.255.255
iface ens3:1 inet6 static
        address ipv6xxxxxxxx
        netmask 64
        gateway  ipv6xxxxxxxx

auto ens3:2
iface ens3:2 inet static
        address 127.0.0.3
        netmask 255.255.255.255
iface ens3:2 inet6 static
        address ipv6xxxxxxxx
        netmask 64

auto ens3:3
iface ens3:3 inet static
        address 127.0.0.4
        netmask 255.255.255.255
iface ens3:3 inet6 static
        address ipv6xxxxxxxx
        netmask 64
        
        
##### if grub=conf        
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
        address 10.0.0.11
        netmask 255.255.255.0
        broadcast 10.0.0.255
        network 10.0.0.0
        gateway  10.0.0.1

auto eth0:1
iface eth0:1 inet static
        address 127.0.0.2
        netmask 255.255.255.255
iface eth0:1 inet6 static
        address ipv6xxxxxxxx
        netmask 64
        gateway  ipv6xxxxxxxx

auto eth0:2
iface eth0:2 inet static
        address 127.0.0.3
        netmask 255.255.255.255
iface eth0:2 inet6 static
        address ipv6xxxxxxxx
        netmask 64

auto eth0:3
iface eth0:3 inet static
        address 127.0.0.4
        netmask 255.255.255.255
iface eth0:3 inet6 static
        address ipv6xxxxxxxx
        netmask 64
