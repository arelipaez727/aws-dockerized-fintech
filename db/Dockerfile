FROM golang:1.26.9-alpine3.24 AS gosu-builder

RUN apk add --no-cache git \
    && git clone --depth 1 --branch 1.19 https://github.com/tianon/gosu.git /src/gosu \
    && cd /src/gosu \
    && go get golang.org/x/sys@v0.48.0 \
    && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /gosu .

FROM mariadb:11.8.9-ubi9

# La imagen oficial incluye gosu compilado con un Go anterior; conservamos su
# función de bajar privilegios, pero lo reconstruimos con el runtime parchado.
COPY --from=gosu-builder /gosu /usr/local/bin/gosu

COPY db/init-scripts/ /docker-entrypoint-initdb.d/
