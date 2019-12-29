# ZGC-Address
来自萌咖的脚本，做个备份！

## 全自动安装默认root密码:MoeClub.org
```bash
apt-get update
apt-get install -y xz-utils openssl gawk file
wget --no-check-certificate -qO InstallNET.sh 'https://moeclub.org/attachment/LinuxShell/InstallNET.sh' && chmod a+x InstallNET.sh
```
### 阿里云主机
```
bash InstallNET.sh -d 10 -v 64 -a --mirror 'http://mirrors.cloud.aliyuncs.com/debian/'
```
### 非阿里里云主机
```bash
bash InstallNET.sh -d 10 -v 64 -a --mirror 'http://ftp.debian.org/debian/'
```

