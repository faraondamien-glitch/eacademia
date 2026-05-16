'use client';

import { useEffect, useState } from 'react';
import {
  collection,
  onSnapshot,
  updateDoc,
  doc,
  query,
  orderBy,
  where,
  Query,
  CollectionReference,
  Timestamp,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { AdminLayout } from '@/components/admin-layout';
import { Check, X } from 'lucide-react';

type Status = 'all' | 'pending' | 'confirmed' | 'cancelled';

const STATUS_FILTERS: { value: Status; label: string }[] = [
  { value: 'all', label: 'Toutes' },
  { value: 'pending', label: 'En attente' },
  { value: 'confirmed', label: 'Confirmées' },
  { value: 'cancelled', label: 'Annulées' },
];

interface Commande {
  id: string;
  packTitle: string;
  userName: string;
  quantity: number;
  total: number;
  status: string;
  comment: string;
  createdAt: Date | null;
}

export default function CommandesPage() {
  const [commandes, setCommandes] = useState<Commande[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<Status>('all');

  useEffect(() => {
    let q: Query | CollectionReference = collection(db, 'commandes');
    q = query(q as CollectionReference, orderBy('createdAt', 'desc'));
    if (statusFilter !== 'all') {
      q = query(collection(db, 'commandes'), where('status', '==', statusFilter), orderBy('createdAt', 'desc'));
    }
    const unsub = onSnapshot(q, (snap) => {
      setCommandes(
        snap.docs.map((d) => ({
          id: d.id,
          packTitle: d.data().packTitle ?? 'Pack',
          userName: d.data().userName ?? 'Inconnu',
          quantity: d.data().quantity ?? 1,
          total: d.data().total ?? 0,
          status: d.data().status ?? 'pending',
          comment: d.data().comment ?? '',
          createdAt: (d.data().createdAt as Timestamp)?.toDate() ?? null,
        }))
      );
      setLoading(false);
    });
    return unsub;
  }, [statusFilter]);

  const updateStatus = async (id: string, status: string) => {
    await updateDoc(doc(db, 'commandes', id), { status });
  };

  const formatDate = (d: Date | null) =>
    d ? d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' }) : '—';

  const formatCurrency = (n: number) =>
    n.toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' });

  const statusBadge = (status: string) => {
    const map: Record<string, { label: string; class: string }> = {
      confirmed: { label: 'Confirmée', class: 'bg-emerald-50 text-emerald-700' },
      cancelled: { label: 'Annulée', class: 'bg-red-50 text-red-600' },
      pending: { label: 'En attente', class: 'bg-amber-50 text-amber-600' },
    };
    const s = map[status] ?? map.pending;
    return (
      <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${s.class}`}>{s.label}</span>
    );
  };

  return (
    <AdminLayout>
      <div className="p-8">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-900">Commandes packs</h1>
          <p className="text-gray-500 text-sm mt-1">{commandes.length} commande(s)</p>
        </div>

        {/* Filter */}
        <div className="flex gap-2 mb-6">
          {STATUS_FILTERS.map(({ value, label }) => (
            <button
              key={value}
              onClick={() => setStatusFilter(value)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors ${
                statusFilter === value
                  ? 'bg-indigo-600 text-white'
                  : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="bg-white rounded-2xl h-24 animate-pulse" />
            ))}
          </div>
        ) : commandes.length === 0 ? (
          <div className="bg-white rounded-2xl p-12 text-center text-gray-400 border border-dashed border-gray-200">
            Aucune commande
          </div>
        ) : (
          <div className="space-y-3">
            {commandes.map((c) => (
              <div
                key={c.id}
                className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100"
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-3 mb-2">
                      <p className="font-semibold text-gray-900 truncate">{c.packTitle}</p>
                      {statusBadge(c.status)}
                    </div>
                    <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-gray-500">
                      <span>👤 {c.userName}</span>
                      <span>📦 Qté : {c.quantity}</span>
                      <span className="font-semibold text-indigo-600">{formatCurrency(c.total)}</span>
                      <span className="text-gray-400">{formatDate(c.createdAt)}</span>
                    </div>
                    {c.comment && (
                      <p className="text-sm text-gray-400 italic mt-2 truncate">&quot;{c.comment}&quot;</p>
                    )}
                  </div>
                  {c.status === 'pending' && (
                    <div className="flex gap-2 shrink-0">
                      <button
                        onClick={() => updateStatus(c.id, 'cancelled')}
                        className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl border border-red-200 text-red-600 text-sm font-medium hover:bg-red-50 transition-colors"
                      >
                        <X size={14} />
                        Refuser
                      </button>
                      <button
                        onClick={() => updateStatus(c.id, 'confirmed')}
                        className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-emerald-600 text-white text-sm font-medium hover:bg-emerald-700 transition-colors"
                      >
                        <Check size={14} />
                        Confirmer
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
