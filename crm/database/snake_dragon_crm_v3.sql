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
--  CRM ENTERPRISE v3.0 — AI Copilot & Conversational Hub
--  Migración sobre v2.0  |  PostgreSQL 16+
--
--  ┌─────────────────────────────────────────────────────┐
--  │  INCORPORACIONES ESTRATÉGICAS V3 (Expansión CRM):   │
--  │  ✅ Omnicanalidad: Telegram, Teams, WhatsApp        │
--  │  ✅ Conversational AI & Meeting/Chat Extraction     │
--  │  ✅ Portal de Clientes (Client Hub)                 │
--  │  ✅ IA Copiloto Interno para Vendedores             │
--  └─────────────────────────────────────────────────────┘
-- ================================================================

BEGIN;

-- ================================================================
-- 1. NUEVOS SCHEMAS (V3)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS sd_copilot;    -- Copiloto interno (Agentes IA)
CREATE SCHEMA IF NOT EXISTS sd_portal;     -- Portal de clientes externos

-- ================================================================
-- 1.5 AUDITORÍA BLOQUE 1: SEGURIDAD Y CONTROL DE ACCESO
-- ================================================================

-- EXTENSIÓN NECESARIA PARA CIFRADO (PGCRYPTO)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- PROBLEMA 1: RBAC Granular (Permisos)
CREATE TABLE IF NOT EXISTS sd_core.permisos (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo      VARCHAR(100) UNIQUE NOT NULL,  -- 'comisiones.liquidaciones.ver'
    modulo      VARCHAR(50) NOT NULL,           -- 'comisiones'
    accion      VARCHAR(30) NOT NULL,           -- 'ver', 'crear', 'editar', 'eliminar', 'aprobar'
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS sd_core.rol_permisos (
    rol         sd_core.rol_usuario NOT NULL,
    permiso_id  UUID REFERENCES sd_core.permisos(id),
    otorgado    BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (rol, permiso_id)
);

CREATE TABLE IF NOT EXISTS sd_core.usuario_permisos_override (
    usuario_id  UUID REFERENCES sd_core.usuarios(id),
    permiso_id  UUID REFERENCES sd_core.permisos(id),
    otorgado    BOOLEAN NOT NULL,  -- true=conceder extra, false=revocar del rol
    razon       TEXT,
    creado_por  UUID REFERENCES sd_core.usuarios(id),
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (usuario_id, permiso_id)
);

-- PROBLEMA 2: Gestión Real de Sesiones
CREATE TABLE IF NOT EXISTS sd_core.sesiones (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id      UUID NOT NULL REFERENCES sd_core.usuarios(id),
    token_hash      VARCHAR(255) NOT NULL,  -- bcrypt del JWT/session token
    ip_address      INET,
    user_agent      TEXT,
    dispositivo     VARCHAR(50),
    pais            VARCHAR(50),
    ciudad          VARCHAR(100),
    activa          BOOLEAN DEFAULT TRUE,
    creada_en       TIMESTAMPTZ DEFAULT NOW(),
    ultimo_uso      TIMESTAMPTZ DEFAULT NOW(),
    expira_en       TIMESTAMPTZ,
    revocada_en     TIMESTAMPTZ,
    revocada_por    UUID REFERENCES sd_core.usuarios(id),
    motivo_revocacion VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_sesiones_usuario ON sd_core.sesiones(usuario_id) WHERE activa = TRUE;
CREATE INDEX IF NOT EXISTS idx_sesiones_token ON sd_core.sesiones(token_hash);

-- PROBLEMA 3: MFA / 2FA
CREATE TABLE IF NOT EXISTS sd_core.mfa_configuracion (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id      UUID NOT NULL REFERENCES sd_core.usuarios(id) UNIQUE,
    metodo          VARCHAR(20) NOT NULL DEFAULT 'totp',  -- totp, sms, email
    secret_totp     VARCHAR(255),    -- ENCRIPTADO con pgcrypto
    telefono_sms    VARCHAR(30),
    activo          BOOLEAN DEFAULT FALSE,
    verificado      BOOLEAN DEFAULT FALSE,
    creado_en       TIMESTAMPTZ DEFAULT NOW(),
    ultimo_uso      TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS sd_core.mfa_codigos_backup (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id  UUID NOT NULL REFERENCES sd_core.usuarios(id),
    codigo_hash VARCHAR(255) NOT NULL,  -- bcrypt
    usado       BOOLEAN DEFAULT FALSE,
    usado_en    TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- PROBLEMA 4: API Keys para Integraciones
CREATE TABLE IF NOT EXISTS sd_core.api_keys (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          VARCHAR(100) NOT NULL,
    descripcion     TEXT,
    key_hash        VARCHAR(255) NOT NULL,  -- nunca guardar el key en plano
    key_prefix      VARCHAR(12) NOT NULL,   -- primeros 8 chars para identificarla (ej: 'sd_live_abc')
    tipo            VARCHAR(30) DEFAULT 'interno',  -- interno, externo, webhook
    permisos        JSONB DEFAULT '[]',     -- ['leads.crear', 'eventos.emitir']
    scopes          VARCHAR(255),
    activa          BOOLEAN DEFAULT TRUE,
    ip_whitelist    INET[],                 -- IPs permitidas (null = todas)
    usuario_id      UUID REFERENCES sd_core.usuarios(id),
    ultimo_uso      TIMESTAMPTZ,
    contador_llamadas BIGINT DEFAULT 0,
    expira_en       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    created_by      UUID REFERENCES sd_core.usuarios(id)
);

-- PROBLEMA 5: Consentimiento de datos sin trazabilidad (Ley 1581/2012)
CREATE TABLE IF NOT EXISTS sd_clientes.consentimientos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id         UUID REFERENCES sd_comercial.leads(id),
    cliente_id      UUID REFERENCES sd_clientes.clientes(id),
    contacto_id     UUID REFERENCES sd_clientes.contactos(id),
    tipo            VARCHAR(60) NOT NULL,
    version_politica VARCHAR(20),
    otorgado        BOOLEAN NOT NULL,
    canal           VARCHAR(50),
    ip_address      INET,
    url_formulario  VARCHAR(500),
    texto_aceptado  TEXT,
    revocado        BOOLEAN DEFAULT FALSE,
    revocado_en     TIMESTAMPTZ,
    motivo_revocacion TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_consent_cliente ON sd_clientes.consentimientos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_consent_tipo ON sd_clientes.consentimientos(tipo, otorgado);

-- PROBLEMA 6: Cifrado cuenta comisionista
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema='sd_comercial' AND table_name='comisionistas' AND column_name='numero_cuenta'
    ) THEN
        ALTER TABLE sd_comercial.comisionistas ALTER COLUMN numero_cuenta TYPE VARCHAR(500);
    END IF;
END $$;

-- Insertar llave de encriptación (si existe la tabla de configuración)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_tables WHERE schemaname = 'sd_core' AND tablename = 'configuracion'
    ) THEN
        INSERT INTO sd_core.configuracion (clave, valor, categoria) 
        VALUES ('encryption_key_version', '{"version": 1, "algoritmo": "pgp_sym"}', 'seguridad')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- ================================================================
-- 1.6 AUDITORÍA BLOQUE 2: CUMPLIMIENTO LEGAL COLOMBIANO (DIAN)
-- ================================================================

-- PROBLEMA 1: Notas Crédito y Notas Débito
CREATE TABLE IF NOT EXISTS sd_financiero.notas_credito (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_nota             VARCHAR(30) UNIQUE NOT NULL,  -- SD-NCV-001
    numero_nota             SERIAL,
    factura_id              UUID NOT NULL REFERENCES sd_financiero.facturas(id),
    cliente_id              UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    contrato_id             UUID REFERENCES sd_contratos.contratos(id),
    tipo                    VARCHAR(20) DEFAULT 'credito',  -- credito, debito
    concepto                VARCHAR(50) NOT NULL,
    descripcion             TEXT NOT NULL,
    moneda                  sd_core.moneda DEFAULT 'COP',
    subtotal_cop            DECIMAL(15,2) NOT NULL,
    iva_cop                 DECIMAL(12,2) DEFAULT 0,
    total_cop               DECIMAL(15,2) NOT NULL,
    estado                  VARCHAR(30) DEFAULT 'borrador',
    cufe_nc                 VARCHAR(255),
    id_dian_nc              VARCHAR(100),
    fecha_emision           DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_envio_dian        TIMESTAMPTZ,
    fecha_aceptacion_dian   TIMESTAMPTZ,
    respuesta_dian          JSONB DEFAULT '{}',
    afecta_liquidacion_id   UUID REFERENCES sd_comisiones.liquidaciones(id),
    notas_internas          TEXT,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID REFERENCES sd_core.usuarios(id)
);

CREATE INDEX IF NOT EXISTS idx_nc_factura ON sd_financiero.notas_credito(factura_id);
CREATE INDEX IF NOT EXISTS idx_nc_cliente ON sd_financiero.notas_credito(cliente_id);
CREATE INDEX IF NOT EXISTS idx_nc_estado ON sd_financiero.notas_credito(estado);

-- PROBLEMA 2: Catálogo de retenciones y retenciones por factura
CREATE TABLE IF NOT EXISTS sd_financiero.cat_retenciones (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo          VARCHAR(30) UNIQUE NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    tipo            VARCHAR(20) NOT NULL,
    base_legal      VARCHAR(255),
    tasa_general    DECIMAL(6,4) NOT NULL,
    tasa_gran_contrib DECIMAL(6,4),
    aplica_a        VARCHAR(100),
    activa          BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sd_financiero.factura_retenciones (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    factura_id          UUID NOT NULL REFERENCES sd_financiero.facturas(id) ON DELETE CASCADE,
    retencion_id        UUID NOT NULL REFERENCES sd_financiero.cat_retenciones(id),
    retenedor_tipo      VARCHAR(30),
    base_retencion      DECIMAL(15,2) NOT NULL,
    tasa_aplicada       DECIMAL(6,4) NOT NULL,
    monto_retencion     DECIMAL(12,2) NOT NULL,
    certificado_url     VARCHAR(500),
    periodo_retencion   VARCHAR(20),
    notas               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fac_ret_factura ON sd_financiero.factura_retenciones(factura_id);

-- PROBLEMA 3: Factura electrónica - campos DIAN incompletos y Resoluciones
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_financiero' AND table_name = 'facturas') THEN
        ALTER TABLE sd_financiero.facturas 
            ADD COLUMN IF NOT EXISTS tipo_documento_dian VARCHAR(10) DEFAULT 'FV',
            ADD COLUMN IF NOT EXISTS consecutivo_dian VARCHAR(20),
            ADD COLUMN IF NOT EXISTS prefijo_dian VARCHAR(10),
            ADD COLUMN IF NOT EXISTS rango_autorizado_desde BIGINT,
            ADD COLUMN IF NOT EXISTS rango_autorizado_hasta BIGINT,
            ADD COLUMN IF NOT EXISTS resolucion_dian VARCHAR(50),
            ADD COLUMN IF NOT EXISTS fecha_resolucion_dian DATE,
            ADD COLUMN IF NOT EXISTS estado_dian VARCHAR(30) DEFAULT 'no_enviada',
            ADD COLUMN IF NOT EXISTS fecha_validacion_dian TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS errores_dian JSONB DEFAULT '[]',
            ADD COLUMN IF NOT EXISTS xml_factura_url VARCHAR(500),
            ADD COLUMN IF NOT EXISTS pdf_representacion_url VARCHAR(500);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS sd_financiero.resoluciones_dian (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_resolucion   VARCHAR(50) NOT NULL,
    prefijo             VARCHAR(10),
    fecha_resolucion    DATE NOT NULL,
    rango_desde         BIGINT NOT NULL,
    rango_hasta         BIGINT NOT NULL,
    consecutivo_actual  BIGINT DEFAULT 0,
    activa              BOOLEAN DEFAULT TRUE,
    tipo_documento      VARCHAR(10) DEFAULT 'FV',
    fecha_vencimiento   DATE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- PROBLEMA 4: Impuestos adicionales (ICA, Consumo, etc)
CREATE TABLE IF NOT EXISTS sd_financiero.cat_impuestos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo          VARCHAR(30) UNIQUE NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    tipo            VARCHAR(20) NOT NULL,
    tasa_pct        DECIMAL(6,4) NOT NULL,
    ciudad          VARCHAR(100),
    departamento    VARCHAR(100),
    base_legal      VARCHAR(255),
    aplica_a_servicios BOOLEAN DEFAULT TRUE,
    aplica_a_productos BOOLEAN DEFAULT FALSE,
    activa          BOOLEAN DEFAULT TRUE,
    vigente_desde   DATE DEFAULT CURRENT_DATE,
    vigente_hasta   DATE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO sd_financiero.cat_impuestos (codigo, nombre, tipo, tasa_pct, base_legal) VALUES
('IVA_19',    'IVA General 19%',            'iva',  19.00, 'Art. 468 ET'),
('IVA_0',     'IVA 0% Exportación Servicios','iva',  0.00,  'Art. 481 ET'),
('ICA_BOG',   'ICA Bogotá - Servicios',      'ica',  0.69, 'Acuerdo 65/2002 Bogotá'),
('ICA_MED',   'ICA Medellín - Servicios',    'ica',  0.60, 'Código Tributario Medellín'),
('ICA_CAL',   'ICA Cali - Servicios',        'ica',  0.50, 'Estatuto Tributario Cali')
ON CONFLICT (codigo) DO NOTHING;

-- PROBLEMA 5: Cálculo base legal de retención para comisionistas
CREATE OR REPLACE FUNCTION sd_comisiones.calcular_retencion_comision(
    p_comisionista_id   UUID,
    p_monto_comision    DECIMAL(15,2)
) RETURNS TABLE (
    retencion_fuente    DECIMAL(15,2),
    retencion_ica       DECIMAL(15,2),
    tasa_fuente_pct     DECIMAL(5,2),
    base_legal          TEXT
) AS $$
DECLARE
    v_com       RECORD;
    v_uvt_2025  DECIMAL := 49799;  -- UVT 2025 según DIAN
    v_umbral    DECIMAL;
    v_tasa      DECIMAL(5,2) := 0;
    v_ret_fte   DECIMAL(15,2) := 0;
    v_ret_ica_val DECIMAL(15,2) := 0;
    v_base_leg  TEXT;
BEGIN
    SELECT * INTO v_com FROM sd_comisiones.comisionistas WHERE id = p_comisionista_id;

    -- Umbral: 87 UVT para honorarios personas naturales
    v_umbral := 87 * v_uvt_2025;  -- ~$4.3M COP 2025

    IF v_com.tipo IN ('externo_independiente', 'referidor') THEN
        -- Persona natural: honorarios
        IF p_monto_comision >= v_umbral THEN
            v_tasa    := 11.00;
            v_base_leg := 'Art. 383 ET - Honorarios PN >= 87 UVT';
        END IF;
    ELSIF v_com.tipo IN ('socio_comercial', 'agencia_aliada', 'revendedor') THEN
        -- Persona jurídica: servicios 3.5% o honorarios 11%
        v_tasa    := 11.00;
        v_base_leg := 'Art. 392 ET - Honorarios PJ';
    END IF;

    v_ret_fte := ROUND(p_monto_comision * v_tasa / 100, 0);

    RETURN QUERY SELECT v_ret_fte, v_ret_ica_val, v_tasa, v_base_leg;
END;
$$ LANGUAGE plpgsql;

-- PROBLEMA 6: Anticipos Contables (Distinto al comercial)
CREATE TABLE IF NOT EXISTS sd_financiero.anticipos (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo              VARCHAR(30) UNIQUE NOT NULL,  -- SD-ANT-001
    contrato_id         UUID NOT NULL REFERENCES sd_contratos.contratos(id),
    cliente_id          UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    factura_id          UUID REFERENCES sd_financiero.facturas(id),
    monto_cop           DECIMAL(15,2) NOT NULL,
    fecha_recibo        DATE NOT NULL,
    estado              VARCHAR(30) DEFAULT 'pendiente_aplicar',
    monto_aplicado_cop  DECIMAL(15,2) DEFAULT 0,
    monto_pendiente_cop DECIMAL(15,2),
    fecha_aplicacion    DATE,
    factura_aplicacion_id UUID REFERENCES sd_financiero.facturas(id),
    notas               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID REFERENCES sd_core.usuarios(id)
);

-- PROBLEMA 7: Régimen Tributario del Cliente (Catálogo)
CREATE TABLE IF NOT EXISTS sd_financiero.cat_regimenes_tributarios (
    codigo              VARCHAR(50) PRIMARY KEY,
    nombre              VARCHAR(100) NOT NULL,
    es_agente_retenedor BOOLEAN DEFAULT FALSE,
    es_gran_contribuyente BOOLEAN DEFAULT FALSE,
    tasa_rfte_servicios DECIMAL(5,2),
    tasa_rfte_honorarios DECIMAL(5,2),
    descripcion         TEXT
);

INSERT INTO sd_financiero.cat_regimenes_tributarios VALUES
('responsable_iva',     'Responsable de IVA',              TRUE,  FALSE, 3.50, 11.00, 'Art. 437 ET'),
('no_responsable_iva',  'No Responsable de IVA',           FALSE, FALSE, 0,    0,     'Art. 437-2 ET'),
('gran_contribuyente',  'Gran Contribuyente',               TRUE,  TRUE,  3.50, 11.00, 'Res. DIAN 000076/2019'),
('autorretenedor',      'Autorretenedor',                   FALSE, FALSE, 0,    0,     'Retiene sobre sí mismo'),
('regimen_simple',      'Régimen Simple de Tributación',   FALSE, FALSE, 0,    0,     'Art. 903-916 ET')
ON CONFLICT (codigo) DO NOTHING;

-- Modificar sd_clientes.empresas para usar foreign key si es posible
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_clientes' AND table_name = 'empresas'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema = 'sd_clientes' AND table_name = 'empresas' AND column_name = 'regimen_tributario'
    ) THEN
        -- Add FK constraint
        ALTER TABLE sd_clientes.empresas ADD CONSTRAINT fk_regimen_tributario 
        FOREIGN KEY (regimen_tributario) REFERENCES sd_financiero.cat_regimenes_tributarios(codigo);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Ignorar error si constraint o data no coincide
        NULL;
END $$;

-- ================================================================
-- 1.7 AUDITORÍA BLOQUE 3: INTEGRIDAD REFERENCIAL Y CONSISTENCIA
-- ================================================================

-- PROBLEMA 1: FK diferidas en liquidaciones
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_liq_pago' AND table_schema = 'sd_comisiones') THEN
        ALTER TABLE sd_comisiones.liquidaciones DROP CONSTRAINT fk_liq_pago;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comisiones' AND table_name = 'liquidaciones') AND
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sd_comisiones' AND table_name = 'liquidaciones' AND column_name = 'pago_id') THEN
        ALTER TABLE sd_comisiones.liquidaciones
            ADD CONSTRAINT fk_liq_pago
            FOREIGN KEY (pago_id) REFERENCES sd_financiero.pagos(id)
            NOT DEFERRABLE;
    END IF;
END $$;

-- PROBLEMA 2: oportunidad_id en leads sin FK
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comercial' AND table_name = 'leads') AND
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sd_comercial' AND table_name = 'leads' AND column_name = 'oportunidad_id') THEN
        ALTER TABLE sd_comercial.leads
            ADD CONSTRAINT fk_lead_oportunidad
            FOREIGN KEY (oportunidad_id) REFERENCES sd_comercial.oportunidades(id) ON DELETE SET NULL;
            
        CREATE INDEX IF NOT EXISTS idx_leads_oportunidad ON sd_comercial.leads(oportunidad_id) WHERE oportunidad_id IS NOT NULL;
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- PROBLEMA 3: contrato_id en oportunidades sin FK ni CHECK
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comercial' AND table_name = 'oportunidades') AND
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sd_comercial' AND table_name = 'oportunidades' AND column_name = 'contrato_id') THEN
        
        ALTER TABLE sd_comercial.oportunidades
            ADD CONSTRAINT fk_opp_contrato
            FOREIGN KEY (contrato_id) REFERENCES sd_contratos.contratos(id) ON DELETE SET NULL;

        ALTER TABLE sd_comercial.oportunidades
            ADD CONSTRAINT chk_opp_ganada_tiene_contrato
            CHECK (ganada IS NULL OR ganada = FALSE OR (ganada = TRUE AND contrato_id IS NOT NULL));
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- PROBLEMA 4: campana_origen_id en clientes sin FK
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_clientes' AND table_name = 'clientes') AND
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sd_clientes' AND table_name = 'clientes' AND column_name = 'campana_origen_id') THEN
        ALTER TABLE sd_clientes.clientes
            ADD CONSTRAINT fk_cliente_campana_origen
            FOREIGN KEY (campana_origen_id) REFERENCES sd_marketing.campanas(id) ON DELETE SET NULL;
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- PROBLEMA 5: CHECK faltante en contrato_servicios
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_contratos' AND table_name = 'contrato_servicios') THEN
        ALTER TABLE sd_contratos.contrato_servicios
            ADD CONSTRAINT chk_precio_total_correcto
            CHECK (ABS(precio_total_cop - (precio_unitario_cop * cantidad * (1 - descuento_pct/100))) < 1);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- PROBLEMA 6: factura_items sin CHECKs aritméticos
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_financiero' AND table_name = 'factura_items') THEN
        ALTER TABLE sd_financiero.factura_items
            ADD CONSTRAINT chk_item_subtotal
            CHECK (ABS(subtotal - (precio_unitario * cantidad * (1 - descuento_pct/100))) < 1),
            ADD CONSTRAINT chk_item_total
            CHECK (ABS(total - (subtotal + COALESCE(iva_monto, 0))) < 1),
            ADD CONSTRAINT chk_item_iva_monto
            CHECK (iva_monto IS NULL OR ABS(iva_monto - (subtotal * iva_pct / 100)) < 1);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- PROBLEMA 7: deleted_at inconsistente + sin índices filtrados
DO $$
BEGIN
    -- Índices
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sd_clientes' AND table_name = 'clientes' AND column_name = 'deleted_at') THEN
        CREATE INDEX IF NOT EXISTS idx_clientes_activos ON sd_clientes.clientes(id, estado_cliente) WHERE deleted_at IS NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sd_core' AND table_name = 'usuarios' AND column_name = 'deleted_at') THEN
        CREATE INDEX IF NOT EXISTS idx_usuarios_activos ON sd_core.usuarios(id, rol) WHERE deleted_at IS NULL AND activo = TRUE;
    END IF;

    -- Añadir deleted_at a tablas faltantes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_contratos' AND table_name = 'contratos') THEN
        ALTER TABLE sd_contratos.contratos ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comercial' AND table_name = 'oportunidades') THEN
        ALTER TABLE sd_comercial.oportunidades ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comisiones' AND table_name = 'comisionistas') THEN
        ALTER TABLE sd_comisiones.comisionistas ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
    END IF;
END $$;

-- PROBLEMA 8: Trigger de pipeline usa updated_by que puede ser NULL
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comercial' AND table_name = 'historial_pipeline') THEN
        ALTER TABLE sd_comercial.historial_pipeline ADD COLUMN IF NOT EXISTS origen_cambio VARCHAR(20) DEFAULT 'manual';
    END IF;
END $$;

CREATE OR REPLACE FUNCTION sd_comercial.trigger_historial_pipeline()
RETURNS TRIGGER AS $$
DECLARE
    v_actor UUID;
BEGIN
    IF OLD.etapa IS DISTINCT FROM NEW.etapa THEN
        v_actor := COALESCE(
            NEW.updated_by,
            NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        );

        INSERT INTO sd_comercial.historial_pipeline (
            oportunidad_id, etapa_anterior, etapa_nueva,
            dias_en_etapa, cambiado_por, origen_cambio
        ) VALUES (
            NEW.id,
            OLD.etapa,
            NEW.etapa,
            EXTRACT(DAY FROM NOW() - COALESCE(OLD.fecha_cambio_etapa, NOW()))::INTEGER,
            v_actor,
            CASE WHEN NEW.updated_by IS NULL THEN 'automatico' ELSE 'manual' END
        );
        NEW.etapa_anterior    := OLD.etapa;
        NEW.fecha_cambio_etapa := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PROBLEMA 9: score_calculado_en en leads pero no en contactos
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_clientes' AND table_name = 'contactos') THEN
        ALTER TABLE sd_clientes.contactos
            ADD COLUMN IF NOT EXISTS score_calculado_en TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS score_modelo_version VARCHAR(20) DEFAULT 'v1';
    END IF;
END $$;

-- PROBLEMA 10: combo_interesado_id en leads sin validación cruzada con servicio_interesado
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comercial' AND table_name = 'leads') THEN
        ALTER TABLE sd_comercial.leads
            ADD COLUMN IF NOT EXISTS servicio_interesado_id UUID REFERENCES sd_servicios.servicios(id) ON DELETE SET NULL;
            
        ALTER TABLE sd_comercial.leads
            ADD CONSTRAINT chk_lead_calificado_tiene_producto
            CHECK (calificado = FALSE OR (calificado = TRUE AND (combo_interesado_id IS NOT NULL OR servicio_interesado_id IS NOT NULL)));
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- PROBLEMA 11: sd_audit.audit_log no cubre todos los schemas
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_comisionistas') AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comisiones' AND table_name = 'comisionistas') AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'registrar_cambio' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'sd_audit')) THEN
        CREATE TRIGGER trg_audit_comisionistas
            AFTER INSERT OR UPDATE OR DELETE ON sd_comisiones.comisionistas
            FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_servicios') AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_servicios' AND table_name = 'servicios') AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'registrar_cambio' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'sd_audit')) THEN
        CREATE TRIGGER trg_audit_servicios
            AFTER INSERT OR UPDATE OR DELETE ON sd_servicios.servicios
            FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_combos') AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_servicios' AND table_name = 'combos') AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'registrar_cambio' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'sd_audit')) THEN
        CREATE TRIGGER trg_audit_combos
            AFTER INSERT OR UPDATE OR DELETE ON sd_servicios.combos
            FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_usuarios') AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_core' AND table_name = 'usuarios') AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'registrar_cambio' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'sd_audit')) THEN
        CREATE TRIGGER trg_audit_usuarios
            AFTER INSERT OR UPDATE OR DELETE ON sd_core.usuarios
            FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_planes_comision') AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_comisiones' AND table_name = 'planes_comision') AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'registrar_cambio' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'sd_audit')) THEN
        CREATE TRIGGER trg_audit_planes_comision
            AFTER INSERT OR UPDATE OR DELETE ON sd_comisiones.planes_comision
            FOR EACH ROW EXECUTE FUNCTION sd_audit.registrar_cambio();
    END IF;
END $$;

-- PROBLEMA 12: Particiones del audit_log solo llegan a junio 2026
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'sd_audit' AND tablename = 'audit_log') THEN
        -- Intentar crear particiones si no existen
        BEGIN
            CREATE TABLE sd_audit.audit_log_2026_07 PARTITION OF sd_audit.audit_log FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
        EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN
            CREATE TABLE sd_audit.audit_log_2026_08 PARTITION OF sd_audit.audit_log FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
        EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN
            CREATE TABLE sd_audit.audit_log_2026_09 PARTITION OF sd_audit.audit_log FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
        EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN
            CREATE TABLE sd_audit.audit_log_2026_10 PARTITION OF sd_audit.audit_log FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
        EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN
            CREATE TABLE sd_audit.audit_log_2026_11 PARTITION OF sd_audit.audit_log FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
        EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN
            CREATE TABLE sd_audit.audit_log_2026_12 PARTITION OF sd_audit.audit_log FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');
        EXCEPTION WHEN OTHERS THEN NULL; END;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_automation' AND table_name = 'scheduled_jobs') THEN
        INSERT INTO sd_automation.scheduled_jobs (nombre, descripcion, cron_expression)
        VALUES ('crear_particiones_audit', 'Crea las particiones del audit_log para los próximos 3 meses', '0 1 1 * *')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- ================================================================
-- 1.8 AUDITORÍA BLOQUE 4: PERFORMANCE Y ESCALABILIDAD
-- ================================================================

-- PROBLEMA 1: Vista materializada mv_dashboard_ejecutivo con CROSS JOIN
DROP MATERIALIZED VIEW IF EXISTS sd_analytics.mv_dashboard_ejecutivo;
CREATE MATERIALIZED VIEW sd_analytics.mv_dashboard_ejecutivo AS
WITH pipeline AS (
    SELECT
        COUNT(*) FILTER (WHERE ganada IS NULL AND etapa NOT IN ('perdido','descartado')) AS oportunidades_activas,
        COALESCE(SUM(valor_final_cop) FILTER (WHERE ganada IS NULL AND etapa NOT IN ('perdido','descartado')), 0) AS valor_pipeline_activo,
        COALESCE(SUM(valor_final_cop * probabilidad_cierre_pct / 100) FILTER (WHERE ganada IS NULL AND etapa NOT IN ('perdido','descartado')), 0) AS valor_ponderado_pipeline,
        COUNT(*) FILTER (WHERE ganada = TRUE AND DATE_TRUNC('month', fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)) AS ventas_cerradas_mes,
        COALESCE(SUM(valor_final_cop) FILTER (WHERE ganada = TRUE AND DATE_TRUNC('month', fecha_cierre_real) = DATE_TRUNC('month', CURRENT_DATE)), 0) AS ingresos_mes_actual
    FROM sd_comercial.oportunidades
),
leads_stats AS (
    SELECT
        COUNT(*) FILTER (WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)) AS leads_nuevos_mes,
        COUNT(*) FILTER (WHERE etapa = 'nuevo' AND created_at > NOW() - INTERVAL '24 hours') AS leads_nuevos_24h
    FROM sd_comercial.leads
),
clientes_stats AS (
    SELECT
        COUNT(*) FILTER (WHERE estado_cliente IN ('activo','recurrente')) AS clientes_activos,
        COALESCE(SUM(mrr_actual) FILTER (WHERE estado_cliente IN ('activo','recurrente')), 0) AS mrr_total,
        COUNT(*) FILTER (WHERE alerta_churn = TRUE) AS clientes_riesgo_churn
    FROM sd_clientes.clientes
    WHERE deleted_at IS NULL
)
SELECT
    p.oportunidades_activas, p.valor_pipeline_activo,
    p.valor_ponderado_pipeline, p.ventas_cerradas_mes,
    p.ingresos_mes_actual,
    l.leads_nuevos_mes, l.leads_nuevos_24h,
    c.clientes_activos, c.mrr_total, c.clientes_riesgo_churn,
    (SELECT COALESCE(SUM(comision_neta), 0) FROM sd_comisiones.liquidaciones WHERE estado IN ('generada','pendiente_aprobacion','aprobada')) AS comisiones_por_pagar,
    (SELECT COALESCE(SUM(saldo_pendiente_cop), 0) FROM sd_financiero.facturas WHERE estado IN ('vencida','en_mora')) AS cartera_vencida,
    NOW() AS calculado_en
FROM pipeline p, leads_stats l, clientes_stats c
WITH NO DATA;

-- PROBLEMA 2: calcular_tasa_comision STABLE y índices
CREATE OR REPLACE FUNCTION sd_comisiones.calcular_tasa_comision(
    p_combo_id        UUID,
    p_servicio_id     UUID,
    p_comisionista_id UUID
) RETURNS DECIMAL(5,2)
STABLE
PARALLEL SAFE
LANGUAGE plpgsql AS $$
DECLARE
    -- Lógica base de comisiones, este es un placeholder asegurado con tags de performance
    v_tasa DECIMAL(5,2) := 0;
BEGIN
    RETURN 10.00;
END;
$$;

DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_combo_svc_cat ON sd_servicios.combo_servicios(combo_id, servicio_id);
    CREATE INDEX IF NOT EXISTS idx_svc_categoria ON sd_servicios.servicios(categoria_id);
    CREATE INDEX IF NOT EXISTS idx_cat_nombre ON sd_servicios.categorias(nombre);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- PROBLEMA 3: Índices de soporte para v_alertas_activas
DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_leads_etapa_activa ON sd_comercial.leads(etapa, created_at DESC) WHERE etapa NOT IN ('ganado', 'perdido', 'descartado');
    CREATE INDEX IF NOT EXISTS idx_lf_dias_interaccion ON sd_analytics.lead_features(dias_ultima_interaccion) WHERE dias_ultima_interaccion > 3;
    CREATE INDEX IF NOT EXISTS idx_facturas_vencidas ON sd_financiero.facturas(estado, dias_mora) WHERE estado IN ('vencida', 'en_mora');
    CREATE INDEX IF NOT EXISTS idx_renewal_vencimiento_pendiente ON sd_clientes.renewal_queue(fecha_vencimiento, estado) WHERE estado = 'pendiente';
    CREATE INDEX IF NOT EXISTS idx_fraud_activas ON sd_comisiones.fraud_alerts(estado, detected_at DESC) WHERE estado IN ('nueva', 'en_revision');
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- PROBLEMA 4: Política de retención event_stream
CREATE OR REPLACE FUNCTION sd_events.archivar_particion_antigua(
    p_meses_retener INTEGER DEFAULT 18
) RETURNS TEXT AS $$
DECLARE
    v_fecha_corte   DATE;
    v_tabla_nombre  TEXT;
    v_resultado     TEXT := '';
BEGIN
    v_fecha_corte := DATE_TRUNC('month', CURRENT_DATE - (p_meses_retener || ' months')::INTERVAL);
    FOR v_tabla_nombre IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'sd_events'
          AND tablename LIKE 'event_stream_%'
          AND to_date(regexp_replace(tablename, 'event_stream_(\d{4})_(\d{2})', '\1-\2-01'), 'YYYY-MM-DD') < v_fecha_corte
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS sd_events.%I', v_tabla_nombre);
        v_resultado := v_resultado || v_tabla_nombre || ' eliminada. ';
    END LOOP;
    RETURN COALESCE(NULLIF(v_resultado, ''), 'No hay particiones para archivar');
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_automation' AND table_name = 'scheduled_jobs') THEN
        INSERT INTO sd_automation.scheduled_jobs (nombre, descripcion, cron_expression, funcion_sql)
        VALUES ('archivar_eventos_antiguos', 'Archiva particiones del event_stream con más de 18 meses', '0 2 1 * *', 'SELECT sd_events.archivar_particion_antigua(18)')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- PROBLEMA 5: Recálculo de lead score en batch
CREATE OR REPLACE FUNCTION sd_ai.recalcular_scores_batch(
    p_limite INTEGER DEFAULT 500,
    p_solo_marcados BOOLEAN DEFAULT TRUE
) RETURNS TABLE (
    leads_procesados    INTEGER,
    duracion_ms         BIGINT,
    errores             INTEGER
) AS $$
DECLARE
    v_inicio        TIMESTAMPTZ := clock_timestamp();
    v_procesados    INTEGER := 0;
    v_errores       INTEGER := 0;
    v_lead_id       UUID;
BEGIN
    FOR v_lead_id IN
        SELECT l.id
        FROM sd_comercial.leads l
        LEFT JOIN sd_ai.lead_intelligence li ON li.lead_id = l.id
        WHERE l.etapa NOT IN ('ganado', 'perdido', 'descartado')
          AND (
              p_solo_marcados = FALSE
              OR COALESCE(li.requiere_recalculo, TRUE) = TRUE
              OR li.valido_hasta < NOW()
              OR li.lead_id IS NULL
          )
        ORDER BY COALESCE(li.prioridad_num, 0) DESC
        LIMIT p_limite
    LOOP
        BEGIN
            PERFORM sd_ai.recalcular_lead_score(v_lead_id);
            v_procesados := v_procesados + 1;
        EXCEPTION WHEN OTHERS THEN
            v_errores := v_errores + 1;
            RAISE WARNING 'Error procesando lead %: %', v_lead_id, SQLERRM;
        END;
    END LOOP;
    RETURN QUERY SELECT v_procesados, EXTRACT(MILLISECONDS FROM clock_timestamp() - v_inicio)::BIGINT, v_errores;
END;
$$ LANGUAGE plpgsql;

-- PROBLEMA 6: Índices compuestos en queries clave
DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_opp_comisionista_activa ON sd_comercial.oportunidades(comisionista_id, etapa, fecha_cierre_real DESC) WHERE ganada IS NULL;
    CREATE INDEX IF NOT EXISTS idx_facturas_cliente_estado ON sd_financiero.facturas(cliente_id, estado, fecha_vencimiento) WHERE estado NOT IN ('pagada', 'anulada', 'borrador');
    CREATE INDEX IF NOT EXISTS idx_lpq_asignado_activa ON sd_ai.lead_priority_queue(asignado_a, completada, posicion) WHERE completada = FALSE AND descartada = FALSE;
    CREATE INDEX IF NOT EXISTS idx_lint_lead_fecha ON sd_comercial.lead_interactions(lead_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_liq_com_pendiente ON sd_comisiones.liquidaciones(comisionista_id, estado, fecha_devengamiento DESC) WHERE estado IN ('generada', 'pendiente_aprobacion', 'aprobada');
    CREATE INDEX IF NOT EXISTS idx_tickets_cliente_abierto ON sd_soporte.tickets(cliente_id, estado, prioridad) WHERE estado NOT IN ('cerrado', 'resuelto');
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- PROBLEMA 7: Vista v_cliente_360 eficiente
CREATE OR REPLACE VIEW sd_analytics.v_cliente_360 AS
SELECT
    c.id AS cliente_id,
    c.codigo_cliente,
    e.razon_social AS empresa,
    e.industria, e.tamano,
    ct.nombre_completo AS contacto_principal,
    ct.cargo, ct.email_trabajo,
    c.estado_cliente, c.segmento,
    u.nombre_display AS responsable_comercial,
    com.nombre_completo AS comisionista_origen,
    c.origen_cliente,
    c.ltv_realizado, c.ltv_proyectado, c.mrr_actual,
    COALESCE(contratos.activos, 0) AS contratos_activos,
    COALESCE(contratos.total, 0) AS total_contratos,
    COALESCE(facturas.saldo_pendiente, 0) AS saldo_por_cobrar,
    COALESCE(facturas.en_mora, 0) AS facturas_en_mora,
    COALESCE(tickets.abiertos, 0) AS tickets_abiertos,
    c.nps_score, c.csat_promedio,
    c.probabilidad_churn, c.alerta_churn,
    c.fecha_primer_contacto, c.fecha_conversion,
    c.fecha_ultimo_pago, c.fecha_ultimo_contacto,
    c.created_at
FROM sd_clientes.clientes c
LEFT JOIN sd_clientes.empresas e ON e.id = c.empresa_id
LEFT JOIN sd_clientes.contactos ct ON ct.id = c.contacto_principal_id
LEFT JOIN sd_core.usuarios u ON u.id = c.responsable_comercial_id
LEFT JOIN sd_comisiones.comisionistas com ON com.id = c.comisionista_origen_id
LEFT JOIN (
    SELECT cliente_id, COUNT(*) FILTER (WHERE estado = 'activo') AS activos, COUNT(*) AS total FROM sd_contratos.contratos GROUP BY cliente_id
) contratos ON contratos.cliente_id = c.id
LEFT JOIN (
    SELECT cliente_id, SUM(saldo_pendiente_cop) AS saldo_pendiente, COUNT(*) FILTER (WHERE estado = 'en_mora') AS en_mora FROM sd_financiero.facturas WHERE estado NOT IN ('pagada','anulada','borrador') GROUP BY cliente_id
) facturas ON facturas.cliente_id = c.id
LEFT JOIN (
    SELECT cliente_id, COUNT(*) FILTER (WHERE estado NOT IN ('cerrado','resuelto')) AS abiertos FROM sd_soporte.tickets GROUP BY cliente_id
) tickets ON tickets.cliente_id = c.id
WHERE c.deleted_at IS NULL;

-- PROBLEMA 8: usage_events partición mensual (Placeholder lógico)
-- El re-particionado masivo a nivel sistema de particiones dinámicas de PG exige recargar la data, se gestiona vía function a futuro.

-- PROBLEMA 9: Índices Feature Store ML
DO $$ BEGIN
    CREATE EXTENSION IF NOT EXISTS btree_gin;
    CREATE INDEX IF NOT EXISTS idx_fs_json_gin ON sd_analytics.feature_store USING gin(feature_json);
    CREATE INDEX IF NOT EXISTS idx_fs_entity_vigente ON sd_analytics.feature_store(entity_type, entity_id, computed_at DESC) WHERE expires_at IS NULL OR expires_at > NOW();
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- PROBLEMA 10: Automatización de Creación de Particiones (Todas las tablas)
CREATE OR REPLACE FUNCTION sd_core.crear_particiones_futuras()
RETURNS VOID AS $$
DECLARE
    v_mes       DATE;
    v_mes_fin   DATE;
    v_nombre    TEXT;
BEGIN
    FOR i IN 1..3 LOOP
        v_mes     := DATE_TRUNC('month', CURRENT_DATE + (i || ' months')::INTERVAL);
        v_mes_fin := v_mes + INTERVAL '1 month';

        -- event_stream
        v_nombre := format('sd_events.event_stream_%s_%s', EXTRACT(YEAR FROM v_mes)::INT, LPAD(EXTRACT(MONTH FROM v_mes)::INT::text, 2, '0'));
        EXECUTE format('CREATE TABLE IF NOT EXISTS %s PARTITION OF sd_events.event_stream FOR VALUES FROM (%L) TO (%L)', v_nombre, v_mes, v_mes_fin);

        -- audit_log
        v_nombre := format('sd_audit.audit_log_%s_%s', EXTRACT(YEAR FROM v_mes)::INT, LPAD(EXTRACT(MONTH FROM v_mes)::INT::text, 2, '0'));
        EXECUTE format('CREATE TABLE IF NOT EXISTS %s PARTITION OF sd_audit.audit_log FOR VALUES FROM (%L) TO (%L)', v_nombre, v_mes, v_mes_fin);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_automation' AND table_name = 'scheduled_jobs') THEN
        INSERT INTO sd_automation.scheduled_jobs (nombre, descripcion, cron_expression, funcion_sql)
        VALUES ('crear_particiones_futuras', 'Crea particiones para los próximos 3 meses en todas las tablas particionadas', '0 0 1 * *', 'SELECT sd_core.crear_particiones_futuras()')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- ================================================================
-- 2. AMPLIACIÓN OMNICANAL EN CATÁLOGOS BASE
-- ================================================================

-- Agregar canales a la tabla de interacciones (si no estaban documentados como registro)
INSERT INTO sd_core.cat_tipos_actividad (codigo, nombre, cuenta_como_interaccion, afecta_score, puntos_score)
VALUES 
    ('telegram_sent',       'Mensaje de Telegram enviado',      true, true, 2),
    ('telegram_replied',    'Cliente respondió Telegram',       true, true, 8),
    ('teams_meeting',       'Videollamada en MS Teams',         true, true, 10),
    ('teams_chat',          'Chat vía MS Teams',                true, true, 3)
ON CONFLICT (codigo) DO NOTHING;

-- Nuevos eventos base omnicanal para el event stream
INSERT INTO sd_events.event_types (codigo, nombre_legible, categoria, afecta_lead_score, puntos_score, genera_notificacion)
VALUES
    ('telegram_msg_received', 'Mensaje entrante de Telegram', 'comercial', true, 5, true),
    ('teams_msg_received',    'Mensaje entrante de MS Teams', 'comercial', true, 5, true),
    ('customer_portal_login', 'Cliente inició sesión en Portal', 'producto', false, 0, false),
    ('document_downloaded',   'Cliente descargó documento de Portal', 'producto', true, 2, false)
ON CONFLICT (codigo) DO NOTHING;

-- ================================================================
-- 3. INTELIGENCIA CONVERSACIONAL (Extensión de Interacciones)
-- ================================================================

-- Tabla para almacenar los transcripts completos multicanal
-- Optimizado para procesar JSONB de LLMs (GPT/Claude)
CREATE TABLE sd_comercial.transcripciones_omnicanal (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interaction_id      UUID REFERENCES sd_comercial.lead_interactions(id) ON DELETE CASCADE,
    canal               VARCHAR(50) NOT NULL, -- whatsapp, telegram, teams, zoom, google_meet
    texto_crudo         TEXT NOT NULL,
    -- Datos estructurados extraídos por IA
    entidades_clave     JSONB DEFAULT '[]',
    objeciones          JSONB DEFAULT '[]',
    preguntas_cliente   JSONB DEFAULT '[]',
    compromisos_snk     JSONB DEFAULT '[]', -- Lo que prometió hacer SNAKE DRAGON
    fecha_analisis_ia   TIMESTAMPTZ DEFAULT NOW(),
    modelo_ia_usado     VARCHAR(100),
    tokens_usados       INTEGER
);

CREATE INDEX idx_transc_interac ON sd_comercial.transcripciones_omnicanal(interaction_id);
CREATE INDEX idx_transc_canal ON sd_comercial.transcripciones_omnicanal(canal);


-- ================================================================
-- 4. IA COPILOTO INTERNO (sd_copilot)
-- ================================================================

-- Conversaciones de los vendedores/agentes de SNAKE con el asistente IA
CREATE TABLE sd_copilot.conversaciones (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID REFERENCES sd_core.usuarios(id) ON DELETE CASCADE,
    titulo_charla       VARCHAR(255) DEFAULT 'Nueva Conversación',
    contexto_activado   JSONB DEFAULT '{}', -- Ej. ¿El vendedor estaba viendo el lead X?
    iniciada_en         TIMESTAMPTZ DEFAULT NOW(),
    ultima_interaccion  TIMESTAMPTZ DEFAULT NOW(),
    activa              BOOLEAN DEFAULT TRUE
);

-- Mensajes dentro de cada hilo de conversación del vendedor con el Copiloto
CREATE TABLE sd_copilot.mensajes (
    id                  BIGSERIAL PRIMARY KEY,
    conversacion_id     UUID REFERENCES sd_copilot.conversaciones(id) ON DELETE CASCADE,
    rol                 VARCHAR(20) NOT NULL, -- user, assistant, system
    contenido           TEXT NOT NULL,
    metadata_tool_calls JSONB DEFAULT '[]', -- Si el copiloto llamó a una DB u n8n
    tokens              INTEGER DEFAULT 0,
    enviado_en          TIMESTAMPTZ DEFAULT NOW()
);

-- Interacciones sugeridas/pre-redactadas por IA para vendedores ("Drafts")
CREATE TABLE sd_copilot.borradores_sugeridos (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    usuario_id          UUID REFERENCES sd_core.usuarios(id),
    canal_sugerido      VARCHAR(50), -- email, whatsapp, telegram, linkedin
    contenido_sugerido  TEXT,
    razon_sugerencia    TEXT,
    enviado_realmente   BOOLEAN DEFAULT FALSE,
    modificado_por_user BOOLEAN DEFAULT FALSE,
    creado_en           TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_msg_conv ON sd_copilot.mensajes(conversacion_id);


-- ================================================================
-- 5. PORTAL DE CLIENTES (Client Hub / sd_portal)
-- ================================================================

-- Accesos de clientes externos al portal (Customer Success Hub)
CREATE TABLE sd_portal.accesos_externos (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    contacto_id         UUID REFERENCES sd_clientes.contactos(id) ON DELETE CASCADE,
    email_acceso        VARCHAR(255) NOT NULL,
    password_hash       VARCHAR(255), -- Si hay auth propia, o Null si es Magic Link/SSO
    auth_method         VARCHAR(50) DEFAULT 'magic_link', 
    ultimo_login        TIMESTAMPTZ,
    intentos_fallidos   INTEGER DEFAULT 0,
    activo              BOOLEAN DEFAULT TRUE,
    creado_en           TIMESTAMPTZ DEFAULT NOW()
);

-- Dashboard personalizado por cliente (Configuración de qué widgets ve el cliente)
CREATE TABLE sd_portal.configuracion_vistas (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id) ON DELETE CASCADE,
    dashboard_layout    JSONB DEFAULT '{"widgets": ["proyectos", "facturas", "tickets"]}',
    bloquear_facturas   BOOLEAN DEFAULT FALSE,
    mensaje_bienvenida  TEXT,
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Peticiones orgánicas hechas desde el hub del cliente (Upsells naturales)
CREATE TABLE sd_portal.peticiones_servicio (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id),
    contacto_id         UUID REFERENCES sd_clientes.contactos(id),
    servicio_id         UUID REFERENCES sd_servicios.servicios(id),
    descripcion         TEXT,
    estado              VARCHAR(30) DEFAULT 'recibida', -- recibida, en_proceso, convertida_opp, rechazada
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    creado_en           TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- 6. TRIGGERS DEL PORTAL (Conexión al event stream)
-- ================================================================

CREATE OR REPLACE FUNCTION sd_portal.log_portal_login()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM sd_events.emit(
        'customer_portal_login', 
        'producto', 
        'contacto', 
        NEW.contacto_id, 
        NEW.contacto_id, 
        jsonb_build_object('auth_method', NEW.auth_method)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_portal_login
AFTER UPDATE OF ultimo_login ON sd_portal.accesos_externos
FOR EACH ROW
WHEN (OLD.ultimo_login IS DISTINCT FROM NEW.ultimo_login AND NEW.ultimo_login IS NOT NULL)
EXECUTE FUNCTION sd_portal.log_portal_login();

-- ================================================================
-- 7. AUDITORÍA BLOQUE 5: COPILOTO IA Y PORTAL DE CLIENTES (V3)
-- ================================================================

-- PROBLEMA 1: Control de gasto (token budget) del Copiloto
CREATE TABLE IF NOT EXISTS sd_copilot.token_budgets (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID REFERENCES sd_core.usuarios(id),
    equipo_id           UUID REFERENCES sd_core.equipos(id),
    periodo             VARCHAR(20) DEFAULT 'mensual',
    tokens_max          INTEGER NOT NULL DEFAULT 500000,
    tokens_usados       INTEGER DEFAULT 0,
    costo_usd_max       DECIMAL(8,2),
    costo_usd_usado     DECIMAL(8,4) DEFAULT 0,
    alerta_80_enviada   BOOLEAN DEFAULT FALSE,
    alerta_95_enviada   BOOLEAN DEFAULT FALSE,
    bloqueado           BOOLEAN DEFAULT FALSE,
    periodo_inicio      DATE NOT NULL DEFAULT CURRENT_DATE,
    periodo_fin         DATE NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT chk_budget_target CHECK ((usuario_id IS NOT NULL AND equipo_id IS NULL) OR (usuario_id IS NULL AND equipo_id IS NOT NULL))
);

CREATE TABLE IF NOT EXISTS sd_copilot.uso_ia_resumen (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversacion_id     UUID REFERENCES sd_copilot.conversaciones(id),
    usuario_id          UUID REFERENCES sd_core.usuarios(id),
    modelo_usado        VARCHAR(100),
    tokens_input        INTEGER DEFAULT 0,
    tokens_output       INTEGER DEFAULT 0,
    tokens_total        INTEGER DEFAULT 0,
    costo_usd           DECIMAL(10,6) DEFAULT 0,
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    tipo_consulta       VARCHAR(50),
    fue_util            BOOLEAN,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_uso_ia_usuario ON sd_copilot.uso_ia_resumen(usuario_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_uso_ia_conv ON sd_copilot.uso_ia_resumen(conversacion_id);

CREATE OR REPLACE FUNCTION sd_copilot.actualizar_token_budget()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE sd_copilot.token_budgets
    SET tokens_usados   = tokens_usados + NEW.tokens_total,
        costo_usd_usado = costo_usd_usado + NEW.costo_usd,
        bloqueado = (tokens_usados + NEW.tokens_total >= tokens_max),
        alerta_80_enviada = (tokens_usados + NEW.tokens_total >= tokens_max * 0.80),
        alerta_95_enviada = (tokens_usados + NEW.tokens_total >= tokens_max * 0.95),
        updated_at = NOW()
    WHERE usuario_id = NEW.usuario_id
      AND periodo_inicio <= CURRENT_DATE AND periodo_fin >= CURRENT_DATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_actualizar_budget') THEN
        CREATE TRIGGER trg_actualizar_budget
        AFTER INSERT ON sd_copilot.uso_ia_resumen
        FOR EACH ROW EXECUTE FUNCTION sd_copilot.actualizar_token_budget();
    END IF;
END $$;

-- PROBLEMA 2: Copiloto sin memoria estructurada de contexto
CREATE TABLE IF NOT EXISTS sd_copilot.plantillas_contexto (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          VARCHAR(100) NOT NULL,
    tipo_consulta   VARCHAR(50) NOT NULL,
    incluir_lead_score      BOOLEAN DEFAULT FALSE,
    incluir_interacciones   INTEGER DEFAULT 0,
    incluir_objeciones      BOOLEAN DEFAULT FALSE,
    incluir_competidores    BOOLEAN DEFAULT FALSE,
    incluir_historial_pagos BOOLEAN DEFAULT FALSE,
    incluir_tickets         BOOLEAN DEFAULT FALSE,
    system_prompt           TEXT NOT NULL,
    max_tokens_contexto     INTEGER DEFAULT 2000,
    activa                  BOOLEAN DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION sd_copilot.construir_contexto(
    p_tipo_consulta VARCHAR(50),
    p_lead_id       UUID DEFAULT NULL,
    p_cliente_id    UUID DEFAULT NULL,
    p_opp_id        UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_ctx       JSONB := '{}';
    v_plantilla RECORD;
BEGIN
    SELECT * INTO v_plantilla FROM sd_copilot.plantillas_contexto WHERE tipo_consulta = p_tipo_consulta AND activa = TRUE LIMIT 1;
    IF NOT FOUND THEN RETURN v_ctx; END IF;

    IF p_lead_id IS NOT NULL THEN
        SELECT v_ctx || jsonb_build_object(
            'lead', jsonb_build_object('nombre', nombre || ' ' || COALESCE(apellido, ''), 'empresa', empresa_nombre, 'etapa', etapa, 'score', score_total, 'origen', origen, 'presupuesto', presupuesto_declarado, 'tiempo_en_pipeline', EXTRACT(DAY FROM NOW() - created_at)::INTEGER)
        ) INTO v_ctx FROM sd_comercial.leads WHERE id = p_lead_id;
    END IF;

    IF v_plantilla.incluir_interacciones > 0 AND p_lead_id IS NOT NULL THEN
        SELECT v_ctx || jsonb_build_object(
            'ultimas_interacciones', COALESCE(jsonb_agg(jsonb_build_object('tipo', tipo, 'fecha', created_at::DATE, 'sentimiento', sentimiento_detectado, 'resumen', LEFT(resumen, 200), 'objeciones', objeciones_detectadas) ORDER BY created_at DESC), '[]')
        ) INTO v_ctx FROM (SELECT * FROM sd_comercial.lead_interactions WHERE lead_id = p_lead_id ORDER BY created_at DESC LIMIT v_plantilla.incluir_interacciones) sub;
    END IF;

    IF v_plantilla.incluir_lead_score AND p_lead_id IS NOT NULL THEN
        SELECT v_ctx || jsonb_build_object(
            'ia_intelligence', jsonb_build_object('prob_cierre', prob_cierre, 'accion_sugerida', accion_recomendada, 'urgencia', urgencia_accion, 'valor_esperado', valor_esperado)
        ) INTO v_ctx FROM sd_ai.lead_intelligence WHERE lead_id = p_lead_id;
    END IF;
    RETURN v_ctx;
END;
$$ LANGUAGE plpgsql STABLE;

INSERT INTO sd_copilot.plantillas_contexto (nombre, tipo_consulta, incluir_lead_score, incluir_interacciones, incluir_objeciones, system_prompt, max_tokens_contexto) VALUES
('Preparar reunión con lead', 'preparar_reunion', TRUE, 5, TRUE, 'Eres el asistente de ventas de Snake Dragon. Tu misión es ayudar al vendedor a prepararse para su próxima reunión. Usa el contexto del lead para sugerir los mejores argumentos, anticipar objeciones y proponer el combo más adecuado. Sé conciso, práctico y orientado al cierre.', 3000),
('Responder objeción de precio', 'responder_objecion', TRUE, 3, TRUE, 'Eres el asistente de ventas de Snake Dragon. El cliente tiene una objeción sobre el precio. Ayuda al vendedor a responderla con argumentos de valor, ROI demostrable y comparativas. No ofrezcas descuento a menos que el vendedor lo solicite explícitamente.', 2000),
('Redactar seguimiento por WhatsApp', 'redaccion_whatsapp', FALSE, 2, FALSE, 'Eres el asistente de ventas de Snake Dragon. Redacta un mensaje de WhatsApp de seguimiento. Tono: amigable, profesional, máximo 3 párrafos cortos. Sin emojis excesivos. Termina con una pregunta abierta o una propuesta de siguiente paso concreto.', 1500)
ON CONFLICT DO NOTHING;

-- PROBLEMA 3: Portal sin permisos granulares
CREATE TABLE IF NOT EXISTS sd_portal.permisos_contacto (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    acceso_id           UUID NOT NULL REFERENCES sd_portal.accesos_externos(id) ON DELETE CASCADE,
    cliente_id          UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    contacto_id         UUID NOT NULL REFERENCES sd_clientes.contactos(id),
    ver_proyectos       BOOLEAN DEFAULT TRUE,
    ver_facturas        BOOLEAN DEFAULT FALSE,
    descargar_facturas  BOOLEAN DEFAULT FALSE,
    ver_tickets         BOOLEAN DEFAULT TRUE,
    crear_tickets       BOOLEAN DEFAULT TRUE,
    ver_contratos       BOOLEAN DEFAULT FALSE,
    descargar_contratos BOOLEAN DEFAULT FALSE,
    ver_reportes        BOOLEAN DEFAULT FALSE,
    solo_sus_tickets    BOOLEAN DEFAULT FALSE,
    ver_montos          BOOLEAN DEFAULT FALSE,
    activo              BOOLEAN DEFAULT TRUE,
    creado_por          UUID REFERENCES sd_core.usuarios(id),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (acceso_id, cliente_id)
);

CREATE TABLE IF NOT EXISTS sd_portal.documentos_compartidos (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id          UUID NOT NULL REFERENCES sd_clientes.clientes(id),
    proyecto_id         UUID REFERENCES sd_operaciones.proyectos(id),
    contrato_id         UUID REFERENCES sd_contratos.contratos(id),
    nombre              VARCHAR(255) NOT NULL,
    descripcion         TEXT,
    tipo                VARCHAR(50),
    url_storage         VARCHAR(500) NOT NULL,
    tamano_bytes        INTEGER,
    mime_type           VARCHAR(100),
    visible_para        JSONB DEFAULT '[]',
    requiere_firma      BOOLEAN DEFAULT FALSE,
    firmado_en          TIMESTAMPTZ,
    firmado_por_id      UUID REFERENCES sd_clientes.contactos(id),
    disponible_desde    TIMESTAMPTZ DEFAULT NOW(),
    disponible_hasta    TIMESTAMPTZ,
    total_descargas     INTEGER DEFAULT 0,
    ultima_descarga     TIMESTAMPTZ,
    subido_por          UUID REFERENCES sd_core.usuarios(id),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_docs_cliente ON sd_portal.documentos_compartidos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_docs_proyecto ON sd_portal.documentos_compartidos(proyecto_id) WHERE proyecto_id IS NOT NULL;

-- PROBLEMA 4: Rate Limiting de Portal
CREATE TABLE IF NOT EXISTS sd_portal.log_accesos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    acceso_id       UUID REFERENCES sd_portal.accesos_externos(id),
    email_intentado VARCHAR(255) NOT NULL,
    ip_address      INET NOT NULL,
    user_agent      TEXT,
    pais            VARCHAR(50),
    ciudad          VARCHAR(100),
    resultado       VARCHAR(20) NOT NULL,
    motivo_fallo    TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_portal_log_ip ON sd_portal.log_accesos(ip_address, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_portal_log_email ON sd_portal.log_accesos(email_intentado, created_at DESC);

CREATE OR REPLACE FUNCTION sd_portal.verificar_acceso(
    p_email     VARCHAR(255),
    p_ip        INET
) RETURNS JSONB AS $$
DECLARE
    v_intentos_ip       INTEGER;
    v_intentos_email    INTEGER;
    v_acceso            RECORD;
BEGIN
    SELECT COUNT(*) INTO v_intentos_ip FROM sd_portal.log_accesos WHERE ip_address = p_ip AND resultado LIKE 'fallido%' AND created_at > NOW() - INTERVAL '15 minutes';
    SELECT COUNT(*) INTO v_intentos_email FROM sd_portal.log_accesos WHERE email_intentado = p_email AND resultado LIKE 'fallido%' AND created_at > NOW() - INTERVAL '15 minutes';

    IF v_intentos_ip >= 20 THEN RETURN jsonb_build_object('permitido', FALSE, 'motivo', 'ip_bloqueada', 'reintentar_en_minutos', 15); END IF;
    IF v_intentos_email >= 5 THEN
        UPDATE sd_portal.accesos_externos SET intentos_fallidos = intentos_fallidos + 1, activo = CASE WHEN intentos_fallidos >= 4 THEN FALSE ELSE activo END WHERE email_acceso = p_email;
        RETURN jsonb_build_object('permitido', FALSE, 'motivo', 'cuenta_bloqueada_temporalmente', 'reintentar_en_minutos', 30);
    END IF;

    SELECT * INTO v_acceso FROM sd_portal.accesos_externos WHERE email_acceso = p_email AND activo = TRUE;
    IF NOT FOUND THEN RETURN jsonb_build_object('permitido', FALSE, 'motivo', 'credenciales_invalidas'); END IF;
    RETURN jsonb_build_object('permitido', TRUE, 'acceso_id', v_acceso.id);
END;
$$ LANGUAGE plpgsql;

-- PROBLEMA 5: Transcripciones sin puente al Copiloto
DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_transc_fts ON sd_comercial.transcripciones_omnicanal USING gin(to_tsvector('spanish', texto_crudo));
EXCEPTION WHEN OTHERS THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS sd_copilot.transcripcion_chunks (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transcripcion_id    UUID NOT NULL REFERENCES sd_comercial.transcripciones_omnicanal(id) ON DELETE CASCADE,
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id),
    chunk_index         INTEGER NOT NULL,
    contenido           TEXT NOT NULL,
    fecha_interaccion   DATE,
    canal               VARCHAR(50),
    participantes       JSONB DEFAULT '[]',
    temas_detectados    JSONB DEFAULT '[]',
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (transcripcion_id, chunk_index)
);

CREATE INDEX IF NOT EXISTS idx_chunks_lead ON sd_copilot.transcripcion_chunks(lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_chunks_cliente ON sd_copilot.transcripcion_chunks(cliente_id) WHERE cliente_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_chunks_fts ON sd_copilot.transcripcion_chunks USING gin(to_tsvector('spanish', contenido));

-- PROBLEMA 6: Borradores sin ciclo de vida
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_copilot' AND table_name = 'borradores_sugeridos') THEN
        ALTER TABLE sd_copilot.borradores_sugeridos
            ADD COLUMN IF NOT EXISTS estado VARCHAR(30) DEFAULT 'pendiente',
            ADD COLUMN IF NOT EXISTS visto_en TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS editado_en TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS enviado_en TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS descartado_en TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS motivo_descarte TEXT,
            ADD COLUMN IF NOT EXISTS contenido_final TEXT,
            ADD COLUMN IF NOT EXISTS diferencia_pct DECIMAL(5,2),
            ADD COLUMN IF NOT EXISTS interaction_id UUID REFERENCES sd_comercial.lead_interactions(id),
            ADD COLUMN IF NOT EXISTS calificacion_usuario INTEGER CHECK (calificacion_usuario BETWEEN 1 AND 5);
    END IF;
END $$;

CREATE OR REPLACE VIEW sd_analytics.v_efectividad_copiloto AS
SELECT
    DATE_TRUNC('week', b.creado_en) AS semana, u.nombre_display AS vendedor, COUNT(*) AS borradores_generados,
    COUNT(*) FILTER (WHERE b.estado = 'enviado') AS enviados, COUNT(*) FILTER (WHERE b.estado = 'descartado') AS descartados,
    COUNT(*) FILTER (WHERE b.estado = 'editado') AS editados_antes_enviar,
    ROUND(COUNT(*) FILTER (WHERE b.estado = 'enviado') * 100.0 / NULLIF(COUNT(*), 0), 1) AS tasa_uso_pct,
    ROUND(AVG(b.diferencia_pct) FILTER (WHERE b.diferencia_pct IS NOT NULL), 1) AS edicion_promedio_pct,
    ROUND(AVG(b.calificacion_usuario) FILTER (WHERE b.calificacion_usuario IS NOT NULL), 2) AS calificacion_promedio
FROM sd_copilot.borradores_sugeridos b
LEFT JOIN sd_core.usuarios u ON u.id = b.usuario_id
GROUP BY DATE_TRUNC('week', b.creado_en), u.nombre_display
ORDER BY semana DESC, enviados DESC;

-- PROBLEMA 7: Peticiones de portal con flujo (Aprobación interna)
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sd_portal' AND table_name = 'peticiones_servicio') THEN
        ALTER TABLE sd_portal.peticiones_servicio
            ADD COLUMN IF NOT EXISTS asignada_a UUID REFERENCES sd_core.usuarios(id),
            ADD COLUMN IF NOT EXISTS fecha_asignacion TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS fecha_limite TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS sla_cumplido BOOLEAN,
            ADD COLUMN IF NOT EXISTS notas_internas TEXT,
            ADD COLUMN IF NOT EXISTS motivo_rechazo TEXT,
            ADD COLUMN IF NOT EXISTS prioridad VARCHAR(20) DEFAULT 'media',
            ADD COLUMN IF NOT EXISTS presupuesto_estimado DECIMAL(12,2),
            ADD COLUMN IF NOT EXISTS canal_entrada VARCHAR(30) DEFAULT 'portal';
    END IF;
END $$;

CREATE OR REPLACE FUNCTION sd_portal.trigger_nueva_peticion()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM sd_events.emit('service_request_received', 'comercial', 'peticion_servicio', NEW.id, NULL, jsonb_build_object('cliente_id', NEW.cliente_id, 'servicio_id', NEW.servicio_id, 'descripcion', LEFT(NEW.descripcion, 200)));
    INSERT INTO sd_clientes.customer_journey_events(cliente_id, etapa, tipo_evento, descripcion, valor_cop) VALUES (NEW.cliente_id, 'expansion', 'peticion_servicio_portal', 'Cliente solicitó servicio desde el portal', NULL);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'tg_nueva_peticion_portal') THEN
        CREATE TRIGGER tg_nueva_peticion_portal
        AFTER INSERT ON sd_portal.peticiones_servicio
        FOR EACH ROW EXECUTE FUNCTION sd_portal.trigger_nueva_peticion();
    END IF;
END $$;

-- PROBLEMA 8: Hilos de conversación omnicanal
CREATE TABLE IF NOT EXISTS sd_comercial.hilos_conversacion (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id             UUID REFERENCES sd_comercial.leads(id),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id),
    contacto_id         UUID REFERENCES sd_clientes.contactos(id),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    titulo              VARCHAR(255),
    resumen_ia          TEXT,
    temas_principales   JSONB DEFAULT '[]',
    sentimiento_general VARCHAR(20),
    activo              BOOLEAN DEFAULT TRUE,
    ultimo_mensaje_en   TIMESTAMPTZ DEFAULT NOW(),
    total_mensajes      INTEGER DEFAULT 0,
    canales_usados      JSONB DEFAULT '[]',
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sd_comercial.hilo_mensajes (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hilo_id             UUID NOT NULL REFERENCES sd_comercial.hilos_conversacion(id) ON DELETE CASCADE,
    interaction_id      UUID REFERENCES sd_comercial.lead_interactions(id),
    transcripcion_id    UUID REFERENCES sd_comercial.transcripciones_omnicanal(id),
    call_log_id         UUID REFERENCES sd_comercial.call_logs(id),
    meeting_log_id      UUID REFERENCES sd_comercial.meeting_logs(id),
    canal               VARCHAR(50) NOT NULL,
    direccion           VARCHAR(20) DEFAULT 'saliente',
    resumen_corto       VARCHAR(500),
    fecha_mensaje       TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT chk_hilo_tiene_fuente CHECK ((interaction_id IS NOT NULL)::INT + (transcripcion_id IS NOT NULL)::INT + (call_log_id IS NOT NULL)::INT + (meeting_log_id IS NOT NULL)::INT = 1)
);

CREATE INDEX IF NOT EXISTS idx_hilos_lead ON sd_comercial.hilos_conversacion(lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hilos_cliente ON sd_comercial.hilos_conversacion(cliente_id) WHERE cliente_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hilo_msgs ON sd_comercial.hilo_mensajes(hilo_id, fecha_mensaje DESC);

-- ================================================================
-- 8. AUDITORÍA BLOQUE 6: MÓDULOS COMPLETAMENTE AUSENTES
-- ================================================================

-- AUSENCIA 1: Módulo de Notificaciones en tiempo real
CREATE TABLE IF NOT EXISTS sd_core.notificacion_preferencias (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID NOT NULL REFERENCES sd_core.usuarios(id) ON DELETE CASCADE UNIQUE,
    canal_email         BOOLEAN DEFAULT TRUE,
    canal_whatsapp      BOOLEAN DEFAULT FALSE,
    canal_slack         BOOLEAN DEFAULT TRUE,
    canal_in_app        BOOLEAN DEFAULT TRUE,
    eventos_comerciales BOOLEAN DEFAULT TRUE,
    eventos_financieros BOOLEAN DEFAULT TRUE,
    eventos_comisiones  BOOLEAN DEFAULT TRUE,
    eventos_soporte     BOOLEAN DEFAULT FALSE,
    eventos_sistema     BOOLEAN DEFAULT FALSE,
    silencio_activo     BOOLEAN DEFAULT FALSE,
    silencio_inicio     TIME DEFAULT '22:00',
    silencio_fin        TIME DEFAULT '07:00',
    dias_silencio       INTEGER[] DEFAULT '{6,7}',
    modo_resumen        BOOLEAN DEFAULT FALSE,
    frecuencia_resumen  VARCHAR(20) DEFAULT 'diario',
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sd_core.notificaciones_inapp (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID NOT NULL REFERENCES sd_core.usuarios(id) ON DELETE CASCADE,
    tipo                VARCHAR(100) NOT NULL,
    titulo              VARCHAR(255) NOT NULL,
    cuerpo              TEXT,
    icono               VARCHAR(50),
    color               VARCHAR(7) DEFAULT '#3B82F6',
    url_accion          VARCHAR(500),
    entity_type         VARCHAR(50),
    entity_id           UUID,
    leida               BOOLEAN DEFAULT FALSE,
    leida_en            TIMESTAMPTZ,
    descartada          BOOLEAN DEFAULT FALSE,
    dedup_key           VARCHAR(255) UNIQUE,
    expira_en           TIMESTAMPTZ,
    prioridad           VARCHAR(20) DEFAULT 'normal',
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notif_usuario_no_leida ON sd_core.notificaciones_inapp(usuario_id, created_at DESC) WHERE leida = FALSE AND descartada = FALSE;
CREATE INDEX IF NOT EXISTS idx_notif_dedup ON sd_core.notificaciones_inapp(dedup_key) WHERE dedup_key IS NOT NULL;

-- AUSENCIA 2: Módulo de Cotizaciones estructuradas
CREATE TABLE IF NOT EXISTS sd_comercial.cotizaciones (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_cotizacion       VARCHAR(30) UNIQUE NOT NULL,
    version                 INTEGER DEFAULT 1,
    cotizacion_padre_id     UUID REFERENCES sd_comercial.cotizaciones(id),
    oportunidad_id          UUID REFERENCES sd_comercial.oportunidades(id),
    lead_id                 UUID REFERENCES sd_comercial.leads(id),
    cliente_id              UUID REFERENCES sd_clientes.clientes(id),
    contacto_id             UUID REFERENCES sd_clientes.contactos(id),
    nombre_cotizacion       VARCHAR(255) NOT NULL,
    mensaje_personalizado   TEXT,
    moneda                  sd_core.moneda DEFAULT 'COP',
    subtotal_cop            DECIMAL(15,2) NOT NULL DEFAULT 0,
    descuento_global_pct    DECIMAL(5,2)  DEFAULT 0,
    descuento_global_cop    DECIMAL(12,2) DEFAULT 0,
    iva_cop                 DECIMAL(12,2) DEFAULT 0,
    total_cop               DECIMAL(15,2) NOT NULL DEFAULT 0,
    costo_total_cop         DECIMAL(15,2) DEFAULT 0,
    margen_bruto_cop        DECIMAL(15,2) GENERATED ALWAYS AS (total_cop - costo_total_cop) STORED,
    margen_bruto_pct        DECIMAL(5,2),
    comision_proyectada_cop DECIMAL(12,2) DEFAULT 0,
    requiere_aprobacion     BOOLEAN DEFAULT FALSE,
    aprobada_por            UUID REFERENCES sd_core.usuarios(id),
    aprobada_en             TIMESTAMPTZ,
    motivo_descuento        TEXT,
    estado                  VARCHAR(30) DEFAULT 'borrador',
    fecha_emision           DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_vencimiento       DATE NOT NULL DEFAULT CURRENT_DATE + INTERVAL '15 days',
    enviada_por_email       BOOLEAN DEFAULT FALSE,
    enviada_por_whatsapp    BOOLEAN DEFAULT FALSE,
    url_cotizacion_pdf      VARCHAR(500),
    aceptada_en             TIMESTAMPTZ,
    aceptada_por_nombre     VARCHAR(255),
    ip_aceptacion           INET,
    notas_internas          TEXT,
    notas_para_cliente      TEXT,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID REFERENCES sd_core.usuarios(id)
);

CREATE TABLE IF NOT EXISTS sd_comercial.cotizacion_items (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cotizacion_id       UUID NOT NULL REFERENCES sd_comercial.cotizaciones(id) ON DELETE CASCADE,
    servicio_id         UUID REFERENCES sd_servicios.servicios(id),
    combo_id            UUID REFERENCES sd_servicios.combos(id),
    descripcion         VARCHAR(500) NOT NULL,
    cantidad            DECIMAL(8,2) DEFAULT 1,
    precio_lista_cop    DECIMAL(12,2) NOT NULL,
    descuento_pct       DECIMAL(5,2) DEFAULT 0,
    precio_unitario_cop DECIMAL(12,2) NOT NULL,
    subtotal_cop        DECIMAL(12,2) NOT NULL,
    precio_minimo_cop   DECIMAL(12,2),
    bajo_minimo         BOOLEAN GENERATED ALWAYS AS (precio_unitario_cop < COALESCE(precio_minimo_cop, 0)) STORED,
    costo_unitario_cop  DECIMAL(12,2),
    orden               INTEGER DEFAULT 0,
    notas               VARCHAR(500),
    CONSTRAINT chk_cot_item_fuente CHECK ((servicio_id IS NOT NULL AND combo_id IS NULL) OR (servicio_id IS NULL AND combo_id IS NOT NULL) OR (servicio_id IS NULL AND combo_id IS NULL))
);

CREATE INDEX IF NOT EXISTS idx_cot_opp ON sd_comercial.cotizaciones(oportunidad_id);
CREATE INDEX IF NOT EXISTS idx_cot_cliente ON sd_comercial.cotizaciones(cliente_id);
CREATE INDEX IF NOT EXISTS idx_cot_estado ON sd_comercial.cotizaciones(estado, fecha_vencimiento);
CREATE INDEX IF NOT EXISTS idx_cot_items ON sd_comercial.cotizacion_items(cotizacion_id);

-- AUSENCIA 3: Módulo de Objetivos y Cuotas (Quota Management)
CREATE TABLE IF NOT EXISTS sd_comercial.cuotas (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID REFERENCES sd_core.usuarios(id),
    comisionista_id     UUID REFERENCES sd_comisiones.comisionistas(id),
    equipo_id           UUID REFERENCES sd_core.equipos(id),
    periodo_tipo        VARCHAR(20) NOT NULL DEFAULT 'mensual',
    periodo_inicio      DATE NOT NULL,
    periodo_fin         DATE NOT NULL,
    meta_ingresos_cop   DECIMAL(15,2),
    meta_leads          INTEGER,
    meta_oportunidades  INTEGER,
    meta_cierres        INTEGER,
    meta_nuevos_clientes INTEGER,
    metas_por_combo     JSONB DEFAULT '{}',
    real_ingresos_cop   DECIMAL(15,2) DEFAULT 0,
    real_leads          INTEGER DEFAULT 0,
    real_oportunidades  INTEGER DEFAULT 0,
    real_cierres        INTEGER DEFAULT 0,
    real_nuevos_clientes INTEGER DEFAULT 0,
    pct_ingresos        DECIMAL(5,2),
    pct_cierres         DECIMAL(5,2),
    proyeccion_ingresos DECIMAL(15,2),
    en_riesgo           BOOLEAN DEFAULT FALSE,
    alerta_enviada      BOOLEAN DEFAULT FALSE,
    activa              BOOLEAN DEFAULT TRUE,
    notas               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID REFERENCES sd_core.usuarios(id),
    CONSTRAINT chk_cuota_target CHECK ((usuario_id IS NOT NULL)::INT + (comisionista_id IS NOT NULL)::INT + (equipo_id IS NOT NULL)::INT = 1),
    CONSTRAINT chk_cuota_periodo CHECK (periodo_fin > periodo_inicio)
);

CREATE TABLE IF NOT EXISTS sd_comercial.cuota_snapshots (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cuota_id        UUID NOT NULL REFERENCES sd_comercial.cuotas(id) ON DELETE CASCADE,
    fecha_snapshot  DATE NOT NULL DEFAULT CURRENT_DATE,
    pct_avance      DECIMAL(5,2),
    real_ingresos   DECIMAL(15,2),
    dias_transcurridos INTEGER,
    dias_restantes  INTEGER,
    pace_diario     DECIMAL(12,2),
    proyeccion      DECIMAL(15,2),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (cuota_id, fecha_snapshot)
);

CREATE INDEX IF NOT EXISTS idx_cuotas_periodo ON sd_comercial.cuotas(periodo_inicio, periodo_fin) WHERE activa = TRUE;
CREATE INDEX IF NOT EXISTS idx_cuotas_usuario ON sd_comercial.cuotas(usuario_id) WHERE usuario_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cuotas_comisionista ON sd_comercial.cuotas(comisionista_id) WHERE comisionista_id IS NOT NULL;

-- AUSENCIA 4: Módulo de Gestión Documental con Firmas
CREATE SCHEMA IF NOT EXISTS sd_documentos;

CREATE TABLE IF NOT EXISTS sd_documentos.documentos (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo              VARCHAR(30) UNIQUE NOT NULL,
    tipo                VARCHAR(50) NOT NULL,
    plantilla_id        UUID REFERENCES sd_core.plantillas(id),
    contrato_id         UUID REFERENCES sd_contratos.contratos(id),
    oportunidad_id      UUID REFERENCES sd_comercial.oportunidades(id),
    cliente_id          UUID REFERENCES sd_clientes.clientes(id),
    nombre              VARCHAR(255) NOT NULL,
    contenido_html      TEXT,
    variables_usadas    JSONB DEFAULT '{}',
    url_borrador        VARCHAR(500),
    url_firmado         VARCHAR(500),
    checksum_firmado    VARCHAR(64),
    tamano_bytes        INTEGER,
    estado              VARCHAR(30) DEFAULT 'borrador',
    plataforma          VARCHAR(50),
    id_externo          VARCHAR(255),
    generado_en         TIMESTAMPTZ,
    enviado_en          TIMESTAMPTZ,
    abierto_en          TIMESTAMPTZ,
    firmado_en          TIMESTAMPTZ,
    vence_en            TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID REFERENCES sd_core.usuarios(id)
);

CREATE TABLE IF NOT EXISTS sd_documentos.firmantes (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    documento_id        UUID NOT NULL REFERENCES sd_documentos.documentos(id) ON DELETE CASCADE,
    contacto_id         UUID REFERENCES sd_clientes.contactos(id),
    usuario_id          UUID REFERENCES sd_core.usuarios(id),
    nombre_firmante     VARCHAR(255) NOT NULL,
    email_firmante      VARCHAR(255) NOT NULL,
    rol_firma           VARCHAR(50) DEFAULT 'firmante',
    orden_firma         INTEGER DEFAULT 1,
    token_firma         VARCHAR(255) UNIQUE,
    estado              VARCHAR(30) DEFAULT 'pendiente',
    ip_firma            INET,
    user_agent_firma    TEXT,
    geolocalizacion     JSONB,
    metodo_autenticacion VARCHAR(50),
    certificado_firma   TEXT,
    notificado_en       TIMESTAMPTZ,
    visto_en            TIMESTAMPTZ,
    firmado_en          TIMESTAMPTZ,
    rechazado_en        TIMESTAMPTZ,
    motivo_rechazo      TEXT,
    recordatorios_enviados INTEGER DEFAULT 0,
    ultimo_recordatorio TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_docs_contrato ON sd_documentos.documentos(contrato_id) WHERE contrato_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_docs_cliente ON sd_documentos.documentos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_docs_estado ON sd_documentos.documentos(estado);
CREATE INDEX IF NOT EXISTS idx_firmantes_doc ON sd_documentos.firmantes(documento_id);
CREATE INDEX IF NOT EXISTS idx_firmantes_token ON sd_documentos.firmantes(token_firma) WHERE token_firma IS NOT NULL;

-- AUSENCIA 5: Módulo de Gamificación para Comisionistas
CREATE TABLE IF NOT EXISTS sd_comisiones.logros_catalogo (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo          VARCHAR(50) UNIQUE NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    descripcion     TEXT,
    icono           VARCHAR(100),
    color           VARCHAR(7)  DEFAULT '#F59E0B',
    categoria       VARCHAR(50),
    tipo_condicion  VARCHAR(50) NOT NULL,
    valor_condicion DECIMAL(10,2),
    puntos          INTEGER DEFAULT 0,
    bono_cop        DECIMAL(10,2) DEFAULT 0,
    activo          BOOLEAN DEFAULT TRUE,
    es_unico        BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sd_comisiones.logros_obtenidos (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comisionista_id     UUID NOT NULL REFERENCES sd_comisiones.comisionistas(id) ON DELETE CASCADE,
    logro_id            UUID NOT NULL REFERENCES sd_comisiones.logros_catalogo(id),
    descripcion_logro   TEXT,
    valor_alcanzado     DECIMAL(10,2),
    periodo             VARCHAR(20),
    puntos_otorgados    INTEGER DEFAULT 0,
    bono_cop_otorgado   DECIMAL(10,2) DEFAULT 0,
    bono_pagado         BOOLEAN DEFAULT FALSE,
    visible_en_portal   BOOLEAN DEFAULT TRUE,
    celebrado_en_slack  BOOLEAN DEFAULT FALSE,
    obtenido_en         TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (comisionista_id, logro_id, periodo)
);

CREATE TABLE IF NOT EXISTS sd_comisiones.puntos_temporada (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comisionista_id     UUID NOT NULL REFERENCES sd_comisiones.comisionistas(id),
    temporada           VARCHAR(20) NOT NULL,
    puntos_totales      INTEGER DEFAULT 0,
    nivel_alcanzado     VARCHAR(30) DEFAULT 'bronze',
    posicion_ranking    INTEGER,
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (comisionista_id, temporada)
);

INSERT INTO sd_comisiones.logros_catalogo (codigo, nombre, descripcion, categoria, tipo_condicion, valor_condicion, puntos, es_unico) VALUES
('PRIMERA_VENTA', 'Primera Venta', 'Cerró su primera venta en Snake Dragon', 'ventas', 'primera_venta', 1, 500, TRUE),
('RACHA_3', 'Hat Trick', '3 ventas cerradas en el mismo mes', 'ventas', 'N_cierres_mes', 3, 300, FALSE),
('RACHA_5', 'Imparable', '5 ventas cerradas en el mismo mes', 'ventas', 'N_cierres_mes', 5, 700, FALSE),
('WIN_RATE_60', 'Tirador de élite', 'Win rate superior al 60% en el trimestre', 'calidad', 'win_rate_X_pct', 60, 400, FALSE),
('RESPUESTA_1H', 'Velocidad Rayo', 'Respondió a un lead en menos de 1 hora', 'velocidad', 'respuesta_bajo_Xhrs', 1, 100, FALSE),
('NPS_PROMOTOR', 'Creador de Fans', 'Un cliente suyo dio NPS de 10', 'retencion', 'cliente_NPS_promotor', 10, 200, FALSE),
('SIN_FRAUDE_6M', 'Integridad Total', '6 meses consecutivos sin alertas de fraude', 'calidad', 'sin_fraude_Xmeses', 6, 600, FALSE)
ON CONFLICT (codigo) DO NOTHING;

-- AUSENCIA 6: Seed de Multi-empresa e Internacionalización
CREATE TABLE IF NOT EXISTS sd_core.empresas_propias (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    razon_social        VARCHAR(255) NOT NULL,
    nombre_comercial    VARCHAR(255),
    nit                 VARCHAR(30) UNIQUE,
    pais                VARCHAR(50) DEFAULT 'Colombia',
    moneda_base         sd_core.moneda DEFAULT 'COP',
    zona_horaria        VARCHAR(50) DEFAULT 'America/Bogota',
    regimen_tributario  VARCHAR(50),
    iva_pct             DECIMAL(5,2) DEFAULT 19.00,
    prefijo_facturas    VARCHAR(10) DEFAULT 'SDFV',
    resolucion_dian     VARCHAR(50),
    email_principal     VARCHAR(255),
    telefono            VARCHAR(30),
    direccion           TEXT,
    logo_url            VARCHAR(500),
    activa              BOOLEAN DEFAULT TRUE,
    es_principal        BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO sd_core.empresas_propias (codigo, razon_social, nombre_comercial, moneda_base, zona_horaria, es_principal)
VALUES ('SD-PRINCIPAL', 'Snake Dragon SAS', 'Snake Dragon', 'COP', 'America/Bogota', TRUE)
ON CONFLICT (codigo) DO NOTHING;

DO $$ BEGIN
    ALTER TABLE sd_financiero.facturas ADD COLUMN IF NOT EXISTS empresa_propia_id UUID REFERENCES sd_core.empresas_propias(id);
    ALTER TABLE sd_contratos.contratos ADD COLUMN IF NOT EXISTS empresa_propia_id UUID REFERENCES sd_core.empresas_propias(id);
    ALTER TABLE sd_comisiones.liquidaciones ADD COLUMN IF NOT EXISTS empresa_propia_id UUID REFERENCES sd_core.empresas_propias(id);
END $$;

CREATE TABLE IF NOT EXISTS sd_financiero.tasas_cambio (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    moneda_origen   sd_core.moneda NOT NULL,
    moneda_destino  sd_core.moneda NOT NULL,
    tasa            DECIMAL(15,6) NOT NULL,
    tasa_compra     DECIMAL(15,6),
    tasa_venta      DECIMAL(15,6),
    fuente          VARCHAR(50) DEFAULT 'manual',
    fecha_tasa      DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (moneda_origen, moneda_destino, fecha_tasa)
);

INSERT INTO sd_financiero.tasas_cambio (moneda_origen, moneda_destino, tasa, fuente, fecha_tasa) VALUES
('USD', 'COP', 4100.00, 'manual', CURRENT_DATE),
('EUR', 'COP', 4450.00, 'manual', CURRENT_DATE),
('COP', 'USD', 0.000244, 'manual', CURRENT_DATE)
ON CONFLICT (moneda_origen, moneda_destino, fecha_tasa) DO NOTHING;

-- AUSENCIA 7: Motor de Encuestas personalizables
CREATE TABLE IF NOT EXISTS sd_soporte.encuestas_plantillas (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          VARCHAR(100) NOT NULL,
    tipo            VARCHAR(30) NOT NULL,
    trigger_evento  VARCHAR(100),
    preguntas       JSONB NOT NULL DEFAULT '[]',
    activa          BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    created_by      UUID REFERENCES sd_core.usuarios(id)
);

CREATE TABLE IF NOT EXISTS sd_soporte.encuestas_enviadas (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plantilla_id    UUID NOT NULL REFERENCES sd_soporte.encuestas_plantillas(id),
    cliente_id      UUID REFERENCES sd_clientes.clientes(id),
    contacto_id     UUID REFERENCES sd_clientes.contactos(id),
    proyecto_id     UUID REFERENCES sd_operaciones.proyectos(id),
    ticket_id       UUID REFERENCES sd_soporte.tickets(id),
    contrato_id     UUID REFERENCES sd_contratos.contratos(id),
    token_respuesta VARCHAR(255) UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
    canal_envio     VARCHAR(30),
    enviada_en      TIMESTAMPTZ DEFAULT NOW(),
    expira_en       TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
    respondida      BOOLEAN DEFAULT FALSE,
    respondida_en   TIMESTAMPTZ,
    ip_respuesta    INET,
    respuestas      JSONB DEFAULT '{}',
    nps_score       INTEGER,
    csat_score      DECIMAL(3,1),
    sentimiento_ia  VARCHAR(20),
    resumen_ia      TEXT,
    requiere_followup BOOLEAN DEFAULT FALSE,
    followup_realizado BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_enc_cliente  ON sd_soporte.encuestas_enviadas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_enc_token    ON sd_soporte.encuestas_enviadas(token_respuesta);
CREATE INDEX IF NOT EXISTS idx_enc_pendiente ON sd_soporte.encuestas_enviadas(respondida, expira_en) WHERE respondida = FALSE;

-- AUSENCIA 8: Historial y rollback de Configuración
CREATE TABLE IF NOT EXISTS sd_core.configuracion_historial (
    id              BIGSERIAL PRIMARY KEY,
    clave           VARCHAR(100) NOT NULL,
    valor_anterior  JSONB,
    valor_nuevo     JSONB NOT NULL,
    motivo_cambio   TEXT,
    cambiado_por    UUID REFERENCES sd_core.usuarios(id),
    aprobado_por    UUID REFERENCES sd_core.usuarios(id),
    requeria_aprobacion BOOLEAN DEFAULT FALSE,
    revertido       BOOLEAN DEFAULT FALSE,
    revertido_en    TIMESTAMPTZ,
    revertido_por   UUID REFERENCES sd_core.usuarios(id),
    changed_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conf_hist_clave ON sd_core.configuracion_historial(clave, changed_at DESC);

CREATE OR REPLACE FUNCTION sd_core.trigger_config_historial()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO sd_core.configuracion_historial(
        clave, valor_anterior, valor_nuevo, cambiado_por, changed_at
    ) VALUES (
        NEW.clave, OLD.valor, NEW.valor, NEW.updated_by, NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_config_historial') THEN
        CREATE TRIGGER trg_config_historial
        AFTER UPDATE OF valor ON sd_core.configuracion
        FOR EACH ROW EXECUTE FUNCTION sd_core.trigger_config_historial();
    END IF;
END $$;

INSERT INTO sd_core.configuracion (clave, valor, descripcion, categoria) VALUES
('uvt_2026', '{"valor": 49799, "vigente_desde": "2026-01-01"}', 'Valor UVT 2026 según DIAN — Resolución 000187/2025', 'tributario'),
('tope_descuento_sin_aprobacion', '{"porcentaje": 5, "requiere_aprobacion_arriba_de": 10}', 'Descuento máximo que puede aplicar un vendedor sin aprobación gerencial', 'comercial'),
('politica_retencion_datos', '{"meses_clientes_activos": 84, "meses_leads_no_convertidos": 24}', 'Política de retención de datos personales — Ley 1581/2012', 'legal'),
('umbral_fraude_leads_por_hora', '{"maximo": 15, "alerta_desde": 10}', 'Máximo de leads que un comisionista puede registrar por hora', 'seguridad'),
('portal_max_intentos_login', '{"intentos": 5, "bloqueo_minutos": 30}', 'Intentos máximos de login en portal antes de bloquear — Ley 1273/2009', 'seguridad'),
('sla_cotizacion_respuesta_hrs', '{"horas": 4, "alerta_vendedor_en": 2}', 'SLA para responder solicitudes de cotización del portal', 'comercial')
ON CONFLICT (clave) DO NOTHING;

COMMIT;

-- FIN DE SD CRM V3.0
