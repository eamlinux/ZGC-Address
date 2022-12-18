## 安装
```
sudo apt install acl zstd
wget https://github.com/foxcpp/maddy/releases/download/v0.6.2/maddy-0.6.2-x86_64-linux-musl.tar.zst
unzstd maddy-0.6.2-x86_64-linux-musl.tar.zst && tar xf maddy-0.6.2-x86_64-linux-musl.tar
rm maddy-0.6.2-x86_64-linux-musl.tar.zst maddy-0.6.2-x86_64-linux-musl.tar
sudo mv maddy-0.6.2-x86_64-linux-musl/maddy /usr/local/bin/
sudo mkdir -pv /opt/maddy
```
## `maddy.conf`主要设置
```
$(hostname) = mx1.example.org
$(primary_domain) = example.org
$(local_domains) = $(primary_domain)
# 如果有其它域名 $(local_domains) = $(primary_domain) example.com other.example.com

# tls 设置
tls file /home/acme/cert/fullchain.pem /home/acme/cert/privkey.pem {
    protocols tls1.3
    curves X25519
    # ciphers ECDHE-ECDSA-WITH-CHACHA20-POLY1305 ECDHE-ECDSA-WITH-AES256-GCM-SHA384
}
```

## acme申请证书
```
sudo useradd -r -m -s /bin/bash acme
sudo su -l acme
curl  https://get.acme.sh | sh
exit
sudo su -l acme
mkdir cert
## 默认ZeroSSL，需要注册zerossl账户,第一次运行acme的时候会有提示
## acme.sh --register-account -m admin@mail.org
## acme.sh --set-default-ca --server zerossl

## 改用letsencrypt
acme.sh --set-default-ca --server letsencrypt

## 使用CFDNS申请证书，在cloudflare上创建api-tokens，使用"编辑区域DNS"的模板，在"特定区域"选上你的域名即可。

export CF_Token=""
export CF_Account_ID=""
export CF_Zone_ID=""

acme.sh --issue -d "mail.org" -d "*.mail.org" \
  --dns dns_cf --key-file /home/acme/cert/privkey.pem \
  --fullchain-file /home/acme/cert/fullchain.pem \
  --ocsp-must-staple --keylength ec-384 --ecc

##  如果是nginx使用，加上
## --reloadcmd     "echo xxxxxx | sudo -S nginx -s reload"

acme.sh --upgrade --auto-upgrade
acme.sh --info -d example.org

## setfacl -R -m u:maddy:rx /home/acme/cert
## 设置dns
example.org.   A     10.2.3.4
example.org.   AAAA  2001:beef::1
example.org.   MX    10   mx1.example.org.
mx1.example.org.   A     10.2.3.4
mx1.example.org.   AAAA  2001:beef::1

example.org.     TXT   "v=spf1 mx ~all"
v=spf1 mx mx:example.org ~all
v=spf1 mx ip4:1.2.3.4/32 ip6:1800:4456::f04f:92f4:fe7e:5f01/128 -all

mx1.example.org. TXT   "v=spf1 mx ~all"

_dmarc.example.org.   TXT    "v=DMARC1; p=quarantine; ruf=mailto:postmaster@example.org"

加dns txt记录：_dmarc.example.org
RR值：v=DMARC1; p=quarantine; rua=mailto:xxxxx@example.org; ruf=mailto:xxxxx@example.org


; Mark domain as MTA-STS compatible (see the next section)
; and request reports about failures to be sent to postmaster@example.org
_mta-sts.mlinux.eu.org.   TXT    "v=STSv1; id=1"
_smtp._tls.mlinux.eu.org. TXT    "v=TLSRPTv1; rua=mailto:admin@mlinux.eu.org"

## dkim设置
cat /opt/maddy/dkim_keys/example.org_default.dns

sudo -u acme cat /opt/maddy/dkim_keys/example.org_default.dns
default._domainkey.example.org.    TXT   "v=DKIM1; k=ed25519; p=nAcUUozPlhc4VPhp7hZl+owES7j7OlEv0laaDEDBAqg="

sudo mkdir /run/maddy
sudo chown -R maddy. /run/maddy

sudo -u maddy maddy creds create admin@example.org
sudo -u maddy maddy imap-acct create admin@example.org
sudo -u maddy touch /opt/maddy/aliases
sudo chown -R maddy. /opt/maddy
```
