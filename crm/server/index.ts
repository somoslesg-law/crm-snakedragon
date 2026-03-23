import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { query } from './db';
import * as dotenv from 'dotenv';
import path from 'path';
import { comparePassword, generateToken, hashPassword } from './auth';
import { authMiddleware, AuthRequest } from './middleware/auth.middleware';
import { GoogleGenAI } from '@google/genai';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const app = express();
const PORT = parseInt(process.env.PORT || process.env.API_PORT || '8080', 10);
const CLIENT_URL = process.env.APP_URL || 'http://localhost:3000';

// ─── Security Middleware ──────────────────────────────────────────────────────
app.use(helmet());

// Log incoming requests for debugging production hits
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} - ${req.ip}`);
    next();
});


app.use(cors({
    origin: (origin, callback) => {
        const allowed = [CLIENT_URL, 'http://localhost:3000', 'http://localhost:5173'];
        if (!origin || allowed.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error(`CORS blocked: ${origin}`));
        }
    },
    credentials: true,
}));

app.use(express.json({ limit: '1mb' }));

// Rate limits
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 200,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Demasiadas solicitudes, intenta más tarde.' },
});

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: { error: 'Demasiados intentos de acceso, espera 15 minutos.' },
});

app.use('/api/', generalLimiter);
app.use('/api/auth/', authLimiter);

// ─── Auth Routes ─────────────────────────────────────────────────────────────

app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email y contraseña son requeridos' });
        }

        // Buscar usuario en la BD
        const result = await query(
            `SELECT id, email, password_hash, nombre, apellido, rol, activo
             FROM sd_core.usuarios WHERE email = $1 LIMIT 1`,
            [email.toLowerCase().trim()]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        const user = result.rows[0];

        if (!user.activo) {
            return res.status(403).json({ error: 'Cuenta desactivada, contacta al administrador' });
        }

        const isValid = await comparePassword(password, user.password_hash);
        if (!isValid) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        // Log session
        await query(
            `INSERT INTO sd_core.sesiones (usuario_id, ip, user_agent) VALUES ($1, $2, $3)`,
            [user.id, req.ip, req.headers['user-agent'] || 'unknown']
        ).catch(() => {}); // Non-blocking

        const token = generateToken({
            userId: user.id,
            email: user.email,
            rol: user.rol,
            nombre: `${user.nombre} ${user.apellido}`,
        });

        res.json({
            success: true,
            token,
            user: {
                id: user.id,
                nombre: `${user.nombre} ${user.apellido}`,
                email: user.email,
                rol: user.rol,
            },
        });
    } catch (error) {
        console.error('[AUTH LOGIN]', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

app.post('/api/auth/logout', authMiddleware, async (req: AuthRequest, res) => {
    res.json({ success: true, message: 'Sesión cerrada correctamente' });
});

app.get('/api/auth/me', authMiddleware, async (req: AuthRequest, res) => {
    res.json({ user: req.user });
});

// ─── Dashboard ────────────────────────────────────────────────────────────────

app.get('/api/dashboard', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const result = await query('SELECT * FROM sd_analytics.mv_dashboard_ejecutivo LIMIT 1');
        res.json(result.rows[0] || {});
    } catch (error) {
        console.error('[DASHBOARD]', error);
        res.status(500).json({ error: 'Error al obtener datos del dashboard' });
    }
});

// ─── Pipeline ─────────────────────────────────────────────────────────────────

app.get('/api/pipeline', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { limit = '50', offset = '0', etapa } = req.query as Record<string, string>;
        let queryStr = `SELECT l.*, u.nombre || ' ' || u.apellido as propietario_nombre
                        FROM sd_comercial.leads l
                        LEFT JOIN sd_core.usuarios u ON l.propietario_id = u.id
                        WHERE l.deleted_at IS NULL`;
        const params: any[] = [];

        if (etapa) {
            params.push(etapa);
            queryStr += ` AND l.etapa = $${params.length}`;
        }

        queryStr += ` ORDER BY l.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        params.push(parseInt(limit), parseInt(offset));

        const result = await query(queryStr, params);
        res.json({ leads: result.rows, total: result.rowCount });
    } catch (error) {
        console.error('[PIPELINE]', error);
        res.status(500).json({ error: 'Error al obtener el pipeline' });
    }
});

app.post('/api/pipeline/leads', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { nombre_completo, empresa, email, telefono, etapa, valor_estimado, fuente, notas } = req.body;

        if (!nombre_completo) {
            return res.status(400).json({ error: 'El nombre es requerido' });
        }

        const result = await query(
            `INSERT INTO sd_comercial.leads
             (nombre_completo, empresa, email, telefono, etapa, valor_estimado, fuente, notas, propietario_id)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
            [nombre_completo, empresa, email, telefono, etapa || 'prospecto', valor_estimado || 0, fuente, notas, req.user?.userId]
        );

        res.status(201).json({ lead: result.rows[0] });
    } catch (error) {
        console.error('[CREATE LEAD]', error);
        res.status(500).json({ error: 'Error al crear el lead' });
    }
});

app.put('/api/pipeline/leads/:id', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { id } = req.params;
        const { nombre_completo, empresa, email, telefono, etapa, valor_estimado, notas } = req.body;

        const result = await query(
            `UPDATE sd_comercial.leads SET
             nombre_completo = COALESCE($1, nombre_completo),
             empresa = COALESCE($2, empresa),
             email = COALESCE($3, email),
             telefono = COALESCE($4, telefono),
             etapa = COALESCE($5, etapa),
             valor_estimado = COALESCE($6, valor_estimado),
             notas = COALESCE($7, notas),
             updated_at = NOW()
             WHERE id = $8 AND deleted_at IS NULL RETURNING *`,
            [nombre_completo, empresa, email, telefono, etapa, valor_estimado, notas, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Lead no encontrado' });
        }

        res.json({ lead: result.rows[0] });
    } catch (error) {
        console.error('[UPDATE LEAD]', error);
        res.status(500).json({ error: 'Error al actualizar el lead' });
    }
});

app.delete('/api/pipeline/leads/:id', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { id } = req.params;
        await query(
            `UPDATE sd_comercial.leads SET deleted_at = NOW() WHERE id = $1`,
            [id]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('[DELETE LEAD]', error);
        res.status(500).json({ error: 'Error al eliminar el lead' });
    }
});

// ─── Copilot ─────────────────────────────────────────────────────────────────

app.post('/api/copilot', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { prompt, type, leadId } = req.body;

        if (!prompt) {
            return res.status(400).json({ error: 'El prompt es requerido' });
        }

        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
            return res.status(503).json({ error: 'Copiloto no disponible: GEMINI_API_KEY no configurada' });
        }

        // Get context from DB if leadId provided
        let contextData = '';
        if (leadId) {
            try {
                const ctxResult = await query(
                    `SELECT sd_copilot.construir_contexto($1, $2)`,
                    [type || 'general', leadId]
                );
                contextData = ctxResult.rows[0]?.construir_contexto || '';
            } catch (e) {
                // Context function may not exist yet, continue without it
            }
        }

        const systemPrompt = `Eres el Copiloto IA del CRM Snake Dragon. Eres un experto en ventas y gestión comercial.
Responde siempre en español. Sé conciso, accionable y estratégico.
${contextData ? `\nContexto del lead:\n${contextData}` : ''}`;

        const ai = new GoogleGenAI({ apiKey });
        const aiResponse = await ai.models.generateContent({
            model: 'gemini-2.0-flash',
            contents: [
                { role: 'user', parts: [{ text: `${systemPrompt}\n\nConsulta: ${prompt}` }] }
            ],
        });

        const responseText = aiResponse.candidates?.[0]?.content?.parts?.[0]?.text 
            || 'No se pudo generar una respuesta.';

        res.json({ response: responseText });
    } catch (error) {
        console.error('[COPILOT]', error);
        res.status(500).json({ error: 'Error al procesar la consulta del Copiloto' });
    }
});

// ─── Customers ───────────────────────────────────────────────────────────────

app.get('/api/customers', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { limit = '50', offset = '0', search } = req.query as Record<string, string>;
        let queryStr = `SELECT * FROM sd_analytics.v_cliente_360 WHERE 1=1`;
        const params: any[] = [];

        if (search) {
            params.push(`%${search}%`);
            queryStr += ` AND (nombre_completo ILIKE $${params.length} OR empresa ILIKE $${params.length})`;
        }

        queryStr += ` LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        params.push(parseInt(limit), parseInt(offset));

        const result = await query(queryStr, params);
        res.json({ customers: result.rows });
    } catch (error) {
        console.error('[CUSTOMERS]', error);
        res.status(500).json({ error: 'Error al obtener clientes' });
    }
});

// ─── Events ──────────────────────────────────────────────────────────────────

app.get('/api/events', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { limit = '50' } = req.query as Record<string, string>;
        const result = await query(
            `SELECT * FROM sd_events.event_stream ORDER BY created_at DESC LIMIT $1`,
            [parseInt(limit)]
        );
        res.json({ events: result.rows });
    } catch (error) {
        console.error('[EVENTS]', error);
        res.status(500).json({ error: 'Error al obtener eventos' });
    }
});

// ─── Analytics ───────────────────────────────────────────────────────────────

app.get('/api/analytics', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const [cuotasResult, facturasResult, comisionesResult] = await Promise.all([
            query(`SELECT usuario_id, periodo, tipo_cuota, monto_objetivo, ventas_actuales,
                          ROUND((ventas_actuales / NULLIF(monto_objetivo, 0) * 100)::numeric, 2) as porcentaje_cumplimiento
                   FROM sd_comercial.cuotas
                   WHERE periodo >= date_trunc('month', CURRENT_DATE) LIMIT 20`),
            query(`SELECT estado_pago, COUNT(*) as cantidad, SUM(total) as monto_total
                   FROM sd_financiero.facturas GROUP BY estado_pago`),
            query(`SELECT estado, SUM(monto_calculado) as monto_total
                   FROM sd_comisiones.liquidaciones
                   WHERE periodo >= date_trunc('month', CURRENT_DATE) GROUP BY estado`),
        ]);

        res.json({
            cuotas: cuotasResult.rows,
            facturacion: facturasResult.rows,
            comisiones: comisionesResult.rows,
        });
    } catch (error) {
        console.error('[ANALYTICS]', error);
        res.status(500).json({ error: 'Error al obtener analytics' });
    }
});

// ─── Settings ────────────────────────────────────────────────────────────────

app.get('/api/settings/company', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const result = await query(`SELECT * FROM sd_core.configuracion_empresa LIMIT 1`);
        res.json({ company: result.rows[0] || {} });
    } catch (error) {
        console.error('[SETTINGS GET]', error);
        res.status(500).json({ error: 'Error al obtener configuración' });
    }
});

app.put('/api/settings/company', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { nombre_empresa, nit, moneda, zona_horaria, logo_url } = req.body;
        const result = await query(
            `UPDATE sd_core.configuracion_empresa
             SET nombre_empresa = COALESCE($1, nombre_empresa),
                 nit = COALESCE($2, nit),
                 moneda = COALESCE($3, moneda),
                 zona_horaria = COALESCE($4, zona_horaria),
                 logo_url = COALESCE($5, logo_url),
                 updated_at = NOW()
             RETURNING *`,
            [nombre_empresa, nit, moneda, zona_horaria, logo_url]
        );
        res.json({ company: result.rows[0] });
    } catch (error) {
        console.error('[SETTINGS UPDATE]', error);
        res.status(500).json({ error: 'Error al actualizar configuración' });
    }
});

app.put('/api/settings/profile', authMiddleware, async (req: AuthRequest, res) => {
    try {
        const { nombre, apellido, telefono } = req.body;
        const result = await query(
            `UPDATE sd_core.usuarios SET
             nombre = COALESCE($1, nombre),
             apellido = COALESCE($2, apellido),
             telefono = COALESCE($3, telefono),
             updated_at = NOW()
             WHERE id = $4 RETURNING id, nombre, apellido, email, telefono, rol`,
            [nombre, apellido, telefono, req.user?.userId]
        );
        res.json({ user: result.rows[0] });
    } catch (error) {
        console.error('[PROFILE UPDATE]', error);
        res.status(500).json({ error: 'Error al actualizar perfil' });
    }
});

// ─── Health Check ─────────────────────────────────────────────────────────────

app.get('/api/health', async (_req, res) => {
    try {
        await query('SELECT 1');
        res.status(200).json({ status: 'ok', db: 'connected', timestamp: new Date().toISOString() });
    } catch {
        res.status(503).json({ status: 'error', db: 'disconnected', timestamp: new Date().toISOString() });
    }
});

// ─── Static Files (Production) ────────────────────────────────────────────────
if (process.env.NODE_ENV === 'production') {
    const distPath = path.resolve(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (_req, res) => {
        res.sendFile(path.join(distPath, 'index.html'));
    });
}

// ─── Start ────────────────────────────────────────────────────────────────────

app.listen(Number(PORT), '0.0.0.0', () => {
    console.log(`🚀 Snake Dragon CRM Backend ready`);
    console.log(`📡 Serving at 0.0.0.0:${PORT} [ENV: ${process.env.NODE_ENV || 'development'}]`);
    if (process.env.NODE_ENV === 'production') {
        console.log(`🌐 Frontend delivery active from /dist folder`);
    } else {
        console.log(`⚠️  Running in DEV MODE: Backend only, frontend not served via static`);
    }
});
