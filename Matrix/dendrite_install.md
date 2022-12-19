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
## 编译配置文件，Postgresql版，sqlite版参见最后，官方不推荐sqlite版，针对低配置小机可用
```
sudo -u caddy nano dendrite.yaml
```
### 以域名matrix.io为例
```yaml
# The version of the configuration file.
version: 2

# 全局配置
global:
  server_name: matrix.io

  # The path to the signing private key file, used to sign requests and events.
  # Note that this is NOT the same private key as used for TLS! To generate a
  # signing key, use "./bin/generate-keys --private-key matrix_key.pem".
  private_key: matrix_key.pem

  # The paths and expiry timestamps (as a UNIX timestamp in millisecond precision)
  # to old signing keys that were formerly in use on this domain name. These
  # keys will not be used for federation request or event signing, but will be
  # provided to any other homeserver that asks when trying to verify old events.
  old_private_keys:
  #  If the old private key file is available:
  #  - private_key: old_matrix_key.pem
  #    expired_at: 1601024554498
  #  If only the public key (in base64 format) and key ID are known:
  #  - public_key: mn59Kxfdq9VziYHSBzI7+EDPDcBS2Xl7jeUdiiQcOnM=
  #    key_id: ed25519:mykeyid
  #    expired_at: 1601024554498

  # How long a remote server can cache our server signing key before requesting it
  # again. Increasing this number will reduce the number of requests made by other
  # servers for our key but increases the period that a compromised key will be
  # considered valid by other homeservers.
  key_validity_period: 168h0m0s

  # 数据库配置
  # 示例：postgres://数据库用户名:用户密码@localhost/数据库名?sslmode=disable
  database:
    connection_string: postgres://matrix:matrixpasswd@localhost/matrix?sslmode=disable
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

  # Configuration for in-memory caches. Caches can often improve performance by
  # keeping frequently accessed items (like events, identifiers etc.) in memory
  # rather than having to read them from the database.
  cache:
    # The estimated maximum size for the global cache in bytes, or in terabytes,
    # gigabytes, megabytes or kilobytes when the appropriate 'tb', 'gb', 'mb' or
    # 'kb' suffix is specified. Note that this is not a hard limit, nor is it a
    # memory limit for the entire process. A cache that is too small may ultimately
    # provide little or no benefit.
    max_size_estimated: 1gb

    # The maximum amount of time that a cache entry can live for in memory before
    # it will be evicted and/or refreshed from the database. Lower values result in
    # easier admission of new cache entries but may also increase database load in
    # comparison to higher values, so adjust conservatively. Higher values may make
    # it harder for new items to make it into the cache, e.g. if new rooms suddenly
    # become popular.
    max_age: 1h

  # The server name to delegate server-server communications to, with optional port
  # 与caddyfile联动 去查看就明白
  # e.g. localhost:443
  well_known_server_name: "matrix.matrix.io:443"

  # The server name to delegate client-server communications to, with optional port
  # e.g. localhost:443
  well_known_client_name: "matrix.matrix.io:443"

  # Lists of domains that the server will trust as identity servers to verify third
  # party identifiers such as phone numbers and email addresses.
  trusted_third_party_id_servers:
    - matrix.org
    - vector.im

  # Disables federation. Dendrite will not be able to communicate with other servers
  # in the Matrix federation and the federation API will not be exposed.
  disable_federation: false

  # Configures the handling of presence events. Inbound controls whether we receive
  # presence events from other servers, outbound controls whether we send presence
  # events for our local users to other servers.
  presence:
    enable_inbound: false
    enable_outbound: false

  # Configures phone-home statistics reporting. These statistics contain the server
  # name, number of active users and some information on your deployment config.
  # We use this information to understand how Dendrite is being used in the wild.
  report_stats:
    enabled: false
    endpoint: https://matrix.org/report-usage-stats/push

  # Server notices allows server admins to send messages to all users on the server.
  server_notices:
    enabled: false
    # The local part, display name and avatar URL (as a mxc:// URL) for the user that
    # will send the server notices. These are visible to all users on the deployment.
    local_part: "_server"
    display_name: "Server Alerts"
    avatar_url: ""
    # The room name to be used when sending server notices. This room name will
    # appear in user clients.
    room_name: "Server Alerts"

  # Configuration for NATS JetStream
  jetstream:
    # A list of NATS Server addresses to connect to. If none are specified, an
    # internal NATS server will be started automatically when running Dendrite in
    # monolith mode. For polylith deployments, it is required to specify the address
    # of at least one NATS Server node.
    addresses:
    # - localhost:4222

    # Disable the validation of TLS certificates of NATS. This is
    # not recommended in production since it may allow NATS traffic
    # to be sent to an insecure endpoint.
    disable_tls_validation: false

    # Persistent directory to store JetStream streams in. This directory should be
    # preserved across Dendrite restarts.
    storage_path: /opt/matrix

    # The prefix to use for stream names for this homeserver - really only useful
    # if you are running more than one Dendrite server on the same NATS deployment.
    topic_prefix: Dendrite

  # Configuration for Prometheus metric collection.
  metrics:
    enabled: false
    basic_auth:
      username: metrics
      password: metrics

  # Optional DNS cache. The DNS cache may reduce the load on DNS servers if there
  # is no local caching resolver available for use.
  dns_cache:
    enabled: false
    cache_size: 256
    cache_lifetime: "5m" # 5 minutes; https://pkg.go.dev/time@master#ParseDuration

# Configuration for the Appservice API.
app_service_api:
  # Disable the validation of TLS certificates of appservices. This is
  # not recommended in production since it may allow appservice traffic
  # to be sent to an insecure endpoint.
  disable_tls_validation: false

  # Appservice configuration files to load into this homeserver.
  config_files:
  #  - /path/to/appservice_registration.yaml

# Configuration for the Client API.
client_api:
  # 开放客户端注册,必须设置ReCAPTCHA才有效，如google ReCAPTCHA
  # using the registration shared secret below.
  registration_disabled: false

  # Prevents new guest accounts from being created. Guest registration is also
  # disabled implicitly by setting 'registration_disabled' above.
  guests_disabled: true

  # 这里注意，用cli创建用户时需要一个共享密钥，创建完后再删除
  # of whether registration is otherwise disabled.
  registration_shared_secret: ""

  # Whether to require reCAPTCHA for registration. If you have enabled registration
  # then this is HIGHLY RECOMMENDED to reduce the risk of your homeserver being used
  # 与开放注册联动.
  enable_registration_captcha: false

  # Settings for ReCAPTCHA 同上.
  recaptcha_public_key: ""
  recaptcha_private_key: ""
  recaptcha_bypass_secret: ""
  recaptcha_siteverify_api: ""

  # To use hcaptcha.com instead of ReCAPTCHA, set the following parameters, otherwise just keep them empty.
  # recaptcha_siteverify_api: "https://hcaptcha.com/siteverify"
  # recaptcha_api_js_url: "https://js.hcaptcha.com/1/api.js"
  # recaptcha_form_field: "h-captcha-response"
  # recaptcha_sitekey_class: "h-captcha"


  # TURN server information that this homeserver should send to clients.
  turn:
    turn_user_lifetime: "5m"
    turn_uris:
    #  - turn:turn.server.org?transport=udp
    #  - turn:turn.server.org?transport=tcp
    turn_shared_secret: ""
    # If your TURN server requires static credentials, then you will need to enter
    # them here instead of supplying a shared secret. Note that these credentials
    # will be visible to clients!
    # turn_username: ""
    # turn_password: ""

  # Settings for rate-limited endpoints. Rate limiting kicks in after the threshold
  # number of "slots" have been taken by requests from a specific host. Each "slot"
  # will be released after the cooloff time in milliseconds. Server administrators
  # and appservice users are exempt from rate limiting by default.
  rate_limiting:
    enabled: true
    threshold: 20
    cooloff_ms: 500
    exempt_user_ids:
    #  - "@user:domain.com"

# Configuration for the Federation API.
federation_api:
  # How many times we will try to resend a failed transaction to a specific server. The
  # backoff is 2**x seconds, so 1 = 2 seconds, 2 = 4 seconds, 3 = 8 seconds etc. Once
  # the max retries are exceeded, Dendrite will no longer try to send transactions to
  # that server until it comes back to life and connects to us again.
  send_max_retries: 16

  # Disable the validation of TLS certificates of remote federated homeservers. Do not
  # enable this option in production as it presents a security risk!
  disable_tls_validation: false

  # Disable HTTP keepalives, which also prevents connection reuse. Dendrite will typically
  # keep HTTP connections open to remote hosts for 5 minutes as they can be reused much
  # more quickly than opening new connections each time. Disabling keepalives will close
  # HTTP connections immediately after a successful request but may result in more CPU and
  # memory being used on TLS handshakes for each new connection instead.
  disable_http_keepalives: false

  # Perspective keyservers to use as a backup when direct key fetches fail. This may
  # be required to satisfy key requests for servers that are no longer online when
  # joining some rooms.
  key_perspectives:
    - server_name: matrix.org
      keys:
        - key_id: ed25519:auto
          public_key: Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw
        - key_id: ed25519:a_RXGa
          public_key: l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ
    - server_name: archlinux.org
      keys:
        - key_id: ed25519:a_KKNB
          public_key: eO1SdnG7CjsIQ/bPaD7k5kwD8CSvYkzHNdhot4gp1Xg
    - server_name: archlinux.org
      keys:
        - key_id: ed25519:0
          public_key: RsDggkM9GntoPcYySc8AsjvGoD0LVz5Ru/B/o5hV9h4

  # This option will control whether Dendrite will prefer to look up keys directly
  # or whether it should try perspective servers first, using direct fetches as a
  # last resort.
  prefer_direct_fetch: false

# Configuration for the Media API.
media_api:
  # Storage path for uploaded media. May be relative or absolute.
  base_path: ./media_store

  # The maximum allowed file size (in bytes) for media uploads to this homeserver
  # (0 = unlimited). If using a reverse proxy, ensure it allows requests at least
  #this large (e.g. the client_max_body_size setting in nginx).
  max_file_size_bytes: 10485760

  # Whether to dynamically generate thumbnails if needed.
  dynamic_thumbnails: false

  # The maximum number of simultaneous thumbnail generators to run.
  max_thumbnail_generators: 10

  # A list of thumbnail sizes to be generated for media content.
  thumbnail_sizes:
    - width: 32
      height: 32
      method: crop
    - width: 96
      height: 96
      method: crop
    - width: 640
      height: 480
      method: scale

# Configuration for enabling experimental MSCs on this homeserver.
mscs:
  mscs:
  #  - msc2836  # (Threading, see https://github.com/matrix-org/matrix-doc/pull/2836)
  #  - msc2946  # (Spaces Summary, see https://github.com/matrix-org/matrix-doc/pull/2946)

# Configuration for the Sync API.
sync_api:
  # This option controls which HTTP header to inspect to find the real remote IP
  # address of the client. This is likely required if Dendrite is running behind
  # a reverse proxy server.
  # real_ip_header: X-Real-IP

  # Configuration for the full-text search engine.
  search:
    # Whether or not search is enabled.
    enabled: false

    # The path where the search index will be created in.
    index_path: "./searchindex"

    # The language most likely to be used on the server - used when indexing, to
    # ensure the returned results match expectations. A full list of possible languages
    # can be found at https://github.com/blevesearch/bleve/tree/master/analysis/lang
    language: "en"

# Configuration for the User API.
user_api:
  # The cost when hashing passwords on registration/login. Default: 10. Min: 4, Max: 31
  # See https://pkg.go.dev/golang.org/x/crypto/bcrypt for more information.
  # Setting this lower makes registration/login consume less CPU resources at the cost
  # of security should the database be compromised. Setting this higher makes registration/login
  # consume more CPU resources but makes it harder to brute force password hashes. This value
  # can be lowered if performing tests or on embedded Dendrite instances (e.g WASM builds).
  bcrypt_cost: 10

  # The length of time that a token issued for a relying party from
  # /_matrix/client/r0/user/{userId}/openid/request_token endpoint
  # is considered to be valid in milliseconds.
  # The default lifetime is 3600000ms (60 minutes).
  # openid_token_lifetime_ms: 3600000

  # Users who register on this homeserver will automatically be joined to the rooms listed under "auto_join_rooms" option.
  # By default, any room aliases included in this list will be created as a publicly joinable room
  # when the first user registers for the homeserver. If the room already exists,
  # make certain it is a publicly joinable room, i.e. the join rule of the room must be set to 'public'.
  # As Spaces are just rooms under the hood, Space aliases may also be used.
  auto_join_rooms:
  #  - "#main:matrix.org"

# Configuration for Opentracing.
# See https://github.com/matrix-org/dendrite/tree/master/docs/tracing for information on
# how this works and how to set it up.
tracing:
  enabled: false
  jaeger:
    serviceName: ""
    disabled: false
    rpc_metrics: false
    tags: []
    sampler: null
    reporter: null
    headers: null
    baggage_restrictions: null
    throttler: null

# Logging configuration. The "std" logging type controls the logs being sent to
# stdout. The "file" logging type controls logs being written to a log folder on
# the disk. Supported log levels are "debug", "info", "warn", "error".
logging:
  - type: std
    level: warn
  - type: file
    level: info
    params:
      path: ./logs
```
## 开机启动
```
sudo systemctl daemon-reload
sudo systemctl start matrix

sudo systemctl status matrix
```
## 创建用户与管理员，注意，是打开共享密钥的情况下才有效，看配置文件说明
```
sudo -u caddy ./bin/create-account -config ./dendrite.yaml -username mlinux
sudo -u caddy ./bin/create-account -config ./dendrite.yaml -username leamnet -admin
```
## 迁移数据库：

### 旧机：
```
sudo systemctl disable --now dendrite
sudo su
pg_dump -U postgres -F c dendrite > db1.tar
```
### 新机：
```
sudo systemctl stop dendrite
sudo su
su postgres
dropdb dendrite
pg_restore -U postgres -d dendrite -1  db1.tar
````
### 媒体文件：
```
备份:

cd /opt/matrix
sudo -u caddy tar -czvf ./media.tar.gz media_store/

恢复:
sudo -u caddy cp media.tar.gz /opt/matrix
cd /opt/matrix
sudo -u caddy tar -xvf media.tar.gz media_store
```

## 这是一份基于sqlite的配置：
```yaml
# The version of the configuration file.
version: 2

# Global Matrix configuration. This configuration applies to all components.
global:
  # The domain name of this homeserver.
  server_name: matrix.io

  # The path to the signing private key file, used to sign requests and events.
  # Note that this is NOT the same private key as used for TLS! To generate a
  # signing key, use "./bin/generate-keys --private-key matrix_key.pem".
  private_key: matrix_key.pem

  # The paths and expiry timestamps (as a UNIX timestamp in millisecond precision)
  # to old signing keys that were formerly in use on this domain name. These
  # keys will not be used for federation request or event signing, but will be
  # provided to any other homeserver that asks when trying to verify old events.
  old_private_keys:
  #  If the old private key file is available:
  #  - private_key: old_matrix_key.pem
  #    expired_at: 1601024554498
  #  If only the public key (in base64 format) and key ID are known:
  #  - public_key: mn59Kxfdq9VziYHSBzI7+EDPDcBS2Xl7jeUdiiQcOnM=
  #    key_id: ed25519:mykeyid
  #    expired_at: 1601024554498

  # How long a remote server can cache our server signing key before requesting it
  # again. Increasing this number will reduce the number of requests made by other
  # servers for our key but increases the period that a compromised key will be
  # considered valid by other homeservers.
  key_validity_period: 168h0m0s

  # Configuration for in-memory caches. Caches can often improve performance by
  # keeping frequently accessed items (like events, identifiers etc.) in memory
  # rather than having to read them from the database.
  cache:
    # The estimated maximum size for the global cache in bytes, or in terabytes,
    # gigabytes, megabytes or kilobytes when the appropriate 'tb', 'gb', 'mb' or
    # 'kb' suffix is specified. Note that this is not a hard limit, nor is it a
    # memory limit for the entire process. A cache that is too small may ultimately
    # provide little or no benefit.
    max_size_estimated: 1gb

    # The maximum amount of time that a cache entry can live for in memory before
    # it will be evicted and/or refreshed from the database. Lower values result in
    # easier admission of new cache entries but may also increase database load in
    # comparison to higher values, so adjust conservatively. Higher values may make
    # it harder for new items to make it into the cache, e.g. if new rooms suddenly
    # become popular.
    max_age: 1h

  # The server name to delegate server-server communications to, with optional port
  # e.g. localhost:443
  well_known_server_name: "matrix.matrix.io:443"

  # The server name to delegate client-server communications to, with optional port
  # e.g. localhost:443
  well_known_client_name: "matrix.matrix.io:443"

  # Lists of domains that the server will trust as identity servers to verify third
  # party identifiers such as phone numbers and email addresses.
  trusted_third_party_id_servers:
    - matrix.org
    - vector.im

  # Disables federation. Dendrite will not be able to communicate with other servers
  # in the Matrix federation and the federation API will not be exposed.
  disable_federation: false

  # Configures the handling of presence events. Inbound controls whether we receive
  # presence events from other servers, outbound controls whether we send presence
  # events for our local users to other servers.
  presence:
    enable_inbound: false
    enable_outbound: false

  # Configures phone-home statistics reporting. These statistics contain the server
  # name, number of active users and some information on your deployment config.
  # We use this information to understand how Dendrite is being used in the wild.
  report_stats:
    enabled: false
    endpoint: https://matrix.org/report-usage-stats/push

  # Server notices allows server admins to send messages to all users on the server.
  server_notices:
    enabled: false
    # The local part, display name and avatar URL (as a mxc:// URL) for the user that
    # will send the server notices. These are visible to all users on the deployment.
    local_part: "_server"
    display_name: "Server Alerts"
    avatar_url: ""
    # The room name to be used when sending server notices. This room name will
    # appear in user clients.
    room_name: "Server Alerts"

  # Configuration for NATS JetStream
  jetstream:
    # A list of NATS Server addresses to connect to. If none are specified, an
    # internal NATS server will be started automatically when running Dendrite in
    # monolith mode. For polylith deployments, it is required to specify the address
    # of at least one NATS Server node.
    addresses:
    # - localhost:4222

    # Disable the validation of TLS certificates of NATS. This is
    # not recommended in production since it may allow NATS traffic
    # to be sent to an insecure endpoint.
    disable_tls_validation: false

    # Persistent directory to store JetStream streams in. This directory should be
    # preserved across Dendrite restarts.
    storage_path: /opt/matrix

    # The prefix to use for stream names for this homeserver - really only useful
    # if you are running more than one Dendrite server on the same NATS deployment.
    topic_prefix: Dendrite

  # Configuration for Prometheus metric collection.
  metrics:
    enabled: false
    basic_auth:
      username: metrics
      password: metrics

  # Optional DNS cache. The DNS cache may reduce the load on DNS servers if there
  # is no local caching resolver available for use.
  dns_cache:
    enabled: false
    cache_size: 256
    cache_lifetime: "5m" # 5 minutes; https://pkg.go.dev/time@master#ParseDuration

# Configuration for the Appservice API.
app_service_api:
  # Disable the validation of TLS certificates of appservices. This is
  # not recommended in production since it may allow appservice traffic
  # to be sent to an insecure endpoint.
  disable_tls_validation: false

  # Appservice configuration files to load into this homeserver.
  config_files:
  #  - /path/to/appservice_registration.yaml
  database:
    connection_string: file:///opt/matrix/db/app_service_api.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

# Configuration for the Client API.
client_api:
  # Prevents new users from being able to register on this homeserver, except when
  # using the registration shared secret below.
  registration_disabled: true

  # Prevents new guest accounts from being created. Guest registration is also
  # disabled implicitly by setting 'registration_disabled' above.
  guests_disabled: true

  # If set, allows registration by anyone who knows the shared secret, regardless
  # of whether registration is otherwise disabled.
  registration_shared_secret: ""

  # Whether to require reCAPTCHA for registration. If you have enabled registration
  # then this is HIGHLY RECOMMENDED to reduce the risk of your homeserver being used
  # for coordinated spam attacks.
  enable_registration_captcha: false

  # Settings for ReCAPTCHA.
  recaptcha_public_key: ""
  recaptcha_private_key: ""
  recaptcha_bypass_secret: ""

  # To use hcaptcha.com instead of ReCAPTCHA, set the following parameters, otherwise just keep them empty.
  # recaptcha_siteverify_api: "https://hcaptcha.com/siteverify"
  # recaptcha_api_js_url: "https://js.hcaptcha.com/1/api.js"
  # recaptcha_form_field: "h-captcha-response"
  # recaptcha_sitekey_class: "h-captcha"


  # TURN server information that this homeserver should send to clients.
  turn:
    turn_user_lifetime: "5m"
    turn_uris:
    #  - turn:turn.server.org?transport=udp
    #  - turn:turn.server.org?transport=tcp
    turn_shared_secret: ""
    # If your TURN server requires static credentials, then you will need to enter
    # them here instead of supplying a shared secret. Note that these credentials
    # will be visible to clients!
    # turn_username: ""
    # turn_password: ""

  # Settings for rate-limited endpoints. Rate limiting kicks in after the threshold
  # number of "slots" have been taken by requests from a specific host. Each "slot"
  # will be released after the cooloff time in milliseconds. Server administrators
  # and appservice users are exempt from rate limiting by default.
  rate_limiting:
    enabled: true
    threshold: 20
    cooloff_ms: 500
    exempt_user_ids:
    #  - "@user:domain.com"

# Configuration for the Federation API.
federation_api:
  # How many times we will try to resend a failed transaction to a specific server. The
  # backoff is 2**x seconds, so 1 = 2 seconds, 2 = 4 seconds, 3 = 8 seconds etc. Once
  # the max retries are exceeded, Dendrite will no longer try to send transactions to
  # that server until it comes back to life and connects to us again.
  send_max_retries: 16

  # Disable the validation of TLS certificates of remote federated homeservers. Do not
  # enable this option in production as it presents a security risk!
  disable_tls_validation: false

  # Disable HTTP keepalives, which also prevents connection reuse. Dendrite will typically
  # keep HTTP connections open to remote hosts for 5 minutes as they can be reused much
  # more quickly than opening new connections each time. Disabling keepalives will close
  # HTTP connections immediately after a successful request but may result in more CPU and
  # memory being used on TLS handshakes for each new connection instead.
  disable_http_keepalives: false

  # Perspective keyservers to use as a backup when direct key fetches fail. This may
  # be required to satisfy key requests for servers that are no longer online when
  # joining some rooms.
  key_perspectives:
    - server_name: matrix.org
      keys:
        - key_id: ed25519:auto
          public_key: Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw
        - key_id: ed25519:a_RXGa
          public_key: l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ
    - server_name: archlinux.org
      keys:
        - key_id: ed25519:a_KKNB
          public_key: eO1SdnG7CjsIQ/bPaD7k5kwD8CSvYkzHNdhot4gp1Xg
    - server_name: archlinux.org
      keys:
        - key_id: ed25519:0
          public_key: RsDggkM9GntoPcYySc8AsjvGoD0LVz5Ru/B/o5hV9h4

  # This option will control whether Dendrite will prefer to look up keys directly
  # or whether it should try perspective servers first, using direct fetches as a
  # last resort.
  prefer_direct_fetch: false
  database:
    connection_string: file:///opt/matrix/db/federation_api.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

# Configuration for the Media API.
media_api:
  # Storage path for uploaded media. May be relative or absolute.
  base_path: ./media_store

  # The maximum allowed file size (in bytes) for media uploads to this homeserver
  # (0 = unlimited). If using a reverse proxy, ensure it allows requests at least
  #this large (e.g. the client_max_body_size setting in nginx).
  max_file_size_bytes: 10485760

  # Whether to dynamically generate thumbnails if needed.
  dynamic_thumbnails: false

  # The maximum number of simultaneous thumbnail generators to run.
  max_thumbnail_generators: 10

  # A list of thumbnail sizes to be generated for media content.
  thumbnail_sizes:
    - width: 32
      height: 32
      method: crop
    - width: 96
      height: 96
      method: crop
    - width: 640
      height: 480
      method: scale
  database:
    connection_string: file:///opt/matrix/db/media_api.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

# Configuration for the Key Server
key_server:
  database:
    connection_string: file:///opt/matrix/db/key_server.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

# Configuration for enabling experimental MSCs on this homeserver.
mscs:
  mscs:
  #  - msc2836  # (Threading, see https://github.com/matrix-org/matrix-doc/pull/2836)
  #  - msc2946  # (Spaces Summary, see https://github.com/matrix-org/matrix-doc/pull/2946)
  database:
    connection_string: file:///opt/matrix/db/mscs.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

# Configuration for the Room Server
room_server:
  database:
    connection_string: file:///opt/matrix/db/room_server.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

# Configuration for the Sync API.
sync_api:
  # This option controls which HTTP header to inspect to find the real remote IP
  # address of the client. This is likely required if Dendrite is running behind
  # a reverse proxy server.
  # real_ip_header: X-Real-IP

  # Configuration for the full-text search engine.
  search:
    # Whether or not search is enabled.
    enabled: false

    # The path where the search index will be created in.
    index_path: "./searchindex"

    # The language most likely to be used on the server - used when indexing, to
    # ensure the returned results match expectations. A full list of possible languages
    # can be found at https://github.com/blevesearch/bleve/tree/master/analysis/lang
    language: "en"
  database:
    connection_string: file:///opt/matrix/db/sync_api.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

# Configuration for the User API.
user_api:
  # The cost when hashing passwords on registration/login. Default: 10. Min: 4, Max: 31
  # See https://pkg.go.dev/golang.org/x/crypto/bcrypt for more information.
  # Setting this lower makes registration/login consume less CPU resources at the cost
  # of security should the database be compromised. Setting this higher makes registration/login
  # consume more CPU resources but makes it harder to brute force password hashes. This value
  # can be lowered if performing tests or on embedded Dendrite instances (e.g WASM builds).
  bcrypt_cost: 10

  # The length of time that a token issued for a relying party from
  # /_matrix/client/r0/user/{userId}/openid/request_token endpoint
  # is considered to be valid in milliseconds.
  # The default lifetime is 3600000ms (60 minutes).
  # openid_token_lifetime_ms: 3600000

  # Users who register on this homeserver will automatically be joined to the rooms listed under "auto_join_rooms" option.
  # By default, any room aliases included in this list will be created as a publicly joinable room
  # when the first user registers for the homeserver. If the room already exists,
  # make certain it is a publicly joinable room, i.e. the join rule of the room must be set to 'public'.
  # As Spaces are just rooms under the hood, Space aliases may also be used.
  auto_join_rooms:
  #  - "#main:matrix.org"
  account_database:
    connection_string: file:///opt/matrix/db/user_api.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1
  device_database:
    connection_string: file:///opt/matrix/db/user_api.db
    max_open_conns: 90
    max_idle_conns: 5
    conn_max_lifetime: -1

# Configuration for Opentracing.
# See https://github.com/matrix-org/dendrite/tree/master/docs/tracing for information on
# how this works and how to set it up.
tracing:
  enabled: false
  jaeger:
    serviceName: ""
    disabled: false
    rpc_metrics: false
    tags: []
    sampler: null
    reporter: null
    headers: null
    baggage_restrictions: null
    throttler: null

# Logging configuration. The "std" logging type controls the logs being sent to
# stdout. The "file" logging type controls logs being written to a log folder on
# the disk. Supported log levels are "debug", "info", "warn", "error".
logging:
  - type: std
    level: warn
  - type: file
    level: info
    params:
      path: ./logs
```
