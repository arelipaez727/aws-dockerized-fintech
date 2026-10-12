FROM node:24-alpine3.24

ENV NODE_ENV=production
ENV PORT=8080

WORKDIR /app

RUN apk upgrade --no-cache

COPY api-pagos/package.json api-pagos/package-lock.json ./
RUN npm ci --omit=dev

COPY --chown=node:node api-pagos/src/ ./src/

USER node

EXPOSE 8080

CMD ["node", "src/server.js"]
