FROM golang:1.26.9-alpine3.24 AS yq-builder

WORKDIR /build
RUN go mod init fintech-nova-yq \
    && go get github.com/mikefarah/yq/v4@v4.54.1 \
    && go get golang.org/x/net@v0.60.0 \
    && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /yq github.com/mikefarah/yq/v4

FROM nginx:1.30.5-alpine3.24

# yq convierte la configuración montada en runtime; Nginx escucha solo en la red interna.
RUN apk upgrade --no-cache \
    && addgroup -S -g 10001 app \
    && adduser -S -D -u 10001 -G app app \
    && chown -R app:app /var/cache/nginx /usr/share/nginx/html

COPY --from=yq-builder /yq /usr/local/bin/yq
COPY nginx.conf /etc/nginx/nginx.conf
COPY --chown=app:app index.html theme.css /usr/share/nginx/html/
COPY --chown=app:app --chmod=755 entrypoint.sh /entrypoint.sh

USER app
EXPOSE 8081

# El entrypoint convierte config.yaml en config.js y arranca Nginx.
ENTRYPOINT ["/entrypoint.sh"]
