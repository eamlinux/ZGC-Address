## Debian10系统
```
sudo apt update
sudo apt upgrade
sudo apt install libsodium-dev wget unzip
```
## 安装V2ray到opt文件夹
```
mkdir v2ray
cd v2ray
wget -c https://github.com/v2ray/v2ray-core/releases/download/v4.22.0/v2ray-linux-64.zip
unzip v2ray-linux-64.zip
rm v2ray-linux-64.zip
cd ..
sudo mv v2ray /opt
```
## 加载v2ray到systemd
```
sudo cp /opt/v2ray/systemd/v2ray.service /etc/systemd/system/
sudo systemctl enable v2ray
```
## 配置v2ray.service
```
sudo nano /etc/systemd/system/v2ray.service
```
### 修改后的内容
```
[Unit]
Description=V2Ray Service
After=network.target
Wants=network.target

[Service]
User=nobody
Type=simple
PIDFile=/opt/v2ray/v2ray.pid
ExecStart=/opt/v2ray/v2ray -config /opt/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
```
## 生成UUID，记得复制下来，要放到配置文件里的UUID里面去。
```
cat /proc/sys/kernel/random/uuid
```
## 建立v2ray配置文件
```
sudo nano /opt/v2ray/config.json
```
### 内容如下，请根据自己的信息更改
```
{
  "inbounds": [
{
  "port": 1443,
  "listen": "0.0.0.0",
  "protocol": "vmess",
  "settings": {
    "clients": [
      {
        "id": "此处填入获得的UUID",
        "alterId": 64
      }
    ]
  },
  "streamSettings": {
    "network": "tcp",
    "security": "tls",
    "tlsSettings": {
      "serverName": "你的域名",
      "allowInsecure": true,
      "certificates": [
        {
          "certificateFile": "/你域名的SSL证书.cer",
          "keyFile": "/你域名的SSL密钥.key"
        }
      ]
    },
    "tcpSettings": {
      "type": "none"
    }
  },
  "tag": "",
  "sniffing": {
    "enabled": true,
    "destOverride": [
      "http",
      "tls"
    ]
  }
 }
],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
```
## 启动v2ray
```
sudo systemctl daemon-reload
sudo systemctl start v2ray
```
到此基本完毕，如果使用ufw防火墙，记得allow 1443端口，也可以是你更改的端口。

## 填坑说明：
在```v2ray.service```配置文件里的```User=nobody```参数，目的是非root模式下使用v2ray，但是这可能影响到你证书的权限是其它用户时，v2ray无法启动。
最好的解决办法就是把```nobody```改成你生成证书或者有证书权限的用户，当然你也可以改成root。
