import React, { useState, useMemo, useRef, useEffect } from 'react';
import { Swords, Target, Trophy, TrendingUp, DollarSign, Users, Flame, Crosshair, Check, Filter, MapPin, Award, Activity, X, ChevronDown } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell, LineChart, Line } from 'recharts';
import { Dragon } from '../types';

const initialDragones: Dragon[] = [
  {
    id: 1,
    name: 'Sarah Connor',
    role: 'Alpha Closer',
    tier: 'Senior',
    region: 'Norte',
    revenue: '$450,000',
    revenueValue: 450000,
    quota: 120, // percentage
    winRate: 68,
    activeDeals: 14,
    status: 'on-fire',
    clients: ['TechCorp Inc.', 'Cyberdyne Systems', 'Skynet Solutions'],
  },
  {
    id: 2,
    name: 'Tony Stark',
    role: 'Enterprise AE',
    tier: 'Senior',
    region: 'Centro',
    revenue: '$380,000',
    revenueValue: 380000,
    quota: 95,
    winRate: 75,
    activeDeals: 8,
    status: 'stable',
    clients: ['Stark Industries', 'Avengers Init.', 'S.H.I.E.L.D.'],
  },
  {
    id: 3,
    name: 'Bruce Wayne',
    role: 'Strategic Accounts',
    tier: 'Enterprise',
    region: 'Sur',
    revenue: '$290,000',
    revenueValue: 290000,
    quota: 85,
    winRate: 52,
    activeDeals: 15,
    status: 'warning',
    clients: ['Wayne Enterprises', 'GCPD', 'Arkham Asylum'],
  },
  {
    id: 4,
    name: 'Diana Prince',
    role: 'Mid-Market AE',
    tier: 'Mid-Level',
    region: 'Centro',
    revenue: '$310,000',
    revenueValue: 310000,
    quota: 105,
    winRate: 61,
    activeDeals: 11,
    status: 'stable',
    clients: ['Themyscira LLC', 'Justice League', 'Ares Corp'],
  },
  {
    id: 5,
    name: 'Clark Kent',
    role: 'SMB AE',
    tier: 'Junior',
    region: 'Norte',
    revenue: '$150,000',
    revenueValue: 150000,
    quota: 110,
    winRate: 80,
    activeDeals: 22,
    status: 'on-fire',
    clients: ['Daily Planet', 'Smallville Farms', 'LuthorCorp'],
  },
  {
    id: 6,
    name: 'Natasha Romanoff',
    role: 'Strategic Accounts',
    tier: 'Enterprise',
    region: 'Sur',
    revenue: '$410,000',
    revenueValue: 410000,
    quota: 98,
    winRate: 70,
    activeDeals: 10,
    status: 'stable',
    clients: ['Red Room', 'KGB', 'S.H.I.E.L.D.'],
  }
];

// Colores de marca SNAKE DRAGON: Rojo Disrupción, Rojo Brillante, Slate Claro, Slate Oscuro
const COLORS = ['#E63946', '#FF2A2A', '#94A3B8', '#334155', '#10B981', '#F59E0B'];

export function Dragones() {
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [selectedRegion, setSelectedRegion] = useState<string>('Todas');
  const [selectedTier, setSelectedTier] = useState<string>('Todos');
  const [selectedStatus, setSelectedStatus] = useState<string>('Todos');
  
  // Dropdown states
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);
  
  // Selected Dragon for Modal
  const [selectedDragon, setSelectedDragon] = useState<Dragon | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  // Close dropdowns when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (!(event.target as Element).closest('.custom-dropdown')) {
        setOpenDropdown(null);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const filteredDragones = useMemo(() => {
    return initialDragones.filter(dragon => {
      const matchRegion = selectedRegion === 'Todas' || dragon.region === selectedRegion;
      const matchTier = selectedTier === 'Todos' || dragon.tier === selectedTier;
      const matchStatus = selectedStatus === 'Todos' || dragon.status === selectedStatus;
      return matchRegion && matchTier && matchStatus;
    });
  }, [selectedRegion, selectedTier, selectedStatus]);

  const stats = useMemo(() => {
    if (filteredDragones.length === 0) return { topDragon: 'N/A', avgQuota: 0, avgWinRate: 0 };
    
    const topDragon = filteredDragones.reduce((prev, current) => (prev.revenueValue > current.revenueValue) ? prev : current);
    const avgQuota = Math.round(filteredDragones.reduce((acc, curr) => acc + curr.quota, 0) / filteredDragones.length);
    const avgWinRate = Math.round(filteredDragones.reduce((acc, curr) => acc + curr.winRate, 0) / filteredDragones.length);
    
    return { topDragon: topDragon.name, avgQuota, avgWinRate };
  }, [filteredDragones]);

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-8 relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-8 right-8 bg-emerald-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50 animate-in fade-in slide-in-from-bottom-5">
          <Check className="w-5 h-5" />
          <span className="font-medium">{toastMessage}</span>
        </div>
      )}

      <header className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-4">
        <div>
          <h2 className="text-3xl font-display font-bold mb-2 flex items-center gap-3">
            <Swords className="w-8 h-8 text-[#E63946]" />
            Dragones
          </h2>
          <p className="text-slate-400">Fuerza de ventas: rendimiento, cuotas y cartera de clientes.</p>
        </div>
        <div className="flex gap-3">
          <button 
            onClick={() => showToast("Abriendo panel de ajuste de cuotas...")}
            className="px-4 py-2 bg-[#111928]/80 border border-white/10 hover:bg-white/5 text-slate-300 rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
          >
            <Target className="w-4 h-4" /> Ajustar Cuotas
          </button>
          <button 
            onClick={() => showToast("Iniciando proceso de reclutamiento de nuevo Dragón...")}
            className="px-4 py-2 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg text-sm font-medium transition-colors flex items-center gap-2 shadow-[0_0_15px_rgba(230,57,70,0.3)]"
          >
            <Flame className="w-4 h-4" /> Reclutar Dragón
          </button>
        </div>
      </header>

      {/* Filters */}
      <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-4 flex flex-wrap items-center gap-4 relative z-30">
        <div className="flex items-center gap-2 text-sm font-medium text-slate-400">
          <Filter className="w-4 h-4" /> Filtros:
        </div>
        
        <div className="relative custom-dropdown">
          <button 
            onClick={() => setOpenDropdown(openDropdown === 'region' ? null : 'region')}
            className="flex items-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg px-3 py-1.5 text-sm text-white transition-all"
          >
            <MapPin className="w-4 h-4 text-slate-500" />
            {selectedRegion === 'Todas' ? 'Todas las Regiones' : selectedRegion}
            <ChevronDown className="w-4 h-4 text-slate-500" />
          </button>
          {openDropdown === 'region' && (
            <div className="absolute top-full left-0 mt-2 w-48 bg-[#111928] border border-white/10 rounded-xl shadow-xl overflow-hidden z-20 animate-in fade-in zoom-in-95 duration-100">
              {['Todas', 'Norte', 'Centro', 'Sur'].map(option => (
                <button
                  key={option}
                  onClick={() => { setSelectedRegion(option); setOpenDropdown(null); }}
                  className={`w-full text-left px-4 py-2 text-sm transition-colors ${selectedRegion === option ? 'bg-[#E63946]/10 text-[#E63946]' : 'text-slate-300 hover:bg-white/5 hover:text-white'}`}
                >
                  {option === 'Todas' ? 'Todas las Regiones' : option}
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="relative custom-dropdown">
          <button 
            onClick={() => setOpenDropdown(openDropdown === 'tier' ? null : 'tier')}
            className="flex items-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg px-3 py-1.5 text-sm text-white transition-all"
          >
            <Award className="w-4 h-4 text-slate-500" />
            {selectedTier === 'Todos' ? 'Todos los Niveles' : selectedTier}
            <ChevronDown className="w-4 h-4 text-slate-500" />
          </button>
          {openDropdown === 'tier' && (
            <div className="absolute top-full left-0 mt-2 w-48 bg-[#111928] border border-white/10 rounded-xl shadow-xl overflow-hidden z-20 animate-in fade-in zoom-in-95 duration-100">
              {['Todos', 'Junior', 'Mid-Level', 'Senior', 'Enterprise'].map(option => (
                <button
                  key={option}
                  onClick={() => { setSelectedTier(option); setOpenDropdown(null); }}
                  className={`w-full text-left px-4 py-2 text-sm transition-colors ${selectedTier === option ? 'bg-[#E63946]/10 text-[#E63946]' : 'text-slate-300 hover:bg-white/5 hover:text-white'}`}
                >
                  {option === 'Todos' ? 'Todos los Niveles' : option}
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="relative custom-dropdown">
          <button 
            onClick={() => setOpenDropdown(openDropdown === 'status' ? null : 'status')}
            className="flex items-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg px-3 py-1.5 text-sm text-white transition-all"
          >
            <Activity className="w-4 h-4 text-slate-500" />
            {selectedStatus === 'Todos' ? 'Todos los Estados' : selectedStatus === 'on-fire' ? 'On Fire 🔥' : selectedStatus === 'stable' ? 'Estable' : 'En Riesgo'}
            <ChevronDown className="w-4 h-4 text-slate-500" />
          </button>
          {openDropdown === 'status' && (
            <div className="absolute top-full left-0 mt-2 w-48 bg-[#111928] border border-white/10 rounded-xl shadow-xl overflow-hidden z-20 animate-in fade-in zoom-in-95 duration-100">
              {[
                { val: 'Todos', label: 'Todos los Estados' },
                { val: 'on-fire', label: 'On Fire 🔥' },
                { val: 'stable', label: 'Estable' },
                { val: 'warning', label: 'En Riesgo' }
              ].map(option => (
                <button
                  key={option.val}
                  onClick={() => { setSelectedStatus(option.val); setOpenDropdown(null); }}
                  className={`w-full text-left px-4 py-2 text-sm transition-colors ${selectedStatus === option.val ? 'bg-[#E63946]/10 text-[#E63946]' : 'text-slate-300 hover:bg-white/5 hover:text-white'}`}
                >
                  {option.label}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Team KPIs */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6 flex items-center gap-5">
          <div className="w-14 h-14 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center">
            <Trophy className="w-7 h-7 text-emerald-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400 font-medium mb-1">Top Dragón (Filtro)</p>
            <h3 className="text-2xl font-display font-bold text-white">{stats.topDragon}</h3>
          </div>
        </div>
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6 flex items-center gap-5">
          <div className="w-14 h-14 rounded-full bg-blue-500/10 border border-blue-500/20 flex items-center justify-center">
            <Crosshair className="w-7 h-7 text-blue-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400 font-medium mb-1">Cuota Promedio Alcanzada</p>
            <div className="flex items-baseline gap-2">
              <h3 className="text-2xl font-display font-bold text-white">{stats.avgQuota}%</h3>
            </div>
          </div>
        </div>
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6 flex items-center gap-5">
          <div className="w-14 h-14 rounded-full bg-purple-500/10 border border-purple-500/20 flex items-center justify-center">
            <TrendingUp className="w-7 h-7 text-purple-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400 font-medium mb-1">Win Rate Promedio</p>
            <div className="flex items-baseline gap-2">
              <h3 className="text-2xl font-display font-bold text-white">{stats.avgWinRate}%</h3>
            </div>
          </div>
        </div>
      </div>

      {/* Dragones Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {filteredDragones.length === 0 ? (
          <div className="col-span-full bg-[#111928]/80 border border-white/10 rounded-2xl p-12 text-center">
            <p className="text-slate-400">No se encontraron Dragones con los filtros seleccionados.</p>
          </div>
        ) : (
          filteredDragones.map((dragon) => (
            <DragonCard key={dragon.id} dragon={dragon} onClick={() => setSelectedDragon(dragon)} />
          ))
        )}
      </div>

      {/* Revenue Chart */}
      {filteredDragones.length > 0 && (
        <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-6 mt-8">
          <h3 className="text-xl font-display font-bold mb-6">Revenue Generado por Dragón</h3>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={filteredDragones} margin={{ top: 10, right: 10, left: 10, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="name" stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `$${value/1000}k`} />
                <Tooltip 
                  cursor={{ fill: 'rgba(255,255,255,0.02)' }}
                  contentStyle={{ backgroundColor: '#0B132B', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '8px' }}
                  formatter={(value: number) => [`$${value.toLocaleString()}`, 'Revenue']}
                />
                <Bar dataKey="revenueValue" radius={[4, 4, 0, 0]} name="Revenue">
                  {filteredDragones.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Dragon Details Modal */}
      {selectedDragon && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#0B132B]/80 backdrop-blur-sm">
          <div className="bg-[#111928] border border-white/10 rounded-2xl w-full max-w-4xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200 max-h-[90vh] flex flex-col">
            <div className="flex justify-between items-start p-6 border-b border-white/10 bg-white/[0.02] shrink-0">
              <div className="flex items-center gap-4">
                <div className="relative">
                  <div className={`w-16 h-16 rounded-xl flex items-center justify-center text-2xl font-display font-bold ${
                    selectedDragon.status === 'on-fire' ? 'bg-gradient-to-br from-[#E63946] to-[#FF2A2A] text-white shadow-[0_0_15px_rgba(230,57,70,0.4)]' : 
                    'bg-white/10 text-slate-300'
                  }`}>
                    {selectedDragon.name.charAt(0)}
                  </div>
                  {selectedDragon.status === 'on-fire' && (
                    <div className="absolute -bottom-2 -right-2 bg-[#0B132B] rounded-full p-1.5">
                      <Flame className="w-5 h-5 text-[#E63946]" fill="currentColor" />
                    </div>
                  )}
                </div>
                <div>
                  <h3 className="text-2xl font-display font-bold text-white mb-1">{selectedDragon.name}</h3>
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-medium px-2.5 py-1 bg-white/5 border border-white/10 rounded-md text-slate-300">
                      {selectedDragon.role}
                    </span>
                    <span className="text-sm font-medium px-2.5 py-1 bg-white/5 border border-white/10 rounded-md text-slate-300 flex items-center gap-1">
                      <MapPin className="w-3.5 h-3.5" /> {selectedDragon.region}
                    </span>
                    <span className="text-sm font-medium px-2.5 py-1 bg-white/5 border border-white/10 rounded-md text-slate-300 flex items-center gap-1">
                      <Award className="w-3.5 h-3.5" /> {selectedDragon.tier}
                    </span>
                  </div>
                </div>
              </div>
              <button 
                onClick={() => setSelectedDragon(null)}
                className="p-2 text-slate-400 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto">
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <p className="text-sm text-slate-400 mb-1">Revenue Generado</p>
                  <p className="text-2xl font-mono font-bold text-emerald-400">{selectedDragon.revenue}</p>
                </div>
                <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <p className="text-sm text-slate-400 mb-1">Cumplimiento Cuota</p>
                  <p className={`text-2xl font-mono font-bold ${selectedDragon.quota >= 100 ? 'text-emerald-400' : selectedDragon.status === 'warning' ? 'text-[#E63946]' : 'text-amber-400'}`}>
                    {selectedDragon.quota}%
                  </p>
                </div>
                <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <p className="text-sm text-slate-400 mb-1">Win Rate</p>
                  <p className="text-2xl font-mono font-bold text-white">{selectedDragon.winRate}%</p>
                </div>
                <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <p className="text-sm text-slate-400 mb-1">Deals Activos</p>
                  <p className="text-2xl font-mono font-bold text-white">{selectedDragon.activeDeals}</p>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-6">
                  <div>
                    <h4 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
                      <TrendingUp className="w-5 h-5 text-purple-400" />
                      Rendimiento Histórico
                    </h4>
                    <div className="h-[200px] w-full bg-white/5 border border-white/10 rounded-xl p-4">
                      <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={[
                          { month: 'Ene', revenue: selectedDragon.revenueValue * 0.7 },
                          { month: 'Feb', revenue: selectedDragon.revenueValue * 0.85 },
                          { month: 'Mar', revenue: selectedDragon.revenueValue * 0.9 },
                          { month: 'Abr', revenue: selectedDragon.revenueValue * 1.1 },
                          { month: 'May', revenue: selectedDragon.revenueValue }
                        ]}>
                          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                          <XAxis dataKey="month" stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} />
                          <Tooltip 
                            contentStyle={{ backgroundColor: '#0B132B', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '8px' }}
                            formatter={(value: number) => [`$${value.toLocaleString()}`, 'Revenue']}
                          />
                          <Line type="monotone" dataKey="revenue" stroke="#E63946" strokeWidth={3} dot={{ fill: '#E63946', strokeWidth: 2, r: 4 }} />
                        </LineChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                </div>

                <div className="space-y-6">
                  <div>
                    <h4 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
                      <Users className="w-5 h-5 text-blue-400" />
                      Cartera de Clientes Principal
                    </h4>
                    <div className="bg-white/5 border border-white/10 rounded-xl p-4 space-y-3">
                      {selectedDragon.clients.map((client: string, idx: number) => (
                        <div key={idx} className="flex justify-between items-center p-3 bg-white/5 rounded-lg border border-white/5">
                          <span className="font-medium text-slate-200">{client}</span>
                          <span className="text-xs text-emerald-400 bg-emerald-400/10 px-2 py-1 rounded">Activo</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="p-4 border-t border-white/10 bg-white/[0.02] flex justify-end gap-3 shrink-0">
              <button 
                onClick={() => { showToast(`Enviando mensaje a ${selectedDragon.name}`); setSelectedDragon(null); }}
                className="px-4 py-2 bg-white/5 hover:bg-white/10 text-white rounded-lg text-sm font-medium transition-colors"
              >
                Enviar Mensaje
              </button>
              <button 
                onClick={() => { showToast(`Asignando nuevos leads a ${selectedDragon.name}`); setSelectedDragon(null); }}
                className="px-4 py-2 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg text-sm font-medium transition-colors shadow-[0_0_15px_rgba(230,57,70,0.3)]"
              >
                Asignar Leads
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const DragonCard: React.FC<{ dragon: Dragon, onClick: () => void }> = ({ dragon, onClick }) => {
  const isFire = dragon.status === 'on-fire';
  const isWarning = dragon.status === 'warning';

  return (
    <div 
      onClick={onClick}
      className={`bg-[#111928]/80 backdrop-blur-md border ${isFire ? 'border-[#E63946]/50 shadow-[0_0_30px_rgba(230,57,70,0.1)]' : 'border-white/10'} rounded-2xl p-6 relative overflow-hidden group hover:border-white/20 transition-all cursor-pointer`}
    >
      {isFire && (
        <div className="absolute top-0 right-0 w-32 h-32 bg-[#E63946]/10 blur-3xl rounded-full translate-x-1/2 -translate-y-1/2"></div>
      )}
      
      <div className="flex justify-between items-start mb-6 relative z-10">
        <div className="flex items-center gap-4">
          <div className="relative">
            <div className={`w-14 h-14 rounded-xl flex items-center justify-center text-xl font-display font-bold ${
              isFire ? 'bg-gradient-to-br from-[#E63946] to-[#FF2A2A] text-white shadow-[0_0_15px_rgba(230,57,70,0.4)]' : 
              'bg-white/10 text-slate-300'
            }`}>
              {dragon.name.charAt(0)}
            </div>
            {isFire && (
              <div className="absolute -bottom-2 -right-2 bg-[#0B132B] rounded-full p-1">
                <Flame className="w-4 h-4 text-[#E63946]" fill="currentColor" />
              </div>
            )}
          </div>
          <div>
            <h3 className="text-xl font-bold text-white flex items-center gap-2">
              {dragon.name}
            </h3>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-xs font-medium px-2 py-0.5 bg-white/5 border border-white/10 rounded text-slate-300">
                {dragon.role}
              </span>
              <span className="text-xs font-medium px-2 py-0.5 bg-white/5 border border-white/10 rounded text-slate-300 flex items-center gap-1">
                <MapPin className="w-3 h-3" /> {dragon.region}
              </span>
            </div>
          </div>
        </div>
        <div className="text-right">
          <p className="text-sm text-slate-400 mb-1">Revenue Generado</p>
          <p className="text-xl font-mono font-bold text-emerald-400">{dragon.revenue}</p>
        </div>
      </div>

      <div className="space-y-5 relative z-10">
        {/* Quota Progress */}
        <div>
          <div className="flex justify-between text-sm mb-2">
            <span className="text-slate-300 font-medium">Cumplimiento de Cuota</span>
            <span className={`font-bold font-mono ${dragon.quota >= 100 ? 'text-emerald-400' : isWarning ? 'text-[#E63946]' : 'text-amber-400'}`}>
              {dragon.quota}%
            </span>
          </div>
          <div className="w-full h-2 bg-white/5 rounded-full overflow-hidden">
            <div 
              className={`h-full rounded-full ${dragon.quota >= 100 ? 'bg-emerald-400' : isWarning ? 'bg-[#E63946]' : 'bg-amber-400'}`}
              style={{ width: `${Math.min(dragon.quota, 100)}%` }}
            ></div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 pt-2 border-t border-white/5">
          <div>
            <p className="text-xs text-slate-500 mb-1 flex items-center gap-1"><Target className="w-3 h-3" /> Win Rate</p>
            <p className="text-lg font-bold text-white">{dragon.winRate}%</p>
          </div>
          <div>
            <p className="text-xs text-slate-500 mb-1 flex items-center gap-1"><DollarSign className="w-3 h-3" /> Deals Activos</p>
            <p className="text-lg font-bold text-white">{dragon.activeDeals}</p>
          </div>
        </div>

        <div className="pt-4 border-t border-white/5">
          <p className="text-xs text-slate-500 mb-3 flex items-center gap-1"><Users className="w-3 h-3" /> Clientes Principales</p>
          <div className="flex flex-wrap gap-2">
            {dragon.clients.map((client: string, idx: number) => (
              <span key={idx} className="px-2.5 py-1 bg-white/[0.03] border border-white/10 rounded-md text-xs text-slate-300">
                {client}
              </span>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
