-- ═══════════════════════════════════════════════════════════════
-- SNAKE DRAGON CRM V3 — SEED DATA
-- Initial data: admin user, catalog tables, pipeline stages
-- ═══════════════════════════════════════════════════════════════

-- Disable triggers temporarily for seeding
SET session_replication_role = 'replica';

-- ─── Empresa Inicial ─────────────────────────────────────────────────────────
INSERT INTO sd_core.configuracion_empresa (
    nombre_empresa, nit, moneda, zona_horaria, logo_url
) VALUES (
    'Snake Dragon Corp', '900.123.456-7', 'COP', 'America/Bogota', NULL
) ON CONFLICT DO NOTHING;

-- ─── Usuario Administrador ────────────────────────────────────────────────────
-- Contraseña por defecto: Admin2024!
-- IMPORTANTE: Cambiar la contraseña en el primer inicio de sesión
-- Hash generado con bcrypt, salt rounds 12
INSERT INTO sd_core.usuarios (
    id,
    email,
    password_hash,
    nombre,
    apellido,
    rol,
    activo
) VALUES (
    gen_random_uuid(),
    'admin@snakedragon.com',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TZFSTk5.3K7Y7hM2F6q.mE2mHRXu',
    'Comandante',
    'Admin',
    'admin',
    true
) ON CONFLICT (email) DO NOTHING;

-- ─── Etapas del Pipeline ─────────────────────────────────────────────────────
INSERT INTO sd_comercial.etapas_pipeline (nombre, orden, color, probabilidad_cierre) VALUES
('Prospecto',       1, '#6B7280', 10),
('Contactado',      2, '#3B82F6', 20),
('Calificado',      3, '#8B5CF6', 35),
('Propuesta',       4, '#F59E0B', 55),
('Negociación',     5, '#EF4444', 70),
('Ganado',          6, '#10B981', 100),
('Perdido',         7, '#1F2937', 0)
ON CONFLICT DO NOTHING;

-- ─── Fuentes de Leads ─────────────────────────────────────────────────────────
INSERT INTO sd_comercial.fuentes_lead (nombre, descripcion) VALUES
('Web Orgánica',        'Visitas directas al sitio web'),
('Referido',            'Recomendación de cliente existente'),
('LinkedIn',            'Campaña o prospección en LinkedIn'),
('Llamada en Frío',     'Outbound telefónico'),
('Evento/Feria',        'Captación en evento presencial o virtual'),
('Google Ads',          'Campaña pagada en Google'),
('Instagram/Facebook',  'Campaña pagada en redes sociales')
ON CONFLICT DO NOTHING;

-- ─── Categorías de Producto ───────────────────────────────────────────────────
INSERT INTO sd_comercial.categorias_producto (nombre, descripcion) VALUES
('Consultoría',     'Servicios de consultoría estratégica'),
('SaaS',            'Software como servicio'),
('Implementación',  'Proyectos de implementación'),
('Soporte',         'Contratos de soporte y mantenimiento'),
('Capacitación',    'Programas de formación y entrenamiento')
ON CONFLICT DO NOTHING;

-- ─── Estado de sesiones ──────────────────────────────────────────────────────
-- Ensure sesiones table exists for auth logging
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'sd_core' AND table_name = 'sesiones'
    ) THEN
        CREATE TABLE sd_core.sesiones (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            usuario_id UUID NOT NULL,
            ip INET,
            user_agent TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
END$$;

-- Re-enable triggers
SET session_replication_role = 'origin';

-- Verification
DO $$
DECLARE
    user_count INT;
BEGIN
    SELECT COUNT(*) INTO user_count FROM sd_core.usuarios;
    RAISE NOTICE '✅ Seed completado. Usuarios creados: %', user_count;
    RAISE NOTICE '📧 Login: admin@snakedragon.com';
    RAISE NOTICE '🔑 Password: Admin2024!';
    RAISE NOTICE '⚠️  IMPORTANTE: Cambiar contraseña en el primer login';
END$$;
