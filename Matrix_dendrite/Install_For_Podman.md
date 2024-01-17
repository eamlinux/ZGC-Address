## 创建数据文件夹
```
mkdir -p ~/dendrite/{config,media,jetstream,searchindex,pgdata}
```
## 创建一个容器间的私有网络
```
podman network create --subnet 192.168.218.0/24 matrix
```
## 容器运行Postgresql
```
podman run \
--name postgres \
--network matrix \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-p 127.0.0.1:5432:5432 \
-v ~/dendrite/pgdata:/var/lib/postgresql/data \
-e POSTGRES_PASSWORD=My_Password \
-e LANG=C.UTF-8 \
-d postgres:alpine
```
## 创建数据库及用户
```
podman exec -it postgres psql -U postgres
CREATE USER dendrite_user WITH password 'DBuser_password';
CREATE DATABASE dendrite_DB ENCODING 'UTF8' OWNER dendrite_user;
```
## 创建数据文件
```
podman run \
--rm --entrypoint="/bin/sh" \
-v ~/dendrite/config:/mnt \
matrixdotorg/dendrite-monolith:latest \
-c "/usr/bin/generate-config \
-dir /var/dendrite/ \
-db postgres://dendrite_user:DBuser_password@postgres/dendrite_DB?sslmode=disable \
-server domain.org > /mnt/dendrite.yaml"
```
## 创建matrix验证密钥
```
podman run --rm \
--entrypoint="/usr/bin/generate-keys" \
-v ~/dendrite/config:/mnt matrixdotorg/dendrite-monolith:latest \
-private-key /mnt/matrix_key.pem
```
## 运行dendrite
```
podman run \
--name dendrite \
--network matrix \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-p 8008:8008 \
-p 8448:8448 \
-v ~/dendrite/config:/etc/dendrite \
-v ~/dendrite/media:/var/dendrite/media \
-v ~/dendrite/jetstream:/var/dendrite/jetstream \
-v ~/dendrite/searchindex:/var/dendrite/searchindex \
-d matrixdotorg/dendrite-monolith:latest
```
## 创建新用户命令
```
podman exec -it dendrite \
/usr/bin/create-account \
-config /etc/dendrite/dendrite.yaml \
-username my_username -admin  # 加admin为管理员，不加为普通用户
```
> dendrite.yaml文件与Caddy反代见其它两个文件
