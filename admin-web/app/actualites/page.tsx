'use client';

import { useEffect, useState } from 'react';
import {
  collection,
  onSnapshot,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  serverTimestamp,
  orderBy,
  query,
  Timestamp,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth-context';
import { AdminLayout } from '@/components/admin-layout';
import { Plus, Pencil, Trash2, Pin, PinOff, X } from 'lucide-react';

const CATEGORIES = ['info', 'produit', 'evenement', 'commercial', 'sante'] as const;
const CAT_LABELS: Record<string, string> = {
  info: 'Information',
  produit: 'Produit',
  evenement: 'Événement',
  commercial: 'Commercial',
  sante: 'Santé',
};
const ROLES = ['pharmacien', 'medecin', 'kine', 'commercial'];
const ROLE_LABELS: Record<string, string> = {
  pharmacien: 'Pharmacien',
  medecin: 'Médecin',
  kine: 'Kinésithérapeute',
  commercial: 'Commercial',
};

interface Actu {
  id: string;
  title: string;
  body: string;
  category: string;
  imageUrl: string;
  author: string;
  publishedAt: Date;
  targetRoles: string[];
  isPinned: boolean;
}

const emptyForm = {
  title: '',
  body: '',
  category: 'info',
  imageUrl: '',
  author: 'Granions',
  targetRoles: [] as string[],
  isPinned: false,
};

export default function ActualitesPage() {
  const { user } = useAuth();
  const [actus, setActus] = useState<Actu[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Actu | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const q = query(collection(db, 'actualites'), orderBy('publishedAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setActus(
        snap.docs.map((d) => {
          const data = d.data();
          return {
            id: d.id,
            title: data.title ?? '',
            body: data.body ?? '',
            category: data.category ?? 'info',
            imageUrl: data.imageUrl ?? '',
            author: data.author ?? '',
            publishedAt: (data.publishedAt as Timestamp)?.toDate() ?? new Date(),
            targetRoles: data.targetRoles ?? [],
            isPinned: data.isPinned ?? false,
          };
        })
      );
      setLoading(false);
    });
    return unsub;
  }, []);

  const openCreate = () => {
    setEditing(null);
    setForm({ ...emptyForm, author: user?.displayName ?? 'Granions' });
    setShowForm(true);
  };

  const openEdit = (a: Actu) => {
    setEditing(a);
    setForm({
      title: a.title,
      body: a.body,
      category: a.category,
      imageUrl: a.imageUrl,
      author: a.author,
      targetRoles: a.targetRoles,
      isPinned: a.isPinned,
    });
    setShowForm(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim() || !form.body.trim()) return;
    setSaving(true);
    try {
      const payload = {
        title: form.title.trim(),
        body: form.body.trim(),
        category: form.category,
        imageUrl: form.imageUrl.trim() || null,
        author: form.author.trim() || 'Granions',
        targetRoles: form.targetRoles,
        isPinned: form.isPinned,
      };
      if (editing) {
        await updateDoc(doc(db, 'actualites', editing.id), payload);
      } else {
        await addDoc(collection(db, 'actualites'), {
          ...payload,
          publishedAt: serverTimestamp(),
        });
      }
      setShowForm(false);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Supprimer cette actualité ?')) return;
    await deleteDoc(doc(db, 'actualites', id));
  };

  const togglePin = async (actu: Actu) => {
    await updateDoc(doc(db, 'actualites', actu.id), { isPinned: !actu.isPinned });
  };

  const toggleRole = (role: string) => {
    setForm((f) => ({
      ...f,
      targetRoles: f.targetRoles.includes(role)
        ? f.targetRoles.filter((r) => r !== role)
        : [...f.targetRoles, role],
    }));
  };

  const formatDate = (d: Date) =>
    d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });

  return (
    <AdminLayout>
      <div className="p-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Actualités</h1>
            <p className="text-gray-500 text-sm mt-1">{actus.length} article(s) publié(s)</p>
          </div>
          <button
            onClick={openCreate}
            className="inline-flex items-center gap-2 bg-indigo-600 text-white px-4 py-2.5 rounded-xl text-sm font-semibold hover:bg-indigo-700 transition-colors"
          >
            <Plus size={16} />
            Publier
          </button>
        </div>

        {/* List */}
        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="bg-white rounded-2xl h-20 animate-pulse" />
            ))}
          </div>
        ) : actus.length === 0 ? (
          <div className="bg-white rounded-2xl p-12 text-center text-gray-400 border border-dashed border-gray-200">
            Aucune actualité. Cliquez sur &quot;Publier&quot; pour créer la première.
          </div>
        ) : (
          <div className="space-y-3">
            {actus.map((a) => (
              <div
                key={a.id}
                className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 flex items-start gap-4"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    {a.isPinned && <Pin size={13} className="text-indigo-500 shrink-0" />}
                    <span className="text-xs font-medium bg-indigo-50 text-indigo-600 px-2 py-0.5 rounded-full">
                      {CAT_LABELS[a.category] ?? a.category}
                    </span>
                    {a.targetRoles.length > 0 && (
                      <span className="text-xs text-gray-400">
                        ({a.targetRoles.map((r) => ROLE_LABELS[r] ?? r).join(', ')})
                      </span>
                    )}
                  </div>
                  <p className="font-semibold text-gray-900 truncate">{a.title}</p>
                  <p className="text-sm text-gray-500 truncate">{a.body}</p>
                  <p className="text-xs text-gray-400 mt-1">
                    {a.author} · {formatDate(a.publishedAt)}
                  </p>
                </div>
                <div className="flex items-center gap-1 shrink-0">
                  <button
                    onClick={() => togglePin(a)}
                    className="p-2 rounded-lg text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 transition-colors"
                    title={a.isPinned ? 'Dés-épingler' : 'Épingler'}
                  >
                    {a.isPinned ? <PinOff size={16} /> : <Pin size={16} />}
                  </button>
                  <button
                    onClick={() => openEdit(a)}
                    className="p-2 rounded-lg text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 transition-colors"
                  >
                    <Pencil size={16} />
                  </button>
                  <button
                    onClick={() => handleDelete(a.id)}
                    className="p-2 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Modal form */}
        {showForm && (
          <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto shadow-xl">
              <div className="flex items-center justify-between px-6 py-4 border-b">
                <h2 className="font-bold text-gray-900">
                  {editing ? 'Modifier l\'actualité' : 'Publier une actualité'}
                </h2>
                <button onClick={() => setShowForm(false)} className="text-gray-400 hover:text-gray-600">
                  <X size={20} />
                </button>
              </div>
              <form onSubmit={handleSave} className="p-6 space-y-4">
                {/* Catégorie */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Catégorie</label>
                  <div className="flex flex-wrap gap-2">
                    {CATEGORIES.map((c) => (
                      <button
                        key={c}
                        type="button"
                        onClick={() => setForm((f) => ({ ...f, category: c }))}
                        className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                          form.category === c
                            ? 'bg-indigo-600 text-white'
                            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                        }`}
                      >
                        {CAT_LABELS[c]}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Titre */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Titre *</label>
                  <input
                    required
                    value={form.title}
                    onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
                    className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    placeholder="Titre de l'actualité"
                  />
                </div>

                {/* Corps */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Contenu *</label>
                  <textarea
                    required
                    rows={5}
                    value={form.body}
                    onChange={(e) => setForm((f) => ({ ...f, body: e.target.value }))}
                    className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                    placeholder="Contenu de l'actualité…"
                  />
                </div>

                {/* Image URL */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">URL image (optionnel)</label>
                  <input
                    type="url"
                    value={form.imageUrl}
                    onChange={(e) => setForm((f) => ({ ...f, imageUrl: e.target.value }))}
                    className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    placeholder="https://…"
                  />
                </div>

                {/* Auteur */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Auteur</label>
                  <input
                    value={form.author}
                    onChange={(e) => setForm((f) => ({ ...f, author: e.target.value }))}
                    className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                {/* Audience */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Audience <span className="text-gray-400 font-normal">(vide = tous)</span>
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {ROLES.map((r) => (
                      <button
                        key={r}
                        type="button"
                        onClick={() => toggleRole(r)}
                        className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                          form.targetRoles.includes(r)
                            ? 'bg-indigo-600 text-white'
                            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                        }`}
                      >
                        {ROLE_LABELS[r]}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Épingler */}
                <label className="flex items-center gap-3 cursor-pointer">
                  <div
                    onClick={() => setForm((f) => ({ ...f, isPinned: !f.isPinned }))}
                    className={`w-10 h-6 rounded-full transition-colors relative ${form.isPinned ? 'bg-indigo-600' : 'bg-gray-200'}`}
                  >
                    <span
                      className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow transition-transform ${form.isPinned ? 'translate-x-5' : 'translate-x-1'}`}
                    />
                  </div>
                  <span className="text-sm font-medium text-gray-700">Épingler en tête de fil</span>
                </label>

                {/* Actions */}
                <div className="flex gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => setShowForm(false)}
                    className="flex-1 border border-gray-200 text-gray-600 rounded-xl py-2.5 text-sm font-medium hover:bg-gray-50 transition-colors"
                  >
                    Annuler
                  </button>
                  <button
                    type="submit"
                    disabled={saving}
                    className="flex-1 bg-indigo-600 text-white rounded-xl py-2.5 text-sm font-semibold hover:bg-indigo-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
                  >
                    {saving && (
                      <span className="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    )}
                    {editing ? 'Enregistrer' : 'Publier'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
