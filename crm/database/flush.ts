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
        
        const sql = `
            DROP SCHEMA IF EXISTS sd_core, sd_clientes, sd_comercial, sd_financiero, sd_servicios, sd_contratos, sd_comisiones, sd_operaciones, sd_marketing, sd_portal, sd_audit, sd_seguridad, sd_analytics, sd_ai, sd_automation, sd_producto, sd_inteligencia, sd_events, sd_soporte, sd_copilot CASCADE;
            
            -- Limpiar tipos (Enums) que puedan haber quedado en el esquema public o residuales
            DO $$ 
            DECLARE 
                r RECORD;
            BEGIN
                FOR r IN (SELECT n.nspname, t.typname 
                          FROM pg_type t 
                          JOIN pg_namespace n ON t.typnamespace = n.oid 
                          WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') 
                            AND t.typtype = 'e') 
                LOOP
                    EXECUTE 'DROP TYPE IF EXISTS ' || quote_ident(r.nspname) || '.' || quote_ident(r.typname) || ' CASCADE';
                END LOOP;
            END $$;
        `;
        
        await client.query(sql);
        console.log('✨ Base de datos vaciada con éxito.');
        
    } catch (error) {
        console.error('❌ Error al limpiar:', error);
    } finally {
        await client.end();
    }
}

flushDB();
