import React, { useState } from 'react';
import { User, Lock, Bell, Link2, Shield, Key, Save, Upload, CheckCircle2 } from 'lucide-react';

export function Settings() {
  const [activeSection, setActiveSection] = useState('perfil');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  return (
    <div className="p-8 max-w-7xl mx-auto h-full flex flex-col relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-8 right-8 bg-emerald-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50 animate-in fade-in slide-in-from-bottom-5">
          <CheckCircle2 className="w-5 h-5" />
          <span className="font-medium">{toastMessage}</span>
        </div>
      )}

      <header className="mb-8 shrink-0">
        <h2 className="text-3xl font-display font-bold mb-2">Configuración del Sistema</h2>
        <p className="text-slate-400">Administra tus preferencias, seguridad y conexiones del CRM.</p>
      </header>

      <div className="flex flex-col md:flex-row gap-8 flex-1 min-h-0">
        {/* Settings Sidebar */}
        <div className="w-full md:w-64 shrink-0 space-y-2">
          <SettingsTab active={activeSection === 'perfil'} onClick={() => setActiveSection('perfil')} icon={User} label="Perfil de Usuario" />
          <SettingsTab active={activeSection === 'seguridad'} onClick={() => setActiveSection('seguridad')} icon={Lock} label="Seguridad y Acceso" />
          <SettingsTab active={activeSection === 'notificaciones'} onClick={() => setActiveSection('notificaciones')} icon={Bell} label="Notificaciones" />
          <SettingsTab active={activeSection === 'integraciones'} onClick={() => setActiveSection('integraciones')} icon={Link2} label="Integraciones API" />
        </div>

        {/* Settings Content */}
        <div className="flex-1 bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl p-8 overflow-y-auto">
          {activeSection === 'perfil' && <ProfileSettings showToast={showToast} />}
          {activeSection === 'seguridad' && <SecuritySettings showToast={showToast} />}
          {activeSection === 'notificaciones' && <NotificationSettings showToast={showToast} />}
          {activeSection === 'integraciones' && <IntegrationSettings showToast={showToast} />}
        </div>
      </div>
    </div>
  );
}

function SettingsTab({ active, onClick, icon: Icon, label }: any) {
  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 text-left ${
        active
          ? 'bg-white/10 text-white border border-white/10 shadow-sm'
          : 'text-slate-400 hover:text-white hover:bg-white/5 border border-transparent'
      }`}
    >
      <Icon className={`w-5 h-5 ${active ? 'text-[#E63946]' : ''}`} />
      <span className="font-medium text-sm">{label}</span>
    </button>
  );
}

function ProfileSettings({ showToast }: { showToast: (msg: string) => void }) {
  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      <div>
        <h3 className="text-xl font-display font-bold mb-1">Perfil de Usuario</h3>
        <p className="text-sm text-slate-400">Actualiza tu información personal y foto de perfil.</p>
      </div>

      <div className="flex items-center gap-6 pb-6 border-b border-white/10">
        <div className="w-24 h-24 rounded-full bg-gradient-to-br from-[#E63946] to-[#FF2A2A] flex items-center justify-center text-3xl font-display font-bold shadow-[0_0_20px_rgba(230,57,70,0.3)]">
          C
        </div>
        <div className="space-y-3">
          <div className="flex gap-3">
            <button 
              onClick={() => showToast("Abriendo selector de archivos...")}
              className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
            >
              <Upload className="w-4 h-4" /> Subir Nueva
            </button>
            <button 
              onClick={() => showToast("Foto de perfil eliminada.")}
              className="px-4 py-2 bg-transparent hover:bg-white/5 text-slate-400 rounded-lg text-sm font-medium transition-colors"
            >
              Eliminar
            </button>
          </div>
          <p className="text-xs text-slate-500">Recomendado: JPG, PNG o GIF cuadrado. Máximo 2MB.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <label className="text-sm font-medium text-slate-400">Nombre Completo</label>
          <input type="text" defaultValue="Comandante" className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all" />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-slate-400">Correo Electrónico</label>
          <input type="email" defaultValue="comandante@snakedragon.com" className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all" />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-slate-400">Rol en el Sistema</label>
          <input type="text" defaultValue="Administrador Global" disabled className="w-full bg-[#0B132B]/50 border border-white/5 rounded-lg px-4 py-2.5 text-slate-500 cursor-not-allowed" />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-slate-400">Zona Horaria</label>
          <select className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all appearance-none">
            <option>(UTC-05:00) Eastern Time (US & Canada)</option>
            <option>(UTC-08:00) Pacific Time (US & Canada)</option>
            <option>(UTC+01:00) Central European Time</option>
          </select>
        </div>
      </div>

      <div className="pt-4 flex justify-end">
        <button 
          onClick={() => showToast("Cambios guardados correctamente.")}
          className="px-6 py-2.5 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg font-medium transition-colors flex items-center gap-2 shadow-[0_0_15px_rgba(230,57,70,0.3)]"
        >
          <Save className="w-4 h-4" /> Guardar Cambios
        </button>
      </div>
    </div>
  );
}

function SecuritySettings({ showToast }: { showToast: (msg: string) => void }) {
  const [twoFactorEnabled, setTwoFactorEnabled] = useState(true);

  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      <div>
        <h3 className="text-xl font-display font-bold mb-1">Seguridad y Acceso</h3>
        <p className="text-sm text-slate-400">Gestiona tus contraseñas y claves de API.</p>
      </div>

      <div className="p-5 border border-white/10 rounded-xl bg-white/[0.02] flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className={`p-3 rounded-lg ${twoFactorEnabled ? 'bg-emerald-500/10' : 'bg-slate-500/10'}`}>
            <Shield className={`w-6 h-6 ${twoFactorEnabled ? 'text-emerald-400' : 'text-slate-400'}`} />
          </div>
          <div>
            <h4 className="font-bold text-white">Autenticación de Dos Factores (2FA)</h4>
            <p className="text-sm text-slate-400">Añade una capa extra de seguridad a tu cuenta.</p>
          </div>
        </div>
        <button 
          onClick={() => {
            setTwoFactorEnabled(!twoFactorEnabled);
            showToast(`Autenticación de Dos Factores ${!twoFactorEnabled ? 'activada' : 'desactivada'}.`);
          }}
          className={`px-4 py-2 rounded-lg text-sm font-bold transition-colors ${
            twoFactorEnabled 
              ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' 
              : 'bg-white/10 text-slate-300 border border-white/20 hover:bg-white/20'
          }`}
        >
          {twoFactorEnabled ? 'Activado' : 'Desactivado'}
        </button>
      </div>

      <div className="space-y-4">
        <h4 className="font-bold text-white flex items-center gap-2">
          <Key className="w-4 h-4 text-[#E63946]" /> Claves de API (Tokens)
        </h4>
        <div className="border border-white/10 rounded-xl overflow-hidden">
          <table className="w-full text-left">
            <thead className="bg-white/[0.02] border-b border-white/10">
              <tr>
                <th className="p-4 text-xs font-bold text-slate-400 uppercase">Nombre del Token</th>
                <th className="p-4 text-xs font-bold text-slate-400 uppercase">Último Uso</th>
                <th className="p-4 text-xs font-bold text-slate-400 uppercase text-right">Acción</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              <tr>
                <td className="p-4 font-mono text-sm text-slate-300">Producción_v3_Key</td>
                <td className="p-4 text-sm text-slate-400">Hace 2 horas</td>
                <td className="p-4 text-right">
                  <button 
                    onClick={() => showToast("Token revocado exitosamente.")}
                    className="text-xs text-[#E63946] hover:text-[#FF2A2A] font-bold"
                  >
                    Revocar
                  </button>
                </td>
              </tr>
              <tr>
                <td className="p-4 font-mono text-sm text-slate-300">Zapier_Integration</td>
                <td className="p-4 text-sm text-slate-400">Hace 5 días</td>
                <td className="p-4 text-right">
                  <button 
                    onClick={() => showToast("Token revocado exitosamente.")}
                    className="text-xs text-[#E63946] hover:text-[#FF2A2A] font-bold"
                  >
                    Revocar
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <button 
          onClick={() => showToast("Generando nuevo token...")}
          className="text-sm text-[#E63946] hover:text-[#FF2A2A] font-medium flex items-center gap-1 mt-2"
        >
          + Generar nuevo token
        </button>
      </div>
    </div>
  );
}

function NotificationSettings({ showToast }: { showToast: (msg: string) => void }) {
  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      <div>
        <h3 className="text-xl font-display font-bold mb-1">Notificaciones</h3>
        <p className="text-sm text-slate-400">Elige qué alertas deseas recibir del Copiloto IA.</p>
      </div>
      <div className="space-y-4">
        <ToggleItem title="Alertas de Churn (Riesgo Alto)" desc="Recibe un email inmediato cuando un cliente clave esté en riesgo." initialActive={true} onToggle={(state) => showToast(`Alertas de Churn ${state ? 'activadas' : 'desactivadas'}.`)} />
        <ToggleItem title="Resumen Diario de Pipeline" desc="Un reporte cada mañana con los deals que necesitan atención." initialActive={true} onToggle={(state) => showToast(`Resumen Diario ${state ? 'activado' : 'desactivado'}.`)} />
        <ToggleItem title="Nuevos Leads Calificados" desc="Notificación push cuando un lead supere el score de 80." initialActive={false} onToggle={(state) => showToast(`Notificaciones de Leads ${state ? 'activadas' : 'desactivadas'}.`)} />
        <ToggleItem title="Eventos de Event Stream" desc="Avisos en tiempo real sobre aperturas de propuestas." initialActive={true} onToggle={(state) => showToast(`Eventos en tiempo real ${state ? 'activados' : 'desactivados'}.`)} />
      </div>
    </div>
  );
}

function IntegrationSettings({ showToast }: { showToast: (msg: string) => void }) {
  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      <div>
        <h3 className="text-xl font-display font-bold mb-1">Integraciones API</h3>
        <p className="text-sm text-slate-400">Conecta SNAKE DRAGON con tu ecosistema actual.</p>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <IntegrationCard name="Slack" status="Conectado" color="text-emerald-400" bg="bg-emerald-400/10" border="border-emerald-400/20" onAction={() => showToast("Abriendo configuración de Slack...")} />
        <IntegrationCard name="Google Workspace" status="Conectado" color="text-emerald-400" bg="bg-emerald-400/10" border="border-emerald-400/20" onAction={() => showToast("Abriendo configuración de Google Workspace...")} />
        <IntegrationCard name="Stripe" status="Desconectado" color="text-slate-400" bg="bg-white/5" border="border-white/10" onAction={() => showToast("Iniciando conexión con Stripe...")} />
        <IntegrationCard name="HubSpot" status="Desconectado" color="text-slate-400" bg="bg-white/5" border="border-white/10" onAction={() => showToast("Iniciando conexión con HubSpot...")} />
      </div>
    </div>
  );
}

function ToggleItem({ title, desc, initialActive, onToggle }: any) {
  const [active, setActive] = useState(initialActive);

  const handleToggle = () => {
    const newState = !active;
    setActive(newState);
    if (onToggle) onToggle(newState);
  };

  return (
    <div className="flex items-center justify-between p-4 border border-white/10 rounded-xl bg-white/[0.02]">
      <div>
        <h4 className="font-bold text-white text-sm">{title}</h4>
        <p className="text-xs text-slate-400 mt-0.5">{desc}</p>
      </div>
      <div 
        onClick={handleToggle}
        className={`w-12 h-6 rounded-full p-1 transition-colors cursor-pointer ${active ? 'bg-[#E63946]' : 'bg-slate-700'}`}
      >
        <div className={`w-4 h-4 rounded-full bg-white transition-transform ${active ? 'translate-x-6' : 'translate-x-0'}`}></div>
      </div>
    </div>
  );
}

function IntegrationCard({ name, status, color, bg, border, onAction }: any) {
  return (
    <div className={`p-5 border ${border} rounded-xl bg-white/[0.02] flex items-center justify-between`}>
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center">
          <Link2 className="w-5 h-5 text-slate-300" />
        </div>
        <div>
          <h4 className="font-bold text-white">{name}</h4>
          <p className={`text-xs font-medium ${color}`}>{status}</p>
        </div>
      </div>
      <button 
        onClick={onAction}
        className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-colors ${status === 'Conectado' ? 'bg-white/5 text-slate-300 hover:bg-white/10' : 'bg-[#E63946]/20 text-[#FF2A2A] border border-[#E63946]/30 hover:bg-[#E63946]/30'}`}
      >
        {status === 'Conectado' ? 'Configurar' : 'Conectar'}
      </button>
    </div>
  );
}
