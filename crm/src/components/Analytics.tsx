import React, { useState, useRef, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell, Legend } from 'recharts';
import { TrendingUp, DollarSign, Target, Award, Download, Sparkles, Calendar, ArrowUpRight, Users, Zap, Filter, Share2, ArrowRightLeft, Activity, CreditCard, TrendingDown, PhoneCall, Video, Clock, Settings2, Trophy, X, ChevronDown, Check } from 'lucide-react';
import { api } from '../api';

const revenueData = [
  { name: 'Ene', actual: 4000, forecast: 4400 },
  { name: 'Feb', actual: 5000, forecast: 5200 },
  { name: 'Mar', actual: 6500, forecast: 6000 },
  { name: 'Abr', actual: 7800, forecast: 7100 },
  { name: 'May', actual: 8200, forecast: 8500 },
  { name: 'Jun', actual: 10500, forecast: 9800 },
  { name: 'Jul', actual: null, forecast: 11200 },
  { name: 'Ago', actual: null, forecast: 12500 },
];

const winRateData = [
  { name: 'Q1', rate: 42 },
  { name: 'Q2', rate: 48 },
  { name: 'Q3', rate: 55 },
  { name: 'Q4', rate: 62 },
];

const winRateTrendData = [
  { name: 'Ene', rate: 41 },
  { name: 'Feb', rate: 43 },
  { name: 'Mar', rate: 48 },
  { name: 'Abr', rate: 51 },
  { name: 'May', rate: 54 },
  { name: 'Jun', rate: 52 },
  { name: 'Jul', rate: 58 },
  { name: 'Ago', rate: 62 },
];

const sourceData = [
  { name: 'Orgánico', value: 45 },
  { name: 'Ads', value: 25 },
  { name: 'Referidos', value: 20 },
  { name: 'Outbound', value: 10 },
];
// Colores de marca SNAKE DRAGON: Rojo Disrupción, Rojo Brillante, Slate Claro, Slate Oscuro
const COLORS = ['#E63946', '#FF2A2A', '#94A3B8', '#334155'];

const topReps = [
  { id: 1, name: 'Sarah Connor', revenue: '$450k', deals: 12, winRate: '68%', trend: '+12%' },
  { id: 2, name: 'Tony Stark', revenue: '$380k', deals: 8, winRate: '75%', trend: '+5%' },
  { id: 3, name: 'Bruce Wayne', revenue: '$290k', deals: 15, winRate: '52%', trend: '-2%' },
];

export function Analytics() {
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [showFilters, setShowFilters] = useState(false);
  const [timePeriod, setTimePeriod] = useState('Este Trimestre');
  const [showPeriodDropdown, setShowPeriodDropdown] = useState(false);
  const [showAiReport, setShowAiReport] = useState(false);
  const [isComparing, setIsComparing] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Real Data State
  const [analyticsData, setAnalyticsData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  // New Filter State
  const [activeFilters, setActiveFilters] = useState([
    { id: 'region', label: 'Región', value: 'LATAM' },
    { id: 'segment', label: 'Segmento', value: 'Enterprise' }
  ]);
  const [showAddFilterMenu, setShowAddFilterMenu] = useState(false);
  const addFilterRef = useRef<HTMLDivElement>(null);

  const availableFilters = [
    { id: 'region', label: 'Región', options: ['LATAM', 'NA', 'EMEA', 'APAC'] },
    { id: 'segment', label: 'Segmento', options: ['Enterprise', 'Mid-Market', 'SMB'] },
    { id: 'product', label: 'Producto', options: ['SaaS Core', 'API Plus', 'Enterprise'] },
    { id: 'source', label: 'Origen', options: ['Inbound', 'Outbound', 'Referral'] }
  ];

  const removeFilter = (id: string) => {
    setActiveFilters(activeFilters.filter(f => f.id !== id));
    showToast(`Filtro eliminado`);
  };

  const addFilter = (filterId: string, value: string) => {
    const filterDef = availableFilters.find(f => f.id === filterId);
    if (!filterDef) return;

    const newFilters = activeFilters.filter(f => f.id !== filterId);
    newFilters.push({ id: filterId, label: filterDef.label, value });

    setActiveFilters(newFilters);
    setShowAddFilterMenu(false);
    showToast(`Filtro añadido: ${filterDef.label} = ${value}`);
  };

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setShowPeriodDropdown(false);
      }
      if (addFilterRef.current && !addFilterRef.current.contains(event.target as Node)) {
        setShowAddFilterMenu(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    const fetchAnalyticsData = async () => {
      setIsLoading(true);
      const data = await api.getAnalytics();
      if (data) setAnalyticsData(data);
      setIsLoading(false);
    };
    fetchAnalyticsData();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const handleExportCSV = (filename: string) => {
    const csvContent = "data:text/csv;charset=utf-8,Mes,Real,Proyectado\nEne,4000,4400\nFeb,5000,5200\nMar,6500,6000\n";
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", filename);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    showToast(`Archivo ${filename} exportado correctamente.`);
  };

  const handleShare = () => {
    navigator.clipboard.writeText(window.location.href);
    showToast("Enlace copiado al portapapeles.");
  };

  const periods = ['Este Mes', 'Este Trimestre', 'Este Año', 'Últimos 12 Meses'];

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6 relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-8 right-8 bg-emerald-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50 animate-in fade-in slide-in-from-bottom-5">
          <Check className="w-5 h-5" />
          <span className="font-medium">{toastMessage}</span>
        </div>
      )}

      {/* AI Report Modal */}
      {showAiReport && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-[#0B132B] border border-white/10 rounded-2xl max-w-2xl w-full p-8 relative shadow-2xl">
            <button
              onClick={() => setShowAiReport(false)}
              className="absolute top-6 right-6 text-slate-400 hover:text-white transition-colors"
            >
              <X className="w-6 h-6" />
            </button>
            <div className="flex items-center gap-3 mb-6">
              <div className="p-3 bg-[#E63946]/20 rounded-xl">
                <Sparkles className="w-6 h-6 text-[#E63946]" />
              </div>
              <h2 className="text-2xl font-display font-bold">Reporte de Inteligencia Artificial</h2>
            </div>
            <div className="space-y-4 text-slate-300 leading-relaxed">
              <p>Basado en los datos de <strong>{timePeriod}</strong>, aquí tienes el análisis predictivo:</p>
              <ul className="space-y-3 list-disc pl-5">
                <li><strong>Tendencia Positiva:</strong> El Win Rate ha aumentado un 4.1% impulsado por el rendimiento excepcional de Sarah Connor en cuentas Enterprise.</li>
                <li><strong>Riesgo Detectado:</strong> El ciclo de ventas en el segmento Mid-Market se ha alargado 3 días en promedio. Se sugiere revisar el proceso de validación técnica.</li>
                <li><strong>Predicción de Cierre:</strong> Existe un 85% de probabilidad de superar la cuota global este mes si se mantienen las tasas de conversión actuales en la etapa de "Propuestas".</li>
                <li><strong>Recomendación:</strong> Enfocar esfuerzos de marketing en canales "Orgánico" y "Ads", ya que representan el 70% de los leads calificados con menor CAC.</li>
              </ul>
            </div>
            <div className="mt-8 flex justify-end">
              <button
                onClick={() => {
                  handleExportCSV('reporte_ia.csv');
                  setShowAiReport(false);
                }}
                className="px-6 py-2.5 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg font-medium transition-colors flex items-center gap-2"
              >
                <Download className="w-4 h-4" /> Descargar Resumen
              </button>
            </div>
          </div>
        </div>
      )}

      <header className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-4">
        <div>
          <h2 className="text-3xl font-display font-bold mb-2">Revenue Intelligence</h2>
          <p className="text-slate-400">Análisis predictivo, rendimiento de ventas y reportes IA.</p>
        </div>
        <div className="flex flex-wrap gap-3">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`px-4 py-2 border rounded-lg text-sm font-medium transition-colors flex items-center gap-2 ${showFilters ? 'bg-white/10 border-white/20 text-white' : 'bg-[#111928]/80 border-white/10 hover:bg-white/5 text-slate-300'}`}
          >
            <Filter className="w-4 h-4" /> Filtros
          </button>
          <button
            onClick={() => {
              setIsComparing(!isComparing);
              showToast(isComparing ? "Modo comparación desactivado." : "Modo comparación activado.");
            }}
            className={`px-4 py-2 border rounded-lg text-sm font-medium transition-colors flex items-center gap-2 ${isComparing ? 'bg-blue-500/20 border-blue-500/30 text-blue-400' : 'bg-[#111928]/80 border-white/10 hover:bg-white/5 text-slate-300'}`}
          >
            <ArrowRightLeft className="w-4 h-4" /> Comparar
          </button>

          <div className="relative" ref={dropdownRef}>
            <button
              onClick={() => setShowPeriodDropdown(!showPeriodDropdown)}
              className="px-4 py-2 bg-[#111928]/80 border border-white/10 hover:bg-white/5 text-slate-300 rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
            >
              <Calendar className="w-4 h-4" /> {timePeriod} <ChevronDown className="w-4 h-4 ml-1 opacity-50" />
            </button>
            {showPeriodDropdown && (
              <div className="absolute top-full right-0 mt-2 w-48 bg-[#111928] border border-white/10 rounded-xl shadow-xl overflow-hidden z-20">
                {periods.map(period => (
                  <button
                    key={period}
                    onClick={() => {
                      setTimePeriod(period);
                      setShowPeriodDropdown(false);
                      showToast(`Período actualizado a: ${period}`);
                    }}
                    className={`w-full text-left px-4 py-2.5 text-sm transition-colors ${timePeriod === period ? 'bg-white/10 text-white font-medium' : 'text-slate-300 hover:bg-white/5'}`}
                  >
                    {period}
                  </button>
                ))}
              </div>
            )}
          </div>

          <button
            onClick={handleShare}
            className="px-4 py-2 bg-[#111928]/80 border border-white/10 hover:bg-white/5 text-slate-300 rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
          >
            <Share2 className="w-4 h-4" /> Compartir
          </button>
          <button
            onClick={() => handleExportCSV('revenue_data.csv')}
            className="px-4 py-2 bg-[#111928]/80 border border-white/10 hover:bg-white/5 text-slate-300 rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
          >
            <Download className="w-4 h-4" /> Exportar CSV
          </button>
          <button
            onClick={() => setShowAiReport(true)}
            className="px-4 py-2 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg text-sm font-medium transition-colors flex items-center gap-2 shadow-[0_0_15px_rgba(230,57,70,0.3)]"
          >
            <Sparkles className="w-4 h-4" /> Reporte IA
          </button>
        </div>
      </header>

      {/* Active Filters Bar */}
      {showFilters && (
        <div className="bg-[#111928]/60 border border-white/10 rounded-xl p-4 flex flex-wrap items-center gap-4 animate-in slide-in-from-top-2 fade-in">
          <span className="text-sm font-medium text-slate-400">Filtros Activos:</span>
          {activeFilters.length === 0 && (
            <span className="text-sm text-slate-500 italic">Ninguno</span>
          )}
          {activeFilters.map(filter => (
            <div key={filter.id} className="flex items-center gap-2 px-3 py-1.5 bg-white/5 border border-white/10 rounded-lg text-sm text-slate-300">
              {filter.label}: {filter.value}
              <button onClick={() => removeFilter(filter.id)} className="hover:text-white ml-1 transition-colors">
                <X className="w-3 h-3" />
              </button>
            </div>
          ))}

          <div className="relative ml-auto" ref={addFilterRef}>
            <button
              onClick={() => setShowAddFilterMenu(!showAddFilterMenu)}
              className="text-sm text-[#E63946] hover:text-[#FF2A2A] font-medium transition-colors flex items-center gap-1"
            >
              + Añadir Filtro
            </button>

            {showAddFilterMenu && (
              <div className="absolute top-full right-0 mt-2 w-56 bg-[#111928] border border-white/10 rounded-xl shadow-xl overflow-hidden z-20 max-h-80 overflow-y-auto">
                <div className="p-2 space-y-2">
                  {availableFilters.map(filterDef => (
                    <div key={filterDef.id} className="space-y-1">
                      <div className="px-3 py-1.5 text-xs font-bold text-slate-500 uppercase tracking-wider">
                        {filterDef.label}
                      </div>
                      {filterDef.options.map(opt => {
                        const isActive = activeFilters.some(f => f.id === filterDef.id && f.value === opt);
                        return (
                          <button
                            key={opt}
                            onClick={() => addFilter(filterDef.id, opt)}
                            className={`w-full text-left px-3 py-2 text-sm rounded-lg transition-colors flex justify-between items-center ${isActive
                                ? 'bg-[#E63946]/10 text-[#E63946] font-medium'
                                : 'text-slate-300 hover:bg-white/5'
                              }`}
                          >
                            {opt}
                            {isActive && <Check className="w-3 h-3" />}
                          </button>
                        );
                      })}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Top KPIs */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MiniKpi title="ARR Total" value="$1.2M" trend="+15%" icon={DollarSign} />
        <MiniKpi title="Win Rate Global" value="54.2%" trend="+4.1%" icon={Award} />
        <MiniKpi title="Ciclo de Venta" value="24 días" trend="-2 días" icon={Target} positive={true} />
        <MiniKpi title="Ticket Promedio" value="$18.5k" trend="+8%" icon={TrendingUp} />
        <MiniKpi title="Pipeline Value" value="$3.4M" trend="+12%" icon={Activity} />
        <MiniKpi title="CAC (Costo Adquisición)" value="$450" trend="-5%" icon={CreditCard} positive={true} />
        <MiniKpi title="LTV (Life Time Value)" value="$12.5k" trend="+15%" icon={Users} />
        <MiniKpi title="Churn Rate" value="2.1%" trend="-0.5%" icon={TrendingDown} positive={true} />
      </div>

      {/* Main Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Chart */}
        <div className="lg:col-span-2 bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-lg font-display font-bold">Estado de Facturación (Cashflow)</h3>
            <span className="px-3 py-1 bg-[#3B82F6]/10 text-[#3B82F6] border border-[#3B82F6]/20 rounded-full text-xs font-bold">
              En tiempo real
            </span>
          </div>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={analyticsData?.facturacion || [
                { estado_pago: 'pagada', monto_total: 125000 },
                { estado_pago: 'pendiente', monto_total: 45000 },
                { estado_pago: 'vencida', monto_total: 12000 }
              ]} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="estado_pago" stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} style={{ textTransform: 'capitalize' }} />
                <YAxis stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `$${value / 1000}k`} />
                <Tooltip
                  cursor={{ fill: 'rgba(255,255,255,0.02)' }}
                  contentStyle={{ backgroundColor: '#0B132B', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '8px' }}
                  formatter={(value: any) => [`$${Number(value).toLocaleString()}`, 'Monto Total']}
                />
                <Bar dataKey="monto_total" radius={[4, 4, 0, 0]}>
                  {
                    (analyticsData?.facturacion || [
                      { estado_pago: 'pagada' },
                      { estado_pago: 'pendiente' },
                      { estado_pago: 'vencida' }
                    ]).map((entry: any, index: number) => {
                      const color = entry.estado_pago === 'pagada' ? '#10B981' : entry.estado_pago === 'vencida' ? '#E63946' : '#F59E0B';
                      return <Cell key={`cell-${index}`} fill={color} />;
                    })
                  }
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Secondary Chart */}
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6">
          <h3 className="text-lg font-display font-bold mb-6">Comisiones (Liquidaciones)</h3>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
                <Pie
                  data={analyticsData?.comisiones || [
                    { estado: 'borrador', monto_total: 4500 },
                    { estado: 'aprobada', monto_total: 12000 },
                    { estado: 'pagada', monto_total: 8000 }
                  ]}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="monto_total"
                  nameKey="estado"
                  stroke="none"
                >
                  {
                    (analyticsData?.comisiones || [
                      { estado: 'borrador' },
                      { estado: 'aprobada' },
                      { estado: 'pagada' }
                    ]).map((entry: any, index: number) => {
                      const color = entry.estado === 'pagada' ? '#10B981' : entry.estado === 'aprobada' ? '#3B82F6' : '#94A3B8';
                      return <Cell key={`cell-${index}`} fill={color} />;
                    })
                  }
                </Pie>
                <Tooltip
                  contentStyle={{ backgroundColor: '#0B132B', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '8px' }}
                  formatter={(value: any) => [`$${Number(value).toLocaleString()}`, 'Monto']}
                />
                <Legend iconType="circle" />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Trend Chart Row */}
      <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6">
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-lg font-display font-bold">Cumplimiento de Cuotas</h3>
          <span className="px-3 py-1 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded-full text-xs font-bold">
            Data en Tiempo Real
          </span>
        </div>
        <div className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={analyticsData?.cuotas || [
              { tipo_cuota: 'ingresos_mensuales', monto_objetivo: 50000, ventas_actuales: 34000, porcentaje_cumplimiento: 68 },
              { tipo_cuota: 'ingresos_mensuales', monto_objetivo: 25000, ventas_actuales: 26000, porcentaje_cumplimiento: 104 }
            ]} margin={{ top: 10, right: 10, left: -20, bottom: 0 }} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" horizontal={false} />
              <XAxis type="number" stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `$${value / 1000}k`} />
              <YAxis dataKey="tipo_cuota" type="category" stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} width={120} />
              <Tooltip
                cursor={{ fill: 'rgba(255,255,255,0.02)' }}
                contentStyle={{ backgroundColor: '#0B132B', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '8px' }}
                formatter={(value: any, name: string) => {
                  if (name === 'porcentaje_cumplimiento') return [`${Number(value).toFixed(1)}%`, '% Cumplimiento'];
                  return [`$${Number(value).toLocaleString()}`, name === 'ventas_actuales' ? 'Ventas' : 'Objetivo'];
                }}
              />
              <Legend />
              <Bar dataKey="monto_objetivo" fill="#334155" radius={[0, 4, 4, 0]} name="Cuota (Objetivo)" barSize={20} />
              <Bar dataKey="ventas_actuales" fill="#E63946" radius={[0, 4, 4, 0]} name="Ventas Reales" barSize={20} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Team Performance Section */}
      <div className="mt-8 mb-6">
        <header className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-6">
          <div>
            <h3 className="text-2xl font-display font-bold mb-2">Rendimiento del Equipo</h3>
            <p className="text-slate-400">Métricas de actividad y alcance de cuotas por representante.</p>
          </div>
          <div className="flex flex-wrap gap-3">
            <button
              onClick={() => showToast("Abriendo directorio del equipo...")}
              className="px-4 py-2 bg-[#111928]/80 border border-white/10 hover:bg-white/5 text-slate-300 rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
            >
              <Users className="w-4 h-4" /> Directorio
            </button>
            <button
              onClick={() => showToast("Abriendo panel de configuración de cuotas...")}
              className="px-4 py-2 bg-[#111928]/80 border border-white/10 hover:bg-white/5 text-slate-300 rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
            >
              <Settings2 className="w-4 h-4" /> Ajustar Cuotas
            </button>
            <button
              onClick={() => handleExportCSV('ranking_equipo.csv')}
              className="px-4 py-2 bg-[#111928]/80 border border-white/10 hover:bg-white/5 text-slate-300 rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
            >
              <Download className="w-4 h-4" /> Exportar Ranking
            </button>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <MiniKpi title="Llamadas Realizadas" value="1,284" trend="+12%" icon={PhoneCall} />
          <MiniKpi title="Demos Agendadas" value="342" trend="+8%" icon={Video} />
          <MiniKpi title="Tiempo de Respuesta" value="14 min" trend="-2 min" icon={Clock} positive={true} />
          <MiniKpi title="Cuota Global Alcanzada" value="85%" trend="+5%" icon={Trophy} />
        </div>
      </div>

      {/* Bottom Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Lead Sources */}
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6">
          <h3 className="text-lg font-display font-bold mb-2">Origen de Leads</h3>
          <p className="text-xs text-slate-400 mb-6">Distribución de canales de adquisición.</p>
          <div className="h-[200px] w-full relative">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={sourceData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                  stroke="none"
                >
                  {sourceData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ backgroundColor: '#0B132B', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '8px' }}
                  itemStyle={{ color: '#fff' }}
                />
              </PieChart>
            </ResponsiveContainer>
            {/* Custom Legend */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center pointer-events-none">
              <span className="block text-2xl font-bold font-display text-white">4</span>
              <span className="block text-[10px] text-slate-400 uppercase tracking-wider">Canales</span>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3 mt-4">
            {sourceData.map((item, idx) => (
              <div key={item.name} className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[idx] }}></div>
                <span className="text-xs text-slate-300">{item.name} <span className="text-slate-500">({item.value}%)</span></span>
              </div>
            ))}
          </div>
        </div>

        {/* Funnel */}
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6">
          <h3 className="text-lg font-display font-bold mb-2">Funnel de Conversión</h3>
          <p className="text-xs text-slate-400 mb-6">Tasas de paso entre etapas del pipeline.</p>
          <div className="space-y-5">
            <FunnelStep label="Leads Generados" value="1,240" percent={100} color="bg-blue-500" />
            <FunnelStep label="Leads Calificados" value="850" percent={68} color="bg-purple-500" />
            <FunnelStep label="Propuestas" value="320" percent={25} color="bg-amber-500" />
            <FunnelStep label="Cierres (Won)" value="145" percent={11} color="bg-[#E63946]" />
          </div>
        </div>

        {/* Leaderboard */}
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h3 className="text-lg font-display font-bold mb-1">Top Performers</h3>
              <p className="text-xs text-slate-400">Ranking de ejecutivos de cuenta.</p>
            </div>
            <button
              onClick={() => showToast("Abriendo vista completa de Top Performers...")}
              className="p-2 hover:bg-white/5 rounded-lg text-slate-400 hover:text-white transition-colors"
            >
              <ArrowUpRight className="w-4 h-4" />
            </button>
          </div>
          <div className="space-y-4">
            {topReps.map((rep, idx) => (
              <div key={rep.id} className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5 hover:border-white/10 transition-colors">
                <div className="flex items-center gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs ${idx === 0 ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' : 'bg-white/10 text-slate-300'}`}>
                    #{idx + 1}
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-white">{rep.name}</h4>
                    <p className="text-xs text-slate-400">{rep.deals} deals cerrados</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-mono font-bold text-emerald-400">{rep.revenue}</p>
                  <p className={`text-xs ${rep.trend.startsWith('+') ? 'text-emerald-500' : 'text-[#E63946]'}`}>{rep.trend}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}

function MiniKpi({ title, value, trend, icon: Icon, positive = true }: any) {
  return (
    <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-xl p-5 flex items-center gap-4 hover:border-white/20 transition-colors group">
      <div className="p-3 rounded-xl bg-white/5 group-hover:bg-[#E63946]/10 transition-colors">
        <Icon className="w-6 h-6 text-slate-400 group-hover:text-[#E63946] transition-colors" />
      </div>
      <div>
        <p className="text-xs font-medium text-slate-400 mb-1">{title}</p>
        <div className="flex items-baseline gap-2">
          <span className="text-2xl font-display font-bold tracking-tight text-white">{value}</span>
          <span className={`text-xs font-bold px-1.5 py-0.5 rounded-md ${positive ? 'bg-emerald-500/10 text-emerald-400' : 'bg-[#E63946]/10 text-[#E63946]'}`}>
            {trend}
          </span>
        </div>
      </div>
    </div>
  );
}

function FunnelStep({ label, value, percent, color }: any) {
  return (
    <div>
      <div className="flex justify-between text-sm mb-1.5">
        <span className="font-medium text-slate-300">{label}</span>
        <div className="flex gap-3">
          <span className="text-slate-400">{value}</span>
          <span className="font-bold font-mono text-white w-10 text-right">{percent}%</span>
        </div>
      </div>
      <div className="w-full h-2.5 bg-white/5 rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full ${color} relative overflow-hidden`}
          style={{ width: `${percent}%` }}
        >
          <div className="absolute inset-0 bg-white/20 w-full animate-[shimmer_2s_infinite] -translate-x-full"></div>
        </div>
      </div>
    </div>
  );
}
