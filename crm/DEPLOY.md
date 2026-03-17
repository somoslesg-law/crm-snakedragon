# Guía de Despliegue — Snake Dragon CRM V3 en Hostinger VPS

## Requisitos Previos
- Hostinger VPS (Ubuntu 22.04+)
- Dominio configurado apuntando al VPS
- Acceso SSH al servidor

---

## PASO 1 — Preparar el Servidor (Primera Vez)

```bash
# Conectarse al VPS
ssh root@tu-ip-del-vps

# Actualizar sistema
apt update && apt upgrade -y

# Instalar Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Instalar PM2 globalmente
npm install -g pm2

# Instalar Nginx
apt install -y nginx

# Instalar PostgreSQL
apt install -y postgresql postgresql-contrib
```

---

## PASO 2 — Configurar PostgreSQL

```bash
# Crear base de datos y usuario
sudo -u postgres psql

# Dentro de psql:
CREATE DATABASE snake_dragon;
CREATE USER sd_admin WITH ENCRYPTED PASSWORD 'TU_PASSWORD_SEGURO';
GRANT ALL PRIVILEGES ON DATABASE snake_dragon TO sd_admin;
\q

# Exportar DATABASE_URL para uso en scripts
export DATABASE_URL="postgresql://sd_admin:TU_PASSWORD_SEGURO@localhost:5432/snake_dragon"
```

---

## PASO 3 — Subir el Proyecto

```bash
# Opción A: Clonar desde Git (recomendado)
git clone https://github.com/tu-usuario/snake-dragon-crm.git /var/www/snake-dragon

# Opción B: Subir con SCP desde tu máquina local
scp -r ./crm root@tu-ip:/var/www/snake-dragon

# Ir al directorio
cd /var/www/snake-dragon

# Instalar dependencias
npm install --production=false
```

---

## PASO 4 — Configurar Variables de Entorno

```bash
# Copiar el template
cp .env.example .env

# Editar con tus valores reales
nano .env
```

**Valores a completar en `.env`:**
```
APP_URL=https://tudominio.com
GEMINI_API_KEY=tu_api_key_real
DATABASE_URL=postgresql://sd_admin:PASSWORD@localhost:5432/snake_dragon
NODE_ENV=production
JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")
API_PORT=5000
VITE_API_URL=https://tudominio.com/api
```

---

## PASO 5 — Inicializar la Base de Datos

```bash
cd /var/www/snake-dragon/database

# Ejecutar el script unificado (V1 → V2 → V3 → Seed) — UNA SOLA VEZ
psql -U sd_admin -d snake_dragon -f init.sql
```

> **Nota:** El script `init.sql` ejecuta automáticamente los 3 esquemas  
> (`snake_dragon_crm_v1.sql → v2.sql → v3.sql`) y luego los datos semilla  
> (`seed.sql`). También refresca las vistas materializadas al terminar.

**Credenciales iniciales creadas:**
- **Email:** `admin@snakedragon.com`
- **Contraseña:** `Admin2024!`
- ⚠️ **Cambiar la contraseña en el primer login**

---

## PASO 6 — Build del Frontend

```bash
cd /var/www/snake-dragon

# Build de producción de Vite
npm run build:prod

# Verificar que se creó la carpeta dist/
ls dist/
```

---

## PASO 7 — Configurar PM2 (Proceso del Backend)

```bash
cd /var/www/snake-dragon

# Crear directorio de logs
mkdir -p logs

# Editar ecosystem.config.cjs con la ruta correcta
# Cambiar: cwd: '/var/www/snake-dragon' (ya está configurado)

# Iniciar con PM2
pm2 start ecosystem.config.cjs

# Verificar que está corriendo
pm2 status
pm2 logs snake-dragon-api

# Guardar configuración para reinicio automático
pm2 save
pm2 startup
# Ejecutar el comando que PM2 te indique (algo como: systemctl enable pm2-root)
```

---

## PASO 8 — Configurar Nginx

```bash
# Copiar configuración
cp /var/www/snake-dragon/nginx.conf /etc/nginx/sites-available/snake-dragon

# Editar: cambiar 'tudominio.com' por tu dominio real
nano /etc/nginx/sites-available/snake-dragon

# Activar el sitio
ln -s /etc/nginx/sites-available/snake-dragon /etc/nginx/sites-enabled/

# Desactivar el sitio por defecto (opcional)
rm /etc/nginx/sites-enabled/default

# Verificar configuración
nginx -t

# Recargar Nginx
systemctl reload nginx
```

---

## PASO 9 — Certificado SSL (HTTPS)

```bash
# Instalar Certbot
apt install -y certbot python3-certbot-nginx

# Obtener certificado (reemplaza con tu dominio)
certbot --nginx -d tudominio.com -d www.tudominio.com

# Verificar renovación automática
certbot renew --dry-run
```

---

## PASO 10 — Verificación Final

```bash
# 1. Verificar el health check del API
curl https://tudominio.com/api/health

# Respuesta esperada:
# {"status":"ok","db":"connected","timestamp":"..."}

# 2. Verificar PM2
pm2 status

# 3. Ver logs en tiempo real
pm2 logs snake-dragon-api --lines 50
```

---

## Comandos Útiles Post-Despliegue

```bash
# Ver estado de todos los servicios
pm2 status && systemctl status nginx && systemctl status postgresql

# Reiniciar el API después de cambios
pm2 restart snake-dragon-api

# Actualizar el proyecto desde Git
cd /var/www/snake-dragon
git pull origin main
npm install
npm run build:prod
pm2 restart snake-dragon-api

# Ver logs de errores
pm2 logs snake-dragon-api --err
tail -f /var/log/nginx/error.log
```

---

## Solución de Problemas Comunes

| Problema | Solución |
|---|---|
| API no responde en `/api/health` | `pm2 logs snake-dragon-api` para ver el error |
| Frontend muestra pantalla en blanco | Verificar que `dist/` existe: `npm run build:prod` |
| Error de conexión a BD | Verificar `DATABASE_URL` en `.env` |
| CORS error en browser | Verificar que `APP_URL` en `.env` coincide con el dominio |
| Puerto 5000 bloqueado | `ufw allow 5000` o verificar que Nginx está proxeando |
