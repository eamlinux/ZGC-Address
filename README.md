# VPS系统全自动安装脚本
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
### 非阿里云主机
```bash
bash InstallNET.sh -d 10 -v 64 -a --mirror 'http://ftp.us.debian.org/debian/'
```
原机系统必须是debian或者ubuntu，脚本安装系统仅以```Debian10```作为示例，其它参考萌咖大神博客。
