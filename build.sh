#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "Uso: $0 <usuario-dockerhub>"
    echo "Ejemplo: $0 miusuario123"
    exit 1
fi

DOCKER_USER=$1

echo "=== Logueando en Docker Hub ==="
docker login

echo "=== Construyendo imágenes ==="
docker build -t "$DOCKER_USER/fintech-nova-db:1.0.0" -f db/Dockerfile .
docker build -t "$DOCKER_USER/fintech-nova-api-clientes:1.0.0" -f api-clientes/Dockerfile .
docker build -t "$DOCKER_USER/fintech-nova-api-pagos:1.0.0" -f api-pagos/Dockerfile .
docker build -t "$DOCKER_USER/fintech-nova-api-facturas:1.0.1" -f api-facturas/Dockerfile .
docker build -t "$DOCKER_USER/fintech-nova-api-transacciones:1.0.0" -f api-transacciones/Dockerfile .
docker build -t "$DOCKER_USER/fintech-nova-api-tarjetas:1.0.0" -f api-tarjetas/Dockerfile .
docker build -t "$DOCKER_USER/fintech-nova-web:1.0.1" -f web/Dockerfile .
docker build -t "$DOCKER_USER/web2:1.0.0" -f web2/Dockerfile .

echo "=== Subiendo imágenes a Docker Hub ==="
docker push "$DOCKER_USER/fintech-nova-db:1.0.0"
docker push "$DOCKER_USER/fintech-nova-api-clientes:1.0.0"
docker push "$DOCKER_USER/fintech-nova-api-pagos:1.0.0"
docker push "$DOCKER_USER/fintech-nova-api-facturas:1.0.1"
docker push "$DOCKER_USER/fintech-nova-api-transacciones:1.0.0"
docker push "$DOCKER_USER/fintech-nova-api-tarjetas:1.0.0"
docker push "$DOCKER_USER/fintech-nova-web:1.0.1"
docker push "$DOCKER_USER/web2:1.0.0"

echo "=== Proceso finalizado ==="
echo "Recuerda actualizar tu docker-compose.yml con las imágenes:"
echo "image: $DOCKER_USER/fintech-nova-db:1.0.0"
