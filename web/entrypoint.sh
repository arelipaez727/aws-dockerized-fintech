#!/bin/sh
set -e

# Crear directorio para certificados si no existe
mkdir -p /etc/nginx/ssl

# Generar certificado autofirmado en runtime si no existe
if [ ! -f /etc/nginx/ssl/cert.pem ]; then
    echo "Generando certificado TLS autofirmado..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/C=AR/ST=CBA/L=Cordoba/O=FinTech/CN=localhost"
    echo "Certificado generado exitosamente."
fi

# Ejecutar NGINX (o el comando que se pase)
exec "$@"
