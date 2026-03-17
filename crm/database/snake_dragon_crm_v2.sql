-- ================================================================
--  ███████╗███╗   ██╗ █████╗ ██╗  ██╗███████╗
--  ██╔════╝████╗  ██║██╔══██╗██║ ██╔╝██╔════╝
--  ███████╗██╔██╗ ██║███████║█████╔╝ █████╗
--  ╚════██║██║╚██╗██║██╔══██║██╔═██╗ ██╔══╝
--  ███████║██║ ╚████║██║  ██║██║  ██╗███████╗
--  ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
--  ██████╗ ██████╗  █████╗  ██████╗  ██████╗ ███╗   ██╗
--  ██╔══██╗██╔══██╗██╔══██╗██╔════╝ ██╔═══██╗████╗  ██║
--  ██║  ██║██████╔╝███████║██║  ███╗██║   ██║██╔██╗ ██║
--  ██║  ██║██╔══██╗██╔══██║██║   ██║██║   ██║██║╚██╗██║
--  ██████╔╝██║  ██║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║
--  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝
--
--  CRM ENTERPRISE v2.0 — Revenue Intelligence System
--  Migración sobre v1.0  |  PostgreSQL 16+
--
--  ┌─────────────────────────────────────────────────────┐
--  │  RESUELVE AUDITORÍA (10 problemas críticos):        │
--  │  P01 ✅ Event Stream particionado                   │
--  │  P02 ✅ Lead interactions dedicada                  │
--  │  P03 ✅ Historial de scoring                        │
--  │  P04 ✅ Feature Store para IA                       │
--  │  P05 ✅ Predicciones de ventas y churn              │
--  │  P06 ✅ Email/Propuesta/Call tracking               │
--  │  P07 ✅ Particionamiento temporal                   │
--  │  P08 ✅ Lookup tables (reemplazo de ENUMs frágiles) │
--  │  P09 ✅ Motor de recomendaciones IA                 │
--  │  P10 ✅ Workflow / automation logs                  │
--  ├─────────────────────────────────────────────────────┤
--  │  MEJORAS ADICIONALES:                               │
--  │  ➕ Motor de detección de fraude en comisiones      │
--  │  ➕ Inteligencia competitiva                        │
--  │  ➕ Revenue recognition (IFRS 15 ready)             │
--  │  ➕ Customer journey mapping                        │
--  │  ➕ Programa de referidos                           │
--  │  ➕ Playbooks de customer success                   │
--  │  ➕ Cola de renovaciones de contratos               │
--  │  ➕ Product usage events (SaaS-ready)               │
--  │  ➕ Cash flow forecast semanal                      │
--  │  ➕ Data quality scoring                            │
--  │  ➕ Snapshots diarios y KPIs mensuales              │
--  │  ➕ 15 vistas analíticas + 3 vistas materializadas  │
--  │  ➕ 35 workflows n8n registrados y documentados     │
--  │  ➕ 8 jobs programados                              │
--  │  ➕ 6 reglas de detección de fraude                 │
--  │  ➕ Triggers automáticos en pipeline y pagos        │
--  ├─────────────────────────────────────────────────────┤
--  │  ESTADÍSTICAS:                                      │
--  │  • 5 schemas nuevos (sd_events, sd_ai,             │
--  │    sd_automation, sd_producto, sd_inteligencia)     │
--  │  • 50+ tablas nuevas                                │
--  │  • 2 funciones IA principales                       │
--  │  • 8 triggers automáticos                           │
--  │  • 15 vistas analíticas                             │
--  │  • 3 vistas materializadas                          │
--  │  • 40+ índices optimizados                          │
--  ├─────────────────────────────────────────────────────┤
--  │  INSTRUCCIONES DE EJECUCIÓN:                        │
--  │  1. Ejecutar primero: snake_dragon_crm_v1.sql       │
--  │  2. Luego ejecutar:  snake_dragon_crm_v2.sql        │
--  │  psql -d snake_dragon_crm \                         │
--  │    -f snake_dragon_crm_v1.sql \                     │
--  │    -f snake_dragon_crm_v2.sql                       │
--  │                                                     │
--  │  REFRESCAR VISTAS MATERIALIZADAS:                   │
--  │  REFRESH MATERIALIZED VIEW sd_analytics.mv_dashboard_ejecutivo;   │
--  │  REFRESH MATERIALIZED VIEW sd_analytics.mv_ranking_comisionistas_mes; │
--  │  REFRESH MATERIALIZED VIEW sd_analytics.mv_health_cartera;        │
--  └─────────────────────────────────────────────────────┘
--
--  Versión:    2.0
--  Creado:     2026-03-08
--  Compatible: PostgreSQL 16+
-- ================================================================
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 1: Schemas + Lookups + ENUMs nuevos
-- ================================================================
BEGIN;

-- Nuevos schemas
CREATE SCHEMA IF NOT EXISTS sd_events;
CREATE SCHEMA IF NOT EXISTS sd_ai;
CREATE SCHEMA IF NOT EXISTS sd_automation;
CREATE SCHEMA IF NOT EXISTS sd_producto;
CREATE SCHEMA IF NOT EXISTS sd_inteligencia;

-- ----------------------------------------------------------------
-- LOOKUP TABLES (reemplazan ENUMs frágiles — auditoría P08)
-- ----------------------------------------------------------------
CREATE TABLE sd_core.cat_industrias (
    codigo          VARCHAR(50) PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    sector_padre    VARCHAR(50),
    es_objetivo_icp BOOLEAN DEFAULT FALSE,
    score_icp       INTEGER DEFAULT 5,       -- 1-10, qué tan buen cliente es esta industria
    activa          BOOLEAN DEFAULT TRUE,
    orden           INTEGER DEFAULT 0
);

CREATE TABLE sd_core.cat_origenes_lead (
    codigo          VARCHAR(60) PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL,
    categoria       VARCHAR(50),             -- organico, pagado, referido, outbound, evento
    es_digital      BOOLEAN DEFAULT TRUE,
    costo_estimado_cop DECIMAL(10,2) DEFAULT 0,
    activo          BOOLEAN DEFAULT TRUE
);

CREATE TABLE sd_core.cat_razones_perdida (
    codigo          VARCHAR(60) PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL,
    categoria       VARCHAR(50),             -- precio, competencia, timing, fit, interno
    requiere_detalle BOOLEAN DEFAULT FALSE,
    activa          BOOLEAN DEFAULT TRUE
);

CREATE TABLE sd_core.cat_tipos_actividad (
    codigo                  VARCHAR(60) PRIMARY KEY,
    nombre                  VARCHAR(120) NOT NULL,
    cuenta_como_interaccion BOOLEAN DEFAULT TRUE,
    afecta_score            BOOLEAN DEFAULT TRUE,
    puntos_score            INTEGER DEFAULT 0,
    activo                  BOOLEAN DEFAULT TRUE
);

CREATE TABLE sd_core.cat_segmentos_icp (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          VARCHAR(100) NOT NULL,
    descripcion     TEXT,
    industrias      JSONB DEFAULT '[]',
    tamano_min      INTEGER,
    tamano_max      INTEGER,
    valor_min_cop   DECIMAL(12,2),
    score_industria INTEGER DEFAULT 5,
    activo          BOOLEAN DEFAULT TRUE
);

-- Nuevos ENUMs necesarios
CREATE TYPE sd_events.event_category AS ENUM (
    'comercial', 'financiero', 'producto', 'soporte',
    'comision', 'sistema', 'seguridad', 'marketing'
);

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 2: Event Stream (auditoría P01, P06, P07)
-- ================================================================
BEGIN;

-- Tabla central particionada por mes
CREATE TABLE sd_events.event_stream (
    event_id        UUID            NOT NULL DEFAULT uuid_generate_v4(),
    event_type      VARCHAR(100)    NOT NULL,
    event_category  VARCHAR(50)     NOT NULL,
    event_subtype   VARCHAR(100),
    entity_type     VARCHAR(50)     NOT NULL,
    entity_id       UUID            NOT NULL,
    entity_codigo   VARCHAR(30),
    actor_type      VARCHAR(30)     DEFAULT 'sistema',
    actor_id        UUID,
    actor_nombre    VARCHAR(255),
    event_data      JSONB           NOT NULL DEFAULT '{}',
    session_id      VARCHAR(255),
    ip_address      INET,
    source          VARCHAR(50)     DEFAULT 'crm',
    parent_event_id UUID,
    correlation_id  VARCHAR(255),
    procesado_scoring   BOOLEAN DEFAULT FALSE,
    procesado_features  BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (event_id, created_at)
) PARTITION BY RANGE (created_at);

-- Particiones 2025-2026
DO $$
DECLARE
    y INTEGER; m INTEGER;
    d1 TEXT; d2 TEXT; tname TEXT;
BEGIN
    FOR y IN 2025..2026 LOOP
        FOR m IN 1..12 LOOP
            tname := format('sd_events.event_stream_%s_%02s', y, m);
            d1 := format('%s-%02s-01', y, m);
            d2 := CASE WHEN m = 12 THEN format('%s-01-01', y+1)
                        ELSE format('%s-%02s-01', y, m+1) END;
            EXECUTE format(
                'CREATE TABLE %s PARTITION OF sd_events.event_stream FOR VALUES FROM (%L) TO (%L)',
                tname, d1, d2
            );
        END LOOP;
    END LOOP;
END $$;

-- Catálogo de tipos de evento
CREATE TABLE sd_events.event_types (
    codigo                  VARCHAR(100) PRIMARY KEY,
    nombre_legible          VARCHAR(200) NOT NULL,
    categoria               VARCHAR(50)  NOT NULL,
    descripcion             TEXT,
    afecta_lead_score       BOOLEAN DEFAULT FALSE,
    puntos_score            INTEGER DEFAULT 0,
    afecta_health_score     BOOLEAN DEFAULT FALSE,
    genera_notificacion     BOOLEAN DEFAULT FALSE,
    activo                  BOOLEAN DEFAULT TRUE
);

-- Índices en particiones (se heredan automáticamente)
CREATE INDEX idx_ev_entity   ON sd_events.event_stream(entity_type, entity_id);
CREATE INDEX idx_ev_type     ON sd_events.event_stream(event_type);
CREATE INDEX idx_ev_created  ON sd_events.event_stream(created_at DESC);
CREATE INDEX idx_ev_actor    ON sd_events.event_stream(actor_id) WHERE actor_id IS NOT NULL;
CREATE INDEX idx_ev_corr     ON sd_events.event_stream(correlation_id) WHERE correlation_id IS NOT NULL;
CREATE INDEX idx_ev_noprocess ON sd_events.event_stream(procesado_scoring) WHERE procesado_scoring = FALSE;

-- Función para emitir eventos desde cualquier trigger/función
CREATE OR REPLACE FUNCTION sd_events.emit(
    p_type      VARCHAR(100),
    p_category  VARCHAR(50),
    p_etype     VARCHAR(50),
    p_eid       UUID,
    p_actor_id  UUID    DEFAULT NULL,
    p_data      JSONB   DEFAULT '{}',
    p_source    VARCHAR DEFAULT 'crm_trigger',
    p_corr      VARCHAR DEFAULT NULL
) RETURNS UUID AS $$
DECLARE v_id UUID := uuid_generate_v4();
BEGIN
    INSERT INTO sd_events.event_stream(
        event_id, event_type, event_category,
        entity_type, entity_id, actor_id,
        event_data, source, correlation_id
    ) VALUES (
        v_id, p_type, p_category,
        p_etype, p_eid, p_actor_id,
        p_data, p_source, p_corr
    );
    RETURN v_id;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'sd_events.emit error: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Datos iniciales: catálogo de eventos
INSERT INTO sd_events.event_types (codigo, nombre_legible, categoria, afecta_lead_score, puntos_score, genera_notificacion) VALUES
('lead_created',            'Lead creado',                          'comercial', true,  5,  true),
('lead_assigned',           'Lead asignado a comisionista',         'comercial', false, 0,  true),
('lead_qualified',          'Lead calificado',                      'comercial', true,  10, true),
('call_made',               'Llamada realizada',                    'comercial', true,  3,  false),
('call_answered',           'Llamada contestada',                   'comercial', true,  5,  false),
('email_sent',              'Email enviado',                        'comercial', true,  2,  false),
('email_opened',            'Email abierto por cliente',            'comercial', true,  4,  false),
('email_clicked',           'Click en enlace del email',            'comercial', true,  6,  false),
('meeting_scheduled',       'Reunión agendada',                     'comercial', true,  8,  true),
('meeting_completed',       'Reunión completada',                   'comercial', true,  10, false),
('proposal_sent',           'Propuesta enviada',                    'comercial', true,  5,  true),
('proposal_viewed',         'Propuesta vista por el cliente',       'comercial', true,  12, true),
('proposal_downloaded',     'Propuesta descargada',                 'comercial', true,  15, true),
('whatsapp_sent',           'WhatsApp enviado',                     'comercial', true,  2,  false),
('whatsapp_replied',        'Cliente respondió WhatsApp',           'comercial', true,  8,  true),
('contract_sent',           'Contrato enviado para firma',          'comercial', true,  10, true),
('contract_signed',         'Contrato firmado',                     'comercial', false, 0,  true),
('opportunity_won',         'Oportunidad ganada',                   'comercial', false, 0,  true),
('opportunity_lost',        'Oportunidad perdida',                  'comercial', false, 0,  true),
('invoice_created',         'Factura creada',                       'financiero',false, 0,  false),
('invoice_sent',            'Factura enviada al cliente',           'financiero',false, 0,  false),
('payment_received',        'Pago recibido',                        'financiero',false, 0,  true),
('payment_overdue',         'Factura vencida sin pagar',            'financiero',false, 0,  true),
('commission_generated',    'Comisión generada',                    'comision',  false, 0,  true),
('commission_approved',     'Comisión aprobada',                    'comision',  false, 0,  true),
('commission_paid',         'Comisión pagada al comisionista',      'comision',  false, 0,  true),
('commission_fraud_alert',  'Alerta de fraude en comisión',         'seguridad', false, 0,  true),
('project_started',         'Proyecto iniciado',                    'comercial', false, 0,  true),
('project_completed',       'Proyecto completado',                  'comercial', false, 0,  true),
('ticket_opened',           'Ticket de soporte abierto',            'soporte',   false, 0,  false),
('ticket_resolved',         'Ticket resuelto',                      'soporte',   false, 0,  false),
('churn_risk_detected',     'Riesgo de churn detectado',            'comercial', false, 0,  true),
('upsell_opportunity',      'Oportunidad de upsell detectada',      'comercial', false, 0,  true),
('nps_response',            'Cliente respondió NPS',                'soporte',   false, 0,  false),
('usage_spike',             'Spike de uso del producto detectado',  'producto',  false, 0,  false),
('usage_drop',              'Caída de uso del producto detectada',  'producto',  false, 0,  true),
('renewal_due',             'Contrato próximo a vencer',            'comercial', false, 0,  true),
('lead_score_change',       'Score del lead cambió significativamente','comercial',false,0,  false),
('fraud_pattern_detected',  'Patrón de fraude detectado',           'seguridad', false, 0,  true);

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 3: Interacciones + Email/Call/Meeting Tracking
--  Resuelve auditoría P02, P06
-- ================================================================
BEGIN;

-- Tabla dedicada de interacciones con leads/clientes
CREATE TABLE sd_comercial.lead_interactions (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id                 UUID REFERENCES sd_comercial.leads(id),
    oportunidad_id          UUID REFERENCES sd_comercial.oportunidades(id),
    cliente_id              UUID REFERENCES sd_clientes.clientes(id),
    contacto_id             UUID REFERENCES sd_clientes.contactos(id),
    comisionista_id         UUID REFERENCES sd_comisiones.comisionistas(id),
    realizada_por           UUID REFERENCES sd_core.usuarios(id),
    -- Clasificación
    tipo                    VARCHAR(60) NOT NULL,   -- call, email, whatsapp, meeting, demo, propuesta_review
    canal                   VARCHAR(50),
    direccion               VARCHAR(20) DEFAULT 'saliente',
    -- Contenido
    resumen                 TEXT,
    transcript_completo     TEXT,
    grabacion_url           VARCHAR(500),
    -- Análisis IA de la interacción
    sentimiento_detectado   VARCHAR(20),            -- positivo, neutro, negativo
    tono_cliente            VARCHAR(50),            -- interesado, dudoso, resistente, entusiasta
    interes_estimado_pct    INTEGER CHECK (interes_estimado_pct BETWEEN 0 AND 100),
    objeciones_detectadas   JSONB DEFAULT '[]',
    compromisos_cliente     JSONB DEFAULT '[]',
    compromisos_vendedor    JSONB DEFAULT '[]',
    temas_clave             JSONB DEFAULT '[]',
    keywords_ia             JSONB DEFAULT '[]',
    proxima_accion          TEXT,
    fecha_proxima_accion    DATE,
    -- Duración
    duracion_minutos        INTEGER,
    hora_inicio             TIMESTAMPTZ,
    hora_fin                TIMESTAMPTZ,
    -- Resultado
    resultado               VARCHAR(50),
    score_impacto           INTEGER DEFAULT 0,      -- impacto en lead score (-10 a +10)
    -- Participantes
    participantes_internos  JSONB DEFAULT '[]',
    participantes_externos  JSONB DEFAULT '[]',
    adjuntos                JSONB DEFAULT '[]',
    -- Auditoría
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- Tracking detallado de propuestas (apertura, tiempo de lectura)
CREATE TABLE sd_comercial.propuesta_tracking (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id) ON DELETE CASCADE,
    evento              VARCHAR(30) NOT NULL,  -- enviada, abierta, descargada, reenviada, expirada
    ip_origen           INET,
    ciudad_origen       VARCHAR(100),
    pais_origen         VARCHAR(50),
    dispositivo         VARCHAR(50),
    navegador           VARCHAR(50),
    tiempo_lectura_seg  INTEGER,
    porcentaje_leido    DECIMAL(5,2),
    secciones_vistas    JSONB DEFAULT '[]',
    url_propuesta       VARCHAR(500),
    version_propuesta   INTEGER DEFAULT 1,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Email events (tracking de emails enviados)
CREATE TABLE sd_marketing.email_events (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id),
    contacto_id         UUID REFERENCES sd_clientes.contactos(id),
    campana_id          UUID REFERENCES sd_marketing.campanas(id),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    -- Evento
    tipo_evento         VARCHAR(30) NOT NULL,  -- enviado, entregado, abierto, click, rebotado, spam, desuscripcion
    subject             VARCHAR(500),
    email_destino       VARCHAR(255),
    template_usado      VARCHAR(100),
    -- Tracking
    ip_apertura         INET,
    ciudad_apertura     VARCHAR(100),
    dispositivo         VARCHAR(50),
    link_clicked        VARCHAR(500),
    tiempo_lectura_seg  INTEGER,
    -- IDs externos
    message_id          VARCHAR(255),
    provider_id         VARCHAR(255),
    provider            VARCHAR(50),  -- sendgrid, postmark, mailersend
    -- Auditoría
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Log de llamadas (call intelligence)
CREATE TABLE sd_comercial.call_logs (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id),
    contacto_id         UUID REFERENCES sd_clientes.contactos(id),
    interaction_id      UUID REFERENCES sd_comercial.lead_interactions(id),
    realizada_por       UUID REFERENCES sd_core.usuarios(id),
    comisionista_id     UUID REFERENCES sd_comisiones.comisionistas(id),
    -- Métricas
    numero_origen       VARCHAR(30),
    numero_destino      VARCHAR(30),
    duracion_segundos   INTEGER,
    contestada          BOOLEAN DEFAULT FALSE,
    fue_voicemail       BOOLEAN DEFAULT FALSE,
    -- Grabación e IA
    grabacion_url       VARCHAR(500),
    transcript_texto    TEXT,
    score_conversacion  INTEGER CHECK (score_conversacion BETWEEN 0 AND 100),
    proximo_paso_ia     TEXT,
    sentiment_ia        VARCHAR(20),
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Log de reuniones
CREATE TABLE sd_comercial.meeting_logs (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id                 UUID REFERENCES sd_comercial.leads(id),
    oportunidad_id          UUID REFERENCES sd_comercial.oportunidades(id),
    cliente_id              UUID REFERENCES sd_clientes.clientes(id),
    organizador_id          UUID REFERENCES sd_core.usuarios(id),
    comisionista_id         UUID REFERENCES sd_comisiones.comisionistas(id),
    tipo                    VARCHAR(50),  -- discovery, demo, propuesta, negociacion, kickoff
    modalidad               VARCHAR(20),  -- virtual, presencial
    plataforma              VARCHAR(50),
    link_reunion            VARCHAR(500),
    agenda_previa           TEXT,
    acta_reunion            TEXT,
    acuerdos                JSONB DEFAULT '[]',
    pendientes              JSONB DEFAULT '[]',
    fecha_inicio            TIMESTAMPTZ NOT NULL,
    fecha_fin               TIMESTAMPTZ,
    duracion_minutos        INTEGER,
    puntualidad_cliente     VARCHAR(20),  -- a_tiempo, tarde_5, tarde_15, no_asistio
    participantes_internos  JSONB DEFAULT '[]',
    participantes_clientes  JSONB DEFAULT '[]',
    resultado               VARCHAR(50),
    nps_reunion             INTEGER CHECK (nps_reunion BETWEEN 1 AND 5),
    proxima_accion          TEXT,
    fecha_proxima_accion    DATE,
    resumen_ia              TEXT,
    temas_ia                JSONB DEFAULT '[]',
    grabacion_url           VARCHAR(500),
    presentacion_url        VARCHAR(500),
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID REFERENCES sd_core.usuarios(id)
);

-- Índices para rendimiento
CREATE INDEX idx_lint_lead       ON sd_comercial.lead_interactions(lead_id);
CREATE INDEX idx_lint_opp        ON sd_comercial.lead_interactions(oportunidad_id);
CREATE INDEX idx_lint_tipo       ON sd_comercial.lead_interactions(tipo);
CREATE INDEX idx_lint_created    ON sd_comercial.lead_interactions(created_at DESC);
CREATE INDEX idx_prop_opp        ON sd_comercial.propuesta_tracking(oportunidad_id);
CREATE INDEX idx_prop_evento     ON sd_comercial.propuesta_tracking(evento);
CREATE INDEX idx_email_lead      ON sd_marketing.email_events(lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX idx_email_tipo      ON sd_marketing.email_events(tipo_evento);
CREATE INDEX idx_email_created   ON sd_marketing.email_events(created_at DESC);
CREATE INDEX idx_call_lead       ON sd_comercial.call_logs(lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX idx_meeting_lead    ON sd_comercial.meeting_logs(lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX idx_meeting_fecha   ON sd_comercial.meeting_logs(fecha_inicio DESC);

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 4: Feature Store + Scoring Histórico
--  Resuelve auditoría P03, P04
-- ================================================================
BEGIN;

-- Historial completo del lead score (P03)
CREATE TABLE sd_analytics.lead_score_history (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id         UUID NOT NULL REFERENCES sd_comercial.leads(id) ON DELETE CASCADE,
    oportunidad_id  UUID REFERENCES sd_comercial.oportunidades(id),
    score_total     INTEGER NOT NULL,
    score_fit       INTEGER DEFAULT 0,
    score_intent    INTEGER DEFAULT 0,
    score_engagement INTEGER DEFAULT 0,
    score_budget    INTEGER DEFAULT 0,
    score_authority INTEGER DEFAULT 0,
    score_ia        INTEGER DEFAULT 0,
    razon_cambio    VARCHAR(200),
    evento_trigger  VARCHAR(100),
    delta_score     INTEGER,
    modelo_version  VARCHAR(20) DEFAULT 'v1',
    calculado_por   VARCHAR(50) DEFAULT 'sistema',
    calculated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Historial del health score de clientes
CREATE TABLE sd_analytics.customer_health_history (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id      UUID NOT NULL REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    health_score    INTEGER NOT NULL CHECK (health_score BETWEEN 0 AND 100),
    score_engagement INTEGER DEFAULT 0,
    score_pago      INTEGER DEFAULT 0,
    score_uso       INTEGER DEFAULT 0,
    score_soporte   INTEGER DEFAULT 0,
    score_expansion INTEGER DEFAULT 0,
    nivel_riesgo    VARCHAR(20),
    factores_positivos JSONB DEFAULT '[]',
    factores_negativos JSONB DEFAULT '[]',
    modelo_version  VARCHAR(20) DEFAULT 'v1',
    calculated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Feature Store genérico EAV (P04)
CREATE TABLE sd_analytics.feature_store (
    id              BIGSERIAL PRIMARY KEY,
    entity_type     VARCHAR(50) NOT NULL,
    entity_id       UUID NOT NULL,
    feature_name    VARCHAR(100) NOT NULL,
    feature_value   DECIMAL(20,6),
    feature_text    VARCHAR(500),
    feature_json    JSONB,
    feature_group   VARCHAR(50),
    model_version   VARCHAR(20) DEFAULT 'v1',
    computed_at     TIMESTAMPTZ DEFAULT NOW(),
    expires_at      TIMESTAMPTZ,
    UNIQUE (entity_type, entity_id, feature_name, model_version)
);

-- Features de leads (tabla dedicada para performance ML)
CREATE TABLE sd_analytics.lead_features (
    lead_id                         UUID PRIMARY KEY REFERENCES sd_comercial.leads(id) ON DELETE CASCADE,
    -- Identidad y empresa
    tamano_empresa_score            INTEGER DEFAULT 0,
    industria_score                 INTEGER DEFAULT 0,
    cargo_decisor_score             INTEGER DEFAULT 0,
    -- Comportamiento cuantitativo
    num_interacciones               INTEGER DEFAULT 0,
    num_emails_abiertos             INTEGER DEFAULT 0,
    num_emails_clicks               INTEGER DEFAULT 0,
    num_visitas_web                 INTEGER DEFAULT 0,
    num_propuestas_vistas           INTEGER DEFAULT 0,
    tiempo_lectura_propuesta_seg    INTEGER DEFAULT 0,
    num_reuniones                   INTEGER DEFAULT 0,
    num_llamadas                    INTEGER DEFAULT 0,
    num_whatsapps_respondidos       INTEGER DEFAULT 0,
    dias_ultima_interaccion         INTEGER,
    -- Timing
    dias_en_pipeline                INTEGER DEFAULT 0,
    hora_registro                   INTEGER,
    dia_semana_registro             INTEGER,
    -- Señales de intención (booleanos)
    pregunto_precio                 BOOLEAN DEFAULT FALSE,
    pidio_demo                      BOOLEAN DEFAULT FALSE,
    pidio_contrato                  BOOLEAN DEFAULT FALSE,
    menciono_competidor             BOOLEAN DEFAULT FALSE,
    presupuesto_declarado           BOOLEAN DEFAULT FALSE,
    timeframe_especifico            BOOLEAN DEFAULT FALSE,
    pidio_referencias               BOOLEAN DEFAULT FALSE,
    -- Contexto
    es_referido                     BOOLEAN DEFAULT FALSE,
    comisionista_win_rate           DECIMAL(5,2),
    velocidad_respuesta_mins        INTEGER,
    -- Scores compuestos
    score_bant                      INTEGER DEFAULT 0,
    score_meddic                    INTEGER DEFAULT 0,
    -- Control
    updated_at                      TIMESTAMPTZ DEFAULT NOW()
);

-- Features de clientes (churn + upsell prediction)
CREATE TABLE sd_analytics.customer_features (
    cliente_id                      UUID PRIMARY KEY REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    -- Financieros
    ltv_realizado                   DECIMAL(15,2) DEFAULT 0,
    ltv_proyectado_12m              DECIMAL(15,2) DEFAULT 0,
    mrr_actual                      DECIMAL(12,2) DEFAULT 0,
    avg_ticket                      DECIMAL(12,2) DEFAULT 0,
    total_pagos                     INTEGER DEFAULT 0,
    dias_mora_promedio              DECIMAL(6,1) DEFAULT 0,
    pagos_puntuales_pct             DECIMAL(5,2) DEFAULT 100,
    tasa_descuento_promedio         DECIMAL(5,2) DEFAULT 0,
    -- Engagement
    dias_ultimo_contacto            INTEGER,
    dias_ultimo_pago                INTEGER,
    dias_ultima_actividad           INTEGER,
    num_interacciones_90d           INTEGER DEFAULT 0,
    num_tickets_90d                 INTEGER DEFAULT 0,
    tickets_sin_resolver            INTEGER DEFAULT 0,
    csat_promedio_90d               DECIMAL(3,1),
    nps_actual                      INTEGER,
    -- Uso del servicio
    proyectos_activos               INTEGER DEFAULT 0,
    proyectos_completados           INTEGER DEFAULT 0,
    tasa_completitud_proyectos      DECIMAL(5,2) DEFAULT 0,
    -- Potencial de crecimiento
    contratos_activos               INTEGER DEFAULT 0,
    servicios_contratados           INTEGER DEFAULT 0,
    servicios_disponibles           INTEGER DEFAULT 0,
    potencial_upsell_cop            DECIMAL(12,2) DEFAULT 0,
    -- Indicadores de riesgo churn
    disminucion_uso_pct             DECIMAL(5,2) DEFAULT 0,
    aumento_tickets_pct             DECIMAL(5,2) DEFAULT 0,
    cambio_contacto_principal       BOOLEAN DEFAULT FALSE,
    menciono_competidor             BOOLEAN DEFAULT FALSE,
    solicito_cancelacion            BOOLEAN DEFAULT FALSE,
    -- Control
    updated_at                      TIMESTAMPTZ DEFAULT NOW()
);

-- Features de performance de comisionistas
CREATE TABLE sd_analytics.agent_features (
    comisionista_id                 UUID PRIMARY KEY REFERENCES sd_comisiones.comisionistas(id) ON DELETE CASCADE,
    leads_activos                   INTEGER DEFAULT 0,
    leads_30d                       INTEGER DEFAULT 0,
    leads_atrasados                 INTEGER DEFAULT 0,
    oportunidades_activas           INTEGER DEFAULT 0,
    valor_pipeline_cop              DECIMAL(15,2) DEFAULT 0,
    win_rate_global                 DECIMAL(5,2) DEFAULT 0,
    win_rate_90d                    DECIMAL(5,2) DEFAULT 0,
    avg_ciclo_venta_dias            DECIMAL(6,1),
    avg_ticket_cop                  DECIMAL(12,2) DEFAULT 0,
    tiempo_respuesta_promedio_hrs   DECIMAL(6,1),
    tasa_contacto_leads_pct         DECIMAL(5,2),
    calidad_leads_score             INTEGER DEFAULT 50,
    pct_leads_datos_completos       DECIMAL(5,2),
    -- Alertas de riesgo
    leads_duplicados_30d            INTEGER DEFAULT 0,
    descuentos_excesivos_count      INTEGER DEFAULT 0,
    performance_score               INTEGER DEFAULT 50 CHECK (performance_score BETWEEN 0 AND 100),
    trend                           VARCHAR(20) DEFAULT 'estable',
    updated_at                      TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_lsh_lead     ON sd_analytics.lead_score_history(lead_id);
CREATE INDEX idx_lsh_calc     ON sd_analytics.lead_score_history(calculated_at DESC);
CREATE INDEX idx_chh_cliente  ON sd_analytics.customer_health_history(cliente_id);
CREATE INDEX idx_chh_calc     ON sd_analytics.customer_health_history(calculated_at DESC);
CREATE INDEX idx_fs_entity    ON sd_analytics.feature_store(entity_type, entity_id);
CREATE INDEX idx_fs_feature   ON sd_analytics.feature_store(feature_name);
CREATE INDEX idx_fs_expires   ON sd_analytics.feature_store(expires_at) WHERE expires_at IS NOT NULL;

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 5: Capa de IA
--  Resuelve auditoría P05 + P09
-- ================================================================
BEGIN;

-- Registro de modelos de IA
CREATE TABLE sd_ai.model_registry (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          VARCHAR(100) NOT NULL,
    tipo            VARCHAR(50) NOT NULL,   -- scoring, churn, forecast, recomendacion, fraude
    version         VARCHAR(20) NOT NULL,
    descripcion     TEXT,
    accuracy        DECIMAL(6,4),
    f1_score        DECIMAL(6,4),
    auc_roc         DECIMAL(6,4),
    features        JSONB DEFAULT '[]',
    hiperparametros JSONB DEFAULT '{}',
    activo          BOOLEAN DEFAULT FALSE,
    en_produccion   BOOLEAN DEFAULT FALSE,
    deployed_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Inteligencia calculada por lead (scoring IA en tiempo real)
CREATE TABLE sd_ai.lead_intelligence (
    lead_id                 UUID PRIMARY KEY REFERENCES sd_comercial.leads(id) ON DELETE CASCADE,
    lead_score              INTEGER DEFAULT 0   CHECK (lead_score BETWEEN 0 AND 100),
    intent_score            INTEGER DEFAULT 0   CHECK (intent_score BETWEEN 0 AND 100),
    fit_score               INTEGER DEFAULT 0   CHECK (fit_score BETWEEN 0 AND 100),
    engagement_score        INTEGER DEFAULT 0   CHECK (engagement_score BETWEEN 0 AND 100),
    urgency_score           INTEGER DEFAULT 0   CHECK (urgency_score BETWEEN 0 AND 100),
    prioridad               VARCHAR(20) DEFAULT 'media',  -- critica, alta, media, baja
    prioridad_num           INTEGER DEFAULT 50,
    prob_cierre             DECIMAL(5,2) DEFAULT 0,
    valor_esperado          DECIMAL(12,2) DEFAULT 0,
    fecha_cierre_predicha   DATE,
    accion_recomendada      VARCHAR(100),
    razon_accion            TEXT,
    urgencia_accion         VARCHAR(20),
    deadline_accion         TIMESTAMPTZ,
    modelo_id               UUID REFERENCES sd_ai.model_registry(id),
    confianza               DECIMAL(5,2),
    explicabilidad          JSONB DEFAULT '{}',
    calculado_en            TIMESTAMPTZ DEFAULT NOW(),
    valido_hasta            TIMESTAMPTZ,
    requiere_recalculo      BOOLEAN DEFAULT FALSE
);

-- Cola de priorización (qué leads contactar hoy)
CREATE TABLE sd_ai.lead_priority_queue (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asignado_a          UUID REFERENCES sd_core.usuarios(id),
    comisionista_id     UUID REFERENCES sd_comisiones.comisionistas(id),
    lead_id             UUID REFERENCES sd_comercial.leads(id) ON DELETE CASCADE,
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    posicion            INTEGER NOT NULL,
    score_prioridad     DECIMAL(8,2) NOT NULL,
    accion_sugerida     VARCHAR(100) NOT NULL,
    descripcion_accion  TEXT,
    razon               TEXT,
    valor_en_juego_cop  DECIMAL(12,2),
    prob_exito          DECIMAL(5,2),
    tiempo_sugerido_mins INTEGER DEFAULT 15,
    deadline            TIMESTAMPTZ,
    completada          BOOLEAN DEFAULT FALSE,
    descartada          BOOLEAN DEFAULT FALSE,
    completada_en       TIMESTAMPTZ,
    descartada_razon    TEXT,
    generada_en         TIMESTAMPTZ DEFAULT NOW(),
    valida_hasta        TIMESTAMPTZ
);

-- Predicciones de cierre por oportunidad (P05)
CREATE TABLE sd_ai.sales_predictions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    oportunidad_id      UUID NOT NULL REFERENCES sd_comercial.oportunidades(id) ON DELETE CASCADE,
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    prob_cierre         DECIMAL(5,2) NOT NULL CHECK (prob_cierre BETWEEN 0 AND 100),
    valor_esperado      DECIMAL(12,2),
    fecha_cierre_pred   DATE,
    rango_fecha_min     DATE,
    rango_fecha_max     DATE,
    nivel_riesgo        VARCHAR(20),
    factores_riesgo     JSONB DEFAULT '[]',
    factores_exito      JSONB DEFAULT '[]',
    win_rate_cohorte    DECIMAL(5,2),
    modelo_id           UUID REFERENCES sd_ai.model_registry(id),
    modelo_version      VARCHAR(20),
    confianza           DECIMAL(5,2),
    features_snapshot   JSONB DEFAULT '{}',
    calculado_en        TIMESTAMPTZ DEFAULT NOW(),
    valido_hasta        TIMESTAMPTZ,
    es_prediccion_actual BOOLEAN DEFAULT TRUE
);

-- Forecast de ingresos mensual (P05)
CREATE TABLE sd_ai.revenue_forecasts (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mes                     DATE NOT NULL,
    forecast_conservador    DECIMAL(15,2) NOT NULL,
    forecast_realista       DECIMAL(15,2) NOT NULL,
    forecast_optimista      DECIMAL(15,2) NOT NULL,
    confianza               DECIMAL(5,2),
    ingresos_comprometidos  DECIMAL(15,2) DEFAULT 0,
    ingresos_probabilisticos DECIMAL(15,2) DEFAULT 0,
    ingresos_mrr_proyectado DECIMAL(15,2) DEFAULT 0,
    por_combo               JSONB DEFAULT '{}',
    por_comisionista        JSONB DEFAULT '{}',
    -- Actuals (se completan al cierre del mes)
    ingresos_reales         DECIMAL(15,2),
    error_abs_pct           DECIMAL(5,2),
    modelo_version          VARCHAR(20) DEFAULT 'v1',
    calculado_en            TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (mes, modelo_version)
);

-- Health score + churn prediction de clientes (P05)
CREATE TABLE sd_ai.customer_health (
    cliente_id              UUID PRIMARY KEY REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    health_score            INTEGER NOT NULL DEFAULT 50 CHECK (health_score BETWEEN 0 AND 100),
    score_financiero        INTEGER DEFAULT 50,
    score_engagement        INTEGER DEFAULT 50,
    score_uso               INTEGER DEFAULT 50,
    score_satisfaccion      INTEGER DEFAULT 50,
    score_expansion         INTEGER DEFAULT 50,
    prob_churn_30d          DECIMAL(5,2) DEFAULT 0,
    prob_churn_60d          DECIMAL(5,2) DEFAULT 0,
    prob_churn_90d          DECIMAL(5,2) DEFAULT 0,
    nivel_riesgo_churn      VARCHAR(20) DEFAULT 'bajo',
    prob_upsell             DECIMAL(5,2) DEFAULT 0,
    servicio_upsell_id      UUID REFERENCES sd_servicios.servicios(id),
    valor_upsell_est        DECIMAL(12,2),
    senales_churn           JSONB DEFAULT '[]',
    senales_upsell          JSONB DEFAULT '[]',
    accion_recomendada      VARCHAR(100),
    urgencia                VARCHAR(20) DEFAULT 'baja',
    descripcion_accion      TEXT,
    modelo_id               UUID REFERENCES sd_ai.model_registry(id),
    calculado_en            TIMESTAMPTZ DEFAULT NOW(),
    valido_hasta            TIMESTAMPTZ,
    requiere_recalculo      BOOLEAN DEFAULT FALSE
);

-- Motor de recomendaciones (P09)
CREATE TABLE sd_ai.recommendations (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type         VARCHAR(30) NOT NULL,
    entity_id           UUID NOT NULL,
    para_usuario_id     UUID REFERENCES sd_core.usuarios(id),
    para_comisionista_id UUID REFERENCES sd_comisiones.comisionistas(id),
    -- Clasificación
    tipo                VARCHAR(50) NOT NULL,
    -- follow_up, enviar_propuesta, agendar_reunion, upsell, cross_sell,
    -- riesgo_churn, lead_caliente, descuento, renovacion, lead_abandonado,
    -- fraude_detectado, pago_atrasado, felicitar_cliente
    titulo              VARCHAR(255) NOT NULL,
    descripcion         TEXT NOT NULL,
    accion_sugerida     TEXT,
    url_accion          VARCHAR(500),
    confianza           DECIMAL(5,2),
    impacto_estimado_cop DECIMAL(12,2),
    urgencia            VARCHAR(20) DEFAULT 'normal',
    -- Estado
    estado              VARCHAR(20) DEFAULT 'pendiente',
    vista_en            TIMESTAMPTZ,
    aceptada_en         TIMESTAMPTZ,
    descartada_en       TIMESTAMPTZ,
    razon_descarte      TEXT,
    resultado           TEXT,
    expira_en           TIMESTAMPTZ,
    generada_por        VARCHAR(50) DEFAULT 'sistema',
    modelo_id           UUID REFERENCES sd_ai.model_registry(id),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Performance IA de comisionistas
CREATE TABLE sd_ai.agent_performance_ai (
    comisionista_id         UUID PRIMARY KEY REFERENCES sd_comisiones.comisionistas(id) ON DELETE CASCADE,
    performance_score       INTEGER DEFAULT 50 CHECK (performance_score BETWEEN 0 AND 100),
    tendencia               VARCHAR(20) DEFAULT 'estable',
    ventas_esperadas_30d    DECIMAL(12,2),
    prob_meta_mes_actual    DECIMAL(5,2),
    tier                    VARCHAR(20) DEFAULT 'junior',
    percentil_equipo        INTEGER,
    fortalezas              JSONB DEFAULT '[]',
    areas_mejora            JSONB DEFAULT '[]',
    recomendaciones_coaching JSONB DEFAULT '[]',
    riesgo_fraude_score     INTEGER DEFAULT 0 CHECK (riesgo_fraude_score BETWEEN 0 AND 100),
    alertas_fraude_activas  INTEGER DEFAULT 0,
    calculado_en            TIMESTAMPTZ DEFAULT NOW(),
    modelo_id               UUID REFERENCES sd_ai.model_registry(id)
);

-- Índices IA
CREATE INDEX idx_li_score    ON sd_ai.lead_intelligence(lead_score DESC);
CREATE INDEX idx_li_prior    ON sd_ai.lead_intelligence(prioridad_num DESC);
CREATE INDEX idx_li_recalc   ON sd_ai.lead_intelligence(requiere_recalculo) WHERE requiere_recalculo = TRUE;
CREATE INDEX idx_lpq_asig    ON sd_ai.lead_priority_queue(asignado_a, completada, posicion);
CREATE INDEX idx_lpq_com     ON sd_ai.lead_priority_queue(comisionista_id, completada);
CREATE INDEX idx_sp_opp      ON sd_ai.sales_predictions(oportunidad_id);
CREATE INDEX idx_sp_actual   ON sd_ai.sales_predictions(es_prediccion_actual) WHERE es_prediccion_actual = TRUE;
CREATE INDEX idx_ch_score    ON sd_ai.customer_health(health_score);
CREATE INDEX idx_ch_churn    ON sd_ai.customer_health(nivel_riesgo_churn);
CREATE INDEX idx_ch_recalc   ON sd_ai.customer_health(requiere_recalculo) WHERE requiere_recalculo = TRUE;
CREATE INDEX idx_recs_entity ON sd_ai.recommendations(entity_type, entity_id);
CREATE INDEX idx_recs_estado ON sd_ai.recommendations(estado) WHERE estado = 'pendiente';
CREATE INDEX idx_recs_user   ON sd_ai.recommendations(para_usuario_id) WHERE para_usuario_id IS NOT NULL;
CREATE INDEX idx_recs_com    ON sd_ai.recommendations(para_comisionista_id) WHERE para_comisionista_id IS NOT NULL;

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 6: Automatización + Fraude
--  Resuelve auditoría P10 + mejora propia: detección de fraude
-- ================================================================
BEGIN;

-- Registro de workflows
CREATE TABLE sd_automation.workflow_registry (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo              VARCHAR(50) UNIQUE NOT NULL,
    nombre              VARCHAR(255) NOT NULL,
    descripcion         TEXT,
    categoria           VARCHAR(50),
    trigger_tipo        VARCHAR(50),
    trigger_config      JSONB DEFAULT '{}',
    n8n_workflow_id     VARCHAR(100),
    n8n_url             VARCHAR(500),
    activo              BOOLEAN DEFAULT TRUE,
    version             INTEGER DEFAULT 1,
    timeout_segundos    INTEGER DEFAULT 300,
    reintentos_max      INTEGER DEFAULT 3,
    -- Métricas acumuladas
    total_ejecuciones   INTEGER DEFAULT 0,
    ejecuciones_exitosas INTEGER DEFAULT 0,
    ejecuciones_fallidas INTEGER DEFAULT 0,
    ultima_ejecucion    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Log de ejecuciones (P10)
CREATE TABLE sd_automation.automation_runs (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id         UUID REFERENCES sd_automation.workflow_registry(id),
    n8n_execution_id    VARCHAR(255),
    trigger_event_type  VARCHAR(100),
    trigger_entity_type VARCHAR(50),
    trigger_entity_id   UUID,
    estado              VARCHAR(20) NOT NULL DEFAULT 'ejecutando',
    intento             INTEGER DEFAULT 1,
    input_data          JSONB DEFAULT '{}',
    output_data         JSONB DEFAULT '{}',
    variables_contexto  JSONB DEFAULT '{}',
    iniciado_en         TIMESTAMPTZ DEFAULT NOW(),
    finalizado_en       TIMESTAMPTZ,
    duracion_ms         INTEGER,
    error_mensaje       TEXT,
    error_stack         TEXT,
    error_nodo          VARCHAR(100),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Registro universal de notificaciones enviadas
CREATE TABLE sd_automation.notification_log (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    destinatario_tipo   VARCHAR(30),
    destinatario_id     UUID,
    email_destino       VARCHAR(255),
    whatsapp_destino    VARCHAR(30),
    canal               VARCHAR(30) NOT NULL,
    tipo_notif          VARCHAR(100) NOT NULL,
    asunto              VARCHAR(500),
    cuerpo              TEXT,
    entity_type         VARCHAR(50),
    entity_id           UUID,
    estado              VARCHAR(20) DEFAULT 'enviado',
    error               TEXT,
    abierto             BOOLEAN DEFAULT FALSE,
    abierto_en          TIMESTAMPTZ,
    enviado_en          TIMESTAMPTZ DEFAULT NOW(),
    provider            VARCHAR(50),
    provider_message_id VARCHAR(255)
);

-- Jobs programados
CREATE TABLE sd_automation.scheduled_jobs (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre              VARCHAR(100) UNIQUE NOT NULL,
    descripcion         TEXT,
    cron_expression     VARCHAR(100),
    funcion_sql         TEXT,
    workflow_id         UUID REFERENCES sd_automation.workflow_registry(id),
    activo              BOOLEAN DEFAULT TRUE,
    ultima_ejecucion    TIMESTAMPTZ,
    proxima_ejecucion   TIMESTAMPTZ,
    ultima_duracion_ms  INTEGER,
    ultimo_estado       VARCHAR(20),
    errores_consecutivos INTEGER DEFAULT 0,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------
-- DETECCIÓN DE FRAUDE EN COMISIONES (mejora propia)
-- ----------------------------------------------------------------
CREATE TABLE sd_comisiones.fraud_rules (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          VARCHAR(100) NOT NULL,
    descripcion     TEXT,
    tipo_regla      VARCHAR(60) NOT NULL,
    -- Tipos disponibles:
    -- leads_duplicados: mismo email/telefono de diferentes leads del mismo comisionista
    -- velocidad_anormal: >N leads por hora/día
    -- leads_sin_empresa: % alto de leads sin empresa
    -- conversion_perfecta: comisionista con 100% conversión (sospechoso)
    -- descuento_excesivo: porcentaje de descuento >umbral frecuentemente
    -- auto_referido: lead que se registró a sí mismo
    -- cliente_fantasma: cliente sin actividad post-venta
    condicion_sql   TEXT,
    umbral          DECIMAL(10,2),
    severidad       VARCHAR(20) DEFAULT 'media',
    accion_auto     VARCHAR(50) DEFAULT 'notificar_admin',
    activa          BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sd_comisiones.fraud_alerts (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    regla_id            UUID REFERENCES sd_comisiones.fraud_rules(id),
    comisionista_id     UUID REFERENCES sd_comisiones.comisionistas(id),
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    liquidacion_id      UUID REFERENCES sd_comisiones.liquidaciones(id),
    tipo_alerta         VARCHAR(100) NOT NULL,
    descripcion         TEXT NOT NULL,
    evidencia           JSONB DEFAULT '{}',
    severidad           VARCHAR(20) DEFAULT 'media',
    estado              VARCHAR(30) DEFAULT 'nueva',
    investigado_por     UUID REFERENCES sd_core.usuarios(id),
    fecha_investigacion TIMESTAMPTZ,
    conclusion          TEXT,
    accion_tomada       TEXT,
    monto_en_riesgo_cop DECIMAL(12,2),
    notificacion_enviada BOOLEAN DEFAULT FALSE,
    detected_at         TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------
-- INTELIGENCIA COMPETITIVA (mejora propia)
-- ----------------------------------------------------------------
CREATE TABLE sd_inteligencia.competidores (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre              VARCHAR(255) NOT NULL,
    sitio_web           VARCHAR(255),
    tipo                VARCHAR(50),   -- directo, indirecto, sustituto
    fortalezas          JSONB DEFAULT '[]',
    debilidades         JSONB DEFAULT '[]',
    rango_precios       JSONB DEFAULT '{}',
    servicios_similares JSONB DEFAULT '[]',
    activo              BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sd_inteligencia.competencia_por_oportunidad (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    oportunidad_id      UUID NOT NULL REFERENCES sd_comercial.oportunidades(id) ON DELETE CASCADE,
    competidor_id       UUID REFERENCES sd_inteligencia.competidores(id),
    nombre_competidor   VARCHAR(255),
    esta_en_evaluacion  BOOLEAN DEFAULT TRUE,
    posicion_cliente    VARCHAR(20),   -- preferido, igual, menor, desconocido
    precio_competidor   DECIMAL(12,2),
    descuento_ofrecido  DECIMAL(5,2),
    fortaleza_percibida TEXT,
    debilidad_percibida TEXT,
    gano_competidor     BOOLEAN,
    razon_resultado     TEXT,
    fuente_info         VARCHAR(50),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID REFERENCES sd_core.usuarios(id)
);

-- Elasticidad de precios (mejora propia)
CREATE TABLE sd_inteligencia.elasticidad_precios (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    servicio_id         UUID REFERENCES sd_servicios.servicios(id),
    combo_id            UUID REFERENCES sd_servicios.combos(id),
    precio_ofrecido     DECIMAL(12,2) NOT NULL,
    descuento_pct       DECIMAL(5,2) DEFAULT 0,
    fue_aceptado        BOOLEAN,
    industria           VARCHAR(100),
    tamano_empresa      VARCHAR(50),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Índices automatización y fraude
CREATE INDEX idx_ar_workflow ON sd_automation.automation_runs(workflow_id);
CREATE INDEX idx_ar_entity   ON sd_automation.automation_runs(trigger_entity_type, trigger_entity_id);
CREATE INDEX idx_ar_estado   ON sd_automation.automation_runs(estado);
CREATE INDEX idx_ar_iniciado ON sd_automation.automation_runs(iniciado_en DESC);
CREATE INDEX idx_nlog_dest   ON sd_automation.notification_log(destinatario_id) WHERE destinatario_id IS NOT NULL;
CREATE INDEX idx_nlog_tipo   ON sd_automation.notification_log(tipo_notif);
CREATE INDEX idx_nlog_entity ON sd_automation.notification_log(entity_type, entity_id);
CREATE INDEX idx_fraud_com   ON sd_comisiones.fraud_alerts(comisionista_id);
CREATE INDEX idx_fraud_est   ON sd_comisiones.fraud_alerts(estado) WHERE estado IN ('nueva','en_revision');

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 7: Mejoras propias
--  Customer Success, Renovaciones, Journey Map, Product Usage,
--  Revenue Recognition, Cash Flow, Data Quality, Snapshots
-- ================================================================
BEGIN;

-- ----------------------------------------------------------------
-- CUSTOMER SUCCESS Y RENOVACIONES
-- ----------------------------------------------------------------
CREATE TABLE sd_clientes.success_playbooks (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre              VARCHAR(255) NOT NULL,
    tipo                VARCHAR(50) NOT NULL,  -- onboarding, activacion, renovacion, churn_recovery
    aplica_a_combo_id   UUID REFERENCES sd_servicios.combos(id),
    aplica_a_segmento   VARCHAR(50) DEFAULT 'todos',
    pasos               JSONB NOT NULL DEFAULT '[]',
    duracion_total_dias INTEGER,
    activo              BOOLEAN DEFAULT TRUE,
    version             INTEGER DEFAULT 1,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID REFERENCES sd_core.usuarios(id)
);

CREATE TABLE sd_clientes.customer_playbook_instances (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    playbook_id         UUID REFERENCES sd_clientes.success_playbooks(id),
    proyecto_id         UUID REFERENCES sd_operaciones.proyectos(id),
    estado              VARCHAR(30) DEFAULT 'activo',
    paso_actual         INTEGER DEFAULT 1,
    porcentaje_avance   DECIMAL(5,2) DEFAULT 0,
    fecha_inicio        DATE DEFAULT CURRENT_DATE,
    fecha_fin_estimada  DATE,
    fecha_fin_real      DATE,
    notas               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Cola de renovaciones de contratos
CREATE TABLE sd_clientes.renewal_queue (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contrato_id             UUID NOT NULL REFERENCES sd_contratos.contratos(id) ON DELETE CASCADE,
    cliente_id              UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    fecha_vencimiento       DATE NOT NULL,
    fecha_alerta_60d        DATE,
    fecha_alerta_30d        DATE,
    fecha_alerta_15d        DATE,
    estado                  VARCHAR(30) DEFAULT 'pendiente',
    responsable_id          UUID REFERENCES sd_core.usuarios(id),
    comisionista_id         UUID REFERENCES sd_comisiones.comisionistas(id),
    valor_renovacion_cop    DECIMAL(12,2),
    propuesta_url           VARCHAR(500),
    propuesta_enviada_en    TIMESTAMPTZ,
    renovado                BOOLEAN,
    nuevo_contrato_id       UUID REFERENCES sd_contratos.contratos(id),
    razon_no_renovacion     TEXT,
    ultimo_contacto         TIMESTAMPTZ,
    proxima_accion          TEXT,
    fecha_proxima_accion    DATE,
    alertas_enviadas        INTEGER DEFAULT 0,
    ultima_alerta_enviada   TIMESTAMPTZ,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- Customer Journey Map (trazabilidad del ciclo completo del cliente)
CREATE TABLE sd_clientes.customer_journey_events (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id          UUID NOT NULL REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    etapa               VARCHAR(50) NOT NULL,
    -- awareness, consideration, decision, onboarding, adoption, expansion, advocacy, churn_risk, renewal
    tipo_evento         VARCHAR(100) NOT NULL,
    descripcion         TEXT,
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    contrato_id         UUID REFERENCES sd_contratos.contratos(id),
    proyecto_id         UUID REFERENCES sd_operaciones.proyectos(id),
    ticket_id           UUID REFERENCES sd_soporte.tickets(id),
    sentimiento         VARCHAR(20),
    nps_momento         INTEGER,
    valor_cop           DECIMAL(12,2),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------
-- PROGRAMA DE REFERIDOS
-- ----------------------------------------------------------------
CREATE TABLE sd_marketing.programa_referidos (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre                  VARCHAR(100) NOT NULL,
    descripcion             TEXT,
    tipo_incentivo          VARCHAR(50),
    valor_incentivo         DECIMAL(10,2),
    porcentaje_incentivo    DECIMAL(5,2),
    aplica_a_combo_id       UUID REFERENCES sd_servicios.combos(id),
    min_valor_venta_cop     DECIMAL(12,2),
    activo                  BOOLEAN DEFAULT TRUE,
    vigente_desde           DATE DEFAULT CURRENT_DATE,
    vigente_hasta           DATE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sd_marketing.referidos (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    programa_id                 UUID REFERENCES sd_marketing.programa_referidos(id),
    referidor_tipo              VARCHAR(20) NOT NULL,   -- cliente, comisionista, contacto
    referidor_cliente_id        UUID REFERENCES sd_clientes.clientes(id),
    referidor_comisionista_id   UUID REFERENCES sd_comisiones.comisionistas(id),
    lead_id                     UUID REFERENCES sd_comercial.leads(id),
    cliente_referido_id         UUID REFERENCES sd_clientes.clientes(id),
    estado                      VARCHAR(30) DEFAULT 'pendiente',
    convertido                  BOOLEAN DEFAULT FALSE,
    fecha_conversion            DATE,
    valor_venta_cop             DECIMAL(12,2),
    incentivo_pagado            BOOLEAN DEFAULT FALSE,
    fecha_pago_incentivo        DATE,
    valor_incentivo_cop         DECIMAL(12,2),
    created_at                  TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------
-- PRODUCT USAGE (SaaS-ready)
-- ----------------------------------------------------------------
CREATE TABLE sd_producto.usage_events (
    id              BIGSERIAL,
    cliente_id      UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    proyecto_id     UUID REFERENCES sd_operaciones.proyectos(id),
    contrato_id     UUID REFERENCES sd_contratos.contratos(id),
    evento          VARCHAR(100) NOT NULL,
    modulo          VARCHAR(50),
    feature         VARCHAR(100),
    cantidad        INTEGER DEFAULT 1,
    duracion_ms     INTEGER,
    exito           BOOLEAN DEFAULT TRUE,
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE sd_producto.usage_events_2025 PARTITION OF sd_producto.usage_events FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE sd_producto.usage_events_2026 PARTITION OF sd_producto.usage_events FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE TABLE sd_producto.feature_adoption (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id          UUID NOT NULL REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    contrato_id         UUID REFERENCES sd_contratos.contratos(id),
    modulo              VARCHAR(50) NOT NULL,
    feature             VARCHAR(100) NOT NULL,
    primera_vez         TIMESTAMPTZ,
    ultima_vez          TIMESTAMPTZ,
    veces_usada_7d      INTEGER DEFAULT 0,
    veces_usada_30d     INTEGER DEFAULT 0,
    veces_usada_total   INTEGER DEFAULT 0,
    adoptada            BOOLEAN DEFAULT FALSE,
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (cliente_id, modulo, feature)
);

-- ----------------------------------------------------------------
-- REVENUE RECOGNITION (IFRS 15 ready)
-- ----------------------------------------------------------------
CREATE TABLE sd_financiero.revenue_recognition (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contrato_id             UUID NOT NULL REFERENCES sd_contratos.contratos(id),
    factura_id              UUID REFERENCES sd_financiero.facturas(id),
    mes_reconocimiento      DATE NOT NULL,
    monto_total_contrato    DECIMAL(15,2) NOT NULL,
    monto_reconocido_mes    DECIMAL(15,2) NOT NULL,
    monto_diferido          DECIMAL(15,2) DEFAULT 0,
    metodo                  VARCHAR(30) DEFAULT 'porcentaje_avance',
    porcentaje_avance       DECIMAL(5,2),
    reconocido              BOOLEAN DEFAULT FALSE,
    fecha_reconocimiento    DATE,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID REFERENCES sd_core.usuarios(id)
);

-- Cash flow forecast semanal
CREATE TABLE sd_financiero.cash_flow_forecast (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    semana              DATE NOT NULL UNIQUE,
    cobros_confirmados  DECIMAL(15,2) DEFAULT 0,
    cobros_proyectados  DECIMAL(15,2) DEFAULT 0,
    comisiones_a_pagar  DECIMAL(12,2) DEFAULT 0,
    gastos_fijos        DECIMAL(12,2) DEFAULT 0,
    otros_gastos        DECIMAL(12,2) DEFAULT 0,
    flujo_neto          DECIMAL(15,2) GENERATED ALWAYS AS (
        cobros_confirmados + cobros_proyectados - comisiones_a_pagar - gastos_fijos - otros_gastos
    ) STORED,
    cobros_reales       DECIMAL(15,2),
    gastos_reales       DECIMAL(12,2),
    notas               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------
-- DATA QUALITY SCORING
-- ----------------------------------------------------------------
CREATE TABLE sd_analytics.data_quality_scores (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type         VARCHAR(50) NOT NULL,
    entity_id           UUID NOT NULL,
    quality_score       INTEGER NOT NULL CHECK (quality_score BETWEEN 0 AND 100),
    score_completitud   INTEGER DEFAULT 0,
    score_precision     INTEGER DEFAULT 0,
    score_consistencia  INTEGER DEFAULT 0,
    score_actualidad    INTEGER DEFAULT 0,
    campos_faltantes    JSONB DEFAULT '[]',
    acciones_mejora     JSONB DEFAULT '[]',
    calculated_at       TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (entity_type, entity_id)
);

-- ----------------------------------------------------------------
-- SNAPSHOTS ANALÍTICOS (para tendencias históricas veloces)
-- ----------------------------------------------------------------
CREATE TABLE sd_analytics.pipeline_daily_snapshot (
    id                      BIGSERIAL,
    snapshot_date           DATE NOT NULL DEFAULT CURRENT_DATE,
    total_leads             INTEGER DEFAULT 0,
    leads_nuevos            INTEGER DEFAULT 0,
    leads_calificados       INTEGER DEFAULT 0,
    en_propuesta            INTEGER DEFAULT 0,
    en_negociacion          INTEGER DEFAULT 0,
    ganados_hoy             INTEGER DEFAULT 0,
    perdidos_hoy            INTEGER DEFAULT 0,
    valor_total_pipeline    DECIMAL(15,2) DEFAULT 0,
    valor_ponderado         DECIMAL(15,2) DEFAULT 0,
    valor_ganado_hoy        DECIMAL(15,2) DEFAULT 0,
    comisiones_devengadas   DECIMAL(12,2) DEFAULT 0,
    comisiones_pendientes   DECIMAL(12,2) DEFAULT 0,
    total_clientes_activos  INTEGER DEFAULT 0,
    mrr_total               DECIMAL(12,2) DEFAULT 0,
    clientes_en_riesgo      INTEGER DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (id, snapshot_date)
) PARTITION BY RANGE (snapshot_date);

CREATE TABLE sd_analytics.pipeline_daily_snapshot_2025 PARTITION OF sd_analytics.pipeline_daily_snapshot FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE sd_analytics.pipeline_daily_snapshot_2026 PARTITION OF sd_analytics.pipeline_daily_snapshot FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- KPIs mensuales consolidados
CREATE TABLE sd_analytics.monthly_kpis (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mes                         DATE UNIQUE NOT NULL,
    leads_generados             INTEGER DEFAULT 0,
    leads_calificados           INTEGER DEFAULT 0,
    oportunidades_creadas       INTEGER DEFAULT 0,
    ventas_cerradas             INTEGER DEFAULT 0,
    win_rate_pct                DECIMAL(5,2),
    ingresos_nuevos_cop         DECIMAL(15,2) DEFAULT 0,
    ingresos_recurrentes_cop    DECIMAL(15,2) DEFAULT 0,
    ingresos_totales_cop        DECIMAL(15,2) DEFAULT 0,
    mrr_cop                     DECIMAL(12,2) DEFAULT 0,
    arr_cop                     DECIMAL(15,2) DEFAULT 0,
    comisiones_devengadas_cop   DECIMAL(12,2) DEFAULT 0,
    comisiones_pagadas_cop      DECIMAL(12,2) DEFAULT 0,
    costo_comisiones_pct        DECIMAL(5,2),
    clientes_nuevos             INTEGER DEFAULT 0,
    clientes_churned            INTEGER DEFAULT 0,
    churn_rate_pct              DECIMAL(5,2),
    ltv_promedio_cop            DECIMAL(12,2),
    cac_promedio_cop            DECIMAL(12,2),
    ltv_cac_ratio               DECIMAL(6,2),
    avg_ciclo_venta_dias        DECIMAL(6,1),
    nps_promedio                DECIMAL(4,1),
    csat_promedio               DECIMAL(4,1),
    combo_top_nombre            VARCHAR(100),
    combo_top_ventas            INTEGER,
    forecast_mes_anterior       DECIMAL(15,2),
    error_forecast_pct          DECIMAL(5,2),
    calculado_en                TIMESTAMPTZ DEFAULT NOW()
);

-- Índices de snapshots y mejoras
CREATE INDEX idx_rq_venc    ON sd_clientes.renewal_queue(fecha_vencimiento);
CREATE INDEX idx_rq_estado  ON sd_clientes.renewal_queue(estado);
CREATE INDEX idx_cje_cli    ON sd_clientes.customer_journey_events(cliente_id);
CREATE INDEX idx_cje_etapa  ON sd_clientes.customer_journey_events(etapa);
CREATE INDEX idx_pu_cli     ON sd_producto.usage_events(cliente_id);
CREATE INDEX idx_pu_evento  ON sd_producto.usage_events(evento);
CREATE INDEX idx_pds_date   ON sd_analytics.pipeline_daily_snapshot(snapshot_date DESC);
CREATE INDEX idx_dq_entity  ON sd_analytics.data_quality_scores(entity_type, entity_id);

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 8: Funciones IA + Triggers
-- ================================================================
BEGIN;

-- Función: Recalcular lead score automáticamente
CREATE OR REPLACE FUNCTION sd_ai.recalcular_lead_score(p_lead_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_lead          RECORD;
    v_features      RECORD;
    v_score_fit     INTEGER := 0;
    v_score_intent  INTEGER := 0;
    v_score_engage  INTEGER := 0;
    v_score_budget  INTEGER := 0;
    v_score_auth    INTEGER := 2;
    v_score_total   INTEGER;
    v_delta         INTEGER;
    v_score_ant     INTEGER;
BEGIN
    SELECT * INTO v_lead FROM sd_comercial.leads WHERE id = p_lead_id;
    IF NOT FOUND THEN RETURN 0; END IF;

    SELECT * INTO v_features FROM sd_analytics.lead_features WHERE lead_id = p_lead_id;

    -- FIT (máx 25): datos de empresa, industria
    IF v_lead.empresa_nombre IS NOT NULL  THEN v_score_fit := v_score_fit + 8; END IF;
    IF v_lead.cargo IS NOT NULL           THEN v_score_fit := v_score_fit + 5; END IF;
    IF v_lead.presupuesto_declarado > 0   THEN v_score_fit := v_score_fit + 7; END IF;
    IF v_lead.combo_interesado_id IS NOT NULL THEN v_score_fit := v_score_fit + 5; END IF;
    v_score_fit := LEAST(v_score_fit, 25);

    -- INTENT (máx 30): señales de compra
    IF v_features IS NOT NULL THEN
        v_score_intent :=
            CASE WHEN v_features.pregunto_precio      THEN 10 ELSE 0 END +
            CASE WHEN v_features.pidio_demo           THEN 8  ELSE 0 END +
            CASE WHEN v_features.pidio_contrato       THEN 15 ELSE 0 END +
            CASE WHEN v_features.timeframe_especifico THEN 7  ELSE 0 END +
            CASE WHEN v_features.pidio_referencias    THEN 5  ELSE 0 END;
        v_score_intent := LEAST(v_score_intent, 30);
    END IF;

    -- ENGAGEMENT (máx 25): comportamiento
    IF v_features IS NOT NULL THEN
        v_score_engage :=
            LEAST(v_features.num_interacciones * 2, 8) +
            LEAST(v_features.num_emails_abiertos,     4) +
            CASE WHEN v_features.num_propuestas_vistas > 0                     THEN 5 ELSE 0 END +
            CASE WHEN v_features.tiempo_lectura_propuesta_seg > 120            THEN 4 ELSE 0 END +
            LEAST(v_features.num_reuniones * 3,       6) +
            CASE WHEN COALESCE(v_features.dias_ultima_interaccion, 99) < 3    THEN 5
                 WHEN COALESCE(v_features.dias_ultima_interaccion, 99) < 7    THEN 3
                 WHEN COALESCE(v_features.dias_ultima_interaccion, 99) < 14   THEN 1
                 ELSE 0 END;
        v_score_engage := LEAST(v_score_engage, 25);
    END IF;

    -- BUDGET (máx 10)
    IF v_lead.presupuesto_declarado IS NOT NULL AND v_lead.presupuesto_declarado > 0 THEN
        v_score_budget := 10;
    END IF;

    -- AUTHORITY (máx 10): cargo del contacto
    IF v_lead.cargo IS NOT NULL THEN
        v_score_auth := CASE
            WHEN v_lead.cargo ILIKE ANY(ARRAY['%ceo%','%presidente%','%propietario%','%dueño%']) THEN 10
            WHEN v_lead.cargo ILIKE ANY(ARRAY['%director%','%gerente%','%vp%','%chief%'])        THEN 7
            WHEN v_lead.cargo ILIKE ANY(ARRAY['%coordinador%','%jefe%','%líder%','%lider%'])     THEN 4
            ELSE 2 END;
    END IF;

    v_score_total := LEAST(v_score_fit + v_score_intent + v_score_engage + v_score_budget + v_score_auth, 100);

    -- Obtener score anterior para calcular delta
    SELECT score_total INTO v_score_ant
    FROM sd_analytics.lead_score_history
    WHERE lead_id = p_lead_id
    ORDER BY calculated_at DESC LIMIT 1;

    v_delta := v_score_total - COALESCE(v_score_ant, 0);

    -- Guardar historial
    INSERT INTO sd_analytics.lead_score_history(
        lead_id, score_total, score_fit, score_intent, score_engagement,
        score_budget, score_authority, razon_cambio, delta_score, modelo_version
    ) VALUES (
        p_lead_id, v_score_total, v_score_fit, v_score_intent, v_score_engage,
        v_score_budget, v_score_auth, 'Recálculo automático', v_delta, 'v1'
    );

    -- Actualizar lead
    UPDATE sd_comercial.leads SET
        score_total = v_score_total, score_fit = v_score_fit,
        score_intent = v_score_intent, score_engagement = v_score_engage,
        score_budget = v_score_budget, score_authority = v_score_auth,
        score_calculado_en = NOW()
    WHERE id = p_lead_id;

    -- Upsert lead_intelligence
    INSERT INTO sd_ai.lead_intelligence(
        lead_id, lead_score, intent_score, fit_score, engagement_score,
        prioridad, prioridad_num, calculado_en, valido_hasta, requiere_recalculo
    ) VALUES (
        p_lead_id, v_score_total, v_score_intent, v_score_fit, v_score_engage,
        CASE WHEN v_score_total >= 80 THEN 'critica'
             WHEN v_score_total >= 60 THEN 'alta'
             WHEN v_score_total >= 40 THEN 'media'
             ELSE 'baja' END,
        v_score_total, NOW(), NOW() + INTERVAL '24 hours', FALSE
    )
    ON CONFLICT (lead_id) DO UPDATE SET
        lead_score       = EXCLUDED.lead_score,
        intent_score     = EXCLUDED.intent_score,
        fit_score        = EXCLUDED.fit_score,
        engagement_score = EXCLUDED.engagement_score,
        prioridad        = EXCLUDED.prioridad,
        prioridad_num    = EXCLUDED.prioridad_num,
        calculado_en     = NOW(),
        valido_hasta     = NOW() + INTERVAL '24 hours',
        requiere_recalculo = FALSE;

    -- Emitir evento
    PERFORM sd_events.emit('lead_score_change', 'comercial', 'lead', p_lead_id,
        NULL, jsonb_build_object('score_nuevo', v_score_total, 'score_anterior', v_score_ant, 'delta', v_delta));

    RETURN v_score_total;
END;
$$ LANGUAGE plpgsql;

-- Función: Recalcular customer health score
CREATE OR REPLACE FUNCTION sd_ai.recalcular_customer_health(p_cliente_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_f             RECORD;
    v_sf            INTEGER := 50;
    v_se            INTEGER := 50;
    v_su            INTEGER := 50;
    v_ss            INTEGER := 50;
    v_health        INTEGER;
    v_nivel         VARCHAR(20);
    v_churn30       DECIMAL(5,2);
BEGIN
    SELECT * INTO v_f FROM sd_analytics.customer_features WHERE cliente_id = p_cliente_id;
    IF NOT FOUND THEN RETURN 50; END IF;

    -- Score financiero
    v_sf := 100
        - LEAST(COALESCE(v_f.dias_mora_promedio, 0)::INTEGER * 3, 40)
        + CASE WHEN COALESCE(v_f.pagos_puntuales_pct, 100) >= 95 THEN 10 ELSE 0 END
        - CASE WHEN COALESCE(v_f.pagos_puntuales_pct, 100) < 70  THEN 20 ELSE 0 END;
    v_sf := GREATEST(0, LEAST(100, v_sf));

    -- Score engagement
    v_se := 100;
    IF COALESCE(v_f.dias_ultimo_contacto, 0) > 60  THEN v_se := v_se - 40;
    ELSIF COALESCE(v_f.dias_ultimo_contacto, 0) > 30 THEN v_se := v_se - 20;
    ELSIF COALESCE(v_f.dias_ultimo_contacto, 0) > 14 THEN v_se := v_se - 10;
    END IF;
    IF v_f.cambio_contacto_principal  THEN v_se := v_se - 15; END IF;
    IF v_f.menciono_competidor        THEN v_se := v_se - 20; END IF;
    IF v_f.solicito_cancelacion       THEN v_se := v_se - 40; END IF;
    v_se := GREATEST(0, LEAST(100, v_se));

    -- Score uso
    v_su := CASE
        WHEN COALESCE(v_f.tasa_completitud_proyectos, 0) >= 90 THEN 90
        WHEN COALESCE(v_f.tasa_completitud_proyectos, 0) >= 70 THEN 70
        WHEN COALESCE(v_f.tasa_completitud_proyectos, 0) >= 50 THEN 50
        ELSE 30 END;

    -- Score satisfacción
    IF v_f.csat_promedio_90d IS NOT NULL THEN
        v_ss := (v_f.csat_promedio_90d * 20)::INTEGER;
    END IF;
    IF COALESCE(v_f.tickets_sin_resolver, 0) > 3 THEN v_ss := v_ss - 20; END IF;
    v_ss := GREATEST(0, LEAST(100, v_ss));

    -- Health total ponderado
    v_health := (v_sf * 0.3 + v_se * 0.3 + v_su * 0.2 + v_ss * 0.2)::INTEGER;

    -- Churn probability (regresión logística simplificada)
    v_churn30 := GREATEST(0, LEAST(100,
        100 - v_health
        + CASE WHEN COALESCE(v_f.dias_ultimo_pago, 0) > 90 THEN 15 ELSE 0 END
        + CASE WHEN v_f.solicito_cancelacion THEN 40 ELSE 0 END
    ))::DECIMAL(5,2) / 2;

    -- Nivel de riesgo
    v_nivel := CASE
        WHEN v_health < 30 THEN 'critico'
        WHEN v_health < 50 THEN 'alto'
        WHEN v_health < 70 THEN 'medio'
        ELSE 'bajo' END;

    -- Upsert customer_health
    INSERT INTO sd_ai.customer_health(
        cliente_id, health_score, score_financiero, score_engagement,
        score_uso, score_satisfaccion,
        prob_churn_30d, nivel_riesgo_churn,
        calculado_en, valido_hasta, requiere_recalculo
    ) VALUES (
        p_cliente_id, v_health, v_sf, v_se, v_su, v_ss,
        v_churn30, v_nivel,
        NOW(), NOW() + INTERVAL '48 hours', FALSE
    )
    ON CONFLICT (cliente_id) DO UPDATE SET
        health_score        = EXCLUDED.health_score,
        score_financiero    = EXCLUDED.score_financiero,
        score_engagement    = EXCLUDED.score_engagement,
        score_uso           = EXCLUDED.score_uso,
        score_satisfaccion  = EXCLUDED.score_satisfaccion,
        prob_churn_30d      = EXCLUDED.prob_churn_30d,
        nivel_riesgo_churn  = EXCLUDED.nivel_riesgo_churn,
        calculado_en        = NOW(),
        valido_hasta        = NOW() + INTERVAL '48 hours',
        requiere_recalculo  = FALSE;

    -- Guardar historial
    INSERT INTO sd_analytics.customer_health_history(
        cliente_id, health_score, score_engagement, score_pago, score_uso, score_soporte, nivel_riesgo
    ) VALUES (
        p_cliente_id, v_health, v_se, v_sf, v_su, v_ss, v_nivel
    );

    -- Actualizar campo en clientes
    UPDATE sd_clientes.clientes SET
        probabilidad_churn = v_churn30,
        alerta_churn = (v_nivel IN ('alto','critico'))
    WHERE id = p_cliente_id;

    -- Emitir evento si riesgo alto
    IF v_nivel IN ('alto','critico') THEN
        PERFORM sd_events.emit('churn_risk_detected', 'comercial', 'cliente', p_cliente_id,
            NULL, jsonb_build_object('health_score', v_health, 'nivel_riesgo', v_nivel, 'prob_churn_30d', v_churn30));
    END IF;

    RETURN v_health;
END;
$$ LANGUAGE plpgsql;

-- Función: Tomar snapshot diario del pipeline
CREATE OR REPLACE FUNCTION sd_analytics.tomar_snapshot_diario()
RETURNS VOID AS $$
BEGIN
    INSERT INTO sd_analytics.pipeline_daily_snapshot(
        snapshot_date, total_leads, leads_nuevos, leads_calificados,
        en_propuesta, en_negociacion, ganados_hoy, perdidos_hoy,
        valor_total_pipeline, valor_ponderado, valor_ganado_hoy,
        comisiones_devengadas, comisiones_pendientes,
        total_clientes_activos, mrr_total, clientes_en_riesgo
    )
    SELECT
        CURRENT_DATE,
        COUNT(DISTINCT l.id),
        COUNT(DISTINCT l.id) FILTER (WHERE l.created_at::DATE = CURRENT_DATE),
        COUNT(DISTINCT l.id) FILTER (WHERE l.calificado = TRUE),
        COUNT(DISTINCT o.id) FILTER (WHERE o.etapa = 'propuesta_enviada'),
        COUNT(DISTINCT o.id) FILTER (WHERE o.etapa = 'negociacion'),
        COUNT(DISTINCT o.id) FILTER (WHERE o.ganada = TRUE AND o.fecha_cierre_real = CURRENT_DATE),
        COUNT(DISTINCT o.id) FILTER (WHERE o.ganada = FALSE AND o.fecha_cierre_real = CURRENT_DATE),
        COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada IS NULL), 0),
        COALESCE(SUM(o.valor_final_cop * o.probabilidad_cierre_pct / 100) FILTER (WHERE o.ganada IS NULL), 0),
        COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE AND o.fecha_cierre_real = CURRENT_DATE), 0),
        COALESCE((SELECT SUM(comision_neta) FROM sd_comisiones.liquidaciones
                  WHERE fecha_devengamiento = CURRENT_DATE), 0),
        COALESCE((SELECT SUM(comision_neta) FROM sd_comisiones.liquidaciones
                  WHERE estado IN ('generada','pendiente_aprobacion','aprobada')), 0),
        (SELECT COUNT(*) FROM sd_clientes.clientes WHERE estado_cliente IN ('activo','recurrente')),
        (SELECT COALESCE(SUM(mrr_actual),0) FROM sd_clientes.clientes WHERE estado_cliente IN ('activo','recurrente')),
        (SELECT COUNT(*) FROM sd_clientes.clientes WHERE alerta_churn = TRUE)
    FROM sd_comercial.leads l
    LEFT JOIN sd_comercial.oportunidades o ON o.lead_id = l.id
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Emitir evento cuando cambia etapa de oportunidad
CREATE OR REPLACE FUNCTION sd_comercial.trigger_evento_pipeline()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.etapa IS DISTINCT FROM NEW.etapa THEN
        PERFORM sd_events.emit(
            CASE WHEN NEW.etapa = 'ganado' THEN 'opportunity_won'
                 WHEN NEW.etapa = 'perdido' THEN 'opportunity_lost'
                 ELSE 'pipeline_stage_change' END,
            'comercial', 'oportunidad', NEW.id,
            NEW.updated_by,
            jsonb_build_object(
                'etapa_anterior', OLD.etapa,
                'etapa_nueva',    NEW.etapa,
                'valor',          NEW.valor_final_cop,
                'combo_id',       NEW.combo_id,
                'comisionista_id', NEW.comisionista_id
            )
        );
        -- Marcar recálculo de score si el lead existe
        IF NEW.lead_id IS NOT NULL THEN
            UPDATE sd_ai.lead_intelligence
            SET requiere_recalculo = TRUE
            WHERE lead_id = NEW.lead_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_evento_pipeline
    AFTER UPDATE OF etapa ON sd_comercial.oportunidades
    FOR EACH ROW EXECUTE FUNCTION sd_comercial.trigger_evento_pipeline();

-- Trigger: Emitir evento cuando se confirma un pago
CREATE OR REPLACE FUNCTION sd_financiero.trigger_evento_pago()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'confirmado' AND (OLD.estado IS NULL OR OLD.estado <> 'confirmado') THEN
        PERFORM sd_events.emit('payment_received', 'financiero', 'pago', NEW.id,
            NULL,
            jsonb_build_object(
                'monto_cop', NEW.monto_cop,
                'cliente_id', NEW.cliente_id,
                'es_primer_pago', NEW.es_primer_pago_contrato,
                'metodo', NEW.metodo_pago
            )
        );
        -- Marcar cliente para recálculo de health
        UPDATE sd_ai.customer_health SET requiere_recalculo = TRUE WHERE cliente_id = NEW.cliente_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_evento_pago
    AFTER UPDATE OF estado ON sd_financiero.pagos
    FOR EACH ROW EXECUTE FUNCTION sd_financiero.trigger_evento_pago();

-- Trigger: Emitir evento cuando se crea un lead
CREATE OR REPLACE FUNCTION sd_comercial.trigger_evento_lead_nuevo()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM sd_events.emit('lead_created', 'comercial', 'lead', NEW.id,
        NEW.comisionista_id,
        jsonb_build_object(
            'origen', NEW.origen,
            'email', NEW.email,
            'empresa', NEW.empresa_nombre,
            'combo_interesado_id', NEW.combo_interesado_id,
            'utm_source', NEW.utm_source,
            'utm_campaign', NEW.utm_campaign
        )
    );
    -- Inicializar features del lead
    INSERT INTO sd_analytics.lead_features(lead_id, es_referido)
    VALUES (NEW.id, NEW.origen = 'referido_cliente' OR NEW.origen = 'referido_comisionista')
    ON CONFLICT (lead_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_evento_lead_nuevo
    AFTER INSERT ON sd_comercial.leads
    FOR EACH ROW EXECUTE FUNCTION sd_comercial.trigger_evento_lead_nuevo();

-- Trigger: Registrar en journey del cliente cuando cambia estado
CREATE OR REPLACE FUNCTION sd_clientes.trigger_journey_cliente()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.estado_cliente IS DISTINCT FROM NEW.estado_cliente THEN
        INSERT INTO sd_clientes.customer_journey_events(
            cliente_id, etapa, tipo_evento, descripcion
        ) VALUES (
            NEW.id,
            CASE NEW.estado_cliente
                WHEN 'activo'    THEN 'onboarding'
                WHEN 'churned'   THEN 'churn_risk'
                WHEN 'inactivo'  THEN 'churn_risk'
                WHEN 'recuperado' THEN 'expansion'
                ELSE 'adoption'
            END,
            'estado_cambiado',
            format('Estado cambió de %s a %s', OLD.estado_cliente, NEW.estado_cliente)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_journey_cliente
    AFTER UPDATE OF estado_cliente ON sd_clientes.clientes
    FOR EACH ROW EXECUTE FUNCTION sd_clientes.trigger_journey_cliente();

-- Trigger: Actualizar features del lead cuando se registra una interacción
CREATE OR REPLACE FUNCTION sd_comercial.trigger_actualizar_features_lead()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar contadores de interacciones en features
    INSERT INTO sd_analytics.lead_features(lead_id, num_interacciones)
    VALUES (COALESCE(NEW.lead_id, (SELECT lead_id FROM sd_comercial.oportunidades WHERE id = NEW.oportunidad_id)), 1)
    ON CONFLICT (lead_id) DO UPDATE SET
        num_interacciones       = sd_analytics.lead_features.num_interacciones + 1,
        dias_ultima_interaccion = 0,
        num_reuniones           = CASE WHEN NEW.tipo = 'meeting' THEN sd_analytics.lead_features.num_reuniones + 1
                                       ELSE sd_analytics.lead_features.num_reuniones END,
        num_llamadas            = CASE WHEN NEW.tipo = 'call' THEN sd_analytics.lead_features.num_llamadas + 1
                                       ELSE sd_analytics.lead_features.num_llamadas END,
        updated_at              = NOW();

    -- Marcar para recálculo de score
    IF COALESCE(NEW.lead_id, (SELECT lead_id FROM sd_comercial.oportunidades WHERE id = NEW.oportunidad_id)) IS NOT NULL THEN
        UPDATE sd_ai.lead_intelligence
        SET requiere_recalculo = TRUE
        WHERE lead_id = COALESCE(NEW.lead_id, (SELECT lead_id FROM sd_comercial.oportunidades WHERE id = NEW.oportunidad_id));
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_features_interaccion
    AFTER INSERT ON sd_comercial.lead_interactions
    FOR EACH ROW EXECUTE FUNCTION sd_comercial.trigger_actualizar_features_lead();

-- Trigger: Crear entrada en renewal_queue cuando se firma un contrato recurrente
CREATE OR REPLACE FUNCTION sd_contratos.trigger_crear_renewal()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'activo' AND NEW.es_recurrente = TRUE
       AND NEW.fecha_fin_servicio IS NOT NULL
       AND (OLD.estado IS NULL OR OLD.estado <> 'activo') THEN
        INSERT INTO sd_clientes.renewal_queue(
            contrato_id, cliente_id, fecha_vencimiento,
            fecha_alerta_60d, fecha_alerta_30d, fecha_alerta_15d,
            responsable_id, comisionista_id
        ) VALUES (
            NEW.id, NEW.cliente_id, NEW.fecha_fin_servicio,
            NEW.fecha_fin_servicio - INTERVAL '60 days',
            NEW.fecha_fin_servicio - INTERVAL '30 days',
            NEW.fecha_fin_servicio - INTERVAL '15 days',
            NEW.responsable_interno_id, NEW.comisionista_id
        )
        ON CONFLICT DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_crear_renewal
    AFTER UPDATE OF estado ON sd_contratos.contratos
    FOR EACH ROW EXECUTE FUNCTION sd_contratos.trigger_crear_renewal();

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 9: Vistas Analíticas + Materializadas
--  15 vistas nuevas + 7 vistas materializadas
-- ================================================================
BEGIN;

-- ---------------------------------------------------------------
-- VISTAS MATERIALIZADAS (alta velocidad para dashboards)
-- ---------------------------------------------------------------

-- 1. Dashboard ejecutivo general (se refresca cada hora)
CREATE MATERIALIZED VIEW sd_analytics.mv_dashboard_ejecutivo AS
SELECT
    -- Pipeline
    COUNT(DISTINCT o.id) FILTER (WHERE o.ganada IS NULL AND o.etapa NOT IN ('perdido','descartado'))
        AS oportunidades_activas,
    COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada IS NULL AND o.etapa NOT IN ('perdido','descartado')), 0)
        AS valor_pipeline_activo,
    COALESCE(SUM(o.valor_final_cop * o.probabilidad_cierre_pct / 100)
             FILTER (WHERE o.ganada IS NULL AND o.etapa NOT IN ('perdido','descartado')), 0)
        AS valor_ponderado_pipeline,
    -- Mes actual
    COUNT(DISTINCT o.id) FILTER (WHERE o.ganada = TRUE
        AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE))
        AS ventas_cerradas_mes,
    COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE
        AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)), 0)
        AS ingresos_mes_actual,
    -- Win rate mes actual
    CASE WHEN COUNT(o.id) FILTER (WHERE o.ganada IS NOT NULL
         AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)) > 0
         THEN ROUND(COUNT(o.id) FILTER (WHERE o.ganada = TRUE
              AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)) * 100.0
              / COUNT(o.id) FILTER (WHERE o.ganada IS NOT NULL
              AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)), 1)
         ELSE 0 END AS win_rate_mes_pct,
    -- Leads
    COUNT(DISTINCT l.id) FILTER (WHERE DATE_TRUNC('month', l.created_at) = DATE_TRUNC('month', CURRENT_DATE))
        AS leads_nuevos_mes,
    COUNT(DISTINCT l.id) FILTER (WHERE l.etapa = 'nuevo' AND l.created_at > NOW() - INTERVAL '24 hours')
        AS leads_nuevos_24h,
    -- Clientes
    COUNT(DISTINCT c.id) FILTER (WHERE c.estado_cliente IN ('activo','recurrente'))
        AS clientes_activos,
    COALESCE(SUM(c.mrr_actual) FILTER (WHERE c.estado_cliente IN ('activo','recurrente')), 0)
        AS mrr_total,
    COUNT(DISTINCT c.id) FILTER (WHERE c.alerta_churn = TRUE)
        AS clientes_riesgo_churn,
    -- Comisiones pendientes de pago
    COALESCE((SELECT SUM(comision_neta) FROM sd_comisiones.liquidaciones
              WHERE estado IN ('generada','pendiente_aprobacion','aprobada')), 0)
        AS comisiones_por_pagar,
    -- Cartera vencida
    COALESCE((SELECT SUM(saldo_pendiente_cop) FROM sd_financiero.facturas
              WHERE estado IN ('vencida','en_mora')), 0)
        AS cartera_vencida,
    -- Timestamp
    NOW() AS calculado_en
FROM sd_comercial.oportunidades o
CROSS JOIN sd_comercial.leads l
CROSS JOIN sd_clientes.clientes c
WITH NO DATA;

CREATE UNIQUE INDEX ON sd_analytics.mv_dashboard_ejecutivo(calculado_en);

-- 2. Vista materializada: ranking de comisionistas del mes
CREATE MATERIALIZED VIEW sd_analytics.mv_ranking_comisionistas_mes AS
SELECT
    com.id,
    com.codigo_comisionista,
    com.nombre_completo,
    com.nivel,
    -- Ventas del mes
    COUNT(o.id) FILTER (WHERE o.ganada = TRUE
        AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE))
        AS ventas_mes,
    COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE
        AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)), 0)
        AS ingresos_mes,
    -- Comisiones del mes
    COALESCE((SELECT SUM(l.comision_neta) FROM sd_comisiones.liquidaciones l
              WHERE l.comisionista_id = com.id
              AND DATE_TRUNC('month', l.fecha_devengamiento) = DATE_TRUNC('month', CURRENT_DATE)), 0)
        AS comisiones_mes,
    -- Pipeline activo
    COUNT(o2.id) FILTER (WHERE o2.ganada IS NULL AND o2.etapa NOT IN ('perdido','descartado'))
        AS pipeline_activo,
    COALESCE(SUM(o2.valor_final_cop) FILTER (WHERE o2.ganada IS NULL AND o2.etapa NOT IN ('perdido','descartado')), 0)
        AS valor_pipeline,
    -- Win rate 90 días
    COALESCE((SELECT af.win_rate_90d FROM sd_analytics.agent_features af WHERE af.comisionista_id = com.id), 0)
        AS win_rate_90d,
    -- Posición en ranking
    ROW_NUMBER() OVER (ORDER BY
        COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE
        AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)), 0) DESC)
        AS posicion_ranking,
    NOW() AS calculado_en
FROM sd_comisiones.comisionistas com
LEFT JOIN sd_comercial.oportunidades o  ON o.comisionista_id = com.id
LEFT JOIN sd_comercial.oportunidades o2 ON o2.comisionista_id = com.id
WHERE com.estado = 'activo'
GROUP BY com.id, com.codigo_comisionista, com.nombre_completo, com.nivel
WITH NO DATA;

CREATE UNIQUE INDEX ON sd_analytics.mv_ranking_comisionistas_mes(id);

-- 3. Vista materializada: health score resumen de cartera de clientes
CREATE MATERIALIZED VIEW sd_analytics.mv_health_cartera AS
SELECT
    segmento,
    COUNT(*)                                                    AS total_clientes,
    ROUND(AVG(ch.health_score), 1)                             AS health_score_promedio,
    COUNT(*) FILTER (WHERE ch.nivel_riesgo_churn = 'bajo')     AS riesgo_bajo,
    COUNT(*) FILTER (WHERE ch.nivel_riesgo_churn = 'medio')    AS riesgo_medio,
    COUNT(*) FILTER (WHERE ch.nivel_riesgo_churn = 'alto')     AS riesgo_alto,
    COUNT(*) FILTER (WHERE ch.nivel_riesgo_churn = 'critico')  AS riesgo_critico,
    COALESCE(SUM(c.mrr_actual) FILTER (WHERE ch.nivel_riesgo_churn IN ('alto','critico')), 0)
                                                                AS mrr_en_riesgo,
    NOW() AS calculado_en
FROM sd_clientes.clientes c
LEFT JOIN sd_ai.customer_health ch ON ch.cliente_id = c.id
WHERE c.estado_cliente IN ('activo','recurrente')
GROUP BY segmento
WITH NO DATA;

CREATE UNIQUE INDEX ON sd_analytics.mv_health_cartera(segmento);

-- ---------------------------------------------------------------
-- VISTAS NORMALES ANALÍTICAS
-- ---------------------------------------------------------------

-- 4. Análisis de fuentes de leads (ROI por canal)
CREATE OR REPLACE VIEW sd_analytics.v_roi_por_canal AS
SELECT
    l.origen,
    COUNT(*)                                                    AS total_leads,
    COUNT(*) FILTER (WHERE l.calificado = TRUE)                AS leads_calificados,
    COUNT(*) FILTER (WHERE o.ganada = TRUE)                    AS leads_convertidos,
    ROUND(COUNT(*) FILTER (WHERE l.calificado = TRUE) * 100.0
          / NULLIF(COUNT(*), 0), 1)                            AS tasa_calificacion_pct,
    ROUND(COUNT(*) FILTER (WHERE o.ganada = TRUE) * 100.0
          / NULLIF(COUNT(*), 0), 1)                            AS tasa_conversion_pct,
    COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0)
                                                                AS ingresos_generados,
    COALESCE(AVG(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0)
                                                                AS ticket_promedio,
    COALESCE(AVG(l.costo_adquisicion), 0)                      AS cac_promedio,
    ROUND(AVG(o.ciclo_venta_dias) FILTER (WHERE o.ganada = TRUE), 1)
                                                                AS dias_promedio_cierre
FROM sd_comercial.leads l
LEFT JOIN sd_comercial.oportunidades o ON o.lead_id = l.id
GROUP BY l.origen
ORDER BY ingresos_generados DESC;

-- 5. Velocidad de ventas (Sales Velocity)
CREATE OR REPLACE VIEW sd_analytics.v_sales_velocity AS
SELECT
    DATE_TRUNC('month', o.fecha_cierre_real)    AS mes,
    COUNT(*) FILTER (WHERE o.ganada = TRUE)     AS oportunidades_ganadas,
    ROUND(AVG(o.ciclo_venta_dias) FILTER (WHERE o.ganada = TRUE), 1)
                                                AS ciclo_promedio_dias,
    ROUND(AVG(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0)
                                                AS ticket_promedio,
    ROUND(COUNT(*) FILTER (WHERE o.ganada = TRUE) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE o.ganada IS NOT NULL), 0), 1)
                                                AS win_rate_pct,
    -- Fórmula de Sales Velocity = (Opps * Win Rate * Ticket Promedio) / Ciclo
    CASE WHEN ROUND(AVG(o.ciclo_venta_dias) FILTER (WHERE o.ganada = TRUE), 1) > 0
         THEN ROUND(
             COUNT(*) FILTER (WHERE o.ganada = TRUE)
             * ROUND(COUNT(*) FILTER (WHERE o.ganada = TRUE) * 1.0
               / NULLIF(COUNT(*) FILTER (WHERE o.ganada IS NOT NULL), 0), 4)
             * ROUND(AVG(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0)
             / ROUND(AVG(o.ciclo_venta_dias) FILTER (WHERE o.ganada = TRUE), 1), 0)
         ELSE 0 END                             AS revenue_por_dia
FROM sd_comercial.oportunidades o
WHERE o.fecha_cierre_real IS NOT NULL
GROUP BY DATE_TRUNC('month', o.fecha_cierre_real)
ORDER BY mes DESC;

-- 6. Análisis de cohortes de clientes (retención mensual)
CREATE OR REPLACE VIEW sd_analytics.v_cohortes_clientes AS
SELECT
    DATE_TRUNC('month', c.fecha_conversion)     AS cohorte_mes,
    COUNT(DISTINCT c.id)                        AS clientes_cohorte,
    COUNT(DISTINCT c.id) FILTER (WHERE c.estado_cliente IN ('activo','recurrente'))
                                                AS clientes_activos_hoy,
    ROUND(COUNT(DISTINCT c.id) FILTER (WHERE c.estado_cliente IN ('activo','recurrente')) * 100.0
          / NULLIF(COUNT(DISTINCT c.id), 0), 1) AS tasa_retencion_pct,
    COALESCE(AVG(c.ltv_realizado), 0)           AS ltv_promedio_cohorte,
    COALESCE(AVG(c.mrr_actual) FILTER (WHERE c.estado_cliente IN ('activo','recurrente')), 0)
                                                AS mrr_promedio_activos,
    EXTRACT(MONTH FROM AGE(CURRENT_DATE, DATE_TRUNC('month', c.fecha_conversion)::DATE))
                                                AS meses_desde_cohorte
FROM sd_clientes.clientes c
WHERE c.fecha_conversion IS NOT NULL
GROUP BY DATE_TRUNC('month', c.fecha_conversion)
ORDER BY cohorte_mes DESC;

-- 7. Detalle de comisiones pendientes (vista operativa para finanzas)
CREATE OR REPLACE VIEW sd_analytics.v_comisiones_pendientes_detalle AS
SELECT
    l.codigo_liquidacion,
    l.fecha_devengamiento,
    com.nombre_completo         AS comisionista,
    com.email                   AS email_comisionista,
    cli.codigo_cliente,
    COALESCE(emp.razon_social, ct.nombre_completo) AS nombre_cliente,
    COALESCE(cmb.nombre, srv.nombre_comercial)      AS producto_vendido,
    l.tipo_comision,
    l.tasa_comision_aplicada    AS tasa_pct,
    l.base_calculo_comision     AS base_calculo,
    l.comision_bruta,
    l.total_retenciones,
    l.comision_neta,
    l.estado,
    -- Días esperando pago
    CURRENT_DATE - l.fecha_devengamiento            AS dias_pendiente,
    -- Datos bancarios
    com.banco,
    com.tipo_cuenta,
    com.numero_cuenta
FROM sd_comisiones.liquidaciones l
JOIN sd_comisiones.comisionistas com  ON com.id = l.comisionista_id
JOIN sd_clientes.clientes cli         ON cli.id = l.cliente_id
LEFT JOIN sd_clientes.empresas emp    ON emp.id = cli.empresa_id
LEFT JOIN sd_clientes.contactos ct    ON ct.id = cli.contacto_principal_id
LEFT JOIN sd_servicios.combos cmb     ON cmb.id = l.combo_id
LEFT JOIN sd_servicios.servicios srv  ON srv.id = l.servicio_id
WHERE l.estado IN ('generada', 'pendiente_aprobacion', 'aprobada')
ORDER BY com.nombre_completo, l.fecha_devengamiento;

-- 8. Análisis de elasticidad de precios
CREATE OR REPLACE VIEW sd_analytics.v_elasticidad_precios AS
SELECT
    COALESCE(s.nombre_comercial, c.nombre) AS producto,
    COUNT(*)                                AS total_cotizaciones,
    COUNT(*) FILTER (WHERE ep.fue_aceptado = TRUE)  AS aceptadas,
    COUNT(*) FILTER (WHERE ep.fue_aceptado = FALSE) AS rechazadas,
    ROUND(COUNT(*) FILTER (WHERE ep.fue_aceptado = TRUE) * 100.0 / NULLIF(COUNT(*), 0), 1) AS tasa_aceptacion_pct,
    ROUND(AVG(ep.precio_ofrecido), 0)       AS precio_promedio_cotizado,
    ROUND(AVG(ep.precio_ofrecido) FILTER (WHERE ep.fue_aceptado = TRUE), 0)  AS precio_promedio_aceptado,
    ROUND(AVG(ep.precio_ofrecido) FILTER (WHERE ep.fue_aceptado = FALSE), 0) AS precio_promedio_rechazado,
    ROUND(AVG(ep.descuento_pct), 1)         AS descuento_promedio_pct,
    ROUND(AVG(ep.descuento_pct) FILTER (WHERE ep.fue_aceptado = TRUE), 1) AS descuento_promedio_aceptado
FROM sd_inteligencia.elasticidad_precios ep
LEFT JOIN sd_servicios.servicios s ON s.id = ep.servicio_id
LEFT JOIN sd_servicios.combos c ON c.id = ep.combo_id
GROUP BY COALESCE(s.nombre_comercial, c.nombre)
ORDER BY tasa_aceptacion_pct DESC;

-- 9. Análisis de competidores (win/loss vs cada competidor)
CREATE OR REPLACE VIEW sd_analytics.v_analisis_competidores AS
SELECT
    COALESCE(comp.nombre, cpo.nombre_competidor) AS competidor,
    COUNT(*)                                     AS veces_en_evaluacion,
    COUNT(*) FILTER (WHERE cpo.gano_competidor = FALSE) AS veces_ganamos,
    COUNT(*) FILTER (WHERE cpo.gano_competidor = TRUE)  AS veces_perdimos,
    ROUND(COUNT(*) FILTER (WHERE cpo.gano_competidor = FALSE) * 100.0 / NULLIF(COUNT(*), 0), 1)
                                                  AS win_rate_vs_competidor_pct,
    ROUND(AVG(cpo.precio_competidor) FILTER (WHERE cpo.precio_competidor IS NOT NULL), 0)
                                                  AS precio_promedio_competidor,
    MODE() WITHIN GROUP (ORDER BY cpo.razon_resultado) AS principal_razon_resultado
FROM sd_inteligencia.competencia_por_oportunidad cpo
LEFT JOIN sd_inteligencia.competidores comp ON comp.id = cpo.competidor_id
GROUP BY COALESCE(comp.nombre, cpo.nombre_competidor)
ORDER BY veces_en_evaluacion DESC;

-- 10. Vista de leads activos con score y próxima acción (para el equipo comercial)
CREATE OR REPLACE VIEW sd_analytics.v_leads_accionables AS
SELECT
    l.id,
    l.codigo_lead,
    COALESCE(l.nombre || ' ' || COALESCE(l.apellido,''), 'Sin nombre') AS nombre_lead,
    l.empresa_nombre,
    l.email,
    l.whatsapp,
    l.etapa,
    li.lead_score,
    li.prioridad,
    li.accion_recomendada,
    li.razon_accion,
    li.deadline_accion,
    lf.dias_ultima_interaccion,
    lf.num_interacciones,
    lf.num_propuestas_vistas,
    -- Comisionista asignado
    com.nombre_completo             AS comisionista,
    -- Valor potencial
    COALESCE(o.valor_final_cop, l.presupuesto_declarado) AS valor_estimado,
    -- Señales calientes
    CASE WHEN lf.pregunto_precio THEN '💰' ELSE '' END ||
    CASE WHEN lf.pidio_demo THEN '🎯' ELSE '' END ||
    CASE WHEN lf.num_propuestas_vistas > 0 THEN '👀' ELSE '' END
        AS senales_calientes,
    -- Días sin actividad (ALERTA si > 3)
    CASE WHEN COALESCE(lf.dias_ultima_interaccion, 99) > 7  THEN 'CRITICO'
         WHEN COALESCE(lf.dias_ultima_interaccion, 99) > 3  THEN 'ALERTA'
         ELSE 'OK' END AS estado_seguimiento,
    l.created_at                    AS fecha_registro
FROM sd_comercial.leads l
LEFT JOIN sd_ai.lead_intelligence li   ON li.lead_id = l.id
LEFT JOIN sd_analytics.lead_features lf ON lf.lead_id = l.id
LEFT JOIN sd_comisiones.comisionistas com ON com.id = l.comisionista_id
LEFT JOIN sd_comercial.oportunidades o  ON o.lead_id = l.id AND o.ganada IS NULL
WHERE l.etapa NOT IN ('ganado','perdido','descartado')
ORDER BY COALESCE(li.prioridad_num, 0) DESC, l.created_at DESC;

-- 11. Análisis de ciclo de vida del cliente (CLV breakdown)
CREATE OR REPLACE VIEW sd_analytics.v_clv_analisis AS
SELECT
    c.id,
    c.codigo_cliente,
    COALESCE(e.razon_social, ct.nombre_completo) AS nombre_cliente,
    c.segmento,
    e.industria,
    -- Tiempo como cliente
    EXTRACT(MONTH FROM AGE(CURRENT_DATE, c.fecha_conversion::DATE))::INTEGER AS meses_como_cliente,
    -- LTV real
    c.ltv_realizado                               AS ltv_historico,
    c.mrr_actual,
    -- LTV proyectado a 12 meses
    c.mrr_actual * 12                             AS ltv_proyectado_12m,
    -- CAC
    c.costo_adquisicion,
    -- LTV/CAC ratio
    CASE WHEN COALESCE(c.costo_adquisicion, 0) > 0
         THEN ROUND(c.ltv_realizado / c.costo_adquisicion, 2)
         ELSE NULL END                            AS ltv_cac_ratio,
    -- Payback period (meses para recuperar CAC)
    CASE WHEN COALESCE(c.mrr_actual, 0) > 0
         THEN ROUND(COALESCE(c.costo_adquisicion, 0) / c.mrr_actual, 1)
         ELSE NULL END                            AS payback_meses,
    -- Potencial restante
    COALESCE(cf.potencial_upsell_cop, 0)          AS potencial_upsell,
    ch.health_score,
    ch.prob_churn_30d
FROM sd_clientes.clientes c
LEFT JOIN sd_clientes.empresas e      ON e.id = c.empresa_id
LEFT JOIN sd_clientes.contactos ct    ON ct.id = c.contacto_principal_id
LEFT JOIN sd_analytics.customer_features cf ON cf.cliente_id = c.id
LEFT JOIN sd_ai.customer_health ch    ON ch.cliente_id = c.id
WHERE c.fecha_conversion IS NOT NULL
ORDER BY c.ltv_realizado DESC;

-- 12. Alertas activas del sistema (vista unificada para el dashboard de alertas)
CREATE OR REPLACE VIEW sd_analytics.v_alertas_activas AS
-- Leads sin contacto
SELECT
    'lead_sin_contacto'         AS tipo_alerta,
    'comercial'                 AS categoria,
    'alta'                      AS severidad,
    l.id                        AS entity_id,
    l.codigo_lead               AS entity_codigo,
    format('Lead %s sin contacto hace %s días', l.codigo_lead,
           COALESCE(lf.dias_ultima_interaccion::TEXT, 'nunca'))
                                AS descripcion,
    com.nombre_completo         AS responsable,
    l.created_at                AS fecha_referencia
FROM sd_comercial.leads l
LEFT JOIN sd_analytics.lead_features lf ON lf.lead_id = l.id
LEFT JOIN sd_comisiones.comisionistas com ON com.id = l.comisionista_id
WHERE l.etapa NOT IN ('ganado','perdido','descartado')
  AND COALESCE(lf.dias_ultima_interaccion, 999) > 3

UNION ALL

-- Facturas vencidas
SELECT
    'factura_vencida', 'financiero', 'alta',
    f.id, f.codigo_factura,
    format('Factura %s vencida hace %s días — $%s COP pendiente',
           f.codigo_factura, f.dias_mora,
           TO_CHAR(f.saldo_pendiente_cop, 'FM999,999,999')),
    u.nombre_display,
    f.fecha_vencimiento
FROM sd_financiero.facturas f
LEFT JOIN sd_clientes.clientes c ON c.id = f.cliente_id
LEFT JOIN sd_core.usuarios u ON u.id = c.responsable_comercial_id
WHERE f.estado IN ('vencida','en_mora') AND f.dias_mora > 0

UNION ALL

-- Clientes en riesgo de churn
SELECT
    'riesgo_churn', 'clientes', 'critica',
    c.id, c.codigo_cliente,
    format('Cliente %s en riesgo de churn — health score: %s',
           COALESCE(emp.razon_social, 'Sin nombre'), COALESCE(ch.health_score::TEXT, '?')),
    u.nombre_display,
    ch.calculado_en
FROM sd_clientes.clientes c
LEFT JOIN sd_clientes.empresas emp ON emp.id = c.empresa_id
LEFT JOIN sd_ai.customer_health ch ON ch.cliente_id = c.id
LEFT JOIN sd_core.usuarios u ON u.id = c.responsable_comercial_id
WHERE c.alerta_churn = TRUE

UNION ALL

-- Contratos por renovar (30 días)
SELECT
    'renovacion_proxima', 'contratos', 'media',
    rq.id, con.codigo_contrato,
    format('Contrato %s vence el %s — valor: $%s COP',
           con.codigo_contrato, rq.fecha_vencimiento,
           TO_CHAR(con.valor_final_cop, 'FM999,999,999')),
    u.nombre_display,
    rq.fecha_vencimiento
FROM sd_clientes.renewal_queue rq
JOIN sd_contratos.contratos con ON con.id = rq.contrato_id
LEFT JOIN sd_core.usuarios u ON u.id = rq.responsable_id
WHERE rq.estado = 'pendiente' AND rq.fecha_vencimiento <= CURRENT_DATE + INTERVAL '30 days'

UNION ALL

-- Alertas de fraude activas
SELECT
    'fraude_comision', 'seguridad', 'critica',
    fa.id, com.codigo_comisionista,
    format('Alerta de fraude: %s — Comisionista: %s', fa.tipo_alerta, com.nombre_completo),
    'Admin',
    fa.detected_at
FROM sd_comisiones.fraud_alerts fa
JOIN sd_comisiones.comisionistas com ON com.id = fa.comisionista_id
WHERE fa.estado IN ('nueva', 'en_revision')

ORDER BY
    CASE severidad WHEN 'critica' THEN 1 WHEN 'alta' THEN 2 WHEN 'media' THEN 3 ELSE 4 END,
    fecha_referencia DESC;

-- 13. Análisis del funnel completo
CREATE OR REPLACE VIEW sd_analytics.v_funnel_completo AS
WITH total_leads AS (SELECT COUNT(*) AS n FROM sd_comercial.leads)
SELECT
    1 AS orden, 'Leads Totales'        AS etapa, COUNT(*) AS cantidad,
    100.0                              AS conversion_desde_inicio,
    NULL::DECIMAL                      AS conversion_paso_anterior
FROM sd_comercial.leads
UNION ALL SELECT 2, 'Leads Calificados', COUNT(*),
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT n FROM total_leads), 0), 1), NULL
FROM sd_comercial.leads WHERE calificado = TRUE
UNION ALL SELECT 3, 'Propuesta Enviada', COUNT(*),
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT n FROM total_leads), 0), 1), NULL
FROM sd_comercial.oportunidades WHERE etapa IN ('propuesta_enviada','propuesta_vista','negociacion','contrato_enviado','ganado')
UNION ALL SELECT 4, 'En Negociación', COUNT(*),
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT n FROM total_leads), 0), 1), NULL
FROM sd_comercial.oportunidades WHERE etapa IN ('negociacion','contrato_enviado','ganado')
UNION ALL SELECT 5, 'Cerrado Ganado', COUNT(*),
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT n FROM total_leads), 0), 1), NULL
FROM sd_comercial.oportunidades WHERE ganada = TRUE
ORDER BY orden;

-- 14. Contribución de cada comisionista por combo (qué combo vende cada quién)
CREATE OR REPLACE VIEW sd_analytics.v_comisionista_por_combo AS
SELECT
    com.nombre_completo                         AS comisionista,
    com.nivel,
    COALESCE(cmb.nombre, srv.nombre_comercial)  AS producto,
    COUNT(o.id)                                 AS veces_en_pipeline,
    COUNT(o.id) FILTER (WHERE o.ganada = TRUE)  AS veces_cerrado,
    COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0) AS ingresos,
    COALESCE(SUM(liq.comision_neta), 0)         AS comisiones_generadas,
    ROUND(COUNT(o.id) FILTER (WHERE o.ganada = TRUE) * 100.0 / NULLIF(COUNT(o.id), 0), 1)
                                                AS win_rate_pct
FROM sd_comisiones.comisionistas com
LEFT JOIN sd_comercial.oportunidades o  ON o.comisionista_id = com.id
LEFT JOIN sd_servicios.combos cmb       ON cmb.id = o.combo_id
LEFT JOIN sd_servicios.servicios srv    ON srv.id = o.servicio_id
LEFT JOIN sd_comisiones.liquidaciones liq ON liq.comisionista_id = com.id
    AND (liq.combo_id = o.combo_id OR liq.servicio_id = o.servicio_id)
WHERE com.estado = 'activo'
GROUP BY com.nombre_completo, com.nivel, COALESCE(cmb.nombre, srv.nombre_comercial)
ORDER BY com.nombre_completo, ingresos DESC;

-- 15. Resumen de automatizaciones ejecutadas
CREATE OR REPLACE VIEW sd_analytics.v_automation_performance AS
SELECT
    wr.codigo,
    wr.nombre,
    wr.categoria,
    wr.total_ejecuciones,
    wr.ejecuciones_exitosas,
    wr.ejecuciones_fallidas,
    CASE WHEN wr.total_ejecuciones > 0
         THEN ROUND(wr.ejecuciones_exitosas * 100.0 / wr.total_ejecuciones, 1)
         ELSE 0 END                 AS tasa_exito_pct,
    wr.ultima_ejecucion,
    -- Últimas 24 horas
    COUNT(ar.id) FILTER (WHERE ar.iniciado_en > NOW() - INTERVAL '24 hours') AS ejecuciones_24h,
    COUNT(ar.id) FILTER (WHERE ar.iniciado_en > NOW() - INTERVAL '24 hours' AND ar.estado = 'fallido') AS fallos_24h,
    -- Duración promedio
    ROUND(AVG(ar.duracion_ms) / 1000.0, 1) AS duracion_promedio_seg
FROM sd_automation.workflow_registry wr
LEFT JOIN sd_automation.automation_runs ar ON ar.workflow_id = wr.id
WHERE wr.activo = TRUE
GROUP BY wr.id, wr.codigo, wr.nombre, wr.categoria,
         wr.total_ejecuciones, wr.ejecuciones_exitosas, wr.ejecuciones_fallidas, wr.ultima_ejecucion
ORDER BY wr.categoria, wr.total_ejecuciones DESC;

COMMIT;
-- ================================================================
--  SNAKE DRAGON — CRM v2.0  |  PARTE 10: Datos Iniciales + Workflows n8n
-- ================================================================
BEGIN;

-- Catálogos lookup de industrias
INSERT INTO sd_core.cat_industrias (codigo, nombre, es_objetivo_icp, score_icp) VALUES
('tecnologia',          'Tecnología y Software',            TRUE,  10),
('startup',             'Startup',                          TRUE,  9),
('ecommerce',           'E-Commerce y Ventas Online',       TRUE,  9),
('consultoria',         'Consultoría y Servicios Profesionales', TRUE, 8),
('finanzas_seguros',    'Finanzas y Seguros',               TRUE,  8),
('salud',               'Salud y Medicina',                 TRUE,  7),
('educacion',           'Educación',                        FALSE, 6),
('retail_comercio',     'Retail y Comercio',                FALSE, 6),
('manufactura',         'Manufactura',                      FALSE, 5),
('logistica',           'Logística y Transporte',           FALSE, 5),
('construccion',        'Construcción e Inmobiliaria',      FALSE, 4),
('gobierno',            'Gobierno y Sector Público',        FALSE, 3),
('otro',                'Otro',                             FALSE, 3);

-- Catálogo de orígenes de lead
INSERT INTO sd_core.cat_origenes_lead (codigo, nombre, categoria, es_digital, costo_estimado_cop) VALUES
('referido_cliente',        'Referido por cliente activo',      'referido',  FALSE, 0),
('referido_comisionista',   'Referido por comisionista',        'referido',  FALSE, 0),
('google_organico',         'Google orgánico (SEO)',             'organico',  TRUE,  0),
('google_ads',              'Google Ads',                        'pagado',    TRUE,  50000),
('linkedin_organico',       'LinkedIn orgánico',                 'organico',  TRUE,  0),
('linkedin_ads',            'LinkedIn Ads',                      'pagado',    TRUE,  80000),
('instagram_organico',      'Instagram orgánico',                'organico',  TRUE,  0),
('facebook_ads',            'Facebook / Instagram Ads',          'pagado',    TRUE,  40000),
('formulario_web',          'Formulario en el sitio web',        'organico',  TRUE,  0),
('whatsapp_directo',        'WhatsApp directo',                  'outbound',  TRUE,  0),
('evento_presencial',       'Evento presencial',                 'evento',    FALSE, 200000),
('evento_virtual',          'Webinar / evento virtual',          'evento',    TRUE,  30000),
('cold_email',              'Outbound email frío',               'outbound',  TRUE,  5000),
('cold_linkedin',           'Outbound LinkedIn',                 'outbound',  TRUE,  5000),
('alianza_estrategica',     'Alianza o partnership',             'referido',  FALSE, 0),
('contenido_blog',          'Blog / Content Marketing',          'organico',  TRUE,  0),
('otro',                    'Otro canal',                        'otro',      FALSE, 0);

-- Catálogo de razones de pérdida
INSERT INTO sd_core.cat_razones_perdida (codigo, nombre, categoria) VALUES
('precio_alto',             'Precio demasiado alto',             'precio'),
('sin_presupuesto',         'No tiene presupuesto ahora',        'precio'),
('eligio_competencia',      'Eligió a un competidor',            'competencia'),
('no_era_momento',          'No era el momento correcto',        'timing'),
('prioridades_cambiaron',   'Cambiaron las prioridades',         'timing'),
('proceso_pausado',         'El proceso interno se pausó',       'timing'),
('no_percibio_valor',       'No percibió el valor de la solución','fit'),
('requerimiento_no_cubierto','Requerimiento que no podemos cubrir','fit'),
('no_responde',             'El contacto dejó de responder',     'interno'),
('perdimos_contacto',       'Perdimos el contacto con el decisor','interno'),
('otro',                    'Otra razón',                        'otro');

-- Catálogo de tipos de actividad
INSERT INTO sd_core.cat_tipos_actividad (codigo, nombre, puntos_score) VALUES
('llamada_saliente',    'Llamada saliente',             3),
('llamada_entrante',    'Llamada entrante',             5),
('email_enviado',       'Email enviado',                2),
('email_respondido',    'Email respondido por cliente', 6),
('whatsapp_enviado',    'WhatsApp enviado',             2),
('whatsapp_respondido', 'Cliente respondió WhatsApp',   8),
('reunion_virtual',     'Reunión virtual',              10),
('reunion_presencial',  'Reunión presencial',           12),
('demo_producto',       'Demo del producto/servicio',   10),
('propuesta_enviada',   'Propuesta enviada',            5),
('propuesta_revisada',  'Propuesta revisada por cliente',12),
('seguimiento',         'Seguimiento general',          2),
('nota_interna',        'Nota interna',                 0),
('contrato_enviado',    'Contrato enviado',             8),
('contrato_firmado',    'Contrato firmado',             0);

-- Workflows n8n registrados
INSERT INTO sd_automation.workflow_registry
    (codigo, nombre, descripcion, categoria, trigger_tipo) VALUES

-- MARKETING
('WF-MKT-001', 'Captura de Leads desde Formulario Web',
 'Recibe leads del formulario web, enriquece con Apollo/Clearbit, hace scoring IA y los ingresa al CRM',
 'marketing', 'webhook'),

('WF-MKT-002', 'Captura de Leads desde WhatsApp',
 'Leads que llegan por WhatsApp Business → CRM',
 'marketing', 'webhook'),

('WF-MKT-003', 'Captura de Leads desde LinkedIn Ads',
 'Lead Forms de LinkedIn → enriquecimiento → CRM',
 'marketing', 'webhook'),

('WF-MKT-004', 'Scoring Automático de Leads',
 'Cada nueva interacción recalcula el score del lead usando sd_ai.recalcular_lead_score()',
 'marketing', 'evento'),

('WF-MKT-005', 'Asignación Automática de Lead a Comisionista',
 'Al calificar un lead, lo asigna al comisionista disponible según reglas de territorio e industria',
 'marketing', 'evento'),

-- VENTAS
('WF-VEN-001', 'Alerta: Lead sin contacto en 24h',
 'Si un lead calificado no tiene actividad en 24h, notifica al comisionista y responsable interno',
 'ventas', 'cron'),

('WF-VEN-002', 'Alerta: Propuesta no abierta en 48h',
 'Si la propuesta fue enviada pero no tiene evento de apertura en 48h, envía recordatorio al comisionista',
 'ventas', 'cron'),

('WF-VEN-003', 'Recordatorio de Follow-up Automático',
 'Genera tareas y notificaciones de seguimiento según la última actividad del lead',
 'ventas', 'cron'),

('WF-VEN-004', 'Generación Automática de Propuesta PDF',
 'Al pasar a etapa propuesta_enviada, genera el PDF con precios y lo sube a Drive',
 'ventas', 'evento'),

('WF-VEN-005', 'Generación Automática de Contrato',
 'Al ganar la oportunidad, genera el contrato desde plantilla y lo envía a DocuSign/Firma.ec',
 'ventas', 'evento'),

('WF-VEN-006', 'Notificación de Oportunidad Ganada',
 'Al cerrar una venta, notifica al equipo por Slack y actualiza dashboard en tiempo real',
 'ventas', 'evento'),

('WF-VEN-007', 'Análisis de Propuesta Vista (Tracking)',
 'Cuando el cliente abre la propuesta, notifica al comisionista con datos de lectura',
 'ventas', 'webhook'),

-- COMISIONISTAS
('WF-COM-001', 'Generación de Liquidación al Confirmar Pago',
 'Trigger automático: pago confirmado → genera liquidación de comisión (ya implementado en SQL)',
 'comisiones', 'evento'),

('WF-COM-002', 'Notificación de Comisión Generada',
 'Cuando se genera una liquidación, notifica al comisionista por WhatsApp y email con el detalle',
 'comisiones', 'evento'),

('WF-COM-003', 'Reporte Semanal de Comisiones al Comisionista',
 'Cada lunes envía resumen de comisiones pendientes y pagadas al comisionista',
 'comisiones', 'cron'),

('WF-COM-004', 'Ranking Semanal de Comisionistas',
 'Cada viernes publica el ranking del equipo en Slack para gamificación',
 'comisiones', 'cron'),

('WF-COM-005', 'Detección de Leads Abandonados',
 'Identifica leads asignados a comisionistas sin actividad > 5 días y envía alerta',
 'comisiones', 'cron'),

('WF-COM-006', 'Detección de Patrones de Fraude',
 'Ejecuta las fraud_rules y crea alertas en sd_comisiones.fraud_alerts',
 'comisiones', 'cron'),

-- CLIENTES
('WF-CLI-001', 'Onboarding Zero-Touch al Firmar Contrato',
 'Contrato firmado → crea proyecto en sistema PM, carpeta en Drive, canal Slack, envia email bienvenida',
 'clientes', 'evento'),

('WF-CLI-002', 'Recordatorio de Pago (3 días antes del vencimiento)',
 'Envía recordatorio amigable de factura próxima a vencer',
 'clientes', 'cron'),

('WF-CLI-003', 'Alerta de Factura Vencida',
 'Al día 1, 7 y 15 de mora envía escalamiento de recordatorios de cobro',
 'clientes', 'cron'),

('WF-CLI-004', 'Alerta de Renovación de Contrato',
 'A los 60, 30 y 15 días antes del vencimiento, notifica y asigna tarea de gestión',
 'clientes', 'cron'),

('WF-CLI-005', 'Encuesta NPS Post-Proyecto',
 'Al marcar proyecto como completado, envía encuesta NPS al cliente',
 'clientes', 'evento'),

('WF-CLI-006', 'Alerta de Churn Risk',
 'Cuando el health score cae < 50, notifica al account manager con plan de acción sugerido',
 'clientes', 'evento'),

('WF-CLI-007', 'Detección de Oportunidad de Upsell',
 'Cuando el health score es > 80 y hay servicios no contratados, genera recomendación de upsell',
 'clientes', 'evento'),

-- FINANZAS
('WF-FIN-001', 'Generación Automática de Factura',
 'Al firmar contrato con condición anticipo, genera la primera factura automáticamente',
 'finanzas', 'evento'),

('WF-FIN-002', 'Conciliación Bancaria Semi-automática',
 'Importa extractos bancarios y concilia contra pagos pendientes en el CRM',
 'finanzas', 'cron'),

('WF-FIN-003', 'Actualización del Cash Flow Forecast',
 'Cada semana recalcula el forecast de caja para las próximas 4 semanas',
 'finanzas', 'cron'),

-- INTELIGENCIA
('WF-INT-001', 'Recálculo Diario de Lead Scores',
 'Cada noche recalcula el score de todos los leads activos con feautures actualizadas',
 'inteligencia', 'cron'),

('WF-INT-002', 'Recálculo de Customer Health Scores',
 'Cada noche actualiza el health score de todos los clientes activos',
 'inteligencia', 'cron'),

('WF-INT-003', 'Actualización del Revenue Forecast',
 'Cada semana actualiza las predicciones de ingresos del mes y los 2 siguientes',
 'inteligencia', 'cron'),

('WF-INT-004', 'Priorización Diaria del Pipeline',
 'Cada mañana genera la cola priorizada de leads para cada comisionista',
 'inteligencia', 'cron'),

('WF-INT-005', 'Actualización del Snapshot Diario',
 'Cada día a medianoche ejecuta sd_analytics.tomar_snapshot_diario()',
 'inteligencia', 'cron'),

-- OPERACIONES
('WF-OPS-001', 'Alerta de Proyecto en Riesgo',
 'Si un proyecto supera el 90% del tiempo planificado sin completarse, genera alerta',
 'operaciones', 'cron'),

('WF-OPS-002', 'Alerta de Baja Utilización del Equipo',
 'Si la utilización de algún miembro cae < 60%, sugiere asignarlo a proyectos activos',
 'operaciones', 'cron');

-- Jobs programados
INSERT INTO sd_automation.scheduled_jobs (nombre, descripcion, cron_expression, ultimo_estado) VALUES
('snapshot_diario',         'Snapshot diario del pipeline',          '0 23 * * *',   'pendiente'),
('recalculo_lead_scores',   'Recálculo masivo de lead scores',       '0 2 * * *',    'pendiente'),
('recalculo_health_scores', 'Recálculo masivo de health scores',     '0 3 * * *',    'pendiente'),
('revenue_forecast',        'Actualizar forecast de ingresos',       '0 6 * * 1',    'pendiente'),
('fraud_detection',         'Detección de fraude en comisiones',     '0 4 * * *',    'pendiente'),
('data_quality_check',      'Calcular data quality scores',          '0 5 * * 0',    'pendiente'),
('renewal_alerts',          'Alertas de renovación de contratos',    '0 8 * * *',    'pendiente'),
('pipeline_prioritization', 'Priorización del pipeline por comisionista', '0 7 * * 1-5', 'pendiente');

-- Reglas de detección de fraude
INSERT INTO sd_comisiones.fraud_rules (nombre, descripcion, tipo_regla, umbral, severidad, accion_auto) VALUES
('Leads duplicados - mismo email',
 'Comisionista tiene >3 leads con el mismo email en 30 días',
 'leads_duplicados', 3, 'alta', 'notificar_admin'),

('Velocidad anormal de leads',
 'Comisionista registra >50 leads en 24 horas',
 'velocidad_anormal', 50, 'alta', 'notificar_admin'),

('Conversión perfecta sospechosa',
 'Comisionista con 100% de conversión en >5 leads (posible auto-registro)',
 'conversion_perfecta', 5, 'media', 'notificar_admin'),

('Leads sin empresa ni cargo',
 '>70% de leads del comisionista sin empresa ni cargo registrado',
 'leads_sin_empresa', 70, 'media', 'notificar_admin'),

('Descuento excesivo frecuente',
 'Comisionista aplica descuento máximo (10%) en >50% de sus ventas',
 'descuento_excesivo', 50, 'media', 'notificar_admin'),

('Cliente sin actividad post-venta',
 'Cliente marcado como activo pero sin ningún proyecto ni ticket en 60 días',
 'cliente_fantasma', 60, 'baja', 'solo_registrar');

COMMIT;
