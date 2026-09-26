#!/bin/sh
set -e

# Inyectar dinámicamente la configuración desde la variable de entorno SERVICES_CONFIG
cat <<EOF > /usr/share/nginx/html/config.js
window.ENV_CONFIG = {
  SERVICES: ${SERVICES_CONFIG:-[]}
};
EOF

# Iniciar NGINX directamente en primer plano
exec nginx -g 'daemon off;'
