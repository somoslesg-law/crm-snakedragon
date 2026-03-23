import pkg from 'pg';
const { Client } = pkg;
import dotenv from 'dotenv';

dotenv.config({ path: '../.env' });
dotenv.config();

const connectionString = process.env.DATABASE_URL;

async function flushDB() {
    const isSslRequired = process.env.DB_REQUIRE_SSL === 'true' || (connectionString && connectionString.includes('sslmode=require'));
    const client = new Client({
        connectionString,
        ssl: isSslRequired ? { rejectUnauthorized: false } : false
    });

    try {
        console.log('🧹 Limpiando base de datos CRM...');
        await client.connect();
        
        const sql = `DROP SCHEMA IF EXISTS sd_core, sd_clientes, sd_comercial, sd_financiero, sd_servicios, sd_contratos, sd_comisiones, sd_operaciones, sd_marketing, sd_portal, sd_audit, sd_seguridad, sd_analytics CASCADE;`;
        
        await client.query(sql);
        console.log('✨ Base de datos vaciada con éxito.');
        
    } catch (error) {
        console.error('❌ Error al limpiar:', error);
    } finally {
        await client.end();
    }
}

flushDB();
