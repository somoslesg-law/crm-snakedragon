import pkg from 'pg';
const { Client } = pkg;
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

// Cargar variables de entorno
dotenv.config({ path: '../.env' });
dotenv.config(); // También cargar del directorio actual si existe

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ Error: DATABASE_URL no está definida.');
  process.exit(1);
}

async function runMigration() {
  const isSslRequired = process.env.DB_REQUIRE_SSL === 'true' || connectionString.includes('sslmode=require');
  
  const client = new Client({
    connectionString,
    ssl: isSslRequired ? { rejectUnauthorized: false } : false
  });

  try {
    console.log('🚀 Iniciando migración de base de datos...');
    await client.connect();
    console.log('✅ Conectado a PostgreSQL.');

    const sqlFiles = [
      'snake_dragon_crm_v1.sql',
      'snake_dragon_crm_v2.sql',
      'snake_dragon_crm_v3.sql',
      'seed.sql'
    ];

    for (const file of sqlFiles) {
      console.log(`📦 Ejecutando ${file}...`);
      const filePath = path.join(__dirname, file);
      
      if (!fs.existsSync(filePath)) {
        console.warn(`⚠️ Archivo ${file} no encontrado, saltando...`);
        continue;
      }

      const sql = fs.readFileSync(filePath, 'utf8');
      
      // Ejecutar el SQL
      await client.query(sql);
      console.log(`✅ ${file} completado.`);
    }

    console.log('🎉 ¡Base de datos inicializada correctamente!');
  } catch (error) {
    console.error('❌ Error durante la migración:', error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();
