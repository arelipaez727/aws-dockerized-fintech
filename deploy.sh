#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "Uso: $0 [--preparar | --levantar]"
    exit 1
fi

case "$1" in
    --preparar)
        echo "=== [1/4] Instalando dependencias básicas (Curl) ==="
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg
            elif [ "$ID" = "amzn" ]; then
                sudo yum update -y
                sudo yum install -y curl
            fi
        fi

        echo "=== [2/4] Instalando Docker y Docker Compose ==="
        if ! command -v docker &> /dev/null; then
            if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
                sudo install -m 0755 -d /etc/apt/keyrings
                if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
                    curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                    sudo chmod a+r /etc/apt/keyrings/docker.gpg
                fi
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            elif [ "$ID" = "amzn" ]; then
                sudo yum install -y docker
                sudo systemctl start docker
                sudo systemctl enable docker
                
                # Instalar docker-compose como plugin
                sudo mkdir -p /usr/local/lib/docker/cli-plugins
                sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
                sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
            fi
            sudo systemctl enable docker || true
            sudo systemctl start docker || true
            # Agregar usuario actual al grupo docker
            sudo usermod -aG docker $USER
            echo "Docker instalado. Puede que necesites salir y volver a entrar (logout/login) para usar docker sin sudo."
        else
            echo "Docker ya está instalado."
        fi

        echo "=== [3/4] Creando carpetas de configuración ==="
        mkdir -p db api-clientes api-pagos api-facturas api-transacciones api-tarjetas web web2 certs

        echo "=== [4/4] Generando certificado SSL ==="
        if [ ! -f certs/cert.pem ] || [ ! -f certs/key.pem ]; then
            openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 365 \
                -keyout certs/key.pem -out certs/cert.pem \
                -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
            echo "Certificado generado en la carpeta certs/."
        else
            echo "Certificados SSL ya existen en certs/."
        fi
        
        echo "=== Pulleando las imágenes de Docker Hub ==="
        sudo docker compose pull
        
        echo "----------------------------------------------------------------------"
        echo "Fase de preparación completada."
        echo "Ahora, ejecuta localmente './transferir.sh --levantar' para enviar los .env,"
        echo "y luego ejecuta en este servidor './deploy.sh --levantar'."
        echo "----------------------------------------------------------------------"
        ;;
        
    --levantar)
        echo "=== [1/2] Validando archivos de configuración ==="
        MISSING_FILES=0

        for folder in db api-clientes api-pagos api-facturas api-transacciones api-tarjetas; do
            if [ ! -f "$folder/.env" ]; then
                echo "ERROR: Falta el archivo .env en $folder/ (esperado: $folder/.env)"
                MISSING_FILES=1
            fi
        done

        if [ ! -f "web2/config.yaml" ]; then
            echo "ERROR: Falta el archivo web2/config.yaml"
            MISSING_FILES=1
        fi

        if [ "$MISSING_FILES" -eq 1 ]; then
            echo "----------------------------------------------------------------------"
            echo "Hay archivos de configuración faltantes."
            echo "Asegúrate de haber ejecutado localmente './transferir.sh --levantar' antes de intentar levantar el stack."
            echo "----------------------------------------------------------------------"
            exit 1
        fi

        echo "Archivos validados correctamente."

        echo "=== [2/2] Levantando los contenedores ==="
        sudo docker compose up -d

        echo "=== Despliegue finalizado exitosamente ==="
        sudo docker compose ps
        ;;
        
    *)
        echo "Parámetro inválido. Uso: $0 [--preparar | --levantar]"
        exit 1
        ;;
esac
