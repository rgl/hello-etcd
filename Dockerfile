FROM golang:1.21-bookworm as builder
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
ENTRYPOINT ["hello"]
ARG HELLO_SOURCE_URL
ARG HELLO_REVISION
LABEL org.opencontainers.image.source="$HELLO_SOURCE_URL"
LABEL org.opencontainers.image.revision="$HELLO_REVISION"
LABEL org.opencontainers.image.description="Hello World example application using Go and etcd"
LABEL org.opencontainers.image.licenses="MIT"
