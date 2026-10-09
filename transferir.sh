#!/bin/bash

# Configura aquí el usuario y la IP de la instancia EC2
EC2_USER="ubuntu"
EC2_IP="0.0.0.0"
SSH_KEY="ruta/a/tu/llave.pem"

if [ $# -eq 0 ]; then
    echo "Uso: $0 [--preparar | --levantar]"
    exit 1
fi

case "$1" in
    --preparar)
        echo "=== Transfiriendo deploy.sh y docker-compose.yml al servidor ==="
        scp -i "$SSH_KEY" deploy.sh docker-compose.yml "$EC2_USER@$EC2_IP:~/"
        echo "Archivos transferidos. Conéctate por SSH y ejecuta: ./deploy.sh --preparar"
        ;;
        
    --levantar)
        echo "=== Transfiriendo los archivos .env y config.yaml al servidor ==="
        # db
        scp -i "$SSH_KEY" db/.env "$EC2_USER@$EC2_IP:~/db/.env"
        # apis
        scp -i "$SSH_KEY" api-clientes/.env "$EC2_USER@$EC2_IP:~/api-clientes/.env"
        scp -i "$SSH_KEY" api-pagos/.env "$EC2_USER@$EC2_IP:~/api-pagos/.env"
        scp -i "$SSH_KEY" api-facturas/.env "$EC2_USER@$EC2_IP:~/api-facturas/.env"
        scp -i "$SSH_KEY" api-transacciones/.env "$EC2_USER@$EC2_IP:~/api-transacciones/.env"
        scp -i "$SSH_KEY" api-tarjetas/.env "$EC2_USER@$EC2_IP:~/api-tarjetas/.env"
        # web2
        scp -i "$SSH_KEY" web2/config.yaml "$EC2_USER@$EC2_IP:~/web2/config.yaml"
        
        echo "Secretos transferidos. Conéctate por SSH y ejecuta: ./deploy.sh --levantar"
        ;;
        
    *)
        echo "Parámetro inválido. Uso: $0 [--preparar | --levantar]"
        exit 1
        ;;
esac
