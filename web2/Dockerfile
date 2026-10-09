FROM nginx:alpine

# Instalar yq para procesar el config.yaml
RUN apk add --no-cache yq

# Copiar archivos estáticos y script de inicialización
COPY index.html /usr/share/nginx/html/index.html
COPY theme.css /usr/share/nginx/html/theme.css
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# El entrypoint inyecta las variables del .env y levanta NGINX directamente
ENTRYPOINT ["/entrypoint.sh"]
