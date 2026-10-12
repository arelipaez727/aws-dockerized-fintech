#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "--build" ]; then
    # Esta opcion se ejecuta localmente, antes de transferir, desde la raiz del proyecto.
    DOCKERHUB_USER="${2:-}"
    if [ "$#" -ne 2 ] || [ -z "$DOCKERHUB_USER" ] || [ ! -f docker-compose.yml ]; then
        echo "Uso local: bash ./deploy.sh --build <usuario-dockerhub> (desde la raiz)" >&2
        exit 1
    fi

    publicar_imagen() {
        local servicio="$1" version="$2" contexto="$3" imagen
        imagen="$DOCKERHUB_USER/fintech-nova-$servicio:$version"
        echo "=== Construyendo $imagen ==="
        docker build -t "$imagen" -f "$servicio/Dockerfile" "$contexto"
        echo "=== Publicando $imagen ==="
        docker push "$imagen"
    }

    publicar_imagen db 1.0.2 .
    publicar_imagen api-clientes 1.0.2 .
    publicar_imagen api-pagos 1.0.2 .
    publicar_imagen api-facturas 1.0.2 .
    publicar_imagen api-transacciones 1.0.2 .
    publicar_imagen api-tarjetas 1.0.2 .
    publicar_imagen web 1.0.2 .
    publicar_imagen web2 1.0.2 web2
    echo "Las ocho imagenes se publicaron en Docker Hub."
    exit 0
fi

if [ "$#" -ne 0 ]; then
    echo "Uso remoto: bash ./deploy.sh (sin parametros)" >&2
    exit 1
fi

# El script remoto no necesita usuario ni llave SSH: ya esta dentro de la EC2.
cd "$(dirname "$0")"

if [ ! -f /etc/os-release ]; then
    echo "Error: no se pudo identificar el sistema operativo." >&2
    exit 1
fi
. /etc/os-release
if [ "${ID:-}" != "amzn" ]; then
    echo "Error: este despliegue remoto esta preparado para Amazon Linux 2023." >&2
    exit 1
fi

if [ ! -s .deploy-public-ip ]; then
    echo "Error: falta .deploy-public-ip; ejecuta primero transferir.sh o transferir.ps1." >&2
    exit 1
fi
PUBLIC_IP="$(tr -d '\r\n' < .deploy-public-ip)"
if ! [[ "$PUBLIC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Error: .deploy-public-ip no contiene una IPv4 valida." >&2
    exit 1
fi
IFS=. read -r -a octetos <<< "$PUBLIC_IP"
for octeto in "${octetos[@]}"; do
    if (( 10#$octeto > 255 )); then
        echo "Error: .deploy-public-ip no contiene una IPv4 valida." >&2
        exit 1
    fi
done

echo "=== [1/5] Validando archivos transferidos ==="
archivos=(
    docker-compose.yml
    db/.env
    api-clientes/.env
    api-pagos/.env
    api-facturas/.env
    api-transacciones/.env
    api-tarjetas/.env
    web2/config.yaml
)
for archivo in "${archivos[@]}"; do
    if [ ! -s "$archivo" ]; then
        echo "Error: falta o esta vacio $archivo." >&2
        exit 1
    fi
done
if [ ! -d certs ]; then
    echo "Error: falta certs/; ejecuta primero el script de transferencia." >&2
    exit 1
fi

echo "=== [2/5] Instalando Docker y Compose en Amazon Linux 2023 ==="
# AL2023 ya suele incluir curl-minimal. No instalar curl completo encima: son incompatibles.
if ! command -v curl >/dev/null 2>&1; then
    sudo dnf install -y curl-minimal
fi
if ! command -v openssl >/dev/null 2>&1; then
    sudo dnf install -y openssl
fi
if ! command -v docker >/dev/null 2>&1; then
    sudo dnf install -y docker
fi
sudo systemctl enable --now docker

if ! sudo docker compose version >/dev/null 2>&1; then
    # La AMI no trae necesariamente el plugin. Version fijada para un despliegue reproducible.
    COMPOSE_VERSION="v5.6.0"
    arquitectura="$(uname -m)"
    case "$arquitectura" in
        x86_64|aarch64) ;;
        *) echo "Error: arquitectura no soportada: $arquitectura" >&2; exit 1 ;;
    esac
    binario_temporal="$(mktemp)"
    trap 'rm -f "$binario_temporal"' EXIT
    curl --fail --show-error --silent --location \
        "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-linux-$arquitectura" \
        --output "$binario_temporal"
    sudo install -d -m 0755 /usr/local/lib/docker/cli-plugins
    sudo install -m 0755 "$binario_temporal" /usr/local/lib/docker/cli-plugins/docker-compose
    rm -f "$binario_temporal"
    trap - EXIT
fi
sudo docker compose version

echo "=== [3/5] Preparando el certificado TLS ==="
certificado_actualizado=0
if [ -s certs/cert.pem ] && [ -s certs/key.pem ] && \
   openssl x509 -in certs/cert.pem -noout -checkend 86400 >/dev/null 2>&1 && \
   openssl x509 -in certs/cert.pem -noout -ext subjectAltName 2>/dev/null | grep -Fq "IP Address:$PUBLIC_IP"; then
    echo "El certificado existente ya incluye $PUBLIC_IP y sigue vigente."
else
    # Generar primero archivos nuevos; conservar copia del par anterior si existia.
    umask 077
    openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 365 \
        -keyout certs/key.pem.nuevo -out certs/cert.pem.nuevo \
        -subj "/CN=$PUBLIC_IP" \
        -addext "subjectAltName=IP:$PUBLIC_IP,DNS:localhost,IP:127.0.0.1"
    marca="$(date -u +%Y%m%dT%H%M%SZ)-$$"
    if [ -f certs/cert.pem ]; then
        cp -p certs/cert.pem "certs/cert.pem.$marca.bak"
    fi
    if [ -f certs/key.pem ]; then
        cp -p certs/key.pem "certs/key.pem.$marca.bak"
        chmod 600 "certs/key.pem.$marca.bak"
    fi
    mv -f certs/key.pem.nuevo certs/key.pem
    mv -f certs/cert.pem.nuevo certs/cert.pem
    chmod 600 certs/key.pem
    certificado_actualizado=1
    echo "Certificado autofirmado generado para $PUBLIC_IP (no confiable por defecto en navegadores)."
fi

echo "=== [4/5] Descargando y levantando las ocho imagenes ==="
sudo docker compose config --quiet
sudo docker compose pull
sudo docker compose up -d
if [ "$certificado_actualizado" -eq 1 ]; then
    sudo docker compose restart web
fi

echo "=== [5/5] Comprobando las rutas HTTPS ==="
for ruta in / /api/clientes /api/pagos /api/facturas /api/transacciones /api/tarjetas /monitor/; do
    estado=""
    for intento in $(seq 1 18); do
        estado="$(curl --insecure --silent --output /dev/null --write-out '%{http_code}' "https://127.0.0.1$ruta" || true)"
        if [ "$estado" = "200" ]; then
            break
        fi
        sleep 5
    done
    if [ "$estado" != "200" ]; then
        echo "Error: $ruta no respondio con HTTP 200 (ultimo estado: $estado)." >&2
        sudo docker compose ps
        exit 1
    fi
    echo "OK: $ruta (HTTP 200)"
done

echo "=== Despliegue finalizado: https://$PUBLIC_IP/ ==="
sudo docker compose ps
