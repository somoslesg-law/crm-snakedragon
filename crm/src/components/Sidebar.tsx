import React from 'react';
import { Flame, LayoutDashboard, Trello, Users, Activity, BarChart3, Settings, LogOut, Swords } from 'lucide-react';

const navItems = [
  { name: 'Copiloto IA', icon: LayoutDashboard },
  { name: 'Pipeline Comercial', icon: Trello },
  { name: 'Customer Hub', icon: Users },
  { name: 'Event Stream', icon: Activity },
  { name: 'Analytics', icon: BarChart3 },
  { name: 'Dragones', icon: Swords },
];

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  onLogout: () => void;
  user?: { nombre?: string; email?: string; rol?: string } | null;
}

export function Sidebar({ activeTab, setActiveTab, onLogout, user }: SidebarProps) {
  return (
    <aside className="w-64 border-r border-white/10 bg-[#0B132B]/50 backdrop-blur-xl flex flex-col">
      <div className="p-6 flex items-center gap-3">
        <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[#E63946] to-[#FF2A2A] flex items-center justify-center shadow-[0_0_20px_rgba(230,57,70,0.4)]">
          <Flame className="text-white w-6 h-6" />
        </div>
        <div>
          <h1 className="font-display font-bold text-lg tracking-tight leading-none">SNAKE DRAGON</h1>
          <span className="text-[10px] uppercase tracking-widest text-[#E63946] font-semibold">CRM v3</span>
        </div>
      </div>

      <nav className="flex-1 px-4 py-6 space-y-2">
        {navItems.map((item) => (
          <button
            key={item.name}
            onClick={() => setActiveTab(item.name)}
            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
              activeTab === item.name
                ? 'bg-gradient-to-r from-[#E63946]/20 to-transparent text-[#FF2A2A] border border-[#E63946]/30'
                : 'text-slate-400 hover:text-white hover:bg-white/5'
            }`}
          >
            <item.icon className={`w-5 h-5 ${activeTab === item.name ? 'text-[#FF2A2A]' : ''}`} />
            <span className="font-medium text-sm">{item.name}</span>
          </button>
        ))}
      </nav>

      <div className="p-4 border-t border-white/10 space-y-2">
        {user && (
          <div className="px-4 py-2 mb-1 rounded-lg bg-white/5">
            <p className="text-sm font-medium text-white truncate">{user.nombre}</p>
            <p className="text-xs text-slate-400 truncate">{user.email}</p>
          </div>
        )}
        <button
          onClick={() => setActiveTab('Configuración')}
          className={`w-full flex items-center gap-3 px-4 py-2 rounded-lg transition-colors ${
            activeTab === 'Configuración'
              ? 'bg-gradient-to-r from-[#E63946]/20 to-transparent text-[#FF2A2A] border border-[#E63946]/30'
              : 'text-slate-400 hover:text-white hover:bg-white/5'
          }`}
        >
          <Settings className={`w-5 h-5 ${activeTab === 'Configuración' ? 'text-[#FF2A2A]' : ''}`} />
          <span className="font-medium text-sm">Configuración</span>
        </button>
        <button
          onClick={onLogout}
          className="w-full flex items-center gap-3 px-4 py-2 rounded-lg text-slate-400 hover:text-[#E63946] hover:bg-[#E63946]/10 transition-colors"
        >
          <LogOut className="w-5 h-5" />
          <span className="font-medium text-sm">Cerrar Sesión</span>
        </button>
      </div>
    </aside>
  );
}
