#!/bin/sh
set -e

# Leer la configuración desde el archivo YAML y convertirla a JSON
if [ -f /app/config.yaml ]; then
  SERVICES_JSON=$(yq -o=json '.services' /app/config.yaml)
else
  SERVICES_JSON="[]"
  echo "ADVERTENCIA: No se encontró /app/config.yaml"
fi

# Inyectar dinámicamente la configuración
cat <<EOF > /usr/share/nginx/html/config.js
window.ENV_CONFIG = {
  SERVICES: ${SERVICES_JSON}
};
EOF

# Iniciar NGINX directamente en primer plano
exec nginx -g 'daemon off;'
