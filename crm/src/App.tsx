import React, { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { Dashboard } from './components/Dashboard';
import { Pipeline } from './components/Pipeline';
import { CustomerHub } from './components/CustomerHub';
import { EventStream } from './components/EventStream';
import { Analytics } from './components/Analytics';
import { Settings } from './components/Settings';
import { Dragones } from './components/Dragones';
import { Flame, LogOut, Loader2 } from 'lucide-react';
import { auth } from './api';

export default function App() {
  const [activeTab, setActiveTab] = useState('Copiloto IA');
  const [isLogoutModalOpen, setIsLogoutModalOpen] = useState(false);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [user, setUser] = useState<any>(null);
  const [isCheckingAuth, setIsCheckingAuth] = useState(true);

  // Check if user is already logged in on mount
  useEffect(() => {
    const checkAuth = async () => {
      if (auth.isLoggedIn()) {
        const data = await auth.me();
        if (data?.user) {
          setUser(data.user);
          setIsLoggedIn(true);
        }
      }
      setIsCheckingAuth(false);
    };
    checkAuth();
  }, []);

  const handleLogout = async () => {
    setIsLogoutModalOpen(false);
    await auth.logout();
    setUser(null);
    setIsLoggedIn(false);
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoggingIn(true);
    setLoginError('');

    try {
      const data = await auth.login(loginEmail, loginPassword);
      if (data?.user) {
        setUser(data.user);
        setIsLoggedIn(true);
      } else {
        setLoginError('Credenciales inválidas. Verifica tu email y contraseña.');
      }
    } catch (err: any) {
      setLoginError(err.message || 'Error al iniciar sesión. Intenta de nuevo.');
    } finally {
      setIsLoggingIn(false);
    }
  };

  // Loading screen while verifying session
  if (isCheckingAuth) {
    return (
      <div className="flex h-screen bg-[#0B132B] text-white items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#E63946] to-[#FF2A2A] flex items-center justify-center shadow-[0_0_40px_rgba(230,57,70,0.5)]">
            <Flame className="text-white w-8 h-8" />
          </div>
          <Loader2 className="w-6 h-6 animate-spin text-slate-400" />
        </div>
      </div>
    );
  }

  if (!isLoggedIn) {
    return (
      <div className="flex h-screen bg-[#0B132B] text-white items-center justify-center font-sans">
        <div className="text-center space-y-6 animate-in fade-in zoom-in duration-500 max-w-sm w-full p-8 border border-white/10 rounded-2xl bg-[#111928]/80 backdrop-blur-xl shadow-2xl">
          <div className="w-20 h-20 mx-auto rounded-2xl bg-gradient-to-br from-[#E63946] to-[#FF2A2A] flex items-center justify-center shadow-[0_0_40px_rgba(230,57,70,0.5)] mb-8">
            <Flame className="text-white w-10 h-10" />
          </div>
          <div>
            <h1 className="font-display font-bold text-3xl tracking-tight mb-2">SNAKE DRAGON</h1>
            <p className="text-slate-400">Acceso Seguro al CRM V3</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4 pt-4 text-left">
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1.5">Correo Electrónico</label>
              <input
                type="email"
                required
                value={loginEmail}
                onChange={e => { setLoginEmail(e.target.value); setLoginError(''); }}
                className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-3 text-white placeholder:text-slate-600 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
                placeholder="admin@snakedragon.com"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1.5">Contraseña</label>
              <input
                type="password"
                required
                value={loginPassword}
                onChange={e => { setLoginPassword(e.target.value); setLoginError(''); }}
                className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-3 text-white placeholder:text-slate-600 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
                placeholder="••••••••"
              />
            </div>

            {loginError && (
              <div className="text-[#E63946] text-sm bg-[#E63946]/10 border border-[#E63946]/20 rounded-lg px-4 py-3">
                {loginError}
              </div>
            )}

            <button
              type="submit"
              disabled={isLoggingIn}
              className="w-full mt-6 px-6 py-3 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-xl font-medium transition-colors shadow-[0_0_15px_rgba(230,57,70,0.3)] flex justify-center items-center disabled:opacity-50"
            >
              {isLoggingIn ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Iniciar Sesión'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-[#0B132B] text-white overflow-hidden font-sans selection:bg-[#E63946] selection:text-white relative">
      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onLogout={() => setIsLogoutModalOpen(true)}
        user={user}
      />
      <main className="flex-1 overflow-y-auto">
        {activeTab === 'Copiloto IA' && <Dashboard user={user} />}
        {activeTab === 'Pipeline Comercial' && <Pipeline />}
        {activeTab === 'Customer Hub' && <CustomerHub />}
        {activeTab === 'Event Stream' && <EventStream />}
        {activeTab === 'Analytics' && <Analytics />}
        {activeTab === 'Dragones' && <Dragones />}
        {activeTab === 'Configuración' && <Settings user={user} onProfileUpdate={setUser} />}
      </main>

      {/* Logout Modal */}
      {isLogoutModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#0B132B]/80 backdrop-blur-sm">
          <div className="bg-[#111928] border border-white/10 rounded-2xl w-full max-w-sm shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200 p-6 text-center">
            <div className="w-16 h-16 mx-auto bg-[#E63946]/10 rounded-full flex items-center justify-center mb-4">
              <LogOut className="w-8 h-8 text-[#E63946]" />
            </div>
            <h3 className="text-xl font-display font-bold mb-2">¿Cerrar Sesión?</h3>
            <p className="text-slate-400 text-sm mb-6">
              Estás a punto de salir del sistema, {user?.nombre?.split(' ')[0] || 'Comandante'}. ¿Deseas continuar?
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setIsLogoutModalOpen(false)}
                className="flex-1 px-4 py-2.5 bg-white/5 hover:bg-white/10 text-white rounded-lg font-medium transition-colors"
              >
                Cancelar
              </button>
              <button
                onClick={handleLogout}
                className="flex-1 px-4 py-2.5 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg font-medium transition-colors shadow-[0_0_15px_rgba(230,57,70,0.3)]"
              >
                Salir
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
