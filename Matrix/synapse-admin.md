#### 下载面板
```
wget https://github.com/Awesome-Technologies/synapse-admin/releases/download/0.8.7/synapse-admin-0.8.7-dirty.tar.gz
tar xf synapse-admin-0.8.7-dirty.tar.gz
mv synapse-admin-0.8.7-dirty synapse-admin
sudo mv synapse-admin /opt/
sudo chown -R caddy:caddy /opt/synapse-admin
```
#### Caddy配置
```
{
  order reverse_proxy before map
  admin off
  log {
    output discard
  }
  default_sni xxyy.top
  servers :443 {
    protocols h1 h2 h3
  }
}

xxyy.top {
  encode {
    gzip 6
  }
  tls {
    protocols tls1.3
    curves x25519
    alpn h2
  }

  @xxyy {
    host xxyy.top
  }
  route @xxyy {
    header /.well-known/matrix/* Content-Type application/json
    header /.well-known/matrix/* Access-Control-Allow-Origin *
    respond /.well-known/matrix/server `{"m.server": "matrix.xxyy.top:443"}`
    respond /.well-known/matrix/client `{"m.homeserver":{"base_url":"https://matrix.xxyy.top"}}`
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Content-Type-Options nosniff
      X-Frame-Options SAMEORIGIN
      Referrer-Policy no-referrer-when-downgrade
    }
    # reverse_proxy localhost:8998 {
    #   header_up Host {host}
    #   header_up X-Real-IP {remote}
    # }
    file_server {
      root /opt/synapse-admin
    }
  }
}

matrix.xxyy.top {
  encode {
    gzip 6
  }
  tls {
    protocols tls1.3
    curves x25519
    alpn h2
  }

  @matrix_xxyy {
    host matrix.xxyy.top
  }
  route @matrix_xxyy {
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Content-Type-Options nosniff
      X-Frame-Options SAMEORIGIN
      Referrer-Policy no-referrer-when-downgrade
    }
    reverse_proxy /_matrix/* localhost:8008 {
      header_up Host {host}
      header_up X-Real-IP {remote}
    }
    reverse_proxy /_synapse/client/* localhost:8008 {
      header_up Host {host}
      header_up X-Real-IP {remote}
    }
    reverse_proxy /_synapse/admin/* localhost:8008 {
      header_up Host {host}
      header_up X-Real-IP {remote}
    }
  }
}
```
