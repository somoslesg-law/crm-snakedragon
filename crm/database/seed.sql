-- ═══════════════════════════════════════════════════════════════
-- SNAKE DRAGON CRM V3 — SEED DATA (Revenue Intelligence System)
-- Initial data: superadmin, system config, category lookups
-- ═══════════════════════════════════════════════════════════════

-- Deshabilitar triggers temporalmente para carga masiva
SET session_replication_role = 'replica';

-- ─── Configuración Inicial del Sistema ──────────────────────────────────────────
INSERT INTO sd_core.configuracion (clave, valor, descripcion, categoria) VALUES
('empresa_nombre', '"Snake Dragon Corp"', 'Nombre legal de la entidad', 'sistema'),
('moneda_principal', '"COP"', 'Moneda base del sistema', 'financiero'),
('n8n_webhook_url', '"https://n8n.tu-dominio.com/webhook/crm"', 'URL base para automatizaciones', 'sistema'),
('pipeline_default_id', '"general"', 'Pipeline por defecto para nuevos leads', 'comercial')
ON CONFLICT (clave) DO UPDATE SET valor = EXCLUDED.valor;

-- ─── Usuario Superadministrador ────────────────────────────────────────────────
-- Contraseña por defecto: Admin2024!
INSERT INTO sd_core.usuarios (
    id, codigo_usuario, email, password_hash, nombre, apellido, nombre_display, rol, activo
) VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'SD-USR-001', 'admin@snakedragon.com', 
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TZFSTk5.3K7Y7hM2F6q.mE2mHRXu', 
    'Andrés', 'Valencia', 'Andrés (SuperAdmin)', 'superadmin', true
) ON CONFLICT (email) DO NOTHING;

-- ─── Catálogo de Industrias (sd_core.cat_industrias) ───────────────────────────
INSERT INTO sd_core.cat_industrias (codigo, nombre, sector_padre, score_icp) VALUES
('IND-TECH',    'Tecnología y Software', 'Servicios', 10),
('IND-FIN',     'Finanzas y Seguros',    'Servicios', 9),
('IND-CONS',    'Consultoría Prof.',     'Servicios', 8),
('IND-RETAIL',  'Retail y Comercio',     'Consumo',   6),
('IND-MANU',    'Manufactura',           'Industrial', 7)
ON CONFLICT (codigo) DO NOTHING;

-- ─── Catálogo de Orígenes de Lead (sd_core.cat_origenes_lead) ──────────────────
INSERT INTO sd_core.cat_origenes_lead (codigo, nombre, categoria, es_digital) VALUES
('SRC-WEB',     'Sitio Web (Orgánico)',  'organico', true),
('SRC-LNK',     'LinkedIn Ads',          'pagado',   true),
('SRC-REF',     'Referido de Cliente',   'referido', false),
('SRC-EVENT',   'Evento Presencial',      'evento',   false),
('SRC-COLD',    'Outbound / Prospección','outbound', false)
ON CONFLICT (codigo) DO NOTHING;

-- ─── Tipos de Actividad (sd_core.cat_tipos_actividad) ─────────────────────────
INSERT INTO sd_core.cat_tipos_actividad (codigo, nombre, puntos_score) VALUES
('ACT-CALL',    'Llamada de Venta',      5),
('ACT-MEET',    'Reunión / Discovery',   10),
('ACT-PROP',    'Presentación Propuesta',15),
('ACT-WAPP',    'WhatsApp Seguimiento',  2),
('ACT-DEMO',    'Demo de Producto',      20)
ON CONFLICT (codigo) DO NOTHING;

-- ─── Re-habilitar triggers ───
SET session_replication_role = 'origin';

-- Verificación final
DO $$
DECLARE
    u_count INT;
BEGIN
    SELECT COUNT(*) INTO u_count FROM sd_core.usuarios;
    RAISE NOTICE '✅ Seed completado.';
    RAISE NOTICE '👤 Usuarios: %', u_count;
    RAISE NOTICE '🚀 CRM Listo para operar.';
END$$;
