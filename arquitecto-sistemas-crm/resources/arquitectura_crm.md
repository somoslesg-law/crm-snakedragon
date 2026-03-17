# Blueprint de Arquitectura CRM (Elite AI System)

Este documento define la estructura técnica del CRM de alto rendimiento diseñado por el **Arquitecto de Sistemas CRM**.

## 1. ESTRUCTURA DE BASE DE DATOS (SQL)

La base de datos utiliza un enfoque híbrido relacional + semántico.

```sql
-- Gestión de Identidad y Registro de Agentes (SAGA)
CREATE TABLE agents_registry (
    agent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    access_token_hash TEXT NOT NULL,
    permissions JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Core CRM: Contactos e Inteligencia
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT,
    last_name TEXT,
    email TEXT UNIQUE NOT NULL,
    job_title TEXT,
    company_id UUID,
    lead_score INT DEFAULT 0,
    lifecycle_stage TEXT DEFAULT 'lead',
    metadata JSONB, -- Datos enriquecidos
    context_vector VECTOR(1536), -- Memoria semántica (pgvector)
    last_interaction TIMESTAMP WITH TIME ZONE
);

-- Pipelines y Deals
CREATE TABLE deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    contact_id UUID REFERENCES contacts(id),
    value DECIMAL(12,2),
    stage TEXT NOT NULL, -- Lead Captured, Qualified, Proposal, etc.
    velocity_metrics JSONB, -- Tracking de tiempo por etapa
    probability FLOAT,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- Trazabilidad y Auditoría (SAGA)
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    actor_id UUID, -- Referencia a agents_registry o user_id
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL, -- 'contact', 'deal', etc.
    entity_id UUID,
    previous_state JSONB,
    new_state JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 2. ARQUITECTURA DE PIPELINE

El pipeline se divide en etapas dinámicas con validación agéntica:
1. **Lead Captured**: Captura automática vía n8n (webhooks/formularios).
2. **Qualified**: Calificación profunda mediante modelos de razonamiento (o1 pattern).
3. **Meeting Scheduled**: Automatización de agenda y preparación de contexto.
4. **Proposal Sent**: Generación dinámica de propuestas basada en Master Data.
5. **Negotiation**: Asistente de objeciones y análisis de probabilidad.
6. **Closed Won / Lost**: Análisis de causa raíz (post-mortem).

## 3. ANALÍTICA E INTELIGENCIA DE NEGOCIO

El sistema debe alimentar dashboards con los siguientes KPIs:
- **Lead Performance**: Leads por fuente, tasa de conversión y CPA.
- **Sales Velocity**: Tiempo promedio entre etapas del embudo.
- **Predictive Metrics**: Probabilidad de cierre basada en comportamiento histórico.
- **Customer Lifetime Value (CLV)**: Proyección de valor a largo plazo.

## 4. AUTOMATIZACIÓN (n8n)

Estructura de flujos nativos:
- **Flujo A (Captura & Enriquecimiento)**: Formulario -> n8n -> Enriquecimiento API (Apollo/Lusha) -> Creación en CRM.
- **Flujo B (Handoff Agéntico)**: Cambio de etapa en CRM -> Webhook -> n8n -> LangGraph (IA de seguimiento) -> Email Personalizado.
- **Flujo C (Seguridad)**: Monitorización de logs -> n8n -> Alerta de anomalías (Anexo SAGA).

## 5. SEGURIDAD (FRAMEWORK SAGA)

- **Access Control**: Roles granulares (Admin, Sales, Agent).
- **Encryption**: Datos sensibles (PII) encriptados en reposo.
- **Recovery**: Backups automáticos cada 6 horas con redundancia regional.
