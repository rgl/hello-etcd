# About

[![Build](https://github.com/rgl/hello-etcd/actions/workflows/build.yml/badge.svg)](https://github.com/rgl/hello-etcd/actions/workflows/build.yml)

This an Hello World example application using Go and etcd.

# Docker Compose Usage

Start the environment defined in the [compose.yml file](compose.yml) and leave it running in foreground:

```bash
docker compose up --build
```

Execute the following commands in another shell.

Show the running containers:

```bash
docker compose ps
```

Try executing commands inside the containers:

```bash
docker compose exec -T hello hello --version
docker compose exec -T etcd etcd --version
docker compose exec -T etcd etcdctl version
docker compose exec -T etcd etcdctl endpoint health
docker compose exec -T etcd etcdctl member list
docker compose exec -T etcd etcdctl put foo bar
docker compose exec -T etcd etcdctl get foo
```

Invoke the [hello endpoint](http://localhost:8888):

```bash
wget -qO- http://localhost:8888
```

At the first shell, stop the environment by pressing `Ctrl+C`, then start it
again. Back at the second shell, redo the test, and notice that the hello
counter resumes where it was left off due to etcd using a persistent volume.

Destroy the environment, including the persistent volumes:

```bash
docker compose down --volumes
```

# References

* [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
* [Compose Spec](https://github.com/compose-spec/compose-spec/blob/master/spec.md)
* [OCI Image Format](https://github.com/opencontainers/image-spec)
  * [Pre-Defined Annotation Keys](https://github.com/opencontainers/image-spec/blob/main/annotations.md) (used in the [Dockerfile](Dockerfile) `LABEL` instructions)
