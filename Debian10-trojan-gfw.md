### 安装编译环境
```
sudo apt -y install build-essential cmake libboost-system-dev libboost-program-options-dev libssl-dev default-libmysqlclient-dev
```
### 拉取源码并编译
```
git clone https://github.com/trojan-gfw/trojan.git
cd trojan/
mkdir build
cd build/
cmake ..
make
sudo mv trojan /usr/local/bin/
