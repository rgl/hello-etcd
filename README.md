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
docker compose down --volumes --timeout=0
```

# Kubernetes Usage

**NB** This assumes you are using a [Kind Kubernetes cluster](https://github.com/kubernetes-sigs/kind) as configured in [rgl/my-ubuntu-ansible-playbooks](https://github.com/rgl/my-ubuntu-ansible-playbooks/tree/main/roles/kind). So YMMV.

Ensure that your Kubernetes cluster has support for persistent data. For that,
display the available `StorageClass`, and ensure that is has a `standard`
class, otherwise you have to modify the [`manifest.yml` file](manifest.yml) to
use a class that exists in your particular cluster:

```bash
kubectl get sc
```

Deploy the manifest:

```bash
kubectl apply -f manifest.yml
```

Wait for the deployments to finish, and `PersistentVolumeClaim` to be bound:

```bash
kubectl rollout status deployment hello-etcd
kubectl rollout status statefulset hello-etcd-etcd
kubectl wait --for jsonpath='{.status.phase}=Bound' pvc/etcd-data-hello-etcd-etcd-0
```

Display the `Ingress`, `Service`, `Pod`, `PersistentVolumeClaim`,
`PersistentVolume`, and `StorageClass` resources:

```bash
kubectl get service,pod,pvc,pv,sc
```

Access the `hello-etcd` service from a [kubectl port-forward local port](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/):

```bash
kubectl port-forward service/hello-etcd 6789:web &
sleep 3
wget -qO- http://localhost:6789 # Hello World #1!
wget -qO- http://localhost:6789 # Hello World #2!
wget -qO- http://localhost:6789 # Hello World #3!
kill %1
sleep 1
```

Delete the resources:

**NB** Since we are using a `StatefulSet` with `persistentVolumeClaimRetentionPolicy` set to `Retain` (the default), the `PersistentVolumeClaim` and `PersistentVolume` resources are not automatically deleted.

```bash
kubectl delete -f manifest.yml
```

Verify that the `PersistentVolumeClaim` and `PersistentVolume` resources are
still available:

```bash
kubectl get pvc,pv
```

Recreate the resources:

```bash
kubectl apply -f manifest.yml
kubectl rollout status deployment hello-etcd
kubectl rollout status statefulset hello-etcd-etcd
kubectl get service,statefulset,pod,pvc,pv,sc
```

Access the `hello-etcd` service from a [kubectl port-forward local port](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/):

```bash
kubectl port-forward service/hello-etcd 6789:web &
sleep 3
wget -qO- http://localhost:6789 # Hello World #4!
wget -qO- http://localhost:6789 # Hello World #5!
wget -qO- http://localhost:6789 # Hello World #6!
kill %1
sleep 1
```

Notice that the hello counter resumes where it was left off due to etcd using a
persistent volume.

Delete everything, including the persistent volume:

```bash
kubectl delete -f manifest.yml
kubectl delete persistentvolumeclaim/etcd-data-hello-etcd-etcd-0
kubectl get service,pod,pvc,pv,sc
```

# References

* [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
* [Compose Spec](https://github.com/compose-spec/compose-spec/blob/master/spec.md)
* [OCI Image Format](https://github.com/opencontainers/image-spec)
  * [Pre-Defined Annotation Keys](https://github.com/opencontainers/image-spec/blob/main/annotations.md) (used in the [Dockerfile](Dockerfile) `LABEL` instructions)
* Kubernetes
  * [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
  * [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
  * [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
