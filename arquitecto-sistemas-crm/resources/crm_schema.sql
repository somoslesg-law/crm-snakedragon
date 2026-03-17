-- ==========================================
-- CRM ELITE ARCHITECTURE - GENERATED DDL
-- ==========================================

-- Extensión para vectores (Supabase/PostgreSQL)
CREATE EXTENSION IF NOT EXISTS pgvector;

-- 1. REGISTRO DE AGENTES (SAGA)
CREATE TABLE IF NOT EXISTS agents_registry (
    agent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    access_token_hash TEXT NOT NULL,
    permissions JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. COMPAÑÍAS
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    industry TEXT,
    website TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CONTACTOS (Híbrido Relacional + Semántico)
CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT,
    last_name TEXT,
    email TEXT UNIQUE NOT NULL,
    job_title TEXT,
    company_id UUID REFERENCES companies(id),
    lead_score INT DEFAULT 0,
    lifecycle_stage TEXT DEFAULT 'lead',
    metadata JSONB,
    context_vector VECTOR(1536),
    last_interaction TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. DEALS (Oportunidades)
CREATE TABLE IF NOT EXISTS deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    contact_id UUID REFERENCES contacts(id),
    value DECIMAL(12,2),
    stage TEXT NOT NULL,
    probability FLOAT,
    velocity_metrics JSONB,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. AUDIT LOGS (Trazabilidad SAGA)
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    actor_id UUID,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    previous_state JSONB,
    new_state JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimización
CREATE INDEX IF NOT EXISTS idx_contacts_email ON contacts(email);
CREATE INDEX IF NOT EXISTS idx_deals_stage ON deals(stage);
