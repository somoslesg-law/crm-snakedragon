import { Pool, PoolConfig, PoolClient } from 'pg';
import * as dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ FATAL: DATABASE_URL is required. The application cannot start without a database connection.');
  process.exit(1);
}

const poolConfig: PoolConfig = {
  connectionString,
  // Límites de conexiones — ajustar según la RAM del VPS
  max: parseInt(process.env.DB_POOL_MAX || '20', 10),
  min: parseInt(process.env.DB_POOL_MIN || '2', 10),
  // Tiempo máximo que una conexión puede estar ociosa antes de cerrarse
  idleTimeoutMillis: 30000,
  // Tiempo máximo para obtener una conexión del pool antes de lanzar error
  connectionTimeoutMillis: 5000,
};

// Activar SSL si se requiere (entornos cloud externos separados)
if (process.env.DB_REQUIRE_SSL === 'true') {
  poolConfig.ssl = { rejectUnauthorized: false };
}

const pool = new Pool(poolConfig);

pool.on('connect', (client: PoolClient) => {
  // Garantizar zona horaria correcta para todos los campos TIMESTAMPTZ
  client.query("SET TIME ZONE 'America/Bogota'").catch(() => {});
  console.log('🔗 Connected to PostgreSQL database');
});

pool.on('error', (err: Error) => {
  // IMPORTANTE: No usar process.exit() aquí. El pool internamente descarga
  // el cliente roto y reconecta en automático. Un process.exit() aquí
  // derribaría toda la app ante cualquier microcorte de red.
  console.error('⚠️ Unexpected error on idle DB client (auto-recovery in progress):', err.message);
});

export const query = (text: string, params?: unknown[]) => pool.query(text, params);
export const getClient = () => pool.connect();
export default pool;

