import React, { useState, useEffect } from 'react';
import { Users, AlertCircle, Zap, MailOpen, MousePointerClick, FileText, Search, Phone, ArrowRight, Activity, Clock, Filter, Check } from 'lucide-react';
import { api } from '../api';

const initialEvents = [
  { id: 1, type: 'action', title: 'Propuesta Abierta', desc: 'Juan Pérez (TechCorp) abrió "Propuesta Q3" por 3ra vez.', time: 'Hace 2 min', icon: MailOpen, color: 'text-emerald-400', bg: 'bg-emerald-400/20', actionText: 'Ver Actividad' },
  { id: 2, type: 'meeting', title: 'Reunión Programada', desc: 'Demo agendada con Global Dynamics para mañana a las 10:00 AM.', time: 'Hace 15 min', icon: Users, color: 'text-blue-400', bg: 'bg-blue-400/20', actionText: 'Ver Calendario' },
  { id: 3, type: 'alert', title: 'Alerta de Riesgo (Churn)', desc: 'Stark Ind. visitó la página de cancelación de suscripción.', time: 'Hace 45 min', icon: AlertCircle, color: 'text-[#E63946]', bg: 'bg-[#E63946]/20', actionText: 'Contactar Urgente' },
  { id: 4, type: 'lead', title: 'Nuevo Lead Calificado', desc: 'Wayne Ent. completó el formulario Enterprise. Puntuación: 95/100.', time: 'Hace 2 horas', icon: Zap, color: 'text-purple-400', bg: 'bg-purple-400/20', actionText: 'Asignar Ejecutivo' },
  { id: 5, type: 'call', title: 'Llamada Completada', desc: 'Llamada de descubrimiento con LexCorp. Interés alto en plan Pro.', time: 'Hace 3 horas', icon: Phone, color: 'text-indigo-400', bg: 'bg-indigo-400/20', actionText: 'Ver Notas' },
  { id: 6, type: 'action', title: 'Clic en Enlace', desc: 'Sarah Connor hizo clic en el caso de éxito enviado ayer.', time: 'Hace 5 horas', icon: MousePointerClick, color: 'text-emerald-400', bg: 'bg-emerald-400/20', actionText: 'Enviar Follow-up' },
  { id: 7, type: 'document', title: 'Contrato Firmado', desc: 'Daily Planet firmó el acuerdo anual. MRR +$4,200.', time: 'Ayer', icon: FileText, color: 'text-amber-400', bg: 'bg-amber-400/20', actionText: 'Ver Contrato' },
];

const filters = [
  { id: 'todos', label: 'Todos' },
  { id: 'alert', label: 'Alertas' },
  { id: 'lead', label: 'Leads' },
  { id: 'meeting', label: 'Reuniones' },
  { id: 'document', label: 'Documentos' },
];

export function EventStream() {
  const [activeFilter, setActiveFilter] = useState('todos');
  const [searchQuery, setSearchQuery] = useState('');
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [eventsList, setEventsList] = useState(initialEvents);

  useEffect(() => {
    const fetchData = async () => {
      const data = await api.getEvents();
      if (data && data.events && data.events.length > 0) {
        const formatted = data.events.map((e: any) => ({
          id: e.id || Date.now() + Math.random(),
          type: 'action',
          title: String(e.tipo_evento).replace('_', ' ').toUpperCase(),
          desc: JSON.stringify(e.detalles || {}),
          time: new Date(e.created_at).toLocaleString(),
          icon: Activity,
          color: 'text-emerald-400',
          bg: 'bg-emerald-400/20',
          actionText: 'Ver detalles'
        }));
        setEventsList(formatted);
      }
    };
    fetchData();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const filteredEvents = eventsList.filter(ev => {
    const matchesFilter = activeFilter === 'todos' || ev.type === activeFilter;
    const matchesSearch = ev.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      ev.desc.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  return (
    <div className="p-8 max-w-5xl mx-auto h-full flex flex-col relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-8 right-8 bg-emerald-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50 animate-in fade-in slide-in-from-bottom-5">
          <Check className="w-5 h-5" />
          <span className="font-medium">{toastMessage}</span>
        </div>
      )}

      <header className="flex flex-col md:flex-row justify-between items-start md:items-end gap-6 mb-8 shrink-0">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <h2 className="text-3xl font-display font-bold">Event Stream</h2>
            <div className="flex items-center gap-1.5 px-2.5 py-1 bg-[#E63946]/10 border border-[#E63946]/20 rounded-full">
              <div className="w-2 h-2 rounded-full bg-[#E63946] animate-pulse"></div>
              <span className="text-xs font-bold text-[#E63946] uppercase tracking-wider">Live</span>
            </div>
          </div>
          <p className="text-slate-400">Monitoreo en tiempo real de las interacciones de tus leads.</p>
        </div>

        <div className="flex flex-col sm:flex-row gap-4 w-full md:w-auto">
          <div className="relative w-full sm:w-64">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              placeholder="Buscar eventos..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[#111928]/80 border border-white/10 rounded-lg pl-9 pr-4 py-2 text-sm text-white placeholder:text-slate-500 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
            />
          </div>
          <button
            onClick={() => showToast("Abriendo opciones de filtros avanzados...")}
            className="px-4 py-2 bg-[#111928]/80 border border-white/10 hover:bg-white/5 text-slate-300 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-2"
          >
            <Filter className="w-4 h-4" /> Más Filtros
          </button>
        </div>
      </header>

      {/* Filters */}
      <div className="flex overflow-x-auto pb-4 mb-4 gap-2 shrink-0 hide-scrollbar">
        {filters.map(f => (
          <button
            key={f.id}
            onClick={() => setActiveFilter(f.id)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-all whitespace-nowrap ${activeFilter === f.id
                ? 'bg-[#E63946] text-white shadow-[0_0_15px_rgba(230,57,70,0.3)]'
                : 'bg-[#111928]/80 border border-white/10 text-slate-400 hover:text-white hover:bg-white/5'
              }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Timeline */}
      <div className="flex-1 overflow-y-auto pr-4 pb-8">
        <div className="bg-[#111928]/60 backdrop-blur-md border border-white/5 rounded-2xl p-6 md:p-8">
          {filteredEvents.length === 0 ? (
            <div className="text-center py-12">
              <Activity className="w-12 h-12 text-slate-600 mx-auto mb-4 opacity-50" />
              <h3 className="text-lg font-medium text-slate-300 mb-1">No hay eventos</h3>
              <p className="text-slate-500 text-sm">No se encontraron eventos que coincidan con tu búsqueda.</p>
            </div>
          ) : (
            <div className="relative before:absolute before:inset-0 before:ml-6 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-white/10 before:via-white/5 before:to-transparent">
              <div className="space-y-6">
                {filteredEvents.map((event) => (
                  <div key={event.id} className="relative flex items-start group">
                    {/* Timeline Line (Mobile: Left, Desktop: Center) */}
                    <div className="absolute left-6 md:left-1/2 w-0.5 h-full bg-white/5 -translate-x-1/2 group-last:hidden"></div>

                    {/* Timeline Dot */}
                    <div className={`absolute left-6 md:left-1/2 -translate-x-1/2 mt-5 w-3 h-3 rounded-full border-2 border-[#111928] ${event.bg} ${event.color} z-10 shadow-[0_0_10px_currentColor] opacity-80 group-hover:opacity-100 group-hover:scale-125 transition-all duration-300`}></div>

                    {/* Content Card */}
                    <div className="ml-16 md:ml-0 w-full md:w-[calc(50%-2.5rem)] md:even:ml-auto md:odd:mr-auto md:even:pl-0 md:odd:pr-0">
                      <div className="bg-[#0B132B]/80 hover:bg-[#111928] border border-white/5 hover:border-white/10 p-5 rounded-xl transition-all duration-300 group-hover:-translate-y-1 group-hover:shadow-xl relative overflow-hidden">
                        {/* Subtle background glow based on event type */}
                        <div className={`absolute top-0 right-0 w-32 h-32 ${event.bg} blur-3xl rounded-full opacity-0 group-hover:opacity-20 transition-opacity duration-500 translate-x-1/2 -translate-y-1/2`}></div>

                        <div className="flex items-start justify-between gap-4 mb-3 relative z-10">
                          <div className="flex items-center gap-3">
                            <div className={`p-2.5 rounded-lg ${event.bg} border border-white/5`}>
                              <event.icon className={`w-4 h-4 ${event.color}`} />
                            </div>
                            <div>
                              <h4 className="font-bold text-white text-base">{event.title}</h4>
                              <div className="flex items-center gap-1.5 text-xs text-slate-500 mt-0.5">
                                <Clock className="w-3 h-3" />
                                <span>{event.time}</span>
                              </div>
                            </div>
                          </div>
                        </div>

                        <p className="text-slate-300 text-sm leading-relaxed mb-4 relative z-10">
                          {event.desc}
                        </p>

                        <div className="flex items-center justify-between pt-3 border-t border-white/5 relative z-10">
                          <button
                            onClick={() => showToast(`Ejecutando acción: ${event.actionText}...`)}
                            className={`text-xs font-bold flex items-center gap-1.5 ${event.color} hover:text-white transition-colors group/btn`}
                          >
                            {event.actionText}
                            <ArrowRight className="w-3 h-3 group-hover/btn:translate-x-1 transition-transform" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
