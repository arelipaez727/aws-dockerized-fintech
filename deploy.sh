#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "Uso: $0 [--build <usuario-dockerhub> | --preparar | --levantar]"
    exit 1
fi

case "$1" in
    --build)
        # Esta fase se ejecuta en la computadora local, desde la raiz del proyecto.
        DOCKERHUB_USER="${2:-${DOCKERHUB_USER:-}}"
        if [ -z "$DOCKERHUB_USER" ] || [ ! -f docker-compose.yml ]; then
            echo "Uso: ./deploy.sh --build <usuario-dockerhub> (desde la raiz del proyecto)"
            exit 1
        fi

        publicar_imagen() {
            servicio="$1"
            version="$2"
            contexto="$3"
            imagen="$DOCKERHUB_USER/fintech-nova-$servicio:$version"

            echo "=== Construyendo $imagen ==="
            docker build -t "$imagen" -f "$servicio/Dockerfile" "$contexto"
            echo "=== Publicando $imagen ==="
            docker push "$imagen"
        }

        publicar_imagen db 1.0.0 .
        publicar_imagen api-clientes 1.0.0 .
        publicar_imagen api-pagos 1.0.0 .
        publicar_imagen api-facturas 1.0.1 .
        publicar_imagen api-transacciones 1.0.0 .
        publicar_imagen api-tarjetas 1.0.0 .
        publicar_imagen web 1.0.1 .
        publicar_imagen web2 1.0.0 web2

        echo "Las ocho imagenes se publicaron en Docker Hub. Falta actualizar y probar docker-compose.yml."
        ;;
    --preparar)
        echo "=== [1/4] Comprobando dependencias básicas (curl y OpenSSL) ==="
        sudo yum update -y
        # Amazon Linux 2023 ya incluye curl-minimal, incompatible con curl completo.
        if ! command -v curl >/dev/null 2>&1; then
            sudo yum install -y curl-minimal
        fi
        if ! command -v openssl >/dev/null 2>&1; then
            sudo yum install -y openssl
        fi

        echo "=== [2/4] Instalando Docker y Docker Compose ==="
        if ! command -v docker &> /dev/null; then
            sudo yum install -y docker
            sudo systemctl start docker
            sudo systemctl enable docker
            
            # Instalar docker-compose como plugin
            sudo mkdir -p /usr/local/lib/docker/cli-plugins
            sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
            sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
            
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
        
        echo "----------------------------------------------------------------------"
        echo "Fase de preparación completada."
        echo "Ahora, ejecuta localmente './transferir.sh --levantar' para enviar los .env,"
        echo "y luego ejecuta en este servidor './deploy.sh --levantar'."
        echo "----------------------------------------------------------------------"
        ;;
        
    --levantar)
        echo "=== [1/4] Validando archivos de configuración ==="
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

        if [ ! -f "certs/cert.pem" ] || [ ! -f "certs/key.pem" ]; then
            echo "ERROR: Faltan los certificados TLS en certs/"
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

        echo "=== [2/4] Descargando las imagenes de Docker Hub ==="
        sudo docker compose pull

        echo "=== [3/4] Levantando los contenedores ==="
        sudo docker compose up -d

        echo "=== [4/4] Comprobando las rutas HTTPS ==="
        for ruta in / /api/clientes /api/pagos /api/facturas /api/transacciones /api/tarjetas /monitor/; do
            estado=""
            for intento in $(seq 1 18); do
                estado=$(curl --insecure --silent --output /dev/null --write-out '%{http_code}' "https://127.0.0.1$ruta" || true)
                if [ "$estado" = "200" ]; then
                    break
                fi
                sleep 5
            done
            if [ "$estado" != "200" ]; then
                echo "ERROR: $ruta no respondio con HTTP 200 (ultimo estado: $estado)"
                sudo docker compose ps
                exit 1
            fi
            echo "OK: $ruta (HTTP 200)"
        done

        echo "=== Despliegue finalizado exitosamente ==="
        sudo docker compose ps
        ;;
        
    *)
        echo "Parámetro inválido. Uso: $0 [--build <usuario-dockerhub> | --preparar | --levantar]"
        exit 1
        ;;
esac
