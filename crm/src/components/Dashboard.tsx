import React, { useState, useRef, useEffect } from 'react';
import { DollarSign, Users, TrendingUp, Zap, Clock, ArrowRight, CheckCircle2, AlertCircle, Check, Search, Filter, Mic, Send, MoreVertical, Mail, Phone, Calendar, Activity, Loader2 } from 'lucide-react';
import { api } from '../api';

export function Dashboard() {
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [commandQuery, setCommandQuery] = useState('');
  const [activeSuggestionFilter, setActiveSuggestionFilter] = useState('Todas');
  const [showSuggestionFilters, setShowSuggestionFilters] = useState(false);
  const [kpiData, setKpiData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isCopilotTyping, setIsCopilotTyping] = useState(false);
  const filterRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const fetchDashboard = async () => {
      setIsLoading(true);
      const data = await api.getDashboard();
      if (data) {
        setKpiData(data);
      }
      setIsLoading(false);
    };
    fetchDashboard();
  }, []);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (filterRef.current && !filterRef.current.contains(event.target as Node)) {
        setShowSuggestionFilters(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const handleCommandSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (commandQuery.trim()) {
      showToast(`Procesando comando: "${commandQuery}"`);
      setIsCopilotTyping(true);
      const res = await api.askCopilot(commandQuery, 'dashboard');
      setIsCopilotTyping(false);
      showToast(res.response || 'Comando procesado.');
      setCommandQuery('');
    }
  };

  const suggestionFilters = ['Todas', 'Riesgo Churn', 'Cierre Alto', 'Upsell'];

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-8 relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-8 right-8 bg-emerald-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50 animate-in fade-in slide-in-from-bottom-5">
          <Check className="w-5 h-5" />
          <span className="font-medium">{toastMessage}</span>
        </div>
      )}

      {/* Header & Command Bar */}
      <header className="flex flex-col lg:flex-row justify-between items-start lg:items-end gap-6">
        <div>
          <h2 className="text-3xl font-display font-bold mb-2">Bienvenido, Comandante.</h2>
          <p className="text-slate-400 flex items-center gap-2">
            <Zap className="w-4 h-4 text-[#E63946]" />
            <span className="italic">"Poder y Fuego"</span> — Tu copiloto IA está listo.
          </p>
        </div>

        {/* AI Command Bar */}
        <div className="w-full lg:w-[450px]">
          <form onSubmit={handleCommandSubmit} className="relative group">
            <div className="absolute inset-0 bg-gradient-to-r from-[#E63946] to-[#FF2A2A] rounded-xl blur opacity-20 group-hover:opacity-40 transition-opacity"></div>
            <div className="relative flex items-center bg-[#111928] border border-white/10 rounded-xl overflow-hidden focus-within:border-[#E63946]/50 transition-colors">
              <div className="pl-4 pr-2 text-slate-400">
                <SparklesIcon className="w-5 h-5 text-[#E63946]" />
              </div>
              <input
                type="text"
                value={commandQuery}
                onChange={(e) => setCommandQuery(e.target.value)}
                placeholder="Pídele a la IA (ej. 'Prepara un email para Tony Stark')"
                className="w-full bg-transparent py-3 text-sm text-white placeholder:text-slate-500 focus:outline-none"
              />
              <div className="flex items-center pr-2 gap-1">
                <button type="button" className="p-2 text-slate-400 hover:text-white transition-colors rounded-lg hover:bg-white/5">
                  <Mic className="w-4 h-4" />
                </button>
                <button type="submit" disabled={isCopilotTyping} className="p-2 text-[#E63946] hover:text-[#FF2A2A] transition-colors rounded-lg hover:bg-[#E63946]/10 disabled:opacity-50">
                  {isCopilotTyping ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
                </button>
              </div>
            </div>
          </form>
        </div>
      </header>

      {/* KPIs & Pipeline Health */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="md:col-span-3 grid grid-cols-1 sm:grid-cols-3 gap-6">
          <KpiCard
            title="MRR Proyectado"
            value={kpiData?.mrr_proyectado ? `$${Number(kpiData.mrr_proyectado).toLocaleString()}` : "$124,500"}
            trend="+12.5%"
            icon={DollarSign}
            positive={true}
            action="Ver Forecast"
            showToast={showToast}
          />
          <KpiCard
            title="Leads Activos"
            value={kpiData?.leads_activos || "842"}
            trend="+5.2%"
            icon={Users}
            positive={true}
            action="Filtrar Leads"
            showToast={showToast}
          />
          <KpiCard
            title="Pipeline Value"
            value={kpiData?.pipeline_value ? `$${(Number(kpiData.pipeline_value) / 1000000).toFixed(1)}M` : "$2.4M"}
            trend="-2.1%"
            icon={TrendingUp}
            positive={false}
            action="Analizar Caída"
            showToast={showToast}
          />
        </div>

        {/* Pipeline Health Indicator */}
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6 flex flex-col justify-between group hover:border-white/20 transition-colors cursor-pointer" onClick={() => showToast("Abriendo diagnóstico del Pipeline...")}>
          <div className="flex justify-between items-start mb-4">
            <div className="p-3 rounded-xl bg-emerald-500/10 text-emerald-400">
              <Activity className="w-6 h-6" />
            </div>
            <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              Saludable
            </span>
          </div>
          <div>
            <h4 className="text-slate-400 text-sm font-medium mb-1">Pipeline Health</h4>
            <div className="flex items-end gap-2">
              <p className="text-3xl font-display font-bold tracking-tight">92<span className="text-lg text-slate-500 font-normal">/100</span></p>
            </div>
          </div>
          <div className="mt-4 w-full h-1.5 bg-white/5 rounded-full overflow-hidden">
            <div className="h-full bg-emerald-400 rounded-full w-[92%]"></div>
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* AI Copilot */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6 relative overflow-hidden">
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-[#E63946] to-[#FF2A2A]"></div>
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-display font-bold flex items-center gap-2">
                <Zap className="w-5 h-5 text-[#E63946]" />
                Sugerencias de la IA
              </h3>

              <div className="flex items-center gap-3">
                <div className="relative" ref={filterRef}>
                  <button
                    onClick={() => setShowSuggestionFilters(!showSuggestionFilters)}
                    className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-sm font-medium text-slate-300 transition-colors border border-white/5"
                  >
                    <Filter className="w-3.5 h-3.5" />
                    {activeSuggestionFilter}
                  </button>

                  {showSuggestionFilters && (
                    <div className="absolute right-0 top-full mt-2 w-40 bg-[#111928] border border-white/10 rounded-xl shadow-xl overflow-hidden z-20">
                      {suggestionFilters.map(filter => (
                        <button
                          key={filter}
                          onClick={() => {
                            setActiveSuggestionFilter(filter);
                            setShowSuggestionFilters(false);
                            showToast(`Filtro aplicado: ${filter}`);
                          }}
                          className={`w-full text-left px-4 py-2 text-sm transition-colors ${activeSuggestionFilter === filter ? 'bg-[#E63946]/10 text-[#E63946] font-medium' : 'text-slate-300 hover:bg-white/5'}`}
                        >
                          {filter}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>

            <div className="space-y-4">
              {(activeSuggestionFilter === 'Todas' || activeSuggestionFilter === 'Cierre Alto') && (
                <AiSuggestionItem
                  company="TechCorp Inc."
                  contact="Sarah Connor"
                  action="Contactar urgente. Probabilidad de cierre subió al 82% tras abrir la propuesta 3 veces hoy."
                  score={82}
                  time="Hace 10 min"
                  impact="$12.5k"
                  effort="Bajo"
                  showToast={showToast}
                />
              )}
              {(activeSuggestionFilter === 'Todas' || activeSuggestionFilter === 'Riesgo Churn') && (
                <AiSuggestionItem
                  company="Global Dynamics"
                  contact="Elon T."
                  action="Riesgo de Churn detectado. No ha respondido en 14 días. Sugiero enviar caso de éxito."
                  score={45}
                  time="Hace 2 horas"
                  isWarning={true}
                  impact="$45k"
                  effort="Medio"
                  showToast={showToast}
                />
              )}
              {(activeSuggestionFilter === 'Todas' || activeSuggestionFilter === 'Cierre Alto') && (
                <AiSuggestionItem
                  company="Stark Industries"
                  contact="Tony S."
                  action="Lead caliente. Acaba de registrarse en el webinar de Enterprise Solutions."
                  score={95}
                  time="Hace 3 horas"
                  impact="$28k"
                  effort="Bajo"
                  showToast={showToast}
                />
              )}
            </div>
          </div>
        </div>

        {/* Event Stream */}
        <div className="space-y-6">
          <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6 h-full">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-display font-bold flex items-center gap-2">
                <Clock className="w-5 h-5 text-slate-400" />
                Event Stream
              </h3>
              <button
                onClick={() => showToast("Abriendo vista completa de Event Stream...")}
                className="text-xs text-[#E63946] hover:text-[#FF2A2A] transition-colors"
              >
                Ver todo
              </button>
            </div>

            <div className="space-y-6 relative before:absolute before:inset-0 before:ml-2 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-white/10 before:to-transparent">
              <EventItem
                title="Propuesta Abierta"
                desc="Juan Pérez (TechCorp) abrió 'Propuesta Q3'."
                time="10:42 AM"
                icon={CheckCircle2}
                color="text-emerald-400"
                bgColor="bg-emerald-400/20"
                showToast={showToast}
              />
              <EventItem
                title="Reunión Programada"
                desc="Demo agendada con Global Dynamics."
                time="09:15 AM"
                icon={Users}
                color="text-blue-400"
                bgColor="bg-blue-400/20"
                showToast={showToast}
              />
              <EventItem
                title="Alerta de Riesgo"
                desc="Stark Ind. canceló la suscripción Pro."
                time="Ayer"
                icon={AlertCircle}
                color="text-[#E63946]"
                bgColor="bg-[#E63946]/20"
                showToast={showToast}
              />
              <EventItem
                title="Nuevo Lead"
                desc="Wayne Ent. se registró vía Orgánico."
                time="Ayer"
                icon={Zap}
                color="text-purple-400"
                bgColor="bg-purple-400/20"
                showToast={showToast}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function KpiCard({ title, value, trend, icon: Icon, positive, action, showToast }: any) {
  return (
    <div
      className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6 hover:border-white/20 transition-colors group cursor-pointer flex flex-col justify-between"
      onClick={() => showToast && action && showToast(`Ejecutando acción: ${action}`)}
    >
      <div>
        <div className="flex justify-between items-start mb-4">
          <div className="p-3 rounded-xl bg-white/5 group-hover:bg-[#E63946]/10 transition-colors">
            <Icon className="w-6 h-6 text-slate-400 group-hover:text-[#E63946] transition-colors" />
          </div>
          <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${positive ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-[#E63946]/10 text-[#E63946] border border-[#E63946]/20'}`}>
            {trend}
          </span>
        </div>
        <div>
          <h4 className="text-slate-400 text-sm font-medium mb-1">{title}</h4>
          <p className="text-3xl font-display font-bold tracking-tight">{value}</p>
        </div>
      </div>
      {action && (
        <div className="mt-4 pt-4 border-t border-white/5 flex items-center justify-between text-sm text-slate-400 group-hover:text-[#E63946] transition-colors">
          <span>{action}</span>
          <ArrowRight className="w-4 h-4 opacity-0 group-hover:opacity-100 transition-opacity transform -translate-x-2 group-hover:translate-x-0" />
        </div>
      )}
    </div>
  );
}

function AiSuggestionItem({ company, contact, action, score, time, isWarning, impact, effort, showToast }: any) {
  return (
    <div className="group p-4 rounded-xl border border-white/5 bg-white/[0.02] hover:bg-white/[0.04] hover:border-white/10 transition-all cursor-pointer flex flex-col sm:flex-row gap-4 items-start">
      <div className="relative flex-shrink-0 mt-1 mx-auto sm:mx-0">
        <svg className="w-14 h-14 transform -rotate-90">
          <circle cx="28" cy="28" r="24" stroke="currentColor" strokeWidth="4" fill="transparent" className="text-white/10" />
          <circle cx="28" cy="28" r="24" stroke="currentColor" strokeWidth="4" fill="transparent"
            strokeDasharray={150.7} strokeDashoffset={150.7 - (150.7 * score) / 100}
            className={isWarning ? 'text-amber-500' : 'text-emerald-500'} />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="text-sm font-bold font-mono">{score}</span>
        </div>
      </div>
      <div className="flex-1 w-full">
        <div className="flex flex-col sm:flex-row sm:justify-between sm:items-start mb-2 gap-2">
          <div>
            <h4 className="font-bold text-lg leading-tight">{company}</h4>
            <span className="text-slate-400 text-sm">{contact}</span>
          </div>
          <div className="flex items-center gap-2">
            {impact && (
              <span className="px-2 py-1 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded-md text-xs font-bold flex items-center gap-1">
                <TrendingUp className="w-3 h-3" /> {impact}
              </span>
            )}
            <span className="text-xs text-slate-500 whitespace-nowrap">{time}</span>
          </div>
        </div>
        <p className="text-sm text-slate-300 mb-4 leading-relaxed">{action}</p>
        <div className="flex flex-wrap gap-2 items-center justify-between">
          <div className="flex gap-2">
            <button
              onClick={(e) => { e.stopPropagation(); showToast(`Ejecutando acción sugerida para ${company}...`); }}
              className="px-4 py-2 rounded-lg bg-[#E63946] hover:bg-[#FF2A2A] text-white text-sm font-medium transition-colors flex items-center gap-2"
            >
              <Zap className="w-4 h-4" /> Ejecutar
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); showToast(`Sugerencia para ${company} descartada.`); }}
              className="px-4 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-slate-300 text-sm font-medium transition-colors"
            >
              Descartar
            </button>
          </div>
          {effort && (
            <span className="text-xs text-slate-500 flex items-center gap-1">
              <Clock className="w-3 h-3" /> Esfuerzo: {effort}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

function EventItem({ title, desc, time, icon: Icon, color, bgColor, showToast }: any) {
  return (
    <div className="relative flex items-start gap-4 group">
      <div className={`absolute left-0 md:left-1/2 -ml-1.5 md:-ml-1.5 w-3 h-3 rounded-full border-2 border-[#111928] ${bgColor} ${color} mt-1.5 z-10`}></div>
      <div className="ml-6 md:ml-0 flex-1 bg-white/[0.01] hover:bg-white/[0.03] border border-transparent hover:border-white/5 rounded-xl p-3 -mt-3 transition-colors">
        <div className="flex items-center gap-2 mb-1">
          <div className={`p-1.5 rounded-md ${bgColor}`}>
            <Icon className={`w-3.5 h-3.5 ${color}`} />
          </div>
          <h4 className="text-sm font-bold text-slate-200">{title}</h4>
          <span className="text-xs text-slate-500 ml-auto">{time}</span>
        </div>
        <p className="text-xs text-slate-400 leading-relaxed mb-2">{desc}</p>

        {/* Quick Actions (Visible on hover) */}
        <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity h-0 group-hover:h-auto overflow-hidden">
          <button
            onClick={() => showToast(`Enviando email rápido sobre: ${title}`)}
            className="p-1.5 bg-white/5 hover:bg-white/10 rounded-md text-slate-400 hover:text-white transition-colors"
            title="Enviar Email"
          >
            <Mail className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={() => showToast(`Iniciando llamada relacionada a: ${title}`)}
            className="p-1.5 bg-white/5 hover:bg-white/10 rounded-md text-slate-400 hover:text-white transition-colors"
            title="Llamar"
          >
            <Phone className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={() => showToast(`Agendando follow-up para: ${title}`)}
            className="p-1.5 bg-white/5 hover:bg-white/10 rounded-md text-slate-400 hover:text-white transition-colors"
            title="Agendar Follow-up"
          >
            <Calendar className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  );
}

function SparklesIcon(props: any) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" />
      <path d="M5 3v4" />
      <path d="M19 17v4" />
      <path d="M3 5h4" />
      <path d="M17 19h4" />
    </svg>
  );
}
