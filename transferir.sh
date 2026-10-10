#!/usr/bin/env bash
set -euo pipefail

# Ejecutar desde la raiz del proyecto en Linux o WSL: bash ./transferir.sh <IP_PUBLICA_EC2>
if [ "$#" -ne 1 ]; then
    echo "Uso: bash ./transferir.sh <IP_PUBLICA_EC2>" >&2
    exit 1
fi

EC2_IP="$1"
EC2_USER="ec2-user"
SSH_KEY="$HOME/.ssh/keydevops.pem"
DESTINO="${EC2_USER}@${EC2_IP}"

validar_ip() {
    local octeto
    [[ "$EC2_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    local -a partes
    IFS=. read -r -a partes <<< "$EC2_IP"
    for octeto in "${partes[@]}"; do
        (( 10#$octeto <= 255 )) || return 1
    done
}

if ! validar_ip; then
    echo "Error: la IP debe ser una direccion IPv4 valida." >&2
    exit 1
fi

if [ ! -f docker-compose.yml ] || [ ! -f deploy.sh ]; then
    echo "Error: ejecuta este script desde la raiz del proyecto." >&2
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo "Error: no existe la llave SSH en $SSH_KEY" >&2
    exit 1
fi

for comando in ssh scp; do
    if ! command -v "$comando" >/dev/null 2>&1; then
        echo "Error: falta el comando $comando." >&2
        exit 1
    fi
done

archivos=(
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
        echo "Error: falta o esta vacio $archivo. No se transfirio nada." >&2
        exit 1
    fi
done

echo "[1/3] Creando carpetas en $DESTINO"
ssh -i "$SSH_KEY" "$DESTINO" \
    'umask 077; mkdir -p db api-clientes api-pagos api-facturas api-transacciones api-tarjetas web2 certs; touch db/.env api-clientes/.env api-pagos/.env api-facturas/.env api-transacciones/.env api-tarjetas/.env web2/config.yaml; chmod 600 db/.env api-clientes/.env api-pagos/.env api-facturas/.env api-transacciones/.env api-tarjetas/.env web2/config.yaml'

echo "[2/3] Transfiriendo Compose, deploy y configuraciones privadas"
scp -i "$SSH_KEY" deploy.sh docker-compose.yml "${DESTINO}:~/"
for archivo in "${archivos[@]}"; do
    scp -i "$SSH_KEY" "$archivo" "${DESTINO}:~/$archivo"
done

echo "[3/3] Guardando la IP publica y ajustando permisos en EC2"
ssh -i "$SSH_KEY" "$DESTINO" \
    "umask 077; printf '%s\\n' '$EC2_IP' > .deploy-public-ip; chmod 600 .deploy-public-ip db/.env api-clientes/.env api-pagos/.env api-facturas/.env api-transacciones/.env api-tarjetas/.env web2/config.yaml"

echo "Transferencia completa. En EC2: cd ~ && bash ./deploy.sh"
