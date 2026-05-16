'use client';

import { useEffect, useState } from 'react';
import {
  collection,
  addDoc,
  onSnapshot,
  serverTimestamp,
  query,
  orderBy,
  limit,
  Timestamp,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth-context';
import { AdminLayout } from '@/components/admin-layout';
import { Send, Info } from 'lucide-react';

const TARGETS = [
  { value: 'all', label: 'Tous les utilisateurs' },
  { value: 'pharmacien', label: 'Pharmaciens' },
  { value: 'medecin', label: 'Médecins' },
  { value: 'kine', label: 'Kinésithérapeutes' },
  { value: 'commercial', label: 'Commerciaux' },
];

const TYPES = [
  { value: 'info', label: 'Information générale' },
  { value: 'formation', label: 'Nouvelle formation' },
  { value: 'challenge', label: 'Challenge' },
  { value: 'facture', label: 'Facture' },
];

interface HistoryItem {
  id: string;
  title: string;
  body: string;
  target: string;
  type: string;
  status: string;
  sentAt: Date | null;
}

export default function NotificationsPage() {
  const { user } = useAuth();
  const [target, setTarget] = useState('all');
  const [type, setType] = useState('info');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);
  const [success, setSuccess] = useState(false);
  const [history, setHistory] = useState<HistoryItem[]>([]);

  useEffect(() => {
    const q = query(collection(db, 'notification_queue'), orderBy('sentAt', 'desc'), limit(10));
    const unsub = onSnapshot(q, (snap) => {
      setHistory(
        snap.docs.map((d) => ({
          id: d.id,
          title: d.data().title ?? '',
          body: d.data().body ?? '',
          target: d.data().target ?? 'all',
          type: d.data().type ?? 'info',
          status: d.data().status ?? 'pending',
          sentAt: (d.data().sentAt as Timestamp)?.toDate() ?? null,
        }))
      );
    });
    return unsub;
  }, []);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) return;
    setSending(true);
    try {
      await addDoc(collection(db, 'notification_queue'), {
        title: title.trim(),
        body: body.trim(),
        target,
        type,
        sentBy: user?.uid ?? 'admin',
        sentAt: serverTimestamp(),
        status: 'pending',
      });
      setTitle('');
      setBody('');
      setTarget('all');
      setType('info');
      setSuccess(true);
      setTimeout(() => setSuccess(false), 4000);
    } finally {
      setSending(false);
    }
  };

  const formatDate = (d: Date | null) =>
    d
      ? d.toLocaleDateString('fr-FR', {
          day: '2-digit',
          month: '2-digit',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
        })
      : '—';

  const statusColor = (s: string) =>
    s === 'sent' ? 'text-emerald-600 bg-emerald-50' : s === 'error' ? 'text-red-600 bg-red-50' : 'text-amber-600 bg-amber-50';

  return (
    <AdminLayout>
      <div className="p-8 max-w-2xl">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-900">Notifications push</h1>
          <p className="text-gray-500 text-sm mt-1">Envoyer une notification à vos utilisateurs</p>
        </div>

        {/* Info banner */}
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 flex gap-3 mb-6">
          <Info size={18} className="text-amber-500 shrink-0 mt-0.5" />
          <p className="text-sm text-amber-700">
            Les notifications sont envoyées via une <strong>Cloud Function Firebase</strong>. Ce formulaire
            écrit dans <code className="bg-amber-100 px-1 rounded">notification_queue</code> — la fonction
            se charge de l&apos;envoi FCM réel.
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSend} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 space-y-5">
          {/* Destinataires */}
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">Destinataires</label>
            <div className="flex flex-wrap gap-2">
              {TARGETS.map(({ value, label }) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setTarget(value)}
                  className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                    target === value
                      ? 'bg-indigo-600 text-white'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* Type */}
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">Type</label>
            <div className="flex flex-wrap gap-2">
              {TYPES.map(({ value, label }) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setType(value)}
                  className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                    type === value
                      ? 'bg-indigo-600 text-white'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* Titre */}
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1">Titre *</label>
            <input
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Nouvelle formation disponible"
            />
          </div>

          {/* Message */}
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1">Message *</label>
            <textarea
              required
              rows={3}
              value={body}
              onChange={(e) => setBody(e.target.value)}
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
              placeholder="Contenu de la notification…"
            />
          </div>

          {success && (
            <div className="bg-emerald-50 border border-emerald-200 text-emerald-700 text-sm rounded-xl px-4 py-3">
              ✅ Notification mise en file d&apos;envoi
            </div>
          )}

          <button
            type="submit"
            disabled={sending}
            className="w-full inline-flex items-center justify-center gap-2 bg-[#1A1A2E] text-white rounded-xl py-3 text-sm font-semibold hover:bg-indigo-900 transition-colors disabled:opacity-60"
          >
            {sending ? (
              <span className="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <Send size={16} />
            )}
            Envoyer la notification
          </button>
        </form>

        {/* History */}
        {history.length > 0 && (
          <div className="mt-8">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">Historique récent</h2>
            <div className="space-y-2">
              {history.map((h) => (
                <div key={h.id} className="bg-white rounded-xl p-4 border border-gray-100 flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 truncate">{h.title}</p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      {h.target} · {h.type} · {formatDate(h.sentAt)}
                    </p>
                  </div>
                  <span className={`text-xs font-semibold px-2.5 py-1 rounded-full shrink-0 ${statusColor(h.status)}`}>
                    {h.status}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
