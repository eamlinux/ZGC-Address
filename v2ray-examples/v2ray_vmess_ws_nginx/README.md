# 使用说明
配置文中```xxx.com```改成你的域名  
nginx可以使用acme生成的证书
## 客户端配置：

| 功能栏  | 填写说明  |
|-------|-------|
| 地址：  | 填写你的域名  |
| 端口：  | 一般为443  |
| 用户ID：  | 配置中的UUID  |
| 额外ID：  | 0  |
| 加密：  | auto   |
| 别名：   | 你随意写   |
| 传输协议：  | ws   |
| 伪装类型：  | none   |
| 伪装域名：  | 填写你的域名   |
| 路径：  | 跟配置中path的路径一致   |
| 底层传输安全：  | tls   |
| 跳过证书验证：  | false   |
# 额外文件
把下面两个文件与v2ray程度放在同一个文件夹，如```/etc/v2ary/```或者```/usr/local/bin/```，主要看你把v2ray程序文件放在哪
```
wget -O geosite.dat https://github.com/v2ray/domain-list-community/releases/latest/download/dlc.dat
wget -O geoip.dat https://github.com/v2ray/geoip/releases/latest/download/geoip.dat
```
