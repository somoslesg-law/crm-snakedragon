import React, { useState, useRef, useEffect, useMemo } from 'react';
import { Search, Filter, ShieldAlert, ShieldCheck, MoreVertical, Building2, Mail, Phone, Check, X, ArrowUpDown, ChevronDown, Download, Trash2, Send } from 'lucide-react';
import { Customer } from '../types';
import { api } from '../api';

const initialCustomers: Customer[] = [
  { id: 1, name: 'TechCorp Inc.', contact: 'Sarah Connor', email: 'sarah@techcorp.com', status: 'Active', health: 92, mrr: 12500, lastActive: 'Hace 2 horas' },
  { id: 2, name: 'Global Dynamics', contact: 'Elon T.', email: 'elon@globald.com', status: 'At Risk', health: 45, mrr: 45000, lastActive: 'Hace 14 días' },
  { id: 3, name: 'Stark Industries', contact: 'Tony S.', email: 'tony@stark.com', status: 'Active', health: 88, mrr: 28000, lastActive: 'Hace 5 horas' },
  { id: 4, name: 'Wayne Enterprises', contact: 'Bruce W.', email: 'bruce@wayne.com', status: 'Onboarding', health: 75, mrr: 8500, lastActive: 'Ayer' },
  { id: 5, name: 'Oscorp', contact: 'Norman O.', email: 'norman@oscorp.com', status: 'Churned', health: 12, mrr: 0, lastActive: 'Hace 2 meses' },
  { id: 6, name: 'Daily Planet', contact: 'Clark K.', email: 'clark@dailyplanet.com', status: 'Active', health: 95, mrr: 4200, lastActive: 'Hace 1 hora' },
];

export function CustomerHub() {
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [customers, setCustomers] = useState(initialCustomers);
  const [selectedCustomers, setSelectedCustomers] = useState<number[]>([]);
  const [sortConfig, setSortConfig] = useState<{ key: keyof Customer, direction: 'asc' | 'desc' } | null>(null);
  const [selectedCustomerDetails, setSelectedCustomerDetails] = useState<Customer | null>(null);
  const [activeDropdown, setActiveDropdown] = useState<number | null>(null);
  const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null);
  const [addingNoteToCustomer, setAddingNoteToCustomer] = useState<Customer | null>(null);
  const [newNote, setNewNote] = useState('');

  // Dynamic Filters
  const [activeFilters, setActiveFilters] = useState<{ id: string, label: string, value: string }[]>([]);
  const [showAddFilterMenu, setShowAddFilterMenu] = useState(false);
  const addFilterRef = useRef<HTMLDivElement>(null);

  const availableFilters = [
    { id: 'status', label: 'Estado', options: ['Active', 'At Risk', 'Onboarding', 'Churned'] },
    { id: 'health', label: 'Health Score', options: ['> 80 (Saludable)', '50-80 (Precaución)', '< 50 (Riesgo)'] },
    { id: 'mrr', label: 'MRR', options: ['> $10k', '$5k - $10k', '< $5k'] }
  ];

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (addFilterRef.current && !addFilterRef.current.contains(event.target as Node)) {
        setShowAddFilterMenu(false);
      }
      // Close dropdown if clicking outside
      if (!(event.target as Element).closest('.action-dropdown-container')) {
        setActiveDropdown(null);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      const data = await api.getCustomers();
      if (data && data.customers && data.customers.length > 0) {
        const formatted: Customer[] = data.customers.map((c: any) => ({
          id: c.cliente_id || Date.now() + Math.random(),
          name: c.razon_social || 'Desconocido',
          contact: c.contacto_principal || 'Sin contacto',
          email: c.email_principal || '',
          status: c.estado_cliente === 'activo' ? 'Active' : c.estado_cliente === 'riesgo' ? 'At Risk' : c.estado_cliente === 'inactivo' ? 'Churned' : 'Onboarding',
          health: c.salud_score || 50,
          mrr: Number(c.mrr_total) || 0,
          lastActive: c.ultima_actividad_dias ? `Hace ${Math.floor(c.ultima_actividad_dias)} días` : 'Reciente'
        }));
        setCustomers(formatted);
      }
    };
    fetchData();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

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

  const handleSort = (key: keyof Customer) => {
    let direction: 'asc' | 'desc' = 'asc';
    if (sortConfig && sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const toggleCustomerSelection = (id: number) => {
    if (selectedCustomers.includes(id)) {
      setSelectedCustomers(selectedCustomers.filter(customerId => customerId !== id));
    } else {
      setSelectedCustomers([...selectedCustomers, id]);
    }
  };

  const toggleAllSelection = () => {
    if (selectedCustomers.length === filteredCustomers.length && filteredCustomers.length > 0) {
      setSelectedCustomers([]);
    } else {
      setSelectedCustomers(filteredCustomers.map(c => c.id));
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(value);
  };

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingCustomer) return;
    setCustomers(customers.map(c => c.id === editingCustomer.id ? editingCustomer : c));
    setEditingCustomer(null);
    showToast(`Cliente ${editingCustomer.name} actualizado correctamente`);
  };

  const handleAddNoteSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newNote.trim() || !addingNoteToCustomer) return;

    // In a real app, this would save the note to the backend
    showToast(`Nota añadida a ${addingNoteToCustomer.name}`);
    setAddingNoteToCustomer(null);
    setNewNote('');
  };

  // Apply filters and search
  const filteredCustomers = useMemo(() => {
    let result = customers.filter(c =>
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.contact.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.email.toLowerCase().includes(searchQuery.toLowerCase())
    );

    activeFilters.forEach(filter => {
      if (filter.id === 'status') {
        result = result.filter(c => c.status === filter.value);
      } else if (filter.id === 'health') {
        if (filter.value.includes('> 80')) result = result.filter(c => c.health > 80);
        else if (filter.value.includes('< 50')) result = result.filter(c => c.health < 50);
        else result = result.filter(c => c.health >= 50 && c.health <= 80);
      } else if (filter.id === 'mrr') {
        if (filter.value.includes('> $10k')) result = result.filter(c => c.mrr > 10000);
        else if (filter.value.includes('< $5k')) result = result.filter(c => c.mrr < 5000);
        else result = result.filter(c => c.mrr >= 5000 && c.mrr <= 10000);
      }
    });

    // Apply sorting
    if (sortConfig !== null) {
      result.sort((a, b) => {
        if (a[sortConfig.key] < b[sortConfig.key]) {
          return sortConfig.direction === 'asc' ? -1 : 1;
        }
        if (a[sortConfig.key] > b[sortConfig.key]) {
          return sortConfig.direction === 'asc' ? 1 : -1;
        }
        return 0;
      });
    }

    return result;
  }, [customers, searchQuery, activeFilters, sortConfig]);

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6 relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-8 right-8 bg-emerald-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50 animate-in fade-in slide-in-from-bottom-5">
          <Check className="w-5 h-5" />
          <span className="font-medium">{toastMessage}</span>
        </div>
      )}

      <header className="flex justify-between items-end mb-4">
        <div>
          <h2 className="text-3xl font-display font-bold mb-2">Customer Hub</h2>
          <p className="text-slate-400">Gestión avanzada de cuentas y Health Scores.</p>
        </div>
      </header>

      {/* Toolbar */}
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="flex-1 relative">
          <Search className="w-5 h-5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Buscar por empresa, contacto o dominio..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[#111928]/80 border border-white/10 rounded-xl py-2.5 pl-10 pr-4 text-white placeholder:text-slate-500 focus:outline-none focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] transition-all"
          />
        </div>
        <button
          onClick={() => setShowFilters(!showFilters)}
          className={`px-4 py-2.5 border rounded-xl text-sm font-medium transition-colors flex items-center gap-2 ${showFilters ? 'bg-white/10 border-white/20 text-white' : 'bg-[#111928]/80 border-white/10 hover:bg-white/5 text-slate-300'}`}
        >
          <Filter className="w-4 h-4" /> Filtros Avanzados
        </button>
      </div>

      {/* Active Filters Bar */}
      {showFilters && (
        <div className="bg-[#111928]/60 border border-white/10 rounded-xl p-4 flex flex-wrap items-center gap-4 animate-in slide-in-from-top-2 fade-in mb-6">
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

      {/* Bulk Actions Bar */}
      {selectedCustomers.length > 0 && (
        <div className="bg-[#E63946]/10 border border-[#E63946]/30 rounded-xl p-3 flex items-center justify-between animate-in slide-in-from-bottom-2 fade-in mb-6">
          <span className="text-sm font-medium text-[#E63946] px-2">
            {selectedCustomers.length} cliente(s) seleccionado(s)
          </span>
          <div className="flex gap-2">
            <button
              onClick={() => showToast(`Enviando email masivo a ${selectedCustomers.length} clientes...`)}
              className="px-3 py-1.5 bg-white/5 hover:bg-white/10 text-white rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
            >
              <Send className="w-4 h-4" /> Email Masivo
            </button>
            <button
              onClick={() => showToast(`Exportando datos de ${selectedCustomers.length} clientes...`)}
              className="px-3 py-1.5 bg-white/5 hover:bg-white/10 text-white rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
            >
              <Download className="w-4 h-4" /> Exportar
            </button>
          </div>
        </div>
      )}

      {/* Data Table */}
      <div className="bg-[#111928]/80 backdrop-blur-md border border-white/10 rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead>
              <tr className="border-b border-white/10 bg-white/[0.02]">
                <th className="p-4 w-12">
                  <input
                    type="checkbox"
                    checked={selectedCustomers.length === filteredCustomers.length && filteredCustomers.length > 0}
                    onChange={toggleAllSelection}
                    className="w-4 h-4 rounded border-white/20 bg-transparent text-[#E63946] focus:ring-[#E63946] focus:ring-offset-0 cursor-pointer"
                  />
                </th>
                <th
                  className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider cursor-pointer hover:text-white transition-colors group"
                  onClick={() => handleSort('name')}
                >
                  <div className="flex items-center gap-1">Empresa / Contacto <ArrowUpDown className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                </th>
                <th
                  className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider cursor-pointer hover:text-white transition-colors group"
                  onClick={() => handleSort('status')}
                >
                  <div className="flex items-center gap-1">Estado <ArrowUpDown className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                </th>
                <th
                  className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider cursor-pointer hover:text-white transition-colors group"
                  onClick={() => handleSort('health')}
                >
                  <div className="flex items-center gap-1">Health Score <ArrowUpDown className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                </th>
                <th
                  className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider cursor-pointer hover:text-white transition-colors group"
                  onClick={() => handleSort('mrr')}
                >
                  <div className="flex items-center gap-1">MRR <ArrowUpDown className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                </th>
                <th
                  className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider cursor-pointer hover:text-white transition-colors group"
                  onClick={() => handleSort('lastActive')}
                >
                  <div className="flex items-center gap-1">Última Actividad <ArrowUpDown className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                </th>
                <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {filteredCustomers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-slate-500">
                    No se encontraron clientes que coincidan con tu búsqueda.
                  </td>
                </tr>
              ) : (
                filteredCustomers.map((customer) => (
                  <tr
                    key={customer.id}
                    className={`hover:bg-white/[0.04] transition-colors group cursor-pointer ${selectedCustomers.includes(customer.id) ? 'bg-white/[0.02]' : ''}`}
                    onClick={() => setSelectedCustomerDetails(customer)}
                  >
                    <td className="p-4" onClick={(e) => e.stopPropagation()}>
                      <input
                        type="checkbox"
                        checked={selectedCustomers.includes(customer.id)}
                        onChange={() => toggleCustomerSelection(customer.id)}
                        className="w-4 h-4 rounded border-white/20 bg-transparent text-[#E63946] focus:ring-[#E63946] focus:ring-offset-0 cursor-pointer"
                      />
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center shrink-0 group-hover:bg-white/10 transition-colors">
                          <Building2 className="w-5 h-5 text-slate-400 group-hover:text-white transition-colors" />
                        </div>
                        <div>
                          <h4 className="font-bold text-white group-hover:text-[#E63946] transition-colors">{customer.name}</h4>
                          <div className="flex items-center gap-2 text-xs text-slate-400 mt-0.5">
                            <span>{customer.contact}</span>
                            <span className="w-1 h-1 rounded-full bg-slate-600"></span>
                            <span
                              className="hover:text-white cursor-pointer transition-colors"
                              onClick={(e) => { e.stopPropagation(); showToast(`Copiando email: ${customer.email}`); }}
                            >
                              {customer.email}
                            </span>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="p-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-bold border ${customer.status === 'Active' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' :
                          customer.status === 'At Risk' ? 'bg-amber-500/10 text-amber-400 border-amber-500/20' :
                            customer.status === 'Churned' ? 'bg-[#E63946]/10 text-[#E63946] border-[#E63946]/20' :
                              'bg-blue-500/10 text-blue-400 border-blue-500/20'
                        }`}>
                        {customer.status}
                      </span>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-2">
                        {customer.health >= 80 ? (
                          <ShieldCheck className="w-4 h-4 text-emerald-400" />
                        ) : customer.health >= 50 ? (
                          <ShieldAlert className="w-4 h-4 text-amber-400" />
                        ) : (
                          <ShieldAlert className="w-4 h-4 text-[#E63946]" />
                        )}
                        <div className="w-24 h-2 bg-white/10 rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full ${customer.health >= 80 ? 'bg-emerald-400' :
                                customer.health >= 50 ? 'bg-amber-400' : 'bg-[#E63946]'
                              }`}
                            style={{ width: `${customer.health}%` }}
                          ></div>
                        </div>
                        <span className="text-xs font-mono font-bold">{customer.health}/100</span>
                      </div>
                    </td>
                    <td className="p-4 font-mono font-bold text-slate-300">{formatCurrency(customer.mrr)}</td>
                    <td className="p-4 text-sm text-slate-400">{customer.lastActive}</td>
                    <td className="p-4 text-right" onClick={(e) => e.stopPropagation()}>
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => showToast(`Enviando correo a ${customer.contact}...`)}
                          className="p-1.5 hover:bg-white/10 rounded-md text-slate-400 hover:text-white transition-colors"
                          title="Enviar Correo"
                        >
                          <Mail className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => showToast(`Iniciando llamada con ${customer.contact}...`)}
                          className="p-1.5 hover:bg-white/10 rounded-md text-slate-400 hover:text-white transition-colors"
                          title="Llamar"
                        >
                          <Phone className="w-4 h-4" />
                        </button>

                        <div className="relative action-dropdown-container">
                          <button
                            onClick={() => setActiveDropdown(activeDropdown === customer.id ? null : customer.id)}
                            className={`p-1.5 rounded-md transition-colors ${activeDropdown === customer.id ? 'bg-white/10 text-white' : 'text-slate-400 hover:bg-white/10 hover:text-[#E63946]'}`}
                            title="Más Opciones"
                          >
                            <MoreVertical className="w-4 h-4" />
                          </button>

                          {activeDropdown === customer.id && (
                            <div className="absolute right-0 mt-2 w-48 bg-[#111928] border border-white/10 rounded-xl shadow-xl overflow-hidden z-50 animate-in fade-in zoom-in-95 duration-100">
                              <div className="p-1">
                                <button
                                  onClick={() => { setEditingCustomer(customer); setActiveDropdown(null); }}
                                  className="w-full text-left px-3 py-2 text-sm text-slate-300 hover:bg-white/5 hover:text-white rounded-lg transition-colors"
                                >
                                  Editar Cliente
                                </button>
                                <button
                                  onClick={() => { setAddingNoteToCustomer(customer); setActiveDropdown(null); }}
                                  className="w-full text-left px-3 py-2 text-sm text-slate-300 hover:bg-white/5 hover:text-white rounded-lg transition-colors"
                                >
                                  Añadir Nota
                                </button>
                                <button
                                  onClick={() => { showToast(`Programando reunión con: ${customer.contact}`); setActiveDropdown(null); }}
                                  className="w-full text-left px-3 py-2 text-sm text-slate-300 hover:bg-white/5 hover:text-white rounded-lg transition-colors"
                                >
                                  Programar Reunión
                                </button>
                                <div className="h-px bg-white/10 my-1 mx-2"></div>
                                <button
                                  onClick={() => { showToast(`Eliminando cliente: ${customer.name}`); setActiveDropdown(null); }}
                                  className="w-full text-left px-3 py-2 text-sm text-[#E63946] hover:bg-[#E63946]/10 rounded-lg transition-colors flex items-center justify-between"
                                >
                                  Eliminar <Trash2 className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
      {/* Customer Details Modal */}
      {selectedCustomerDetails && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#0B132B]/80 backdrop-blur-sm">
          <div className="bg-[#111928] border border-white/10 rounded-2xl w-full max-w-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex justify-between items-start p-6 border-b border-white/10 bg-white/[0.02]">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 rounded-xl bg-white/5 flex items-center justify-center shrink-0">
                  <Building2 className="w-7 h-7 text-slate-400" />
                </div>
                <div>
                  <h3 className="text-2xl font-display font-bold text-white mb-1">{selectedCustomerDetails.name}</h3>
                  <div className="flex items-center gap-3">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-bold border ${selectedCustomerDetails.status === 'Active' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' :
                        selectedCustomerDetails.status === 'At Risk' ? 'bg-amber-500/10 text-amber-400 border-amber-500/20' :
                          selectedCustomerDetails.status === 'Churned' ? 'bg-[#E63946]/10 text-[#E63946] border-[#E63946]/20' :
                            'bg-blue-500/10 text-blue-400 border-blue-500/20'
                      }`}>
                      {selectedCustomerDetails.status}
                    </span>
                    <span className="text-sm text-slate-400">{selectedCustomerDetails.email}</span>
                  </div>
                </div>
              </div>
              <button
                onClick={() => setSelectedCustomerDetails(null)}
                className="text-slate-400 hover:text-white transition-colors p-2 hover:bg-white/5 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <p className="text-xs text-slate-400 mb-1">Contacto Principal</p>
                  <p className="text-lg font-bold text-white">{selectedCustomerDetails.contact}</p>
                </div>
                <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <p className="text-xs text-slate-400 mb-1">MRR Actual</p>
                  <p className="text-lg font-mono font-bold text-emerald-400">{formatCurrency(selectedCustomerDetails.mrr)}</p>
                </div>
              </div>

              <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                <div className="flex justify-between items-center mb-2">
                  <p className="text-sm font-bold text-white">Health Score</p>
                  <span className="text-sm font-mono font-bold">{selectedCustomerDetails.health}/100</span>
                </div>
                <div className="w-full h-3 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full ${selectedCustomerDetails.health >= 80 ? 'bg-emerald-400' :
                        selectedCustomerDetails.health >= 50 ? 'bg-amber-400' : 'bg-[#E63946]'
                      }`}
                    style={{ width: `${selectedCustomerDetails.health}%` }}
                  ></div>
                </div>
                <p className="text-xs text-slate-400 mt-3">Última actividad: {selectedCustomerDetails.lastActive}</p>
              </div>
            </div>

            <div className="p-4 border-t border-white/10 bg-white/[0.02] flex justify-end gap-3">
              <button
                onClick={() => { showToast(`Iniciando llamada con ${selectedCustomerDetails.contact}`); setSelectedCustomerDetails(null); }}
                className="px-4 py-2 bg-white/5 hover:bg-white/10 text-white rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
              >
                <Phone className="w-4 h-4" /> Llamar
              </button>
              <button
                onClick={() => { showToast(`Redactando email para ${selectedCustomerDetails.contact}`); setSelectedCustomerDetails(null); }}
                className="px-4 py-2 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg text-sm font-medium transition-colors shadow-[0_0_15px_rgba(230,57,70,0.3)] flex items-center gap-2"
              >
                <Mail className="w-4 h-4" /> Enviar Email
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Customer Modal */}
      {editingCustomer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#0B132B]/80 backdrop-blur-sm">
          <div className="bg-[#111928] border border-white/10 rounded-2xl w-full max-w-md shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center p-6 border-b border-white/10">
              <h3 className="text-xl font-display font-bold text-white">Editar Cliente</h3>
              <button
                onClick={() => setEditingCustomer(null)}
                className="text-slate-400 hover:text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleEditSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1.5">Empresa</label>
                <input
                  type="text"
                  required
                  value={editingCustomer.name}
                  onChange={e => setEditingCustomer({ ...editingCustomer, name: e.target.value })}
                  className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1.5">Contacto Principal</label>
                <input
                  type="text"
                  required
                  value={editingCustomer.contact}
                  onChange={e => setEditingCustomer({ ...editingCustomer, contact: e.target.value })}
                  className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1.5">Email</label>
                <input
                  type="email"
                  required
                  value={editingCustomer.email}
                  onChange={e => setEditingCustomer({ ...editingCustomer, email: e.target.value })}
                  className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-400 mb-1.5">Estado</label>
                  <select
                    value={editingCustomer.status}
                    onChange={e => setEditingCustomer({ ...editingCustomer, status: e.target.value })}
                    className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all appearance-none"
                  >
                    <option value="Active">Active</option>
                    <option value="At Risk">At Risk</option>
                    <option value="Onboarding">Onboarding</option>
                    <option value="Churned">Churned</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-400 mb-1.5">Health Score</label>
                  <input
                    type="number"
                    min="0" max="100"
                    required
                    value={editingCustomer.health}
                    onChange={e => setEditingCustomer({ ...editingCustomer, health: Number(e.target.value) })}
                    className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all font-mono"
                  />
                </div>
              </div>

              <div className="pt-4 flex gap-3">
                <button
                  type="button"
                  onClick={() => setEditingCustomer(null)}
                  className="flex-1 px-4 py-2.5 bg-white/5 hover:bg-white/10 text-white rounded-lg font-medium transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2.5 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg font-medium transition-colors shadow-[0_0_15px_rgba(230,57,70,0.3)]"
                >
                  Guardar Cambios
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Note Modal */}
      {addingNoteToCustomer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#0B132B]/80 backdrop-blur-sm">
          <div className="bg-[#111928] border border-white/10 rounded-2xl w-full max-w-md shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center p-6 border-b border-white/10">
              <h3 className="text-xl font-display font-bold text-white">Añadir Nota</h3>
              <button
                onClick={() => { setAddingNoteToCustomer(null); setNewNote(''); }}
                className="text-slate-400 hover:text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleAddNoteSubmit} className="p-6 space-y-4">
              <div>
                <p className="text-sm text-slate-400 mb-3">
                  Añadiendo nota para <span className="font-bold text-white">{addingNoteToCustomer.name}</span>
                </p>
                <textarea
                  required
                  value={newNote}
                  onChange={e => setNewNote(e.target.value)}
                  placeholder="Escribe los detalles de la interacción, acuerdos o próximos pasos..."
                  className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-3 text-white placeholder:text-slate-600 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all min-h-[120px] resize-y"
                />
              </div>

              <div className="pt-2 flex gap-3">
                <button
                  type="button"
                  onClick={() => { setAddingNoteToCustomer(null); setNewNote(''); }}
                  className="flex-1 px-4 py-2.5 bg-white/5 hover:bg-white/10 text-white rounded-lg font-medium transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={!newNote.trim()}
                  className="flex-1 px-4 py-2.5 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg font-medium transition-colors shadow-[0_0_15px_rgba(230,57,70,0.3)] disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none"
                >
                  Guardar Nota
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
