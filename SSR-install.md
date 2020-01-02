## 安装shadowsocksr
```
sudo apt install libsodium-dev git
git clone https://github.com/shadowsocksrr/shadowsocksr.git
sudo mv shadowsocksr/shadowsocks /usr/local/
sudo nano /usr/local/shadowsocks/config.json
```
## 配置,注意！端口要大于1000：
```
{
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "local_address":"127.0.0.1",
    "local_port":1080,
    "port_password":{
        "端口1":"密码1",
        "端口2":"密码2",
        "端口3":"密码3"
    },
    "timeout":120,
    "method":"chacha20-ietf",
    "protocol":"auth_aes128_sha1",
    "protocol_param":"#",
    "obfs":"tls1.2_ticket_auth",
    "obfs_param":"ajax.microsoft.com",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":true,
    "workers":1
}
```
## 安装服务
```
sudo nano /etc/systemd/system/ssr.service

### 内容如下：
[Unit]
Description=SSR Proxy
After=network-online.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/shadowsocks/server.py -c /usr/local/shadowsocks/config.json

[Install]
WantedBy=multi-user.target
```
## 开机启动
```
sudo systemctl enable ssr
sudo systemctl start ssr
```
很简单的，不需要用一键脚本。
