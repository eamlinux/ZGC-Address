## 使用Podman部署Postgresql数据库
```
podman run \
--name postgres \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-p 127.0.0.1:5432:5432 \
-v pgdata:/var/lib/postgresql/data \
-e POSTGRES_PASSWORD=my_password \
-e LANG=C.UTF-8 \
-d postgres:alpine
```
## 建立Synapse数据库及用户
```
podman exec -it postgres createuser -U postgres --pwprompt synapse_user
podman exec -it postgres createdb -U postgres --encoding=UTF8 --locale=C --template=template0 --owner=synapse_user synapse_db
```
## 生成 Synapse 配置文件
```
podman run -it --rm \
-v data/:/data/ \
-e SYNAPSE_SERVER_NAME=domain.org \
-e SYNAPSE_REPORT_STATS=no \
ghcr.io/element-hq/synapse:latest \
generate
```
## 运行Synapse容器
```
podman run \
--name synapse \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-p 127.0.0.1:8008:8008 \
-v data/:/data/ \
-d ghcr.io/element-hq/synapse:latest
```
## 创建用户
```
podman exec -it synapse \
register_new_matrix_user \
http://localhost:8008 \
-c /data/homeserver.yaml
```
> `homeserver.yaml`请参照教程目录的下的文件  
## 开机启动
```
podman generate systemd --files --name synapse
mkdir -p .config/systemd/user/
mv container-synapse.service ~/.config/systemd/user/
systemctl --user enable container-synapse.service
```
