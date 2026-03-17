# ─── Build Stage ─────────────────────────────────────────────────────────────
FROM node:20-slim AS builder

WORKDIR /app

# Instalar dependencias
COPY package*.json ./
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*
RUN npm install

# Copiar el resto del código
COPY . .

# Build del frontend (Vite)
RUN npm run build:prod

# ─── Production Stage ────────────────────────────────────────────────────────
FROM node:20-slim

WORKDIR /app

# Copiar dependencias de producción y binarios necesarios
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server ./server

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV API_PORT=5000

# Exponer el puerto
EXPOSE 5000

# Comando para arrancar el backend (que sirve el frontend)
CMD ["npx", "tsx", "server/index.ts"]
