FROM node:24-bookworm-slim AS build
WORKDIR /app

COPY web/package.json web/package-lock.json ./
RUN npm ci

COPY web/index.html web/vite.config.js ./
COPY web/src/ ./src/
RUN npm run build

FROM nginx:1.30.5-alpine3.24
COPY web/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/ /usr/share/nginx/html/

EXPOSE 443
