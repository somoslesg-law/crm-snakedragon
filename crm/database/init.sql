-- ═══════════════════════════════════════════════════════════════
-- SNAKE DRAGON CRM — UNIFIED DATABASE INITIALIZATION SCRIPT
-- Ejecuta los 3 esquemas (V1 → V2 → V3) + datos semilla
-- 
-- USO:
--   psql -U sd_admin -d snake_dragon -f database/init.sql
--
-- REQUISITOS:
--   - PostgreSQL 16+
--   - Base de datos 'snake_dragon' creada previamente
--   - Ejecutar desde la raíz del proyecto (/var/www/snake-dragon)
--
-- ⚠️  EJECUTAR UNA SOLA VEZ en una base de datos vacía
-- ═══════════════════════════════════════════════════════════════

\echo '══════════════════════════════════════════════════'
\echo '  🐉 SNAKE DRAGON CRM — Inicialización de BD'
\echo '══════════════════════════════════════════════════'

-- ─── PASO 1: Esquema base V1 (Core, Comercial, Financiero) ──────────────────
\echo ''
\echo '📦 [1/4] Cargando esquema V1 (estructuras base)...'
\i snake_dragon_crm_v1.sql
\echo '✅ V1 completado.'

-- ─── PASO 2: Expansión V2 (Event Stream, IA, Feature Store) ─────────────────
\echo ''
\echo '📦 [2/4] Cargando esquema V2 (Revenue Intelligence)...'
\i snake_dragon_crm_v2.sql
\echo '✅ V2 completado.'

-- ─── PASO 3: Expansión V3 (Copiloto, Auditoría, Seguridad) ─────────────────
\echo ''
\echo '📦 [3/4] Cargando esquema V3 (Enterprise & Copilot)...'
\i snake_dragon_crm_v3.sql
\echo '✅ V3 completado.'

-- ─── PASO 4: Datos iniciales (Admin, Catálogos, Pipeline) ───────────────────
\echo ''
\echo '📦 [4/4] Cargando datos semilla...'
\i seed.sql
\echo '✅ Seed completado.'

-- ─── Refrescar vistas materializadas ────────────────────────────────────────
\echo ''
\echo '🔄 Refrescando vistas materializadas...'
DO $$
BEGIN
    -- Intentar refrescar cada vista materializada
    BEGIN
        REFRESH MATERIALIZED VIEW sd_analytics.mv_dashboard_ejecutivo;
        RAISE NOTICE '  ✅ mv_dashboard_ejecutivo refrescada';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '  ⚠️  mv_dashboard_ejecutivo: %', SQLERRM;
    END;

    BEGIN
        REFRESH MATERIALIZED VIEW sd_analytics.mv_ranking_comisionistas_mes;
        RAISE NOTICE '  ✅ mv_ranking_comisionistas_mes refrescada';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '  ⚠️  mv_ranking_comisionistas_mes: %', SQLERRM;
    END;

    BEGIN
        REFRESH MATERIALIZED VIEW sd_analytics.mv_health_cartera;
        RAISE NOTICE '  ✅ mv_health_cartera refrescada';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '  ⚠️  mv_health_cartera: %', SQLERRM;
    END;
END $$;

-- ─── Verificación final ─────────────────────────────────────────────────────
\echo ''
\echo '══════════════════════════════════════════════════'
\echo '  🎉 INICIALIZACIÓN COMPLETADA'
\echo '══════════════════════════════════════════════════'
\echo ''
\echo '  📧 Login:    admin@snakedragon.com'
\echo '  🔑 Password: Admin2024!'
\echo '  ⚠️  CAMBIAR CONTRASEÑA EN EL PRIMER LOGIN'
\echo ''
\echo '══════════════════════════════════════════════════'
