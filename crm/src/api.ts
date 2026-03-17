const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

// Token management
const getToken = (): string | null => localStorage.getItem('sd_token');
const setToken = (token: string) => localStorage.setItem('sd_token', token);
const removeToken = () => localStorage.removeItem('sd_token');

function authHeaders(): HeadersInit {
    const token = getToken();
    return token
        ? { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }
        : { 'Content-Type': 'application/json' };
}

async function apiFetch<T>(path: string, options?: RequestInit): Promise<T | null> {
    try {
        const res = await fetch(`${API_URL}${path}`, {
            ...options,
            headers: { ...authHeaders(), ...options?.headers },
        });

        if (res.status === 401) {
            // Token expired — force logout
            removeToken();
            window.location.reload();
            return null;
        }

        if (!res.ok) {
            const err = await res.json().catch(() => ({ error: 'Error desconocido' }));
            throw new Error(err.error || `HTTP ${res.status}`);
        }

        return await res.json();
    } catch (e) {
        console.warn(`[API] ${path}`, e);
        return null;
    }
}

export const auth = {
    login: async (email: string, password: string) => {
        const data = await apiFetch<{ token: string; user: any }>('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ email, password }),
        });
        if (data?.token) setToken(data.token);
        return data;
    },

    logout: async () => {
        await apiFetch('/auth/logout', { method: 'POST' });
        removeToken();
    },

    me: () => apiFetch<{ user: any }>('/auth/me'),

    isLoggedIn: () => !!getToken(),
};

export const api = {
    getDashboard: () => apiFetch<any>('/dashboard'),

    getPipeline: (params?: { etapa?: string; limit?: number; offset?: number }) => {
        const q = new URLSearchParams();
        if (params?.etapa) q.set('etapa', params.etapa);
        if (params?.limit) q.set('limit', String(params.limit));
        if (params?.offset) q.set('offset', String(params.offset));
        return apiFetch<{ leads: any[]; total: number }>(`/pipeline?${q.toString()}`);
    },

    createLead: (data: any) =>
        apiFetch<{ lead: any }>('/pipeline/leads', { method: 'POST', body: JSON.stringify(data) }),

    updateLead: (id: string, data: any) =>
        apiFetch<{ lead: any }>(`/pipeline/leads/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

    deleteLead: (id: string) =>
        apiFetch<{ success: boolean }>(`/pipeline/leads/${id}`, { method: 'DELETE' }),

    getCustomers: (params?: { search?: string; limit?: number; offset?: number }) => {
        const q = new URLSearchParams();
        if (params?.search) q.set('search', params.search);
        if (params?.limit) q.set('limit', String(params.limit));
        if (params?.offset) q.set('offset', String(params.offset));
        return apiFetch<{ customers: any[] }>(`/customers?${q.toString()}`);
    },

    getEvents: (limit = 50) =>
        apiFetch<{ events: any[] }>(`/events?limit=${limit}`),

    getAnalytics: () => apiFetch<any>('/analytics'),

    askCopilot: (prompt: string, type: string, leadId?: string) =>
        apiFetch<{ response: string }>('/copilot', {
            method: 'POST',
            body: JSON.stringify({ prompt, type, leadId }),
        }),

    getCompanySettings: () => apiFetch<{ company: any }>('/settings/company'),

    updateCompanySettings: (data: any) =>
        apiFetch<{ company: any }>('/settings/company', { method: 'PUT', body: JSON.stringify(data) }),

    updateProfile: (data: any) =>
        apiFetch<{ user: any }>('/settings/profile', { method: 'PUT', body: JSON.stringify(data) }),

    health: () => apiFetch<{ status: string; db: string }>('/health'),
};
