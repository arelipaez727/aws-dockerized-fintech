FROM node:24-bookworm-slim

ENV NODE_ENV=production
ENV PORT=8080

WORKDIR /app

COPY api-pagos/package.json api-pagos/package-lock.json ./
RUN npm ci --omit=dev

COPY --chown=node:node api-pagos/src/ ./src/

USER node

EXPOSE 8080

CMD ["node", "src/server.js"]