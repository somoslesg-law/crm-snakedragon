import React, { useState, useEffect } from 'react';
import { MoreHorizontal, Clock, DollarSign, Plus, AlertTriangle, X, Check, FileText, Activity, Mail, Phone, Calendar, ArrowRight } from 'lucide-react';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';
import { api } from '../api';

const columns = [
  { id: 'nuevo', title: 'Nuevo Lead', count: 12, value: '$145k', color: 'border-blue-500' },
  { id: 'calificado', title: 'Calificado', count: 8, value: '$320k', color: 'border-purple-500' },
  { id: 'propuesta', title: 'Propuesta Enviada', count: 5, value: '$850k', color: 'border-amber-500' },
  { id: 'negociacion', title: 'Negociación', count: 3, value: '$1.2M', color: 'border-[#E63946]' },
];

const initialCards = [
  { id: 1, col: 'nuevo', company: 'Wayne Enterprises', contact: 'Bruce W.', value: '$45,000', prob: 20, days: 2 },
  { id: 2, col: 'nuevo', company: 'Daily Planet', contact: 'Clark K.', value: '$12,000', prob: 15, days: 1 },
  { id: 3, col: 'calificado', company: 'Stark Industries', contact: 'Tony S.', value: '$150,000', prob: 45, days: 5 },
  { id: 4, col: 'calificado', company: 'Oscorp', contact: 'Norman O.', value: '$85,000', prob: 30, days: 12, alert: true },
  { id: 5, col: 'propuesta', company: 'TechCorp Inc.', contact: 'Sarah C.', value: '$450,000', prob: 82, days: 15 },
  { id: 6, col: 'negociacion', company: 'Global Dynamics', contact: 'Elon T.', value: '$800,000', prob: 95, days: 22 },
];

export function Pipeline() {
  const [cards, setCards] = useState(initialCards);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedDeal, setSelectedDeal] = useState<any>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    company: '',
    contact: '',
    value: '',
    prob: 20,
    col: 'nuevo'
  });

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  useEffect(() => {
    const fetchData = async () => {
      const data = await api.getPipeline();
      if (data && data.leads && data.leads.length > 0) {
        const formatted = data.leads.map((l: any) => ({
          id: l.id || Date.now() + Math.random(),
          col: l.etapa || 'nuevo',
          company: l.empresa_nombre || 'Desconocido',
          contact: l.contacto_nombre || 'Sin contacto',
          value: `$${Number(l.valor_estimado || 0).toLocaleString()}`,
          prob: l.probabilidad_cierre || 20,
          days: l.dias_en_etapa || 0,
          alert: false
        }));
        setCards(formatted);
      }
    };
    fetchData();
  }, []);

  const onDragEnd = (result: DropResult) => {
    const { source, destination, draggableId } = result;

    if (!destination) return;

    if (
      source.droppableId === destination.droppableId &&
      source.index === destination.index
    ) {
      return;
    }

    setCards(prevCards => {
      const newCards = [...prevCards];
      const cardIndex = newCards.findIndex(c => c.id.toString() === draggableId);
      const [movedCard] = newCards.splice(cardIndex, 1);

      movedCard.col = destination.droppableId;

      const destColCards = newCards.filter(c => c.col === destination.droppableId);

      if (destination.index >= destColCards.length) {
        newCards.push(movedCard);
      } else {
        const cardAtDestIndex = destColCards[destination.index];
        const absoluteInsertIndex = newCards.findIndex(c => c.id === cardAtDestIndex.id);
        newCards.splice(absoluteInsertIndex, 0, movedCard);
      }

      return newCards;
    });

    showToast(`Deal movido a ${columns.find(c => c.id === destination.droppableId)?.title}`);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const newCard = {
      id: Date.now(),
      company: formData.company,
      contact: formData.contact,
      value: formData.value.startsWith('$') ? formData.value : `$${formData.value}`,
      prob: Number(formData.prob),
      col: formData.col,
      days: 0,
      alert: false
    };
    setCards([...cards, newCard]);
    setIsModalOpen(false);
    setFormData({ company: '', contact: '', value: '', prob: 20, col: 'nuevo' });
    showToast("Nuevo deal creado exitosamente.");
  };

  const handleCardClick = (card: any) => {
    setSelectedDeal(card);
  };

  const closeDealModal = () => {
    setSelectedDeal(null);
  };

  return (
    <div className="p-8 h-full flex flex-col relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-8 right-8 bg-emerald-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50 animate-in fade-in slide-in-from-bottom-5">
          <Check className="w-5 h-5" />
          <span className="font-medium">{toastMessage}</span>
        </div>
      )}

      <header className="flex justify-between items-end mb-8 shrink-0">
        <div>
          <h2 className="text-3xl font-display font-bold mb-2">Pipeline Comercial</h2>
          <p className="text-slate-400">Arrastra y suelta para actualizar el estado de los deals.</p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="px-4 py-2 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg font-medium transition-colors flex items-center gap-2 shadow-[0_0_15px_rgba(230,57,70,0.3)]"
        >
          <Plus className="w-5 h-5" /> Nuevo Deal
        </button>
      </header>

      <DragDropContext onDragEnd={onDragEnd}>
        <div className="flex-1 overflow-x-auto pb-4">
          <div className="flex gap-6 h-full min-w-max">
            {columns.map(col => {
              const colCards = cards.filter(c => c.col === col.id);
              return (
                <div key={col.id} className="w-80 flex flex-col h-full">
                  {/* Column Header */}
                  <div className={`bg-[#111928]/80 backdrop-blur-md border border-white/10 border-t-2 ${col.color} rounded-t-xl p-4 shrink-0`}>
                    <div className="flex justify-between items-center mb-2">
                      <h3 className="font-display font-bold text-lg">{col.title}</h3>
                      <span className="bg-white/10 text-slate-300 text-xs font-bold px-2 py-1 rounded-md">{colCards.length}</span>
                    </div>
                    <p className="text-sm text-slate-400 font-mono">{col.value}</p>
                  </div>

                  {/* Column Body */}
                  <Droppable droppableId={col.id}>
                    {(provided, snapshot) => (
                      <div
                        ref={provided.innerRef}
                        {...provided.droppableProps}
                        className={`bg-[#111928]/40 border border-white/5 border-t-0 rounded-b-xl p-3 flex-1 overflow-y-auto transition-colors ${snapshot.isDraggingOver ? 'bg-white/[0.05]' : ''}`}
                      >
                        {colCards.map((card, index) => (
                          // @ts-ignore
                          <Draggable key={card.id} draggableId={card.id.toString()} index={index}>
                            {(provided, snapshot) => (
                              <KanbanCard
                                card={card}
                                innerRef={provided.innerRef}
                                provided={provided}
                                isDragging={snapshot.isDragging}
                                showToast={showToast}
                                onClick={() => handleCardClick(card)}
                              />
                            )}
                          </Draggable>
                        ))}
                        {provided.placeholder}
                      </div>
                    )}
                  </Droppable>
                </div>
              );
            })}
          </div>
        </div>
      </DragDropContext>

      {/* Modal Nuevo Deal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#0B132B]/80 backdrop-blur-sm">
          <div className="bg-[#111928] border border-white/10 rounded-2xl w-full max-w-md shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center p-6 border-b border-white/10">
              <h3 className="text-xl font-display font-bold flex items-center gap-2">
                <Plus className="w-5 h-5 text-[#E63946]" />
                Agregar Nuevo Deal
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1.5">Empresa</label>
                <input
                  type="text"
                  required
                  value={formData.company}
                  onChange={e => setFormData({ ...formData, company: e.target.value })}
                  className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder:text-slate-600 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
                  placeholder="Ej. LexCorp"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1.5">Contacto Principal</label>
                <input
                  type="text"
                  required
                  value={formData.contact}
                  onChange={e => setFormData({ ...formData, contact: e.target.value })}
                  className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder:text-slate-600 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
                  placeholder="Ej. Lex Luthor"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-400 mb-1.5">Valor (MRR/ARR)</label>
                  <div className="relative">
                    <DollarSign className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                    <input
                      type="text"
                      required
                      value={formData.value}
                      onChange={e => setFormData({ ...formData, value: e.target.value })}
                      className="w-full bg-[#0B132B] border border-white/10 rounded-lg pl-9 pr-4 py-2.5 text-white placeholder:text-slate-600 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all font-mono"
                      placeholder="50,000"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-400 mb-1.5">Probabilidad (%)</label>
                  <input
                    type="number"
                    min="0" max="100"
                    required
                    value={formData.prob}
                    onChange={e => setFormData({ ...formData, prob: Number(e.target.value) })}
                    className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder:text-slate-600 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all font-mono"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1.5">Etapa Inicial</label>
                <select
                  value={formData.col}
                  onChange={e => setFormData({ ...formData, col: e.target.value })}
                  className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all appearance-none"
                >
                  <option value="nuevo">Nuevo Lead</option>
                  <option value="calificado">Calificado</option>
                  <option value="propuesta">Propuesta Enviada</option>
                  <option value="negociacion">Negociación</option>
                </select>
              </div>

              <div className="pt-4 flex gap-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 px-4 py-2.5 bg-white/5 hover:bg-white/10 text-white rounded-lg font-medium transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2.5 bg-[#E63946] hover:bg-[#FF2A2A] text-white rounded-lg font-medium transition-colors shadow-[0_0_15px_rgba(230,57,70,0.3)]"
                >
                  Crear Deal
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Detalles del Deal */}
      {selectedDeal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#0B132B]/80 backdrop-blur-sm">
          <div className="bg-[#111928] border border-white/10 rounded-2xl w-full max-w-3xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200 max-h-[90vh] flex flex-col">
            {/* Header */}
            <div className="flex justify-between items-start p-6 border-b border-white/10 bg-white/[0.02]">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <h3 className="text-2xl font-display font-bold text-white">{selectedDeal.company}</h3>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${selectedDeal.prob >= 80 ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : selectedDeal.prob >= 40 ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20' : 'bg-[#E63946]/10 text-[#E63946] border border-[#E63946]/20'}`}>
                    {selectedDeal.prob}% Probabilidad
                  </span>
                </div>
                <p className="text-slate-400 flex items-center gap-2">
                  Contacto: <span className="text-white font-medium">{selectedDeal.contact}</span>
                </p>
              </div>
              <button
                onClick={closeDealModal}
                className="text-slate-400 hover:text-white transition-colors p-2 hover:bg-white/5 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 flex flex-col md:flex-row gap-8">
              {/* Left Column: Details & Notes */}
              <div className="flex-1 space-y-8">
                {/* Key Metrics */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                    <p className="text-xs text-slate-400 mb-1 flex items-center gap-1.5"><DollarSign className="w-3.5 h-3.5" /> Valor del Deal</p>
                    <p className="text-2xl font-mono font-bold text-emerald-400">{selectedDeal.value}</p>
                  </div>
                  <div className="bg-white/5 border border-white/10 rounded-xl p-4">
                    <p className="text-xs text-slate-400 mb-1 flex items-center gap-1.5"><Clock className="w-3.5 h-3.5" /> Tiempo en Pipeline</p>
                    <p className="text-2xl font-mono font-bold text-white">{selectedDeal.days} <span className="text-sm text-slate-500 font-normal">días</span></p>
                  </div>
                </div>

                {/* Notes Section */}
                <div>
                  <h4 className="text-sm font-bold text-white mb-3 flex items-center gap-2">
                    <FileText className="w-4 h-4 text-slate-400" /> Notas Recientes
                  </h4>
                  <div className="space-y-3">
                    <div className="bg-white/[0.02] border border-white/5 rounded-xl p-4">
                      <p className="text-sm text-slate-300 leading-relaxed">
                        El cliente mostró mucho interés en la integración con su ERP actual. Necesitamos preparar una demo técnica para la próxima semana enfocada en la API.
                      </p>
                      <p className="text-xs text-slate-500 mt-2">Añadido hace 2 días por ti</p>
                    </div>
                    <div className="relative">
                      <input
                        type="text"
                        placeholder="Añadir una nueva nota..."
                        className="w-full bg-[#0B132B] border border-white/10 rounded-lg px-4 py-3 text-sm text-white placeholder:text-slate-600 focus:border-[#E63946] focus:ring-1 focus:ring-[#E63946] outline-none transition-all"
                      />
                      <button className="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 text-[#E63946] hover:bg-[#E63946]/10 rounded-md transition-colors">
                        <ArrowRight className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Column: Activity History */}
              <div className="w-full md:w-72 shrink-0">
                <h4 className="text-sm font-bold text-white mb-4 flex items-center gap-2">
                  <Activity className="w-4 h-4 text-slate-400" /> Historial de Actividad
                </h4>

                <div className="space-y-6 relative before:absolute before:inset-0 before:ml-2 before:-translate-x-px before:h-full before:w-0.5 before:bg-white/10">
                  <div className="relative flex items-start gap-3">
                    <div className="absolute left-0 w-4 h-4 rounded-full border-2 border-[#111928] bg-emerald-400 mt-0.5 z-10"></div>
                    <div className="ml-6">
                      <p className="text-sm font-medium text-white">Propuesta Enviada</p>
                      <p className="text-xs text-slate-400 mt-0.5">Ayer, 14:30</p>
                    </div>
                  </div>

                  <div className="relative flex items-start gap-3">
                    <div className="absolute left-0 w-4 h-4 rounded-full border-2 border-[#111928] bg-blue-400 mt-0.5 z-10 flex items-center justify-center">
                      <Mail className="w-2 h-2 text-[#111928]" />
                    </div>
                    <div className="ml-6">
                      <p className="text-sm font-medium text-white">Email: Follow-up técnico</p>
                      <p className="text-xs text-slate-400 mt-0.5">Hace 3 días</p>
                    </div>
                  </div>

                  <div className="relative flex items-start gap-3">
                    <div className="absolute left-0 w-4 h-4 rounded-full border-2 border-[#111928] bg-purple-400 mt-0.5 z-10 flex items-center justify-center">
                      <Phone className="w-2 h-2 text-[#111928]" />
                    </div>
                    <div className="ml-6">
                      <p className="text-sm font-medium text-white">Llamada de descubrimiento</p>
                      <p className="text-xs text-slate-400 mt-0.5">Hace 5 días</p>
                    </div>
                  </div>

                  <div className="relative flex items-start gap-3">
                    <div className="absolute left-0 w-4 h-4 rounded-full border-2 border-[#111928] bg-slate-500 mt-0.5 z-10"></div>
                    <div className="ml-6">
                      <p className="text-sm font-medium text-white">Deal Creado</p>
                      <p className="text-xs text-slate-400 mt-0.5">Hace 12 días</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Footer Actions */}
            <div className="p-4 border-t border-white/10 bg-white/[0.02] flex justify-end gap-3">
              <button
                onClick={() => { showToast("Agendando reunión..."); closeDealModal(); }}
                className="px-4 py-2 bg-white/5 hover:bg-white/10 text-white rounded-lg text-sm font-medium transition-colors flex items-center gap-2"
              >
                <Calendar className="w-4 h-4" /> Agendar Reunión
              </button>
              <button
                onClick={() => { showToast("Deal marcado como Ganado!"); closeDealModal(); }}
                className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg text-sm font-medium transition-colors shadow-[0_0_15px_rgba(16,185,129,0.3)]"
              >
                Marcar como Ganado
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function KanbanCard({ card, innerRef, provided, isDragging, showToast, onClick }: any) {
  const { company, contact, value, prob, days, alert } = card;
  return (
    <div
      ref={innerRef}
      {...provided.draggableProps}
      {...provided.dragHandleProps}
      style={{ ...provided.draggableProps.style }}
      onClick={onClick}
      className={`bg-[#111928] border ${isDragging ? 'border-[#E63946] shadow-[0_0_20px_rgba(230,57,70,0.3)]' : 'border-white/10 hover:border-white/20'} rounded-xl p-4 cursor-grab active:cursor-grabbing transition-colors group relative overflow-hidden mb-3`}
    >
      {alert && <div className="absolute top-0 right-0 w-16 h-16 bg-[#E63946]/10 blur-xl rounded-full translate-x-1/2 -translate-y-1/2"></div>}

      <div className="flex justify-between items-start mb-3 relative z-10">
        <div>
          <h4 className="font-bold text-sm text-white mb-0.5">{company}</h4>
          <p className="text-xs text-slate-400">{contact}</p>
        </div>
        <button
          onClick={(e) => { e.stopPropagation(); showToast(`Abriendo opciones para ${company}...`); }}
          className="text-slate-500 hover:text-white transition-colors opacity-0 group-hover:opacity-100"
        >
          <MoreHorizontal className="w-4 h-4" />
        </button>
      </div>

      <div className="flex items-center gap-2 mb-4 relative z-10">
        <span className="text-sm font-mono font-bold text-emerald-400 flex items-center">
          <DollarSign className="w-3.5 h-3.5 mr-0.5" />
          {value.replace('$', '')}
        </span>
      </div>

      <div className="flex items-center justify-between text-xs relative z-10">
        <div className="flex items-center gap-1.5 text-slate-400">
          <Clock className="w-3.5 h-3.5" />
          <span>{days} días</span>
          {alert && <AlertTriangle className="w-3.5 h-3.5 text-amber-500 ml-1" />}
        </div>
        <div className="flex items-center gap-2">
          <span className="text-slate-500">Cierre:</span>
          <span className={`font-bold ${prob >= 80 ? 'text-emerald-400' : prob >= 40 ? 'text-amber-400' : 'text-[#E63946]'}`}>
            {prob}%
          </span>
        </div>
      </div>
    </div>
  );
}
