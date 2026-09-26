# Etapa 1: Build de Vite
FROM node:20-alpine AS builder

WORKDIR /app

# Instalar dependencias
COPY package*.json ./
RUN npm ci

# Copiar código fuente y buildear
COPY . .
RUN npm run build

# Etapa 2: Servir con NGINX
FROM nginx:alpine

# Instalar OpenSSL para poder generar el certificado al iniciar el contenedor
RUN apk add --no-cache openssl

# Copiar la configuración del proxy de NGINX
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Copiar el build compilado de la etapa 1
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar el script de inicialización (entrypoint)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Exponer el puerto HTTPS (la consigna pide no abrir el 80)
EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
