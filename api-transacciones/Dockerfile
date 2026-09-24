FROM golang:1.26.8-alpine3.24 AS build

WORKDIR /src

COPY api-transacciones/go.mod api-transacciones/go.sum ./
RUN go mod download

COPY api-transacciones/*.go ./
RUN CGO_ENABLED=0 go build -trimpath -o /api-transacciones .

FROM alpine:3.24

RUN apk add --no-cache ca-certificates \
    && addgroup -S -g 10001 app \
    && adduser -S -D -H -u 10001 -G app app

WORKDIR /app

COPY --from=build --chown=app:app /api-transacciones ./api-transacciones

USER app

EXPOSE 8080

ENTRYPOINT ["/app/api-transacciones"]