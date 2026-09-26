FROM nginx:alpine

# Copiar archivos estáticos y script de inicialización
COPY index.html /usr/share/nginx/html/index.html
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

# El entrypoint inyecta las variables del .env y levanta NGINX directamente
ENTRYPOINT ["/entrypoint.sh"]
