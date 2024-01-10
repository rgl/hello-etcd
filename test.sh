#!/bin/bash
set -euxo pipefail

# ensure we start without an existent environment.
docker compose down --volumes

# create the environment defined in compose.yml and leave it running in the
# background.
docker compose up --build -d

# show running containers.
docker compose ps

# execute command inside the containers.
docker compose exec -T hello hello --version
docker compose exec -T etcd etcd --version
docker compose exec -T etcd etcdctl version
docker compose exec -T etcd etcdctl endpoint health
docker compose exec -T etcd etcdctl put foo bar
docker compose exec -T etcd etcdctl get foo

# invoke the hello endpoint.
hello_endpoint='http://localhost:8888'
result="$(wget -qO- $hello_endpoint)"
if [ -z "$(grep 'Hello World #1!' <<<"$result")" ]; then
    exit 1
fi

# restart the environment.
docker compose down
docker compose up -d
docker compose ps

# invoke the hello endpoint again. this time, the hello counter should be 2,
# because etcd is using a persistent volume.
result="$(wget -qO- $hello_endpoint)"
if [ -z "$(grep 'Hello World #2!' <<<"$result")" ]; then
    exit 1
fi

# show logs.
docker compose logs

# destroy the environment, including the volumes.
docker compose down --volumes
