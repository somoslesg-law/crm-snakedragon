# ─── Build Stage ─────────────────────────────────────────────────────────────
FROM node:20-slim AS builder

WORKDIR /app

# Instalar postgresql-client para los scripts de migraciones
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

# Instalar TODAS las dependencias (incluidas devDeps para build)
COPY package*.json ./
RUN npm ci

# Copiar el código fuente y compilar el frontend
COPY . .
RUN npm run build:prod

# ─── Production Stage ────────────────────────────────────────────────────────
FROM node:20-slim

WORKDIR /app

# Instalar solo dependencias de producción
COPY package*.json ./
RUN npm ci --omit=dev

# Copiar artefactos del build stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/dist-server ./dist-server
COPY --from=builder /app/database ./database

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=5000

# Exponer el puerto
EXPOSE 5000

# El comando ahora es node puro (mucho más rápido y ligero)
CMD ["node", "dist-server/index.js"]
