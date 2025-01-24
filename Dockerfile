# syntax=docker.io/docker/dockerfile:1.13

FROM golang:1.23.5-bookworm as builder
WORKDIR /src
COPY go.* ./
RUN go mod download
COPY *.go ./
ARG HELLO_VERSION='0.0.0-dev'
ARG HELLO_REVISION='0000000000000000000000000000000000000000'
RUN CGO_ENABLED=0 go build -ldflags="-s -X main.version=${HELLO_VERSION} -X main.revision=${HELLO_REVISION}"

# NB we use the buster-slim (instead of scratch) image so we can enter the container to execute bash etc.
FROM debian:bookworm-slim
EXPOSE 8888
COPY --from=builder /src/hello /usr/local/bin/
# NB 65534:65534 is the uid:gid of the nobody:nogroup user:group.
# NB we use a numeric uid:gid to easy the use in kubernetes securityContext.
#    k8s will only be able to infer the runAsUser and runAsGroup values when
#    the USER intruction has a numeric uid:gid. otherwise it will fail with:
#       kubelet Error: container has runAsNonRoot and image has non-numeric
#       user (nobody), cannot verify user is non-root
USER 65534:65534
ENTRYPOINT ["hello"]
ARG HELLO_SOURCE_URL
ARG HELLO_REVISION
LABEL org.opencontainers.image.source="$HELLO_SOURCE_URL"
LABEL org.opencontainers.image.revision="$HELLO_REVISION"
LABEL org.opencontainers.image.description="Hello World example application using Go and etcd"
LABEL org.opencontainers.image.licenses="MIT"
