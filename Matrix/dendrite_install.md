# 在debian11下安装matrix即时IM
## 安装Golang
```
wget -c https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
tar xf go1.19.4.linux-amd64.tar.gz
sudo mv go /usr/local/
sudo ln -snf /usr/local/go/bin/* /usr/local/bin/
```
## 拉取且build matrix go版dendrite
```
git clone https://github.com/matrix-org/dendrite
cd dendrite/
mkdir bin
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "-w -s" -v -o "bin/" ./cmd/...

sudo mkdir /opt/matrix
sudo mv bin/ /opt/matrix/

sudo mv dendrite-sample.monolith.yaml /opt/matrix/dendrite.yaml
sudo chown -R caddy. /opt/matrix/
cd /opt/matrix/
sudo -u caddy ./bin/generate-keys --private-key matrix_key.pem
```
## 编辑开机启动脚本
```
sudo nano /etc/systemd/system/matrix.service

[Unit]
Description=Dendrite (Matrix Homeserver)
After=syslog.target network.target postgresql.service

[Service]
Environment=GODEBUG=madvdontneed=1
RestartSec=2s
Type=simple
User=caddy
Group=caddy
WorkingDirectory=/opt/matrix/
ExecStart=/opt/matrix/bin/dendrite-monolith-server
Restart=always
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```
## 安装Postgresql数据库并创建matrix数据库，如果使用sqlite3，则不用安装
```
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql.list

sudo apt install postgresql-15
sudo passwd postgres
sudo -u postgres createuser -P matrix
sudo -u postgres createdb -O matrix -E UTF-8 matrix
```
sudo -u caddy nano dendrite.yaml
