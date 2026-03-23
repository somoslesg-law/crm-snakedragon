-- ============================================================
--  SNAKE DRAGON — CRM ENTERPRISE
--  PostgreSQL DDL Completo v1.0
--  Máxima captura de datos para analítica y decisiones
--
--  SCHEMAS:
--    sd_core        → Catálogos globales, usuarios, RBAC
--    sd_comercial   → Leads, pipeline, actividades, comisionistas
--    sd_clientes    → Clientes 360°, contactos, empresas
--    sd_servicios   → Catálogo de servicios, combos, precios
--    sd_contratos   → Contratos, SLA, renovaciones
--    sd_financiero  → Facturas, pagos, CxC, conciliaciones
--    sd_comisiones  → Motor de comisiones, liquidaciones, pagos
--    sd_operaciones → Proyectos, tareas, entregables, timetracking
--    sd_marketing   → Campañas, UTMs, contenido, conversiones
--    sd_soporte     → Tickets, escalaciones, satisfacción
--    sd_analytics   → Vistas materializadas, KPIs, cohorts
--    sd_audit       → Log universal de cambios y eventos
-- ============================================================

-- ============================================================
-- 0. EXTENSIONES
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";        -- Hashing seguro
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- Búsqueda fuzzy
CREATE EXTENSION IF NOT EXISTS "unaccent";        -- Búsqueda sin tildes
CREATE EXTENSION IF NOT EXISTS "tablefunc";       -- Pivot / crosstab
CREATE EXTENSION IF NOT EXISTS "hstore";          -- Key-value en campos
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; -- Query analytics

-- ============================================================
-- 1. SCHEMAS
-- ============================================================
CREATE SCHEMA IF NOT EXISTS sd_core;
CREATE SCHEMA IF NOT EXISTS sd_comercial;
CREATE SCHEMA IF NOT EXISTS sd_clientes;
CREATE SCHEMA IF NOT EXISTS sd_servicios;
CREATE SCHEMA IF NOT EXISTS sd_contratos;
CREATE SCHEMA IF NOT EXISTS sd_financiero;
CREATE SCHEMA IF NOT EXISTS sd_comisiones;
CREATE SCHEMA IF NOT EXISTS sd_operaciones;
CREATE SCHEMA IF NOT EXISTS sd_marketing;
CREATE SCHEMA IF NOT EXISTS sd_soporte;
CREATE SCHEMA IF NOT EXISTS sd_analytics;
CREATE SCHEMA IF NOT EXISTS sd_audit;

-- ============================================================
-- 2. TIPOS ENUMERADOS GLOBALES (ENUMs)
-- ============================================================

-- Estados genéricos
CREATE TYPE sd_core.estado_generico AS ENUM (
    'activo', 'inactivo', 'suspendido', 'eliminado', 'en_revision', 'borrador'
);

-- Monedas
CREATE TYPE sd_core.moneda AS ENUM (
    'COP', 'USD', 'EUR', 'GBP', 'MXN', 'ARS', 'BRL', 'CLP'
);

-- Canales de comunicación
CREATE TYPE sd_core.canal_comunicacion AS ENUM (
    'email', 'telefono', 'whatsapp', 'telegram', 'slack',
    'videollamada', 'presencial', 'linkedin', 'instagram',
    'formulario_web', 'chat_web', 'sms', 'otro'
);

-- Sentimientos / NPS categórico
CREATE TYPE sd_core.sentimiento AS ENUM (
    'muy_positivo', 'positivo', 'neutro', 'negativo', 'muy_negativo'
);

-- Roles de usuario
CREATE TYPE sd_core.rol_usuario AS ENUM (
    'superadmin', 'admin', 'gerente_comercial', 'vendedor_interno',
    'comisionista', 'gerente_operaciones', 'delivery_manager',
    'soporte_tecnico', 'contador', 'analista_datos', 'solo_lectura'
);

-- Tamaño de empresa
CREATE TYPE sd_core.tamano_empresa AS ENUM (
    'micro_1_10', 'pequena_11_50', 'mediana_51_200',
    'grande_201_500', 'corporacion_500_mas', 'no_aplica'
);

-- Industria / sector
CREATE TYPE sd_core.industria AS ENUM (
    'tecnologia', 'retail_comercio', 'salud_medicina', 'educacion',
    'finanzas_seguros', 'manufactura', 'logistica_transporte',
    'construccion_inmobiliaria', 'alimentos_bebidas', 'turismo_hoteleria',
    'medios_entretenimiento', 'gobierno_publico', 'ong_fundaciones',
    'agropecuario', 'energia_mineria', 'consultoria_servicios_profesionales',
    'ecommerce', 'startup', 'otro'
);

-- Etapas del pipeline comercial
CREATE TYPE sd_comercial.etapa_pipeline AS ENUM (
    'nuevo',              -- 1. Entra al sistema
    'calificado',         -- 2. Se confirma que tiene potencial
    'primer_contacto',    -- 3. Primer acercamiento realizado
    'reunion_agendada',   -- 4. Llamada / reunión programada
    'diagnostico',        -- 5. Análisis de necesidades
    'propuesta_enviada',  -- 6. Propuesta o cotización enviada
    'propuesta_vista',    -- 7. Tracking: el cliente abrió la propuesta
    'negociacion',        -- 8. En discusión de condiciones
    'contrato_enviado',   -- 9. Contrato pendiente de firma
    'ganado',             -- 10. Cierre exitoso
    'perdido',            -- 11. No se cerró
    'descartado',         -- 12. No es cliente potencial
    'nurturing'           -- 13. En cultivo para futuro
);

-- Razones de pérdida del lead
CREATE TYPE sd_comercial.razon_perdida AS ENUM (
    'precio_alto', 'eligio_competencia', 'no_tiene_presupuesto',
    'no_era_el_momento', 'no_percibio_valor', 'cambio_de_prioridades',
    'proceso_interno_pausado', 'contacto_no_responde',
    'requerimiento_no_cubierto', 'otro'
);

-- Origen del lead
CREATE TYPE sd_comercial.origen_lead AS ENUM (
    'referido_cliente', 'referido_comisionista', 'red_social_organico',
    'red_social_pagado', 'google_organico', 'google_ads', 'linkedin_organico',
    'linkedin_ads', 'formulario_web', 'evento_presencial', 'evento_virtual',
    'cold_outreach_email', 'cold_outreach_linkedin', 'cold_call',
    'content_marketing', 'alianza_estrategica', 'base_datos_comprada',
    'otro'
);

-- Tipos de actividad CRM
CREATE TYPE sd_comercial.tipo_actividad AS ENUM (
    'llamada_saliente', 'llamada_entrante', 'email_enviado', 'email_recibido',
    'whatsapp_enviado', 'whatsapp_recibido', 'reunion_virtual',
    'reunion_presencial', 'demo_producto', 'propuesta_presentada',
    'seguimiento', 'nota_interna', 'tarea_completada', 'contrato_enviado',
    'contrato_firmado', 'visita_cliente', 'otro'
);

-- Resultado de actividad
CREATE TYPE sd_comercial.resultado_actividad AS ENUM (
    'positivo', 'neutral', 'negativo', 'sin_respuesta',
    'reprogramar', 'completado', 'cancelado'
);

-- Tipo de cliente
CREATE TYPE sd_clientes.tipo_cliente AS ENUM (
    'empresa', 'persona_natural', 'startup', 'gobierno',
    'ong', 'freelancer', 'holding'
);

-- Estado del cliente
CREATE TYPE sd_clientes.estado_cliente AS ENUM (
    'prospecto', 'activo', 'recurrente', 'inactivo',
    'en_mora', 'churned', 'recuperado', 'suspendido'
);

-- Segmento de cliente (por valor)
CREATE TYPE sd_clientes.segmento_cliente AS ENUM (
    'platinum',  -- LTV muy alto, alta frecuencia
    'gold',      -- LTV alto
    'silver',    -- LTV medio
    'bronze',    -- LTV bajo, potencial de crecimiento
    'sin_clasificar'
);

-- Tipo de cobro del servicio
CREATE TYPE sd_servicios.tipo_cobro AS ENUM (
    'unico', 'mensual', 'trimestral', 'semestral', 'anual',
    'por_hora', 'por_proyecto_hitos', 'mixto'
);

-- Nivel del combo
CREATE TYPE sd_servicios.nivel_combo AS ENUM (
    'entrada', 'estandar', 'estrella', 'premium', 'enterprise'
);

-- Estado del contrato
CREATE TYPE sd_contratos.estado_contrato AS ENUM (
    'borrador', 'enviado_firma', 'firmado', 'activo', 'pausado',
    'vencido', 'cancelado', 'renovado', 'en_disputa'
);

-- Tipo de contrato
CREATE TYPE sd_contratos.tipo_contrato AS ENUM (
    'proyecto_unico', 'servicio_recurrente', 'retainer',
    'mantenimiento', 'licencia', 'combo'
);

-- Estado de factura
CREATE TYPE sd_financiero.estado_factura AS ENUM (
    'borrador', 'emitida', 'enviada', 'vista_por_cliente',
    'parcialmente_pagada', 'pagada', 'vencida', 'en_mora',
    'anulada', 'en_disputa'
);

-- Estado del pago
CREATE TYPE sd_financiero.estado_pago AS ENUM (
    'pendiente', 'procesando', 'confirmado', 'rechazado',
    'reembolsado', 'parcial', 'conciliado'
);

-- Método de pago
CREATE TYPE sd_financiero.metodo_pago AS ENUM (
    'transferencia_bancaria', 'pse', 'tarjeta_credito', 'tarjeta_debito',
    'efectivo', 'cheque', 'wompi', 'payu', 'nequi', 'daviplata',
    'paypal', 'stripe', 'cripto', 'otro'
);

-- Estado de liquidación de comisión
CREATE TYPE sd_comisiones.estado_liquidacion AS ENUM (
    'generada', 'pendiente_aprobacion', 'aprobada', 'en_pago',
    'pagada', 'rechazada', 'en_disputa', 'ajustada', 'cancelada'
);

-- Tipo de comisionista
CREATE TYPE sd_comisiones.tipo_comisionista AS ENUM (
    'externo_independiente', 'empleado_ventas', 'socio_comercial',
    'agencia_aliada', 'referidor', 'revendedor'
);

-- Nivel de comisionista (determina acelerador)
CREATE TYPE sd_comisiones.nivel_comisionista AS ENUM (
    'junior', 'senior', 'elite', 'socio_estrategico'
);

-- Estado del proyecto
CREATE TYPE sd_operaciones.estado_proyecto AS ENUM (
    'por_iniciar', 'en_progreso', 'en_revision', 'pausado',
    'completado', 'cancelado', 'en_riesgo'
);

-- Prioridad
CREATE TYPE sd_operaciones.prioridad AS ENUM (
    'critica', 'alta', 'media', 'baja'
);

-- Estado de ticket
CREATE TYPE sd_soporte.estado_ticket AS ENUM (
    'abierto', 'en_progreso', 'esperando_cliente', 'escalado',
    'resuelto', 'cerrado', 'reabierto'
);

-- Tipo de ticket
CREATE TYPE sd_soporte.tipo_ticket AS ENUM (
    'bug', 'consulta_tecnica', 'solicitud_cambio', 'mejora',
    'incidente_critico', 'consulta_comercial', 'facturacion',
    'capacitacion', 'otro'
);

-- ============================================================
-- 3. SCHEMA: sd_core — USUARIOS, RBAC, CONFIGURACIÓN
-- ============================================================

-- Tabla de usuarios internos del sistema
CREATE TABLE sd_core.usuarios (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_usuario          VARCHAR(20) UNIQUE NOT NULL, -- SD-USR-001
    email                   VARCHAR(255) UNIQUE NOT NULL,
    email_verificado        BOOLEAN DEFAULT FALSE,
    password_hash           VARCHAR(255),                -- bcrypt
    nombre                  VARCHAR(100) NOT NULL,
    apellido                VARCHAR(100) NOT NULL,
    nombre_display          VARCHAR(255),
    rol                     sd_core.rol_usuario NOT NULL DEFAULT 'solo_lectura',
    telefono                VARCHAR(30),
    avatar_url              VARCHAR(500),
    zona_horaria            VARCHAR(50) DEFAULT 'America/Bogota',
    idioma                  VARCHAR(10) DEFAULT 'es',
    -- Estado y control de acceso
    estado                  sd_core.estado_generico DEFAULT 'activo',
    activo                  BOOLEAN DEFAULT TRUE,
    ultimo_login            TIMESTAMPTZ,
    sesiones_activas        INTEGER DEFAULT 0,
    intentos_login_fallidos INTEGER DEFAULT 0,
    bloqueado_hasta         TIMESTAMPTZ,
    -- Preferencias y personalización
    preferencias            JSONB DEFAULT '{}',          -- UI settings, notificaciones
    configuracion_crm       JSONB DEFAULT '{}',          -- Pipeline view, filtros guardados
    -- Metas comerciales (si es vendedor / comisionista)
    meta_mensual_cop        DECIMAL(15,2),
    meta_trimestral_cop     DECIMAL(15,2),
    -- Auditoría
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ
);

-- Equipos / departamentos
CREATE TABLE sd_core.equipos (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre              VARCHAR(100) NOT NULL,
    descripcion         TEXT,
    lider_id            UUID REFERENCES sd_core.usuarios(id),
    tipo                VARCHAR(50), -- ventas, operaciones, marketing, soporte, finanzas
    estado              sd_core.estado_generico DEFAULT 'activo',
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sd_core.usuarios_equipos (
    usuario_id  UUID REFERENCES sd_core.usuarios(id) ON DELETE CASCADE,
    equipo_id   UUID REFERENCES sd_core.equipos(id) ON DELETE CASCADE,
    rol_en_equipo VARCHAR(50),
    fecha_ingreso DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY (usuario_id, equipo_id)
);

-- Configuración global del sistema
CREATE TABLE sd_core.configuracion (
    clave       VARCHAR(100) PRIMARY KEY,
    valor       JSONB NOT NULL,
    descripcion TEXT,
    categoria   VARCHAR(50), -- financiero, crm, comisiones, notificaciones
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_by  UUID REFERENCES sd_core.usuarios(id)
);

-- Plantillas de documentos
CREATE TABLE sd_core.plantillas (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tipo        VARCHAR(50) NOT NULL, -- contrato, propuesta, factura, email, whatsapp
    nombre      VARCHAR(255) NOT NULL,
    contenido   TEXT NOT NULL,        -- Handlebars/Mustache template
    variables   JSONB,                -- variables disponibles en la plantilla
    activa      BOOLEAN DEFAULT TRUE,
    version     INTEGER DEFAULT 1,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    created_by  UUID REFERENCES sd_core.usuarios(id)
);

-- Tags globales (etiquetas reutilizables)
CREATE TABLE sd_core.tags (
    id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre  VARCHAR(100) UNIQUE NOT NULL,
    color   VARCHAR(7) DEFAULT '#6B7280',
    icono   VARCHAR(50),
    tipo    VARCHAR(50) -- lead, cliente, servicio, ticket, etc.
);

-- ============================================================
-- 4. SCHEMA: sd_clientes — CLIENTES 360°
-- ============================================================

-- Empresas (puede ser propia o del cliente)
CREATE TABLE sd_clientes.empresas (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_empresa              VARCHAR(20) UNIQUE NOT NULL, -- SD-EMP-001
    -- Identidad legal
    razon_social                VARCHAR(255) NOT NULL,
    nombre_comercial            VARCHAR(255),
    nit                         VARCHAR(30) UNIQUE,
    tipo_personeria             VARCHAR(20) DEFAULT 'juridica', -- natural, juridica
    regimen_tributario          VARCHAR(50), -- simplificado, comun, gran_contribuyente
    codigo_ciiu                 VARCHAR(10), -- actividad económica DANE
    -- Clasificación
    industria                   sd_core.industria,
    sub_industria               VARCHAR(100),
    tamano                      sd_core.tamano_empresa,
    numero_empleados            INTEGER,
    rango_ingresos_anuales      VARCHAR(50), -- para segmentación
    -- Contacto
    email_principal             VARCHAR(255),
    email_facturacion           VARCHAR(255),
    telefono_principal          VARCHAR(30),
    telefono_alternativo        VARCHAR(30),
    whatsapp                    VARCHAR(30),
    sitio_web                   VARCHAR(255),
    -- Ubicación
    pais                        VARCHAR(50) DEFAULT 'Colombia',
    departamento                VARCHAR(100),
    ciudad                      VARCHAR(100),
    direccion_fiscal            TEXT,
    barrio                      VARCHAR(100),
    codigo_postal               VARCHAR(20),
    -- Digital y redes
    linkedin_url                VARCHAR(255),
    instagram_url               VARCHAR(255),
    facebook_url                VARCHAR(255),
    twitter_url                 VARCHAR(255),
    -- Datos de enriquecimiento (API externa)
    enriquecimiento_clearbit    JSONB DEFAULT '{}',
    enriquecimiento_apollo      JSONB DEFAULT '{}',
    tecnologias_detectadas      JSONB DEFAULT '[]', -- stack tecnológico detectado
    -- Relaciones
    empresa_matriz_id           UUID REFERENCES sd_clientes.empresas(id), -- holdings
    -- Metadata
    notas_internas              TEXT,
    estado                      sd_core.estado_generico DEFAULT 'activo',
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id),
    updated_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Contactos (personas físicas)
CREATE TABLE sd_clientes.contactos (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_contacto             VARCHAR(20) UNIQUE NOT NULL, -- SD-CON-001
    empresa_id                  UUID REFERENCES sd_clientes.empresas(id),
    -- Identidad
    nombre                      VARCHAR(100) NOT NULL,
    apellido                    VARCHAR(100),
    nombre_completo             VARCHAR(255),
    documento_tipo              VARCHAR(20), -- cc, ce, pasaporte, nit
    documento_numero            VARCHAR(30),
    -- Cargo y rol
    cargo                       VARCHAR(150),
    departamento                VARCHAR(100),
    nivel_seniority             VARCHAR(50), -- c_level, director, gerente, coordinador, analista, operativo
    es_decisor                  BOOLEAN DEFAULT FALSE,  -- ¿puede firmar contratos?
    es_influenciador            BOOLEAN DEFAULT FALSE,  -- ¿influye en la decisión?
    es_usuario_final            BOOLEAN DEFAULT FALSE,  -- ¿usará el servicio?
    es_pagador                  BOOLEAN DEFAULT FALSE,  -- ¿gestiona el pago?
    -- Contacto
    email_trabajo               VARCHAR(255) UNIQUE NOT NULL,
    email_personal              VARCHAR(255),
    telefono_trabajo            VARCHAR(30),
    telefono_movil              VARCHAR(30),
    whatsapp                    VARCHAR(30),
    extension_telefonica        VARCHAR(10),
    -- Preferencias de contacto
    canal_preferido             sd_core.canal_comunicacion DEFAULT 'email',
    horario_contacto_inicio     TIME,
    horario_contacto_fin        TIME,
    dias_contacto               VARCHAR(50) DEFAULT 'lunes-viernes',
    frecuencia_contacto         VARCHAR(30), -- semanal, quincenal, mensual
    -- Información personal (para personalización)
    fecha_cumpleanos            DATE,
    ciudad_residencia           VARCHAR(100),
    linkedin_url                VARCHAR(255),
    idioma_preferido            VARCHAR(10) DEFAULT 'es',
    -- Lead scoring
    lead_score                  INTEGER DEFAULT 0 CHECK (lead_score BETWEEN 0 AND 100),
    score_engagement            INTEGER DEFAULT 0, -- basado en interacciones
    score_fit                   INTEGER DEFAULT 0, -- encaja con ICP
    score_intent                INTEGER DEFAULT 0, -- señales de intención
    score_calculado_en          TIMESTAMPTZ,
    -- Estado y ciclo de vida
    estado                      sd_core.estado_generico DEFAULT 'activo',
    activo                      BOOLEAN DEFAULT TRUE,
    -- Enriquecimiento
    datos_enriquecidos          JSONB DEFAULT '{}',
    -- Auditoría
    notas_internas              TEXT,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id),
    updated_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Clientes (la cuenta comercial — puede ser empresa o persona natural)
CREATE TABLE sd_clientes.clientes (
    id                              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_cliente                  VARCHAR(20) UNIQUE NOT NULL, -- SD-CLI-001
    -- Vínculos
    empresa_id                      UUID REFERENCES sd_clientes.empresas(id),
    contacto_principal_id           UUID REFERENCES sd_clientes.contactos(id),
    -- Clasificación
    tipo_cliente                    sd_clientes.tipo_cliente NOT NULL DEFAULT 'empresa',
    estado_cliente                  sd_clientes.estado_cliente DEFAULT 'prospecto',
    segmento                        sd_clientes.segmento_cliente DEFAULT 'sin_clasificar',
    -- Responsable comercial
    responsable_comercial_id        UUID REFERENCES sd_core.usuarios(id),
    comisionista_origen_id          UUID, -- FK a sd_comisiones.comisionistas (se agrega después)
    -- Origen y adquisición
    origen_cliente                  sd_comercial.origen_lead,
    canal_adquisicion_detalle       VARCHAR(255),
    campana_origen_id               UUID, -- FK a sd_marketing.campanas
    utm_source                      VARCHAR(100),
    utm_medium                      VARCHAR(100),
    utm_campaign                    VARCHAR(100),
    utm_content                     VARCHAR(100),
    utm_term                        VARCHAR(100),
    costo_adquisicion               DECIMAL(12,2), -- CAC individual
    -- Fechas del ciclo de vida
    fecha_primer_contacto           DATE,
    fecha_calificacion              DATE,
    fecha_primera_propuesta         DATE,
    fecha_conversion                DATE,       -- lead → cliente
    fecha_primer_pago               DATE,
    fecha_ultimo_pago               DATE,
    fecha_ultimo_contacto           DATE,
    fecha_ultimo_login_portal       TIMESTAMPTZ,
    -- Métricas calculadas (actualizadas por trigger/job)
    ltv_realizado                   DECIMAL(15,2) DEFAULT 0, -- ingresos totales cobrados
    ltv_proyectado                  DECIMAL(15,2) DEFAULT 0, -- contratos activos proyectados
    mrr_actual                      DECIMAL(12,2) DEFAULT 0, -- ingreso recurrente mensual
    total_proyectos                 INTEGER DEFAULT 0,
    proyectos_activos               INTEGER DEFAULT 0,
    total_facturas                  INTEGER DEFAULT 0,
    facturas_pagadas                INTEGER DEFAULT 0,
    facturas_vencidas               INTEGER DEFAULT 0,
    dias_promedio_pago              DECIMAL(6,1), -- DSO de este cliente
    dias_en_mora_acumulados         INTEGER DEFAULT 0,
    -- NPS y satisfacción
    nps_score                       INTEGER CHECK (nps_score BETWEEN 0 AND 10),
    nps_categoria                   VARCHAR(20), -- promotor, pasivo, detractor
    csat_promedio                   DECIMAL(3,1),
    ultima_encuesta_nps             DATE,
    -- Churn
    probabilidad_churn              DECIMAL(5,2), -- 0-100%, calculado por modelo
    alerta_churn                    BOOLEAN DEFAULT FALSE,
    fecha_churn                     DATE,
    motivo_churn                    TEXT,
    -- Potencial de crecimiento
    score_upsell                    INTEGER DEFAULT 0, -- potencial de venta adicional
    servicios_recomendados          JSONB DEFAULT '[]',
    presupuesto_estimado            DECIMAL(12,2),
    -- Comunicación y preferencias
    acepta_marketing                BOOLEAN DEFAULT TRUE,
    acepta_whatsapp                 BOOLEAN DEFAULT TRUE,
    acepta_email_comercial          BOOLEAN DEFAULT TRUE,
    idioma_preferido                VARCHAR(10) DEFAULT 'es',
    notas_internas                  TEXT,
    -- Configuración de facturación
    condiciones_pago                VARCHAR(50) DEFAULT 'contado', -- contado, 15d, 30d, 60d
    limite_credito                  DECIMAL(12,2),
    moneda_preferida                sd_core.moneda DEFAULT 'COP',
    -- Datos adicionales libres
    metadatos                       JSONB DEFAULT '{}',
    -- Auditoría
    created_at                      TIMESTAMPTZ DEFAULT NOW(),
    updated_at                      TIMESTAMPTZ DEFAULT NOW(),
    created_by                      UUID REFERENCES sd_core.usuarios(id),
    updated_by                      UUID REFERENCES sd_core.usuarios(id),
    deleted_at                      TIMESTAMPTZ
);

-- Relación muchos a muchos: contactos de un cliente
CREATE TABLE sd_clientes.cliente_contactos (
    cliente_id          UUID REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    contacto_id         UUID REFERENCES sd_clientes.contactos(id) ON DELETE CASCADE,
    rol_en_cuenta       VARCHAR(100),   -- decisor, pagador, técnico, usuario
    es_principal        BOOLEAN DEFAULT FALSE,
    fecha_asociacion    DATE DEFAULT CURRENT_DATE,
    notas               TEXT,
    PRIMARY KEY (cliente_id, contacto_id)
);

-- Tags de clientes
CREATE TABLE sd_clientes.cliente_tags (
    cliente_id  UUID REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    tag_id      UUID REFERENCES sd_core.tags(id) ON DELETE CASCADE,
    added_by    UUID REFERENCES sd_core.usuarios(id),
    added_at    TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (cliente_id, tag_id)
);

-- Documentos asociados al cliente
CREATE TABLE sd_clientes.documentos_cliente (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id      UUID REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    tipo_documento  VARCHAR(50), -- rut, camara_comercio, contrato_marco, nda, otro
    nombre          VARCHAR(255) NOT NULL,
    url_storage     VARCHAR(500) NOT NULL,
    tamano_bytes    INTEGER,
    mime_type       VARCHAR(100),
    checksum        VARCHAR(64),
    notas           TEXT,
    vigente         BOOLEAN DEFAULT TRUE,
    fecha_vencimiento DATE,
    uploaded_at     TIMESTAMPTZ DEFAULT NOW(),
    uploaded_by     UUID REFERENCES sd_core.usuarios(id)
);

-- ============================================================
-- 5. SCHEMA: sd_servicios — CATÁLOGO DE SERVICIOS Y COMBOS
-- ============================================================

CREATE TABLE sd_servicios.categorias (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo      VARCHAR(20) UNIQUE NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    descripcion TEXT,
    icono       VARCHAR(50),
    color       VARCHAR(7),
    orden       INTEGER DEFAULT 0,
    activa      BOOLEAN DEFAULT TRUE
);

CREATE TABLE sd_servicios.servicios (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_servicio             VARCHAR(20) UNIQUE NOT NULL, -- SD-SRV-001
    categoria_id                UUID REFERENCES sd_servicios.categorias(id),
    -- Identidad
    nombre_interno              VARCHAR(255) NOT NULL, -- nombre técnico
    nombre_comercial            VARCHAR(255) NOT NULL, -- nombre de venta
    tagline                     VARCHAR(500),
    descripcion_corta           VARCHAR(500),
    descripcion_completa        TEXT,
    descripcion_tecnica         TEXT,
    -- Pricing
    tipo_cobro                  sd_servicios.tipo_cobro NOT NULL DEFAULT 'unico',
    precio_base_cop             DECIMAL(12,2) NOT NULL,
    precio_minimo_negociacion   DECIMAL(12,2) NOT NULL, -- floor de descuento
    precio_minimo_absoluto      DECIMAL(12,2) NOT NULL, -- nunca por debajo
    precio_sugerido_cop         DECIMAL(12,2),          -- precio recomendado si difiere
    costo_interno_cop           DECIMAL(12,2) NOT NULL, -- costo real de entrega
    iva_aplica                  BOOLEAN DEFAULT TRUE,
    porcentaje_iva              DECIMAL(5,2) DEFAULT 19.00,
    moneda                      sd_core.moneda DEFAULT 'COP',
    -- Comisiones
    tasa_comision_base          DECIMAL(5,2) DEFAULT 10.00,  -- % comisión servicio individual
    tasa_comision_combo         DECIMAL(5,2),               -- % si va en combo con web
    tasa_comision_elite         DECIMAL(5,2),               -- % si va en combo full
    -- Márgenes calculados
    margen_bruto_objetivo       DECIMAL(5,2),
    margen_neto_objetivo        DECIMAL(5,2),
    -- Entregables y alcance
    entregables                 JSONB DEFAULT '[]',  -- lista estructurada
    exclusiones                 JSONB DEFAULT '[]',  -- qué NO incluye
    requisitos_previos          JSONB DEFAULT '[]',  -- qué necesita el cliente antes
    -- Timing
    duracion_estimada_dias      INTEGER,
    duracion_minima_dias        INTEGER,
    duracion_maxima_dias        INTEGER,
    horas_estimadas             DECIMAL(8,2),
    -- Control
    activo                      BOOLEAN DEFAULT TRUE,
    disponible_para_venta       BOOLEAN DEFAULT TRUE,
    requiere_diagnostico_previo BOOLEAN DEFAULT FALSE,
    version                     INTEGER DEFAULT 1,
    version_anterior_id         UUID REFERENCES sd_servicios.servicios(id),
    -- Metadata
    etiquetas_seo               VARCHAR(500),
    faqs                        JSONB DEFAULT '[]',
    casos_de_uso                JSONB DEFAULT '[]',
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Combos de servicios (los 5 combos definidos)
CREATE TABLE sd_servicios.combos (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_combo                VARCHAR(20) UNIQUE NOT NULL, -- SD-CMB-001
    nivel                       sd_servicios.nivel_combo NOT NULL,
    nombre                      VARCHAR(255) NOT NULL,
    tagline                     VARCHAR(500),
    descripcion_comercial       TEXT,
    descripcion_para_comisionista TEXT,
    -- Pricing del combo
    precio_combo_cop            DECIMAL(12,2) NOT NULL,
    descuento_combo_pct         DECIMAL(5,2),           -- % descuento vs precio individual
    precio_referencia_cop       DECIMAL(12,2),          -- suma de servicios individuales
    costo_total_cop             DECIMAL(12,2),          -- suma de costos internos
    -- Comisión del combo
    tasa_comision               DECIMAL(5,2) NOT NULL,  -- 10, 12 o 15
    monto_comision_cop          DECIMAL(12,2),
    -- Margen calculado
    margen_bruto_cop            DECIMAL(12,2),
    -- Soporte recurrente incluido
    incluye_soporte_mensual     BOOLEAN DEFAULT TRUE,
    precio_soporte_mensual_cop  DECIMAL(12,2),
    -- Métricas de negocio del combo
    ltv_proyectado_12m_cop      DECIMAL(12,2), -- precio + 12 meses soporte
    -- Control
    activo                      BOOLEAN DEFAULT TRUE,
    orden_display               INTEGER DEFAULT 0,
    color_display               VARCHAR(7),
    icono                       VARCHAR(50),
    -- Argumentario de ventas
    target_cliente              TEXT,
    pitch_principal             TEXT,
    objeciones_comunes          JSONB DEFAULT '[]',
    respuestas_objeciones       JSONB DEFAULT '[]',
    upsell_natural              TEXT,
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Servicios que componen cada combo (N:M)
CREATE TABLE sd_servicios.combo_servicios (
    combo_id            UUID REFERENCES sd_servicios.combos(id) ON DELETE CASCADE,
    servicio_id         UUID REFERENCES sd_servicios.servicios(id) ON DELETE CASCADE,
    cantidad            INTEGER DEFAULT 1,
    es_servicio_anchor  BOOLEAN DEFAULT FALSE,   -- ej: el web es el anchor
    es_opcional         BOOLEAN DEFAULT FALSE,
    precio_en_combo     DECIMAL(12,2),           -- precio que aporta al combo
    notas               VARCHAR(255),
    PRIMARY KEY (combo_id, servicio_id)
);

-- Historial de precios (para análisis histórico)
CREATE TABLE sd_servicios.historial_precios (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    servicio_id         UUID REFERENCES sd_servicios.servicios(id),
    combo_id            UUID REFERENCES sd_servicios.combos(id),
    precio_anterior     DECIMAL(12,2),
    precio_nuevo        DECIMAL(12,2),
    razon_cambio        TEXT,
    efectivo_desde      DATE NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID REFERENCES sd_core.usuarios(id)
);

-- ============================================================
-- 6. SCHEMA: sd_comercial — LEADS, PIPELINE, ACTIVIDADES
-- ============================================================

-- Leads (registros crudos antes de calificar)
CREATE TABLE sd_comercial.leads (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_lead                 VARCHAR(20) UNIQUE NOT NULL, -- SD-LED-001
    -- Datos básicos
    nombre                      VARCHAR(100),
    apellido                    VARCHAR(100),
    email                       VARCHAR(255),
    telefono                    VARCHAR(30),
    whatsapp                    VARCHAR(30),
    empresa_nombre              VARCHAR(255),
    cargo                       VARCHAR(150),
    sitio_web                   VARCHAR(255),
    -- Origen y tracking completo
    origen                      sd_comercial.origen_lead,
    origen_detalle              VARCHAR(255),     -- ej: nombre del evento, URL exacta
    canal_entrada               VARCHAR(100),     -- formulario, whatsapp, linkedin, etc.
    pagina_aterrizaje           VARCHAR(500),     -- URL donde llegó
    referrer_url                VARCHAR(500),
    utm_source                  VARCHAR(100),
    utm_medium                  VARCHAR(100),
    utm_campaign                VARCHAR(100),
    utm_content                 VARCHAR(100),
    utm_term                    VARCHAR(100),
    gclid                       VARCHAR(255),     -- Google Click ID
    fbclid                      VARCHAR(255),     -- Facebook Click ID
    ip_address                  INET,
    user_agent                  TEXT,
    dispositivo                 VARCHAR(50),      -- desktop, mobile, tablet
    pais_deteccion              VARCHAR(50),
    ciudad_deteccion            VARCHAR(100),
    -- Datos de intención
    servicio_interesado         VARCHAR(255),     -- qué servicio mencionó
    combo_interesado_id         UUID REFERENCES sd_servicios.combos(id),
    presupuesto_declarado       DECIMAL(12,2),
    timeframe_declarado         VARCHAR(100),     -- "en 1 mes", "en el Q3", etc.
    mensaje_inicial             TEXT,
    necesidades_declaradas      TEXT,
    -- Calificación
    etapa                       sd_comercial.etapa_pipeline DEFAULT 'nuevo',
    calificado                  BOOLEAN DEFAULT FALSE,
    fecha_calificacion          TIMESTAMPTZ,
    razon_descarte              sd_comercial.razon_perdida,
    razon_descarte_detalle      TEXT,
    -- Scores
    score_total                 INTEGER DEFAULT 0,
    score_fit                   INTEGER DEFAULT 0,    -- encaja con ICP
    score_intent                INTEGER DEFAULT 0,    -- urgencia / señales
    score_budget                INTEGER DEFAULT 0,    -- tiene presupuesto
    score_authority             INTEGER DEFAULT 0,    -- puede decidir
    score_ia                    INTEGER DEFAULT 0,    -- score calculado por IA
    score_ia_razon              TEXT,
    -- Asignación
    comisionista_id             UUID, -- FK a comisionistas
    responsable_interno_id      UUID REFERENCES sd_core.usuarios(id),
    fecha_asignacion            TIMESTAMPTZ,
    asignado_por_id             UUID REFERENCES sd_core.usuarios(id),
    -- Conversión
    convertido_a_oportunidad    BOOLEAN DEFAULT FALSE,
    oportunidad_id              UUID,   -- FK a oportunidades
    fecha_conversion            TIMESTAMPTZ,
    -- Respuesta y velocidad
    fecha_primer_contacto_real  TIMESTAMPTZ,
    tiempo_respuesta_minutos    INTEGER,          -- Lead Response Time
    intentos_contacto           INTEGER DEFAULT 0,
    ultimo_intento_contacto     TIMESTAMPTZ,
    -- Metadatos del formulario
    datos_formulario_raw        JSONB DEFAULT '{}', -- payload completo del form
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Oportunidades (leads calificados en proceso de venta)
CREATE TABLE sd_comercial.oportunidades (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_oportunidad          VARCHAR(20) UNIQUE NOT NULL, -- SD-OPP-001
    -- Vínculos
    lead_id                     UUID REFERENCES sd_comercial.leads(id),
    cliente_id                  UUID REFERENCES sd_clientes.clientes(id),
    contacto_principal_id       UUID REFERENCES sd_clientes.contactos(id),
    -- Identidad
    nombre_oportunidad          VARCHAR(255) NOT NULL,
    descripcion                 TEXT,
    -- Servicio / combo de interés
    tipo_venta                  VARCHAR(20) DEFAULT 'combo', -- individual, combo
    servicio_id                 UUID REFERENCES sd_servicios.servicios(id),
    combo_id                    UUID REFERENCES sd_servicios.combos(id),
    -- Pricing de la oportunidad
    valor_estimado_cop          DECIMAL(12,2),
    valor_propuesto_cop         DECIMAL(12,2),     -- valor en propuesta enviada
    descuento_aplicado_pct      DECIMAL(5,2) DEFAULT 0,
    valor_final_cop             DECIMAL(12,2),     -- valor cerrado
    moneda                      sd_core.moneda DEFAULT 'COP',
    -- Pipeline
    etapa                       sd_comercial.etapa_pipeline DEFAULT 'calificado',
    etapa_anterior              sd_comercial.etapa_pipeline,
    fecha_cambio_etapa          TIMESTAMPTZ,
    probabilidad_cierre_pct     DECIMAL(5,2) DEFAULT 25,
    -- Timing
    fecha_apertura              DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_cierre_estimada       DATE,
    fecha_cierre_real           DATE,
    ciclo_venta_dias            INTEGER GENERATED ALWAYS AS (
        CASE WHEN fecha_cierre_real IS NOT NULL
             THEN (fecha_cierre_real - fecha_apertura)
             ELSE NULL END
    ) STORED,
    -- Resultado
    ganada                      BOOLEAN,
    razon_perdida               sd_comercial.razon_perdida,
    razon_perdida_detalle       TEXT,
    competidor_ganador          VARCHAR(255),
    precio_competidor           DECIMAL(12,2),
    -- Responsabilidades
    comisionista_id             UUID,  -- FK a comisionistas
    responsable_interno_id      UUID REFERENCES sd_core.usuarios(id),
    revisor_id                  UUID REFERENCES sd_core.usuarios(id),
    -- Propuesta
    propuesta_enviada           BOOLEAN DEFAULT FALSE,
    fecha_propuesta_enviada     TIMESTAMPTZ,
    propuesta_vista             BOOLEAN DEFAULT FALSE,
    fecha_propuesta_vista       TIMESTAMPTZ,
    veces_vista_propuesta       INTEGER DEFAULT 0,
    url_propuesta               VARCHAR(500),
    -- Contrato
    contrato_id                 UUID,  -- FK a contratos
    -- Competencia
    hay_competidores            BOOLEAN DEFAULT FALSE,
    competidores_identificados  JSONB DEFAULT '[]',
    -- Notas y contexto
    notas_internas              TEXT,
    factores_de_decision        JSONB DEFAULT '[]',
    proximos_pasos              TEXT,
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id),
    updated_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Historial de cambios de etapa del pipeline
CREATE TABLE sd_comercial.historial_pipeline (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id) ON DELETE CASCADE,
    etapa_anterior      sd_comercial.etapa_pipeline,
    etapa_nueva         sd_comercial.etapa_pipeline NOT NULL,
    dias_en_etapa       INTEGER,             -- cuántos días estuvo en la etapa anterior
    motivo_cambio       TEXT,
    cambiado_por        UUID REFERENCES sd_core.usuarios(id),
    changed_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Actividades CRM (todo contacto o acción registrada)
CREATE TABLE sd_comercial.actividades (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Vínculos (puede relacionarse con lead, oportunidad, cliente o contacto)
    lead_id                     UUID REFERENCES sd_comercial.leads(id),
    oportunidad_id              UUID REFERENCES sd_comercial.oportunidades(id),
    cliente_id                  UUID REFERENCES sd_clientes.clientes(id),
    contacto_id                 UUID REFERENCES sd_clientes.contactos(id),
    -- Tipo
    tipo                        sd_comercial.tipo_actividad NOT NULL,
    resultado                   sd_comercial.resultado_actividad,
    sentimiento_percibido       sd_core.sentimiento,
    -- Contenido
    titulo                      VARCHAR(255),
    descripcion                 TEXT,
    notas_privadas              TEXT,           -- solo visibles internamente
    -- Timing
    fecha_actividad             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duracion_minutos            INTEGER,
    fecha_proxima_accion        TIMESTAMPTZ,
    tipo_proxima_accion         VARCHAR(100),
    -- Responsable
    realizada_por               UUID REFERENCES sd_core.usuarios(id),
    comisionista_id             UUID,
    -- Adjuntos y multimedia
    grabacion_url               VARCHAR(500),   -- grabación de llamada
    transcripcion               TEXT,           -- transcripción de llamada/reunión
    adjuntos                    JSONB DEFAULT '[]',
    -- Canal y metadata
    canal                       sd_core.canal_comunicacion,
    herramienta_usada           VARCHAR(100),   -- Zoom, Teams, WhatsApp, etc.
    -- IA y análisis
    analisis_ia                 JSONB DEFAULT '{}', -- análisis de sentimiento, keywords, etc.
    temas_detectados            JSONB DEFAULT '[]',
    objeciones_detectadas       JSONB DEFAULT '[]',
    compromisos_detectados      JSONB DEFAULT '[]',
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Tareas del CRM
CREATE TABLE sd_comercial.tareas_crm (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo              VARCHAR(255) NOT NULL,
    descripcion         TEXT,
    tipo                VARCHAR(50), -- llamada, email, reunion, seguimiento, propuesta, otro
    prioridad           sd_operaciones.prioridad DEFAULT 'media',
    -- Vínculos
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id),
    contacto_id         UUID REFERENCES sd_clientes.contactos(id),
    -- Responsable y asignación
    asignada_a          UUID REFERENCES sd_core.usuarios(id) NOT NULL,
    creada_por          UUID REFERENCES sd_core.usuarios(id) NOT NULL,
    -- Timing
    fecha_vencimiento   TIMESTAMPTZ NOT NULL,
    fecha_completada    TIMESTAMPTZ,
    recordatorio_en     TIMESTAMPTZ,
    -- Estado
    completada          BOOLEAN DEFAULT FALSE,
    cancelada           BOOLEAN DEFAULT FALSE,
    notas_cierre        TEXT,
    -- Auditoría
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. SCHEMA: sd_comisiones — COMISIONISTAS Y MOTOR DE COMISIONES
-- ============================================================

CREATE TABLE sd_comisiones.comisionistas (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_comisionista         VARCHAR(20) UNIQUE NOT NULL, -- SD-COM-001
    usuario_id                  UUID REFERENCES sd_core.usuarios(id), -- si tiene acceso al sistema
    -- Identidad
    tipo                        sd_comisiones.tipo_comisionista NOT NULL DEFAULT 'externo_independiente',
    nivel                       sd_comisiones.nivel_comisionista DEFAULT 'junior',
    nombre                      VARCHAR(100) NOT NULL,
    apellido                    VARCHAR(100) NOT NULL,
    nombre_completo             VARCHAR(255) GENERATED ALWAYS AS (nombre || ' ' || apellido) STORED,
    -- Documentación
    tipo_documento              VARCHAR(20) DEFAULT 'cc', -- cc, ce, pasaporte, nit
    numero_documento            VARCHAR(30) NOT NULL,
    -- Contacto
    email                       VARCHAR(255) UNIQUE NOT NULL,
    telefono                    VARCHAR(30),
    whatsapp                    VARCHAR(30),
    ciudad                      VARCHAR(100),
    departamento                VARCHAR(100),
    -- Datos de pago
    banco                       VARCHAR(100),
    tipo_cuenta                 VARCHAR(30),    -- ahorros, corriente
    numero_cuenta               VARCHAR(50),    -- ENCRIPTADO en producción
    titular_cuenta              VARCHAR(255),
    nit_facturacion             VARCHAR(30),    -- si factura como empresa
    -- Acuerdo comercial
    estado                      sd_core.estado_generico DEFAULT 'activo',
    activo                      BOOLEAN DEFAULT TRUE,
    fecha_inicio_relacion       DATE DEFAULT CURRENT_DATE,
    fecha_fin_relacion          DATE,
    contrato_firmado            BOOLEAN DEFAULT FALSE,
    url_contrato                VARCHAR(500),
    -- Tasas de comisión (pueden diferir de las base del servicio)
    tasa_individual_override    DECIMAL(5,2),   -- si tiene tasa diferente (null = usa la base)
    tasa_combo_override         DECIMAL(5,2),
    tasa_elite_override         DECIMAL(5,2),
    -- Territorio / segmento asignado
    territorio                  VARCHAR(255),
    industrias_asignadas        JSONB DEFAULT '[]',
    cuentas_asignadas           JSONB DEFAULT '[]',  -- clientes específicos asignados
    -- Métricas acumuladas (actualizadas por trigger)
    leads_registrados           INTEGER DEFAULT 0,
    leads_convertidos           INTEGER DEFAULT 0,
    tasa_conversion             DECIMAL(5,2) DEFAULT 0,
    ventas_total_cop            DECIMAL(15,2) DEFAULT 0,
    ticket_promedio_cop         DECIMAL(12,2) DEFAULT 0,
    comisiones_generadas_cop    DECIMAL(15,2) DEFAULT 0,
    comisiones_pagadas_cop      DECIMAL(15,2) DEFAULT 0,
    comisiones_pendientes_cop   DECIMAL(15,2) GENERATED ALWAYS AS (comisiones_generadas_cop - comisiones_pagadas_cop) STORED,
    -- Metas
    meta_mensual_ventas_cop     DECIMAL(12,2),
    meta_mensual_leads          INTEGER,
    -- Notas
    notas_internas              TEXT,
    perfil_publico              TEXT,           -- descripción para mostrar internamente
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Foreign keys diferidas (relación comisionistas ↔ leads y clientes)
ALTER TABLE sd_comercial.leads
    ADD CONSTRAINT fk_lead_comisionista
    FOREIGN KEY (comisionista_id) REFERENCES sd_comisiones.comisionistas(id);

ALTER TABLE sd_comercial.oportunidades
    ADD CONSTRAINT fk_opp_comisionista
    FOREIGN KEY (comisionista_id) REFERENCES sd_comisiones.comisionistas(id);

ALTER TABLE sd_clientes.clientes
    ADD CONSTRAINT fk_cliente_comisionista_origen
    FOREIGN KEY (comisionista_origen_id) REFERENCES sd_comisiones.comisionistas(id);

-- Planes de comisión (configurable por servicio/combo y nivel)
CREATE TABLE sd_comisiones.planes_comision (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre                  VARCHAR(100) NOT NULL,
    descripcion             TEXT,
    -- Tipo de plan
    aplica_a                VARCHAR(20) NOT NULL, -- 'servicio_individual', 'combo_web', 'combo_full'
    -- Tasas
    tasa_base               DECIMAL(5,2) NOT NULL,  -- % de comisión
    -- Condiciones de activación
    condicion_activacion    TEXT,  -- descripción legible de cuándo aplica
    requiere_web            BOOLEAN DEFAULT FALSE,
    requiere_ia_o_crm       BOOLEAN DEFAULT FALSE,
    monto_minimo_venta      DECIMAL(12,2),          -- mínimo para aplicar
    -- Vigencia
    activo                  BOOLEAN DEFAULT TRUE,
    vigente_desde           DATE DEFAULT CURRENT_DATE,
    vigente_hasta           DATE,
    -- Auditoría
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID REFERENCES sd_core.usuarios(id)
);

-- Tasas de comisión por servicio (granularidad máxima)
CREATE TABLE sd_comisiones.tasas_por_servicio (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    servicio_id         UUID REFERENCES sd_servicios.servicios(id),
    combo_id            UUID REFERENCES sd_servicios.combos(id),
    nivel_comisionista  sd_comisiones.nivel_comisionista,  -- null = aplica a todos
    comisionista_id     UUID REFERENCES sd_comisiones.comisionistas(id), -- null = aplica a todos
    tasa_pct            DECIMAL(5,2) NOT NULL,
    base_calculo        VARCHAR(20) DEFAULT 'precio_base', -- precio_base, precio_final, valor_neto
    notas               TEXT,
    activa              BOOLEAN DEFAULT TRUE,
    vigente_desde       DATE DEFAULT CURRENT_DATE,
    vigente_hasta       DATE,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT check_servicio_o_combo CHECK (
        (servicio_id IS NOT NULL AND combo_id IS NULL) OR
        (servicio_id IS NULL AND combo_id IS NOT NULL)
    )
);

-- ===== EL MOTOR: Tabla de Liquidaciones =====
-- Esta tabla es el corazón del sistema de comisiones.
-- Se genera automáticamente via TRIGGER cuando se confirma un pago.
CREATE TABLE sd_comisiones.liquidaciones (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_liquidacion          VARCHAR(30) UNIQUE NOT NULL, -- SD-LIQ-001
    -- Trigger: el pago que origina esta liquidación
    pago_id                     UUID NOT NULL, -- FK a sd_financiero.pagos
    -- Cadena de referencias
    factura_id                  UUID NOT NULL, -- FK a sd_financiero.facturas
    contrato_id                 UUID NOT NULL, -- FK a sd_contratos.contratos
    cliente_id                  UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    oportunidad_id              UUID REFERENCES sd_comercial.oportunidades(id),
    servicio_id                 UUID REFERENCES sd_servicios.servicios(id),
    combo_id                    UUID REFERENCES sd_servicios.combos(id),
    -- Comisionista acreedor
    comisionista_id             UUID NOT NULL REFERENCES sd_comisiones.comisionistas(id),
    plan_comision_id            UUID REFERENCES sd_comisiones.planes_comision(id),
    -- Montos del pago del cliente
    monto_pago_cliente_bruto    DECIMAL(15,2) NOT NULL,  -- con IVA
    monto_pago_cliente_neto     DECIMAL(15,2) NOT NULL,  -- sin IVA (BASE del cálculo)
    descuento_aplicado_pct      DECIMAL(5,2) DEFAULT 0,
    monto_con_descuento         DECIMAL(15,2) NOT NULL,  -- base real de comisión
    -- Cálculo de comisión
    tasa_comision_aplicada      DECIMAL(5,2) NOT NULL,
    tipo_comision               VARCHAR(30) NOT NULL, -- 'individual_10', 'combo_web_12', 'combo_full_15'
    base_calculo_comision       DECIMAL(15,2) NOT NULL, -- sobre qué monto se calcula
    comision_bruta              DECIMAL(15,2) NOT NULL, -- antes de retenciones
    -- Retenciones e impuestos
    retencion_fuente_pct        DECIMAL(5,2) DEFAULT 0,
    retencion_ica_pct           DECIMAL(5,2) DEFAULT 0,
    retencion_iva_pct           DECIMAL(5,2) DEFAULT 0,
    total_retenciones           DECIMAL(15,2) DEFAULT 0,
    comision_neta               DECIMAL(15,2) NOT NULL, -- LO QUE SE LE PAGA AL COMISIONISTA
    -- Estado de la liquidación
    estado                      sd_comisiones.estado_liquidacion DEFAULT 'generada',
    -- Fechas clave del ciclo
    fecha_devengamiento         DATE NOT NULL,           -- cuando el cliente pagó
    fecha_aprobacion            TIMESTAMPTZ,
    fecha_pago_comision         DATE,                    -- cuando SD le pagó
    dias_en_estado_actual       INTEGER,
    -- Pago al comisionista
    metodo_pago_comision        sd_financiero.metodo_pago,
    referencia_pago_comision    VARCHAR(100),            -- # transferencia
    comprobante_pago_url        VARCHAR(500),
    banco_destino               VARCHAR(100),
    cuenta_destino              VARCHAR(50),             -- últimos 4 dígitos
    -- Aprobación
    aprobado_por                UUID REFERENCES sd_core.usuarios(id),
    rechazado_por               UUID REFERENCES sd_core.usuarios(id),
    motivo_rechazo              TEXT,
    -- Ajustes y disputas
    es_ajuste                   BOOLEAN DEFAULT FALSE,
    liquidacion_original_id     UUID REFERENCES sd_comisiones.liquidaciones(id),
    motivo_ajuste               TEXT,
    -- Notas
    notas_internas              TEXT,
    notas_para_comisionista     TEXT,
    -- Auditoría
    generada_automaticamente    BOOLEAN DEFAULT TRUE,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)  -- null si fue trigger
);

-- Pagos a comisionistas (el pago real de múltiples liquidaciones)
CREATE TABLE sd_comisiones.pagos_comisionistas (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_pago                 VARCHAR(30) UNIQUE NOT NULL, -- SD-PCO-001
    comisionista_id             UUID NOT NULL REFERENCES sd_comisiones.comisionistas(id),
    -- Montos
    monto_total_cop             DECIMAL(15,2) NOT NULL,
    cantidad_liquidaciones      INTEGER NOT NULL,
    -- Detalles del pago
    metodo_pago                 sd_financiero.metodo_pago NOT NULL,
    banco_origen                VARCHAR(100),
    banco_destino               VARCHAR(100),
    numero_cuenta_destino       VARCHAR(50),
    referencia_bancaria         VARCHAR(100),
    comprobante_url             VARCHAR(500),
    -- Estado
    estado                      VARCHAR(30) DEFAULT 'procesado', -- procesado, rechazado, revertido
    -- Período
    periodo_desde               DATE,
    periodo_hasta               DATE,
    -- Notas
    notas                       TEXT,
    -- Auditoría
    fecha_pago                  DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Relación pago de comisionista ↔ liquidaciones
CREATE TABLE sd_comisiones.pago_liquidaciones (
    pago_id         UUID REFERENCES sd_comisiones.pagos_comisionistas(id) ON DELETE CASCADE,
    liquidacion_id  UUID REFERENCES sd_comisiones.liquidaciones(id) ON DELETE CASCADE,
    monto_incluido  DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (pago_id, liquidacion_id)
);

-- ============================================================
-- 8. SCHEMA: sd_contratos — CONTRATOS
-- ============================================================

CREATE TABLE sd_contratos.contratos (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_contrato             VARCHAR(30) UNIQUE NOT NULL, -- SD-CTR-001
    -- Vínculos
    cliente_id                  UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    oportunidad_id              UUID REFERENCES sd_comercial.oportunidades(id),
    contacto_firmante_id        UUID REFERENCES sd_clientes.contactos(id),
    comisionista_id             UUID REFERENCES sd_comisiones.comisionistas(id),
    responsable_interno_id      UUID REFERENCES sd_core.usuarios(id),
    -- Tipo y alcance
    tipo                        sd_contratos.tipo_contrato NOT NULL,
    nombre_proyecto             VARCHAR(255) NOT NULL,
    descripcion_alcance         TEXT,
    -- Servicios contratados
    combo_id                    UUID REFERENCES sd_servicios.combos(id),
    -- Pricing
    moneda                      sd_core.moneda DEFAULT 'COP',
    valor_total_cop             DECIMAL(15,2) NOT NULL,
    valor_descuento_cop         DECIMAL(12,2) DEFAULT 0,
    valor_final_cop             DECIMAL(15,2) NOT NULL,
    iva_cop                     DECIMAL(12,2),
    valor_con_iva_cop           DECIMAL(15,2),
    -- Condiciones de pago
    condicion_pago              VARCHAR(50) NOT NULL, -- contado, 50-50, 70-30, mensual
    anticipo_pct                DECIMAL(5,2) DEFAULT 0,
    anticipo_cop                DECIMAL(12,2),
    -- Recurrencia (si aplica)
    es_recurrente               BOOLEAN DEFAULT FALSE,
    monto_mensual_cop           DECIMAL(12,2),
    dia_cobro                   INTEGER CHECK (dia_cobro BETWEEN 1 AND 31),
    -- Vigencia
    fecha_firma                 DATE,
    fecha_inicio_servicio       DATE,
    fecha_fin_servicio          DATE,
    duracion_meses              INTEGER,
    -- Renovación
    auto_renovacion             BOOLEAN DEFAULT FALSE,
    dias_aviso_renovacion       INTEGER DEFAULT 30,
    fecha_prox_renovacion       DATE,
    renovado_en_contrato_id     UUID REFERENCES sd_contratos.contratos(id),
    -- Estado
    estado                      sd_contratos.estado_contrato DEFAULT 'borrador',
    fecha_envio_firma           TIMESTAMPTZ,
    fecha_firma_cliente         TIMESTAMPTZ,
    plataforma_firma            VARCHAR(50),   -- docusign, firma.ec, hellosign, manual
    id_firma_externa            VARCHAR(255),  -- ID en la plataforma de firma
    url_contrato_firmado        VARCHAR(500),
    -- Scope creep tracking
    addendums                   JSONB DEFAULT '[]',   -- cambios de alcance aprobados
    horas_extra_autorizadas     DECIMAL(8,2) DEFAULT 0,
    valor_addendums_cop         DECIMAL(12,2) DEFAULT 0,
    -- SLA
    sla_tiempo_respuesta_hrs    INTEGER DEFAULT 24,
    sla_tiempo_resolucion_hrs   INTEGER DEFAULT 72,
    penalidad_incumplimiento    TEXT,
    -- Notas
    notas_internas              TEXT,
    condiciones_especiales      TEXT,
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Servicios específicos de un contrato (detalle)
CREATE TABLE sd_contratos.contrato_servicios (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contrato_id         UUID REFERENCES sd_contratos.contratos(id) ON DELETE CASCADE,
    servicio_id         UUID REFERENCES sd_servicios.servicios(id),
    cantidad            INTEGER DEFAULT 1,
    precio_unitario_cop DECIMAL(12,2) NOT NULL,
    precio_total_cop    DECIMAL(12,2) NOT NULL,
    descuento_pct       DECIMAL(5,2) DEFAULT 0,
    notas               VARCHAR(500),
    completado          BOOLEAN DEFAULT FALSE,
    fecha_entrega       DATE
);

-- (Bloque de FK diferidas movido más abajo para evitar error de dependencia)

-- ============================================================
-- 9. SCHEMA: sd_financiero — FACTURAS, PAGOS, CxC
-- ============================================================

CREATE TABLE sd_financiero.facturas (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_factura              VARCHAR(30) UNIQUE NOT NULL, -- SD-FAC-001
    numero_factura              SERIAL,                      -- número consecutivo
    -- Vínculos
    cliente_id                  UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    contrato_id                 UUID REFERENCES sd_contratos.contratos(id),
    -- Estado
    estado                      sd_financiero.estado_factura DEFAULT 'borrador',
    -- Montos
    moneda                      sd_core.moneda DEFAULT 'COP',
    subtotal_cop                DECIMAL(15,2) NOT NULL,
    descuento_cop               DECIMAL(12,2) DEFAULT 0,
    base_iva_cop                DECIMAL(15,2),
    iva_cop                     DECIMAL(12,2) DEFAULT 0,
    retenciones_cop             DECIMAL(12,2) DEFAULT 0,    -- retenciones que aplica el cliente
    total_cop                   DECIMAL(15,2) NOT NULL,
    total_pagado_cop            DECIMAL(15,2) DEFAULT 0,
    saldo_pendiente_cop         DECIMAL(15,2) GENERATED ALWAYS AS (total_cop - total_pagado_cop) STORED,
    -- Fechas
    fecha_emision               DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_vencimiento           DATE NOT NULL,
    fecha_envio_cliente         TIMESTAMPTZ,
    fecha_vista_cliente         TIMESTAMPTZ,
    fecha_primer_pago           DATE,
    fecha_ultimo_pago           DATE,
    fecha_pago_completo         DATE,
    -- Mora
    dias_mora                   INTEGER DEFAULT 0,
    interes_mora_cop            DECIMAL(12,2) DEFAULT 0,
    -- Recordatorios enviados
    recordatorios_enviados      INTEGER DEFAULT 0,
    ultimo_recordatorio         TIMESTAMPTZ,
    -- Delivery
    entregada_email             BOOLEAN DEFAULT FALSE,
    entregada_whatsapp          BOOLEAN DEFAULT FALSE,
    url_factura_pdf             VARCHAR(500),
    id_factura_electronica      VARCHAR(100),  -- si hay facturación electrónica
    cufe                        VARCHAR(255),  -- Código Único de Factura Electrónica (DIAN)
    -- Notas
    notas_factura               TEXT,          -- visible al cliente
    notas_internas              TEXT,
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Ítems de la factura
CREATE TABLE sd_financiero.factura_items (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    factura_id          UUID REFERENCES sd_financiero.facturas(id) ON DELETE CASCADE,
    servicio_id         UUID REFERENCES sd_servicios.servicios(id),
    descripcion         VARCHAR(500) NOT NULL,
    cantidad            DECIMAL(8,2) DEFAULT 1,
    precio_unitario     DECIMAL(12,2) NOT NULL,
    descuento_pct       DECIMAL(5,2) DEFAULT 0,
    subtotal            DECIMAL(12,2) NOT NULL,
    iva_pct             DECIMAL(5,2) DEFAULT 19,
    iva_monto           DECIMAL(12,2),
    total               DECIMAL(12,2) NOT NULL,
    orden               INTEGER DEFAULT 0
);

-- PAGOS (el evento financiero más importante)
CREATE TABLE sd_financiero.pagos (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_pago                 VARCHAR(30) UNIQUE NOT NULL, -- SD-PAG-001
    -- Vínculos
    factura_id                  UUID REFERENCES sd_financiero.facturas(id) NOT NULL,
    cliente_id                  UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    contrato_id                 UUID REFERENCES sd_contratos.contratos(id),
    -- Monto
    moneda                      sd_core.moneda DEFAULT 'COP',
    monto_cop                   DECIMAL(15,2) NOT NULL,
    monto_iva_incluido          DECIMAL(15,2),             -- monto total con IVA
    monto_base_sin_iva          DECIMAL(15,2),             -- para cálculo de comisión
    -- Método y datos del pago
    metodo_pago                 sd_financiero.metodo_pago NOT NULL,
    pasarela_pago               VARCHAR(50),               -- wompi, payu, stripe, manual
    id_transaccion_pasarela     VARCHAR(255),              -- ID en la pasarela
    banco_origen                VARCHAR(100),              -- banco del cliente
    numero_referencia           VARCHAR(100),              -- referencia de la transferencia
    ultimos_digitos_tarjeta     VARCHAR(4),
    -- Estado
    estado                      sd_financiero.estado_pago DEFAULT 'pendiente',
    -- Fechas
    fecha_pago                  DATE NOT NULL,
    fecha_confirmacion          TIMESTAMPTZ,
    fecha_conciliacion          TIMESTAMPTZ,
    -- Conciliación
    conciliado                  BOOLEAN DEFAULT FALSE,
    conciliado_por              UUID REFERENCES sd_core.usuarios(id),
    banco_extracto_linea        VARCHAR(255),              -- referencia del extracto
    -- Comprobante
    comprobante_url             VARCHAR(500),
    -- Es primer pago (importante para trigger de comisión)
    es_primer_pago_contrato     BOOLEAN DEFAULT FALSE,
    numero_cuota                INTEGER,                   -- si es pago en cuotas
    -- Webhook data (si viene de pasarela)
    webhook_payload             JSONB DEFAULT '{}',
    -- Notas
    notas                       TEXT,
    -- Auditoría
    registrado_manualmente      BOOLEAN DEFAULT FALSE,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- FK diferidas para liquidaciones (Movido aquí para asegurar que 'pagos' y 'facturas' existan)
ALTER TABLE sd_comisiones.liquidaciones
    ADD CONSTRAINT fk_liq_pago       FOREIGN KEY (pago_id)    REFERENCES sd_financiero.pagos(id)        DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE sd_comisiones.liquidaciones
    ADD CONSTRAINT fk_liq_factura    FOREIGN KEY (factura_id) REFERENCES sd_financiero.facturas(id)     DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE sd_comisiones.liquidaciones
    ADD CONSTRAINT fk_liq_contrato   FOREIGN KEY (contrato_id) REFERENCES sd_contratos.contratos(id)   DEFERRABLE INITIALLY DEFERRED;


-- Cuentas por cobrar (vista resumida para gestión de cartera)
CREATE TABLE sd_financiero.cuentas_por_cobrar (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id              UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    factura_id              UUID NOT NULL REFERENCES sd_financiero.facturas(id) UNIQUE,
    -- Montos
    monto_original_cop      DECIMAL(15,2) NOT NULL,
    monto_pagado_cop        DECIMAL(15,2) DEFAULT 0,
    saldo_cop               DECIMAL(15,2) NOT NULL,
    -- Antigüedad de cartera
    fecha_vencimiento       DATE NOT NULL,
    dias_vencida            INTEGER DEFAULT 0,
    rango_antiguedad        VARCHAR(20),  -- al_dia, 1_30, 31_60, 61_90, mas_90
    -- Estado de gestión
    en_cobro_juridico       BOOLEAN DEFAULT FALSE,
    castigada               BOOLEAN DEFAULT FALSE,
    -- Auditoría
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 10. SCHEMA: sd_operaciones — PROYECTOS Y ENTREGA
-- ============================================================

CREATE TABLE sd_operaciones.proyectos (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_proyecto             VARCHAR(20) UNIQUE NOT NULL, -- SD-PRY-001
    -- Vínculos
    contrato_id                 UUID REFERENCES sd_contratos.contratos(id),
    cliente_id                  UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    combo_id                    UUID REFERENCES sd_servicios.combos(id),
    -- Identidad
    nombre                      VARCHAR(255) NOT NULL,
    descripcion                 TEXT,
    tipo_proyecto               VARCHAR(50), -- implementacion, consultoria, desarrollo, soporte
    -- Equipo
    project_manager_id          UUID REFERENCES sd_core.usuarios(id),
    lider_tecnico_id            UUID REFERENCES sd_core.usuarios(id),
    -- Estado y prioridad
    estado                      sd_operaciones.estado_proyecto DEFAULT 'por_iniciar',
    prioridad                   sd_operaciones.prioridad DEFAULT 'media',
    -- Fechas planificadas
    fecha_inicio_planificada    DATE,
    fecha_fin_planificada       DATE,
    -- Fechas reales
    fecha_inicio_real           DATE,
    fecha_fin_real              DATE,
    -- Horas y presupuesto
    horas_estimadas             DECIMAL(8,2),
    horas_reales                DECIMAL(8,2) DEFAULT 0,
    horas_facturables           DECIMAL(8,2) DEFAULT 0,
    porcentaje_avance           DECIMAL(5,2) DEFAULT 0,
    -- Salud del proyecto
    esta_en_riesgo              BOOLEAN DEFAULT FALSE,
    motivo_riesgo               TEXT,
    dias_retraso                INTEGER DEFAULT 0,
    -- Scope creep
    cambios_alcance_aprobados   INTEGER DEFAULT 0,
    horas_scope_creep           DECIMAL(8,2) DEFAULT 0,
    -- Satisfacción
    nps_cierre                  INTEGER,
    csat_cierre                 DECIMAL(3,1),
    testimonial_obtenido        BOOLEAN DEFAULT FALSE,
    testimonial_texto           TEXT,
    caso_exito_publicado        BOOLEAN DEFAULT FALSE,
    -- URLs de trabajo
    url_carpeta_drive           VARCHAR(500),
    url_proyecto_pm             VARCHAR(500),  -- Notion, Jira, etc.
    url_canal_slack             VARCHAR(255),
    -- Notas
    notas_internas              TEXT,
    lecciones_aprendidas        TEXT,
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Registro de tiempo (timetracking)
CREATE TABLE sd_operaciones.timetracking (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proyecto_id         UUID REFERENCES sd_operaciones.proyectos(id) ON DELETE CASCADE,
    usuario_id          UUID REFERENCES sd_core.usuarios(id) NOT NULL,
    servicio_id         UUID REFERENCES sd_servicios.servicios(id),
    -- Tiempo registrado
    fecha               DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_inicio         TIMESTAMPTZ,
    hora_fin            TIMESTAMPTZ,
    horas               DECIMAL(5,2) NOT NULL,
    -- Clasificación
    tipo_trabajo        VARCHAR(50), -- desarrollo, reunion, documentacion, soporte, admin
    facturable          BOOLEAN DEFAULT TRUE,
    aprobado            BOOLEAN DEFAULT FALSE,
    -- Descripción
    descripcion         TEXT NOT NULL,
    tarea_relacionada   VARCHAR(255),
    -- Auditoría
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 11. SCHEMA: sd_marketing — CAMPAÑAS Y TRACKING
-- ============================================================

CREATE TABLE sd_marketing.campanas (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_campana              VARCHAR(20) UNIQUE NOT NULL, -- SD-CAM-001
    nombre                      VARCHAR(255) NOT NULL,
    tipo                        VARCHAR(50), -- email, social_ads, google_ads, contenido, evento, referidos
    objetivo                    VARCHAR(50), -- awareness, leads, conversion, retencion
    -- Audiencia
    segmento_objetivo           TEXT,
    industrias_objetivo         JSONB DEFAULT '[]',
    -- Budget
    presupuesto_cop             DECIMAL(12,2),
    gasto_real_cop              DECIMAL(12,2) DEFAULT 0,
    -- Fechas
    fecha_inicio                DATE,
    fecha_fin                   DATE,
    -- UTMs
    utm_source                  VARCHAR(100),
    utm_medium                  VARCHAR(100),
    utm_campaign                VARCHAR(100),
    -- Métricas (actualizadas por job)
    impresiones                 INTEGER DEFAULT 0,
    clicks                      INTEGER DEFAULT 0,
    ctr                         DECIMAL(6,4) DEFAULT 0,
    leads_generados             INTEGER DEFAULT 0,
    oportunidades_generadas     INTEGER DEFAULT 0,
    ventas_cerradas             INTEGER DEFAULT 0,
    ingresos_atribuidos_cop     DECIMAL(12,2) DEFAULT 0,
    cpl_cop                     DECIMAL(10,2),   -- costo por lead
    cac_cop                     DECIMAL(10,2),   -- costo de adquisición
    roi_pct                     DECIMAL(8,2),
    -- Estado
    estado                      sd_core.estado_generico DEFAULT 'activo',
    notas                       TEXT,
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Eventos de tracking (cada interacción digital)
CREATE TABLE sd_marketing.eventos_tracking (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Identidad del visitante
    session_id      VARCHAR(255),
    visitor_id      VARCHAR(255),   -- anonymous ID antes de convertir
    lead_id         UUID REFERENCES sd_comercial.leads(id),
    cliente_id      UUID REFERENCES sd_clientes.clientes(id),
    -- Evento
    tipo_evento     VARCHAR(100) NOT NULL, -- pageview, click, form_submit, video_play, download, etc.
    url_pagina      VARCHAR(500),
    elemento        VARCHAR(255),   -- botón, formulario, enlace, etc.
    valor           VARCHAR(255),
    -- Atribución
    campana_id      UUID REFERENCES sd_marketing.campanas(id),
    utm_source      VARCHAR(100),
    utm_medium      VARCHAR(100),
    utm_campaign    VARCHAR(100),
    utm_content     VARCHAR(100),
    utm_term        VARCHAR(100),
    -- Metadata técnica
    ip_address      INET,
    user_agent      TEXT,
    dispositivo     VARCHAR(30),
    navegador       VARCHAR(50),
    sistema_operativo VARCHAR(50),
    resolucion      VARCHAR(20),
    pais            VARCHAR(50),
    ciudad          VARCHAR(100),
    -- Contexto
    referrer        VARCHAR(500),
    metadata        JSONB DEFAULT '{}',
    -- Timestamp
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 12. SCHEMA: sd_soporte — TICKETS Y SATISFACCIÓN
-- ============================================================

CREATE TABLE sd_soporte.tickets (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_ticket               VARCHAR(20) UNIQUE NOT NULL, -- SD-TKT-001
    -- Vínculos
    cliente_id                  UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    contacto_id                 UUID REFERENCES sd_clientes.contactos(id),
    proyecto_id                 UUID REFERENCES sd_operaciones.proyectos(id),
    contrato_id                 UUID REFERENCES sd_contratos.contratos(id),
    -- Clasificación
    tipo                        sd_soporte.tipo_ticket NOT NULL,
    prioridad                   sd_operaciones.prioridad NOT NULL DEFAULT 'media',
    estado                      sd_soporte.estado_ticket DEFAULT 'abierto',
    -- Contenido
    titulo                      VARCHAR(500) NOT NULL,
    descripcion                 TEXT NOT NULL,
    pasos_reproduccion          TEXT,
    comportamiento_esperado     TEXT,
    comportamiento_actual       TEXT,
    -- Adjuntos
    adjuntos                    JSONB DEFAULT '[]',
    -- Asignación
    asignado_a                  UUID REFERENCES sd_core.usuarios(id),
    equipo_asignado_id          UUID REFERENCES sd_core.equipos(id),
    -- Escalación
    escalado                    BOOLEAN DEFAULT FALSE,
    nivel_escalacion            INTEGER DEFAULT 0,
    escalado_a                  UUID REFERENCES sd_core.usuarios(id),
    motivo_escalacion           TEXT,
    -- SLA tracking
    sla_respuesta_hrs           INTEGER DEFAULT 24,
    sla_resolucion_hrs          INTEGER DEFAULT 72,
    fecha_limite_respuesta      TIMESTAMPTZ,
    fecha_limite_resolucion     TIMESTAMPTZ,
    sla_respuesta_cumplido      BOOLEAN,
    sla_resolucion_cumplido     BOOLEAN,
    -- Timing
    fecha_apertura              TIMESTAMPTZ DEFAULT NOW(),
    fecha_primer_respuesta      TIMESTAMPTZ,
    tiempo_primera_respuesta_min INTEGER,
    fecha_resolucion            TIMESTAMPTZ,
    tiempo_resolucion_min       INTEGER,
    fecha_cierre                TIMESTAMPTZ,
    -- Canal de entrada
    canal_entrada               sd_core.canal_comunicacion,
    -- Satisfacción post-cierre
    csat_score                  INTEGER CHECK (csat_score BETWEEN 1 AND 5),
    csat_comentario             TEXT,
    csat_respondido_en          TIMESTAMPTZ,
    -- Análisis IA
    categoria_ia                VARCHAR(100),   -- categorización automática por IA
    sentimiento_ia              sd_core.sentimiento,
    solucion_sugerida_ia        TEXT,
    -- Tags
    tags                        JSONB DEFAULT '[]',
    -- Auditoría
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID REFERENCES sd_core.usuarios(id)
);

-- Respuestas a tickets
CREATE TABLE sd_soporte.respuestas_ticket (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id           UUID REFERENCES sd_soporte.tickets(id) ON DELETE CASCADE,
    autor_usuario_id    UUID REFERENCES sd_core.usuarios(id),
    autor_cliente_nombre VARCHAR(255),  -- si responde el cliente directamente
    tipo_respuesta      VARCHAR(30) DEFAULT 'respuesta', -- respuesta, nota_interna, escalacion
    contenido           TEXT NOT NULL,
    adjuntos            JSONB DEFAULT '[]',
    visible_para_cliente BOOLEAN DEFAULT TRUE,
    es_solucion         BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Encuestas de satisfacción (NPS / CSAT)
CREATE TABLE sd_soporte.encuestas_satisfaccion (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tipo                VARCHAR(20) NOT NULL, -- nps, csat, ces
    cliente_id          UUID REFERENCES sd_clientes.clientes(id),
    contacto_id         UUID REFERENCES sd_clientes.contactos(id),
    proyecto_id         UUID REFERENCES sd_operaciones.proyectos(id),
    ticket_id           UUID REFERENCES sd_soporte.tickets(id),
    -- Respuesta
    score               INTEGER,
    comentario          TEXT,
    categoria_nps       VARCHAR(20),  -- promotor (9-10), pasivo (7-8), detractor (0-6)
    -- Canal
    canal_envio         VARCHAR(30),  -- email, whatsapp, en_app
    enviada_en          TIMESTAMPTZ DEFAULT NOW(),
    respondida_en       TIMESTAMPTZ,
    -- Seguimiento
    seguimiento_realizado BOOLEAN DEFAULT FALSE,
    notas_seguimiento   TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 13. SCHEMA: sd_audit — LOG UNIVERSAL DE CAMBIOS
-- ============================================================

CREATE TABLE sd_audit.audit_log (
    id              BIGSERIAL PRIMARY KEY,
    -- Identificación del evento
    tabla_schema    VARCHAR(50) NOT NULL,
    tabla_nombre    VARCHAR(100) NOT NULL,
    operacion       VARCHAR(10) NOT NULL,   -- INSERT, UPDATE, DELETE
    registro_id     UUID,
    -- Usuario
    usuario_id      UUID,
    rol_usuario     VARCHAR(50),
    ip_address      INET,
    user_agent      TEXT,
    -- Datos
    datos_antes     JSONB,                  -- row anterior (UPDATE, DELETE)
    datos_despues   JSONB,                  -- row nueva (INSERT, UPDATE)
    campos_cambiados TEXT[],               -- lista de campos que cambiaron
    -- Contexto
    modulo          VARCHAR(50),
    accion_descripcion TEXT,
    -- Timestamp
    created_at      TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Partición por mes (crear manualmente o con pg_partman)
CREATE TABLE sd_audit.audit_log_2025_01 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE sd_audit.audit_log_2025_02 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE sd_audit.audit_log_2025_03 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE sd_audit.audit_log_2025_04 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE sd_audit.audit_log_2025_05 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE sd_audit.audit_log_2025_06 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE sd_audit.audit_log_2025_07 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE sd_audit.audit_log_2025_08 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE sd_audit.audit_log_2025_09 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE sd_audit.audit_log_2025_10 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE sd_audit.audit_log_2025_11 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE sd_audit.audit_log_2025_12 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE sd_audit.audit_log_2026_01 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE sd_audit.audit_log_2026_02 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE sd_audit.audit_log_2026_03 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE sd_audit.audit_log_2026_04 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE sd_audit.audit_log_2026_05 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE sd_audit.audit_log_2026_06 PARTITION OF sd_audit.audit_log
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

-- ============================================================
-- 14. INDEXES — RENDIMIENTO EN QUERIES ANALÍTICOS
-- ============================================================

-- sd_clientes.clientes
CREATE INDEX idx_clientes_estado ON sd_clientes.clientes(estado_cliente);
CREATE INDEX idx_clientes_segmento ON sd_clientes.clientes(segmento);
CREATE INDEX idx_clientes_comisionista ON sd_clientes.clientes(comisionista_origen_id);
CREATE INDEX idx_clientes_responsable ON sd_clientes.clientes(responsable_comercial_id);
CREATE INDEX idx_clientes_fecha_conv ON sd_clientes.clientes(fecha_conversion);
CREATE INDEX idx_clientes_mrr ON sd_clientes.clientes(mrr_actual);
CREATE INDEX idx_clientes_alerta_churn ON sd_clientes.clientes(alerta_churn) WHERE alerta_churn = TRUE;

-- sd_clientes.contactos
CREATE UNIQUE INDEX idx_contactos_email ON sd_clientes.contactos(email_trabajo);
CREATE INDEX idx_contactos_empresa ON sd_clientes.contactos(empresa_id);
CREATE INDEX idx_contactos_score ON sd_clientes.contactos(lead_score DESC);

-- sd_comercial.leads
CREATE INDEX idx_leads_origen ON sd_comercial.leads(origen);
CREATE INDEX idx_leads_etapa ON sd_comercial.leads(etapa);
CREATE INDEX idx_leads_comisionista ON sd_comercial.leads(comisionista_id);
CREATE INDEX idx_leads_created ON sd_comercial.leads(created_at DESC);
CREATE INDEX idx_leads_email ON sd_comercial.leads(email);
CREATE INDEX idx_leads_score ON sd_comercial.leads(score_total DESC);

-- sd_comercial.oportunidades
CREATE INDEX idx_opp_etapa ON sd_comercial.oportunidades(etapa);
CREATE INDEX idx_opp_cliente ON sd_comercial.oportunidades(cliente_id);
CREATE INDEX idx_opp_comisionista ON sd_comercial.oportunidades(comisionista_id);
CREATE INDEX idx_opp_combo ON sd_comercial.oportunidades(combo_id);
CREATE INDEX idx_opp_ganada ON sd_comercial.oportunidades(ganada);
CREATE INDEX idx_opp_valor ON sd_comercial.oportunidades(valor_final_cop DESC);
CREATE INDEX idx_opp_fecha_cierre ON sd_comercial.oportunidades(fecha_cierre_real);

-- sd_financiero.facturas
CREATE INDEX idx_facturas_cliente ON sd_financiero.facturas(cliente_id);
CREATE INDEX idx_facturas_estado ON sd_financiero.facturas(estado);
CREATE INDEX idx_facturas_vencimiento ON sd_financiero.facturas(fecha_vencimiento);
CREATE INDEX idx_facturas_mora ON sd_financiero.facturas(dias_mora) WHERE dias_mora > 0;
CREATE INDEX idx_facturas_contrato ON sd_financiero.facturas(contrato_id);

-- sd_financiero.pagos
CREATE INDEX idx_pagos_factura ON sd_financiero.pagos(factura_id);
CREATE INDEX idx_pagos_cliente ON sd_financiero.pagos(cliente_id);
CREATE INDEX idx_pagos_estado ON sd_financiero.pagos(estado);
CREATE INDEX idx_pagos_fecha ON sd_financiero.pagos(fecha_pago DESC);
CREATE INDEX idx_pagos_primer_pago ON sd_financiero.pagos(es_primer_pago_contrato) WHERE es_primer_pago_contrato = TRUE;

-- sd_comisiones.liquidaciones
CREATE INDEX idx_liq_comisionista ON sd_comisiones.liquidaciones(comisionista_id);
CREATE INDEX idx_liq_estado ON sd_comisiones.liquidaciones(estado);
CREATE INDEX idx_liq_pago ON sd_comisiones.liquidaciones(pago_id);
CREATE INDEX idx_liq_fecha ON sd_comisiones.liquidaciones(fecha_devengamiento DESC);
CREATE INDEX idx_liq_pendientes ON sd_comisiones.liquidaciones(comisionista_id, estado)
    WHERE estado IN ('generada','pendiente_aprobacion','aprobada');

-- sd_comisiones.comisionistas
CREATE UNIQUE INDEX idx_comisionistas_email ON sd_comisiones.comisionistas(email);
CREATE INDEX idx_comisionistas_estado ON sd_comisiones.comisionistas(estado);

-- sd_audit.audit_log
CREATE INDEX idx_audit_tabla ON sd_audit.audit_log(tabla_schema, tabla_nombre);
CREATE INDEX idx_audit_usuario ON sd_audit.audit_log(usuario_id);
CREATE INDEX idx_audit_registro ON sd_audit.audit_log(registro_id);
CREATE INDEX idx_audit_created ON sd_audit.audit_log(created_at DESC);

-- Full text search
CREATE INDEX idx_clientes_fts ON sd_clientes.clientes
    USING gin(to_tsvector('spanish', COALESCE((SELECT nombre_completo FROM sd_clientes.contactos WHERE id = contacto_principal_id), '')));
CREATE INDEX idx_leads_fts ON sd_comercial.leads
    USING gin(to_tsvector('spanish', COALESCE(nombre, '') || ' ' || COALESCE(empresa_nombre, '') || ' ' || COALESCE(email, '')));

-- ============================================================
-- 15. FUNCIONES AUXILIARES
-- ============================================================

-- Función para generar códigos únicos con prefijo y secuencia
CREATE OR REPLACE FUNCTION sd_core.generar_codigo(prefijo TEXT, schema_nombre TEXT, tabla_nombre TEXT)
RETURNS TEXT AS $$
DECLARE
    seq_name TEXT;
    next_val BIGINT;
BEGIN
    seq_name := 'sd_core.seq_' || lower(replace(prefijo, '-', '_'));
    -- Crear secuencia si no existe
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %s START 1', seq_name);
    EXECUTE format('SELECT nextval(''%s'')', seq_name) INTO next_val;
    RETURN prefijo || '-' || lpad(next_val::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Función para determinar la tasa de comisión aplicable
-- Lógica: 10% individual | 12% con Web | 15% con Web + (IA o CRM)
CREATE OR REPLACE FUNCTION sd_comisiones.calcular_tasa_comision(
    p_combo_id      UUID,
    p_servicio_id   UUID,
    p_comisionista_id UUID
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_tasa              DECIMAL(5,2);
    v_tiene_web         BOOLEAN := FALSE;
    v_tiene_ia_o_crm    BOOLEAN := FALSE;
    v_override          DECIMAL(5,2);
    v_combo_nivel       sd_servicios.nivel_combo;
BEGIN
    -- 1. Verificar si hay override específico para este comisionista
    SELECT tasa_pct INTO v_override
    FROM sd_comisiones.tasas_por_servicio
    WHERE (combo_id = p_combo_id OR servicio_id = p_servicio_id)
      AND comisionista_id = p_comisionista_id
      AND activa = TRUE
      AND (vigente_hasta IS NULL OR vigente_hasta >= CURRENT_DATE)
    ORDER BY comisionista_id NULLS LAST
    LIMIT 1;

    IF v_override IS NOT NULL THEN
        RETURN v_override;
    END IF;

    -- 2. Lógica del combo
    IF p_combo_id IS NOT NULL THEN
        SELECT nivel INTO v_combo_nivel FROM sd_servicios.combos WHERE id = p_combo_id;

        -- Verificar si el combo incluye Web
        SELECT EXISTS (
            SELECT 1 FROM sd_servicios.combo_servicios cs
            JOIN sd_servicios.servicios s ON s.id = cs.servicio_id
            JOIN sd_servicios.categorias c ON c.id = s.categoria_id
            WHERE cs.combo_id = p_combo_id AND c.nombre = 'Web'
        ) INTO v_tiene_web;

        -- Verificar si el combo incluye IA o CRM/Sistemas
        SELECT EXISTS (
            SELECT 1 FROM sd_servicios.combo_servicios cs
            JOIN sd_servicios.servicios s ON s.id = cs.servicio_id
            JOIN sd_servicios.categorias c ON c.id = s.categoria_id
            WHERE cs.combo_id = p_combo_id
              AND c.nombre IN ('IA Negocios', 'Sistemas')
        ) INTO v_tiene_ia_o_crm;

        IF v_tiene_web AND v_tiene_ia_o_crm THEN
            v_tasa := 15.00;  -- Combo completo
        ELSIF v_tiene_web THEN
            v_tasa := 12.00;  -- Combo con Web
        ELSE
            v_tasa := 10.00;  -- Combo básico
        END IF;
    ELSE
        -- Servicio individual → 10%
        v_tasa := 10.00;
    END IF;

    RETURN v_tasa;
END;
$$ LANGUAGE plpgsql;

-- Función para calcular comisión completa de un pago
CREATE OR REPLACE FUNCTION sd_comisiones.calcular_comision_pago(
    p_pago_id UUID
) RETURNS TABLE (
    comisionista_id     UUID,
    tasa_aplicada       DECIMAL(5,2),
    tipo_comision       VARCHAR(30),
    base_calculo        DECIMAL(15,2),
    comision_bruta      DECIMAL(15,2),
    comision_neta       DECIMAL(15,2)
) AS $$
DECLARE
    v_pago              RECORD;
    v_contrato          RECORD;
    v_oportunidad       RECORD;
    v_comisionista_id   UUID;
    v_tasa              DECIMAL(5,2);
    v_tipo              VARCHAR(30);
    v_base              DECIMAL(15,2);
    v_bruta             DECIMAL(15,2);
    v_neta              DECIMAL(15,2);
BEGIN
    -- Obtener datos del pago
    SELECT p.*, f.contrato_id
    INTO v_pago
    FROM sd_financiero.pagos p
    JOIN sd_financiero.facturas f ON f.id = p.factura_id
    WHERE p.id = p_pago_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pago % no encontrado', p_pago_id;
    END IF;

    -- Solo calcular para primer pago del contrato
    IF NOT v_pago.es_primer_pago_contrato THEN
        RETURN;
    END IF;

    -- Obtener contrato
    SELECT * INTO v_contrato
    FROM sd_contratos.contratos
    WHERE id = v_pago.contrato_id;

    IF v_contrato.comisionista_id IS NULL THEN
        RETURN; -- No hay comisionista → no hay comisión
    END IF;

    v_comisionista_id := v_contrato.comisionista_id;

    -- Calcular tasa
    v_tasa := sd_comisiones.calcular_tasa_comision(
        v_contrato.combo_id,
        NULL,
        v_comisionista_id
    );

    -- Determinar tipo de comisión
    v_tipo := CASE v_tasa
        WHEN 15.00 THEN 'combo_full_15'
        WHEN 12.00 THEN 'combo_web_12'
        ELSE 'individual_10'
    END;

    -- Base de cálculo: precio sin IVA y sin descuento según regla SD
    v_base := v_pago.monto_base_sin_iva;
    IF v_base IS NULL THEN
        v_base := v_pago.monto_cop / 1.19;  -- quitar IVA si no viene separado
    END IF;

    -- Ajustar por descuento aplicado (REGLA 3 de la política)
    IF v_contrato.valor_descuento_cop > 0 THEN
        v_base := v_base * (1 - (v_contrato.valor_descuento_cop / v_contrato.valor_total_cop));
    END IF;

    v_bruta := ROUND(v_base * v_tasa / 100, 0);
    v_neta  := v_bruta; -- Sin retenciones por defecto; ajustar según config

    RETURN QUERY SELECT
        v_comisionista_id,
        v_tasa,
        v_tipo,
        v_base,
        v_bruta,
        v_neta;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 16. TRIGGERS
-- ============================================================

-- 16.1 Trigger: Generar liquidación automática al confirmar pago
CREATE OR REPLACE FUNCTION sd_comisiones.trigger_generar_liquidacion()
RETURNS TRIGGER AS $$
DECLARE
    v_calculo           RECORD;
    v_factura           RECORD;
    v_cod_liquidacion   TEXT;
    v_contrato_id       UUID;
BEGIN
    -- Solo actuar cuando el estado cambia a 'confirmado'
    IF (NEW.estado = 'confirmado' AND (OLD.estado IS NULL OR OLD.estado != 'confirmado')) THEN

        -- Solo en primer pago del contrato
        IF NEW.es_primer_pago_contrato = TRUE THEN

            -- Obtener factura y contrato
            SELECT f.*, f.contrato_id INTO v_factura
            FROM sd_financiero.facturas f
            WHERE f.id = NEW.factura_id;

            v_contrato_id := v_factura.contrato_id;

            -- Calcular comisión
            FOR v_calculo IN
                SELECT * FROM sd_comisiones.calcular_comision_pago(NEW.id)
            LOOP
                -- Generar código de liquidación
                v_cod_liquidacion := 'SD-LIQ-' || lpad(
                    (SELECT COALESCE(MAX(CAST(split_part(codigo_liquidacion, '-', 3) AS INTEGER)), 0) + 1
                     FROM sd_comisiones.liquidaciones)::TEXT, 4, '0'
                );

                -- Insertar liquidación
                INSERT INTO sd_comisiones.liquidaciones (
                    codigo_liquidacion,
                    pago_id,
                    factura_id,
                    contrato_id,
                    cliente_id,
                    oportunidad_id,
                    combo_id,
                    comisionista_id,
                    monto_pago_cliente_bruto,
                    monto_pago_cliente_neto,
                    monto_con_descuento,
                    tasa_comision_aplicada,
                    tipo_comision,
                    base_calculo_comision,
                    comision_bruta,
                    comision_neta,
                    estado,
                    fecha_devengamiento,
                    generada_automaticamente
                ) VALUES (
                    v_cod_liquidacion,
                    NEW.id,
                    NEW.factura_id,
                    v_contrato_id,
                    NEW.cliente_id,
                    (SELECT oportunidad_id FROM sd_contratos.contratos WHERE id = v_contrato_id),
                    (SELECT combo_id FROM sd_contratos.contratos WHERE id = v_contrato_id),
                    v_calculo.comisionista_id,
                    NEW.monto_cop,
                    v_calculo.base_calculo,
                    v_calculo.base_calculo,
                    v_calculo.tasa_aplicada,
                    v_calculo.tipo_comision,
                    v_calculo.base_calculo,
                    v_calculo.comision_bruta,
                    v_calculo.comision_neta,
                    'generada',
                    NEW.fecha_pago,
                    TRUE
                );

                -- Actualizar acumulados del comisionista
                UPDATE sd_comisiones.comisionistas
                SET
                    comisiones_generadas_cop = comisiones_generadas_cop + v_calculo.comision_neta,
                    ventas_total_cop = ventas_total_cop + NEW.monto_cop,
                    updated_at = NOW()
                WHERE id = v_calculo.comisionista_id;

            END LOOP;
        END IF;

        -- Actualizar datos del cliente con el pago
        UPDATE sd_clientes.clientes
        SET
            ltv_realizado = ltv_realizado + NEW.monto_cop,
            total_facturas = total_facturas + CASE WHEN NEW.es_primer_pago_contrato THEN 1 ELSE 0 END,
            facturas_pagadas = facturas_pagadas + CASE WHEN NEW.es_primer_pago_contrato THEN 1 ELSE 0 END,
            fecha_ultimo_pago = NEW.fecha_pago,
            fecha_primer_pago = COALESCE(fecha_primer_pago, NEW.fecha_pago),
            updated_at = NOW()
        WHERE id = NEW.cliente_id;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generar_liquidacion_comision
    AFTER UPDATE OF estado ON sd_financiero.pagos
    FOR EACH ROW
    EXECUTE FUNCTION sd_comisiones.trigger_generar_liquidacion();

-- 16.2 Trigger: Actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION sd_core.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a todas las tablas con updated_at
DO $$
DECLARE
    t RECORD;
BEGIN
    FOR t IN
        SELECT table_schema, table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema IN ('sd_core','sd_clientes','sd_comercial','sd_comisiones',
                               'sd_contratos','sd_financiero','sd_operaciones',
                               'sd_marketing','sd_soporte')
    LOOP
        EXECUTE format('
            CREATE TRIGGER trg_updated_at_%s_%s
            BEFORE UPDATE ON %I.%I
            FOR EACH ROW EXECUTE FUNCTION sd_core.set_updated_at()',
            t.table_schema, t.table_name,
            t.table_schema, t.table_name
        );
    END LOOP;
END $$;

-- 16.3 Trigger: Historial de cambios de etapa del pipeline
CREATE OR REPLACE FUNCTION sd_comercial.trigger_historial_pipeline()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.etapa IS DISTINCT FROM NEW.etapa THEN
        INSERT INTO sd_comercial.historial_pipeline (
            oportunidad_id, etapa_anterior, etapa_nueva,
            dias_en_etapa, cambiado_por
        ) VALUES (
            NEW.id,
            OLD.etapa,
            NEW.etapa,
            EXTRACT(DAY FROM NOW() - OLD.fecha_cambio_etapa)::INTEGER,
            NEW.updated_by
        );
        NEW.etapa_anterior := OLD.etapa;
        NEW.fecha_cambio_etapa := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historial_pipeline
    BEFORE UPDATE OF etapa ON sd_comercial.oportunidades
    FOR EACH ROW
    EXECUTE FUNCTION sd_comercial.trigger_historial_pipeline();

-- 16.4 Trigger: Audit Log universal
CREATE OR REPLACE FUNCTION sd_audit.registrar_cambio()
RETURNS TRIGGER AS $$
DECLARE
    v_datos_antes   JSONB;
    v_datos_despues JSONB;
    v_campos        TEXT[];
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_datos_antes := to_jsonb(OLD);
        v_datos_despues := NULL;
    ELSIF TG_OP = 'INSERT' THEN
        v_datos_antes := NULL;
        v_datos_despues := to_jsonb(NEW);
    ELSE -- UPDATE
        v_datos_antes := to_jsonb(OLD);
        v_datos_despues := to_jsonb(NEW);
        -- Detectar qué campos cambiaron
        SELECT array_agg(key)
        INTO v_campos
        FROM (
            SELECT key FROM jsonb_each(v_datos_despues)
            EXCEPT
            SELECT key FROM jsonb_each(v_datos_antes)
            UNION
            SELECT d.key FROM jsonb_each(v_datos_despues) d
            JOIN jsonb_each(v_datos_antes) a ON a.key = d.key
            WHERE a.value::TEXT != d.value::TEXT
        ) changed_keys;
    END IF;

    INSERT INTO sd_audit.audit_log (
        tabla_schema, tabla_nombre, operacion,
        registro_id, datos_antes, datos_despues,
        campos_cambiados
    ) VALUES (
        TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP,
        CASE WHEN TG_OP = 'DELETE' THEN (v_datos_antes->>'id')::UUID
             ELSE (v_datos_despues->>'id')::UUID END,
        v_datos_antes, v_datos_despues, v_campos
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Aplicar audit a tablas críticas
CREATE TRIGGER trg_audit_clientes
    AFTER INSERT OR UPDATE OR DELETE ON sd_clientes.clientes
    FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();

CREATE TRIGGER trg_audit_oportunidades
    AFTER INSERT OR UPDATE OR DELETE ON sd_comercial.oportunidades
    FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();

CREATE TRIGGER trg_audit_contratos
    AFTER INSERT OR UPDATE OR DELETE ON sd_contratos.contratos
    FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();

CREATE TRIGGER trg_audit_facturas
    AFTER INSERT OR UPDATE OR DELETE ON sd_financiero.facturas
    FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();

CREATE TRIGGER trg_audit_pagos
    AFTER INSERT OR UPDATE OR DELETE ON sd_financiero.pagos
    FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();

CREATE TRIGGER trg_audit_liquidaciones
    AFTER INSERT OR UPDATE OR DELETE ON sd_comisiones.liquidaciones
    FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();

-- ============================================================
-- 17. VISTAS ANALÍTICAS (sd_analytics)
-- ============================================================

-- Vista: Resumen 360° de cliente
CREATE OR REPLACE VIEW sd_analytics.v_cliente_360 AS
SELECT
    c.id                            AS cliente_id,
    c.codigo_cliente,
    -- Empresa
    e.razon_social                  AS empresa,
    e.industria,
    e.tamano,
    -- Contacto principal
    ct.nombre_completo              AS contacto_principal,
    ct.cargo,
    ct.email_trabajo,
    -- Estado
    c.estado_cliente,
    c.segmento,
    -- Responsable y origen
    u.nombre_display                AS responsable_comercial,
    com.nombre_completo             AS comisionista_origen,
    c.origen_cliente,
    -- Métricas financieras
    c.ltv_realizado,
    c.ltv_proyectado,
    c.mrr_actual,
    -- Contratos
    (SELECT COUNT(*) FROM sd_contratos.contratos ct2 WHERE ct2.cliente_id = c.id AND ct2.estado = 'activo') AS contratos_activos,
    (SELECT COUNT(*) FROM sd_contratos.contratos ct2 WHERE ct2.cliente_id = c.id) AS total_contratos,
    -- Facturas
    (SELECT COALESCE(SUM(saldo_pendiente_cop), 0) FROM sd_financiero.facturas f WHERE f.cliente_id = c.id AND f.estado NOT IN ('pagada','anulada')) AS saldo_por_cobrar,
    (SELECT COUNT(*) FROM sd_financiero.facturas f WHERE f.cliente_id = c.id AND f.estado = 'en_mora') AS facturas_en_mora,
    -- Soporte
    (SELECT COUNT(*) FROM sd_soporte.tickets t WHERE t.cliente_id = c.id AND t.estado NOT IN ('cerrado','resuelto')) AS tickets_abiertos,
    -- Satisfacción
    c.nps_score,
    c.csat_promedio,
    c.probabilidad_churn,
    c.alerta_churn,
    -- Fechas clave
    c.fecha_primer_contacto,
    c.fecha_conversion,
    c.fecha_ultimo_pago,
    c.fecha_ultimo_contacto,
    -- Auditoría
    c.created_at
FROM sd_clientes.clientes c
LEFT JOIN sd_clientes.empresas e ON e.id = c.empresa_id
LEFT JOIN sd_clientes.contactos ct ON ct.id = c.contacto_principal_id
LEFT JOIN sd_core.usuarios u ON u.id = c.responsable_comercial_id
LEFT JOIN sd_comisiones.comisionistas com ON com.id = c.comisionista_origen_id
WHERE c.deleted_at IS NULL;

-- Vista: Pipeline comercial con KPIs
CREATE OR REPLACE VIEW sd_analytics.v_pipeline_comercial AS
SELECT
    o.id                        AS oportunidad_id,
    o.codigo_oportunidad,
    o.nombre_oportunidad,
    o.etapa,
    o.valor_final_cop,
    o.probabilidad_cierre_pct,
    -- Valor ponderado
    ROUND(o.valor_final_cop * o.probabilidad_cierre_pct / 100, 0) AS valor_ponderado,
    -- Cliente
    c.codigo_cliente,
    COALESCE(e.razon_social, ct.nombre_completo) AS cliente_nombre,
    -- Responsables
    u.nombre_display            AS responsable,
    com.nombre_completo         AS comisionista,
    -- Servicio / combo
    srv.nombre_comercial        AS servicio,
    cmb.nombre                  AS combo,
    -- Comisión proyectada
    ROUND(o.valor_final_cop * sd_comisiones.calcular_tasa_comision(o.combo_id, o.servicio_id, o.comisionista_id) / 100, 0) AS comision_proyectada,
    -- Timing
    o.fecha_apertura,
    o.fecha_cierre_estimada,
    CURRENT_DATE - o.fecha_apertura AS dias_en_pipeline,
    o.ciclo_venta_dias,
    -- Estado
    o.ganada,
    o.razon_perdida,
    -- Actividad reciente
    (SELECT MAX(fecha_actividad) FROM sd_comercial.actividades a WHERE a.oportunidad_id = o.id) AS ultima_actividad
FROM sd_comercial.oportunidades o
LEFT JOIN sd_clientes.clientes c ON c.id = o.cliente_id
LEFT JOIN sd_clientes.empresas e ON e.id = c.empresa_id
LEFT JOIN sd_clientes.contactos ct ON ct.id = o.contacto_principal_id
LEFT JOIN sd_core.usuarios u ON u.id = o.responsable_interno_id
LEFT JOIN sd_comisiones.comisionistas com ON com.id = o.comisionista_id
LEFT JOIN sd_servicios.servicios srv ON srv.id = o.servicio_id
LEFT JOIN sd_servicios.combos cmb ON cmb.id = o.combo_id;

-- Vista: Dashboard de comisionistas
CREATE OR REPLACE VIEW sd_analytics.v_dashboard_comisionistas AS
SELECT
    com.id                          AS comisionista_id,
    com.codigo_comisionista,
    com.nombre_completo,
    com.nivel,
    com.estado,
    -- Pipeline activo
    COUNT(DISTINCT o.id) FILTER (WHERE o.ganada IS NULL) AS oportunidades_activas,
    COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada IS NULL), 0) AS valor_pipeline_activo,
    -- Ventas
    COUNT(DISTINCT o.id) FILTER (WHERE o.ganada = TRUE) AS ventas_cerradas,
    COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0) AS ingresos_generados,
    COALESCE(AVG(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0) AS ticket_promedio,
    -- Tasa de conversión
    CASE WHEN COUNT(DISTINCT o.id) > 0
         THEN ROUND(COUNT(DISTINCT o.id) FILTER (WHERE o.ganada = TRUE) * 100.0 / COUNT(DISTINCT o.id), 1)
         ELSE 0 END AS tasa_conversion_pct,
    -- Comisiones
    com.comisiones_generadas_cop,
    com.comisiones_pagadas_cop,
    com.comisiones_pendientes_cop,
    -- Liquidaciones pendientes
    COUNT(DISTINCT liq.id) FILTER (WHERE liq.estado IN ('generada','pendiente_aprobacion','aprobada')) AS liquidaciones_pendientes,
    COALESCE(SUM(liq.comision_neta) FILTER (WHERE liq.estado IN ('generada','pendiente_aprobacion','aprobada')), 0) AS monto_pendiente_cobrar,
    -- Ciclo promedio
    ROUND(AVG(o.ciclo_venta_dias) FILTER (WHERE o.ganada = TRUE), 1) AS dias_promedio_cierre,
    -- Meta
    com.meta_mensual_ventas_cop,
    CASE WHEN com.meta_mensual_ventas_cop > 0
         THEN ROUND(COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE AND DATE_TRUNC('month', o.fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)), 0) * 100 / com.meta_mensual_ventas_cop, 1)
         ELSE NULL END AS pct_meta_mes_actual
FROM sd_comisiones.comisionistas com
LEFT JOIN sd_comercial.oportunidades o ON o.comisionista_id = com.id
LEFT JOIN sd_comisiones.liquidaciones liq ON liq.comisionista_id = com.id
GROUP BY com.id, com.codigo_comisionista, com.nombre_completo, com.nivel, com.estado,
         com.comisiones_generadas_cop, com.comisiones_pagadas_cop, com.comisiones_pendientes_cop,
         com.meta_mensual_ventas_cop;

-- Vista: MRR y ARR (ingresos recurrentes)
CREATE OR REPLACE VIEW sd_analytics.v_mrr_arr AS
SELECT
    DATE_TRUNC('month', CURRENT_DATE)   AS mes,
    COALESCE(SUM(c.mrr_actual), 0)      AS mrr_total,
    COALESCE(SUM(c.mrr_actual) * 12, 0) AS arr_total,
    COUNT(*) FILTER (WHERE c.mrr_actual > 0) AS clientes_con_mrr,
    COALESCE(AVG(c.mrr_actual) FILTER (WHERE c.mrr_actual > 0), 0) AS arpu,
    -- Por segmento
    COALESCE(SUM(c.mrr_actual) FILTER (WHERE c.segmento = 'platinum'), 0) AS mrr_platinum,
    COALESCE(SUM(c.mrr_actual) FILTER (WHERE c.segmento = 'gold'), 0) AS mrr_gold,
    COALESCE(SUM(c.mrr_actual) FILTER (WHERE c.segmento = 'silver'), 0) AS mrr_silver,
    -- Churn alerts
    COUNT(*) FILTER (WHERE c.alerta_churn = TRUE) AS clientes_en_riesgo_churn
FROM sd_clientes.clientes c
WHERE c.estado_cliente IN ('activo', 'recurrente');

-- Vista: Cartera y antigüedad
CREATE OR REPLACE VIEW sd_analytics.v_cartera_antiguedad AS
SELECT
    c.id                                    AS cliente_id,
    c.codigo_cliente,
    COALESCE(e.razon_social, ct.nombre_completo) AS nombre_cliente,
    -- Cartera total
    COALESCE(SUM(f.saldo_pendiente_cop), 0) AS cartera_total,
    -- Por antigüedad
    COALESCE(SUM(f.saldo_pendiente_cop) FILTER (WHERE f.dias_mora = 0), 0)          AS al_dia,
    COALESCE(SUM(f.saldo_pendiente_cop) FILTER (WHERE f.dias_mora BETWEEN 1 AND 30), 0)  AS mora_1_30,
    COALESCE(SUM(f.saldo_pendiente_cop) FILTER (WHERE f.dias_mora BETWEEN 31 AND 60), 0) AS mora_31_60,
    COALESCE(SUM(f.saldo_pendiente_cop) FILTER (WHERE f.dias_mora BETWEEN 61 AND 90), 0) AS mora_61_90,
    COALESCE(SUM(f.saldo_pendiente_cop) FILTER (WHERE f.dias_mora > 90), 0)          AS mora_mas_90,
    -- Peor mora
    COALESCE(MAX(f.dias_mora), 0)           AS max_dias_mora,
    -- Responsable
    u.nombre_display                        AS responsable_cobro
FROM sd_clientes.clientes c
LEFT JOIN sd_clientes.empresas e ON e.id = c.empresa_id
LEFT JOIN sd_clientes.contactos ct ON ct.id = c.contacto_principal_id
LEFT JOIN sd_financiero.facturas f ON f.cliente_id = c.id
    AND f.estado NOT IN ('pagada','anulada','borrador')
LEFT JOIN sd_core.usuarios u ON u.id = c.responsable_comercial_id
GROUP BY c.id, c.codigo_cliente, e.razon_social, ct.nombre_completo, u.nombre_display
HAVING COALESCE(SUM(f.saldo_pendiente_cop), 0) > 0;

-- Vista: KPIs financieros del mes
CREATE OR REPLACE VIEW sd_analytics.v_kpis_mes_actual AS
SELECT
    DATE_TRUNC('month', CURRENT_DATE)   AS mes,
    -- Ingresos
    COALESCE(SUM(p.monto_cop) FILTER (WHERE p.estado = 'confirmado'), 0) AS ingresos_cobrados,
    COALESCE(SUM(f.total_cop) FILTER (WHERE f.estado IN ('emitida','enviada','parcialmente_pagada')), 0) AS ingresos_facturados,
    -- Leads y pipeline
    (SELECT COUNT(*) FROM sd_comercial.leads WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)) AS leads_nuevos,
    (SELECT COUNT(*) FROM sd_comercial.oportunidades WHERE ganada = TRUE AND DATE_TRUNC('month', fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)) AS ventas_cerradas,
    (SELECT COALESCE(SUM(valor_final_cop), 0) FROM sd_comercial.oportunidades WHERE ganada = TRUE AND DATE_TRUNC('month', fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)) AS valor_ventas_cerradas,
    -- Comisiones
    (SELECT COALESCE(SUM(comision_neta), 0) FROM sd_comisiones.liquidaciones WHERE DATE_TRUNC('month', fecha_devengamiento) = DATE_TRUNC('month', CURRENT_DATE)) AS comisiones_devengadas_mes,
    (SELECT COALESCE(SUM(monto_total_cop), 0) FROM sd_comisiones.pagos_comisionistas WHERE DATE_TRUNC('month', fecha_pago) = DATE_TRUNC('month', CURRENT_DATE)) AS comisiones_pagadas_mes,
    -- Clientes nuevos
    (SELECT COUNT(*) FROM sd_clientes.clientes WHERE DATE_TRUNC('month', fecha_conversion) = DATE_TRUNC('month', CURRENT_DATE)) AS clientes_nuevos,
    -- Win rate del mes
    (SELECT ROUND(
        COUNT(*) FILTER (WHERE ganada = TRUE) * 100.0 / NULLIF(COUNT(*) FILTER (WHERE ganada IS NOT NULL), 0), 1
     ) FROM sd_comercial.oportunidades WHERE DATE_TRUNC('month', fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)
    ) AS win_rate_pct
FROM sd_financiero.pagos p
FULL JOIN sd_financiero.facturas f ON DATE_TRUNC('month', f.fecha_emision) = DATE_TRUNC('month', CURRENT_DATE)
WHERE DATE_TRUNC('month', p.fecha_pago) = DATE_TRUNC('month', CURRENT_DATE)
   OR DATE_TRUNC('month', f.fecha_emision) = DATE_TRUNC('month', CURRENT_DATE);

-- Vista: Análisis de combos (qué combos se venden más)
CREATE OR REPLACE VIEW sd_analytics.v_performance_combos AS
SELECT
    cmb.id                          AS combo_id,
    cmb.codigo_combo,
    cmb.nombre,
    cmb.nivel,
    cmb.precio_combo_cop,
    cmb.tasa_comision,
    -- Ventas
    COUNT(o.id) FILTER (WHERE o.ganada = TRUE)  AS veces_vendido,
    COUNT(o.id) FILTER (WHERE o.ganada = FALSE)  AS veces_perdido,
    COUNT(o.id) FILTER (WHERE o.ganada IS NULL)  AS en_pipeline,
    -- Win rate del combo
    CASE WHEN COUNT(o.id) FILTER (WHERE o.ganada IS NOT NULL) > 0
         THEN ROUND(COUNT(o.id) FILTER (WHERE o.ganada = TRUE) * 100.0
              / COUNT(o.id) FILTER (WHERE o.ganada IS NOT NULL), 1)
         ELSE 0 END AS win_rate_pct,
    -- Ingresos generados
    COALESCE(SUM(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0) AS ingresos_totales,
    COALESCE(AVG(o.valor_final_cop) FILTER (WHERE o.ganada = TRUE), 0) AS ticket_promedio_real,
    -- Comisiones generadas por este combo
    COALESCE(SUM(liq.comision_neta), 0)         AS total_comisiones_generadas,
    -- Ciclo de venta
    ROUND(AVG(o.ciclo_venta_dias) FILTER (WHERE o.ganada = TRUE), 1) AS dias_promedio_cierre,
    -- Razones de pérdida
    MODE() WITHIN GROUP (ORDER BY o.razon_perdida::TEXT) AS principal_razon_perdida
FROM sd_servicios.combos cmb
LEFT JOIN sd_comercial.oportunidades o ON o.combo_id = cmb.id
LEFT JOIN sd_comisiones.liquidaciones liq ON liq.combo_id = cmb.id
GROUP BY cmb.id, cmb.codigo_combo, cmb.nombre, cmb.nivel, cmb.precio_combo_cop, cmb.tasa_comision;

-- ============================================================
-- 18. DATOS INICIALES DE CONFIGURACIÓN
-- ============================================================

-- Categorías de servicios
INSERT INTO sd_servicios.categorias (codigo, nombre, descripcion, orden) VALUES
('CAT-AUTO',  'Automatización',    'Automatización de procesos de negocio',          1),
('CAT-IA',    'IA Negocios',       'Inteligencia Artificial aplicada al negocio',     2),
('CAT-INTEG', 'Integraciones',     'Integraciones tecnológicas entre sistemas',       3),
('CAT-SIS',   'Sistemas',         'Sistemas internos a medida y CRM',               4),
('CAT-DIAG',  'Diagnóstico',      'Diagnóstico y consultoría estratégica',           5),
('CAT-SOP',   'Soporte Mensual',  'Soporte técnico y mantenimiento mensual',         6),
('CAT-FORM',  'Formación',        'Formación técnica y capacitación',                7),
('CAT-WEB',   'Web',              'Presencia digital y desarrollo web inteligente',  8);

-- Servicios del catálogo completo
INSERT INTO sd_servicios.servicios (
    codigo_servicio, categoria_id, nombre_interno, nombre_comercial,
    tipo_cobro, precio_base_cop, precio_minimo_negociacion, precio_minimo_absoluto,
    costo_interno_cop, tasa_comision_base, tasa_comision_combo, tasa_comision_elite
) VALUES
-- Automatización
('SD-SRV-001', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-AUTO'), 'Automatización START',  'Auto START',  'unico', 400000,  360000, 340000, 165000, 10, 12, 15),
('SD-SRV-002', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-AUTO'), 'Automatización FLOW',  'Auto FLOW',   'unico', 700000,  630000, 595000, 350000, 10, 12, 15),
('SD-SRV-003', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-AUTO'), 'Automatización CORE',  'Auto CORE',   'unico', 1500000, 1350000,1275000, 650000, 10, 12, 15),
-- IA
('SD-SRV-004', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-IA'),   'IA START',              'IA START',      'unico', 600000,  540000, 510000, 250000, 10, 12, 15),
('SD-SRV-005', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-IA'),   'IA OPERATIVA',          'IA OPERATIVA',  'unico', 1250000, 1125000,1062500,500000, 10, 12, 15),
('SD-SRV-006', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-IA'),   'IA ESTRATÉGICA',        'IA ESTRATÉGICA','unico', 2550000, 2295000,2167500,1000000,10, 12, 15),
-- Integraciones
('SD-SRV-007', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-INTEG'),'Integración CONNECT',   'Integr. CONNECT','unico',500000,  450000, 425000, 200000, 10, 12, 15),
('SD-SRV-008', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-INTEG'),'Integración SYNC',      'Integr. SYNC',   'unico',1150000, 1035000, 977500,480000, 10, 12, 15),
('SD-SRV-009', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-INTEG'),'Integración ORQUESTA',  'Integr. ORQUESTA','unico',2250000,2025000,1912500,900000, 10, 12, 15),
-- Sistemas / CRM
('SD-SRV-010', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-SIS'),  'Sistemas BUILD',        'Sistemas BUILD',  'unico', 1010000, 990000, 935000, 450000, 10, 12, 15),
('SD-SRV-011', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-SIS'),  'CRM COMMAND',           'CRM COMMAND',     'unico', 1690000, 1575000,1487500,700000, 10, 12, 15),
('SD-SRV-012', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-SIS'),  'Sistemas SCALE',        'Sistemas SCALE',  'unico', 2850000, 2610000,2465000,1150000,10, 12, 15),
-- Diagnóstico
('SD-SRV-013', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-DIAG'), 'Diagnóstico SCAN',      'Diagnóstico SCAN',    'unico',800000, 720000, 680000, 300000, 10, 12, 15),
('SD-SRV-014', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-DIAG'), 'Diagnóstico BLUEPRINT', 'Diagnóstico BLUEPRINT','unico',1500000,1350000,1275000,550000, 10, 12, 15),
('SD-SRV-015', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-DIAG'), 'Diagnóstico ADVISORY',  'Diagnóstico ADVISORY', 'unico',2200000,1980000,1870000,800000, 10, 12, 15),
-- Soporte mensual
('SD-SRV-016', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-SOP'),  'Soporte CARE',          'Soporte CARE',      'mensual',200000, 180000, 170000,  60000, 10, 12, 15),
('SD-SRV-017', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-SOP'),  'Soporte STABILITY',     'Soporte STABILITY', 'mensual',300000, 270000, 255000,  90000, 10, 12, 15),
('SD-SRV-018', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-SOP'),  'Soporte EVOLVE',        'Soporte EVOLVE',    'mensual',500000, 450000, 425000, 150000, 10, 12, 15),
-- Formación
('SD-SRV-019', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-FORM'), 'Formación START',       'Formación START',   'unico', 500000, 450000, 425000, 180000, 10, 12, 15),
('SD-SRV-020', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-FORM'), 'Formación ENABLE',      'Formación ENABLE',  'unico', 600000, 540000, 510000, 210000, 10, 12, 15),
('SD-SRV-021', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-FORM'), 'Formación MASTER',      'Formación MASTER',  'unico', 1500000,1350000,1275000, 500000, 10, 12, 15),
-- Web
('SD-SRV-022', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-WEB'),  'Web PRESENCE',          'Web PRESENCE',      'unico', 1500000,1350000,1275000, 600000, 10, 12, 15),
('SD-SRV-023', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-WEB'),  'Web CONNECT',           'Web CONNECT',       'unico', 2500000,2250000,2125000, 950000, 10, 12, 15),
('SD-SRV-024', (SELECT id FROM sd_servicios.categorias WHERE codigo='CAT-WEB'),  'Web INTELLIGENT',       'Web INTELLIGENT',   'unico', 5000000,4500000,4250000,1800000, 10, 12, 15);

-- Planes de comisión
INSERT INTO sd_comisiones.planes_comision
    (nombre, aplica_a, tasa_base, condicion_activacion, requiere_web, requiere_ia_o_crm) VALUES
('Individual 10%',    'servicio_individual', 10.00, 'Cualquier servicio vendido de forma individual sin combo',             FALSE, FALSE),
('Combo Web 12%',     'combo_web',           12.00, 'Combo que incluye Web + otros servicios (sin IA ni CRM/Sistemas)',    TRUE,  FALSE),
('Combo Completo 15%','combo_full',          15.00, 'Combo con Web + (IA Negocios o CRM/Sistemas) — máxima motivación',   TRUE,  TRUE);

-- Configuración del sistema
INSERT INTO sd_core.configuracion (clave, valor, descripcion, categoria) VALUES
('iva_colombia',               '{"porcentaje": 19, "aplica_a": "todos"}',                         'Porcentaje de IVA Colombia',                   'financiero'),
('comision_individual',        '{"tasa": 10, "base": "precio_sin_iva"}',                          'Tasa comisión servicios individuales',          'comisiones'),
('comision_combo_web',         '{"tasa": 12, "requiere_web": true}',                              'Tasa comisión combo con Web',                   'comisiones'),
('comision_combo_full',        '{"tasa": 15, "requiere_web": true, "requiere_ia_crm": true}',     'Tasa comisión combo completo',                  'comisiones'),
('descuento_maximo',           '{"porcentaje": 10}',                                               'Descuento máximo autorizable sin aprobación',   'comercial'),
('dias_vencimiento_factura',   '{"dias": 30}',                                                    'Días de plazo por defecto en facturas',         'financiero'),
('dias_alerta_renovacion',     '{"dias": 30}',                                                    'Días de anticipación para alertar renovación',  'contratos'),
('sla_soporte_standard_hrs',   '{"respuesta": 24, "resolucion": 72}',                             'SLA por defecto para tickets de soporte',       'soporte'),
('score_churn_alerta',         '{"umbral": 70}',                                                  'Score de churn para activar alerta',            'clientes'),
('nps_promotor_min',           '{"min": 9, "max": 10}',                                           'Rango NPS para categoría Promotor',             'satisfaccion'),
('dias_lead_sin_actividad',    '{"alerta": 3, "critico": 7}',                                     'Días sin actividad para alertas de seguimiento','crm');

-- ============================================================
-- FIN DEL DDL
-- ============================================================
-- Snake Dragon CRM Enterprise v1.0
-- 12 schemas | 40+ tablas | 6 triggers | 6 vistas analíticas
-- Motor de comisiones automático
-- Auditoría universal con particionamiento por mes
-- ============================================================
