'use client';

import { useEffect, useState } from 'react';
import {
  collection,
  onSnapshot,
  updateDoc,
  doc,
  query,
  orderBy,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { AdminLayout } from '@/components/admin-layout';
import { Shield, ShieldOff, ChevronDown } from 'lucide-react';

const ROLES = ['pharmacien', 'preparateur', 'medecin', 'kine', 'commercial', 'admin'] as const;
const ROLE_LABELS: Record<string, string> = {
  pharmacien: 'Pharmacien',
  preparateur: 'Préparateur',
  medecin: 'Médecin',
  kine: 'Kinésithérapeute',
  commercial: 'Commercial',
  admin: 'Admin',
};

interface AppUser {
  id: string;
  name: string;
  email: string;
  role: string;
  region: string;
  isAdmin: boolean;
  level: string;
}

export default function UsersPage() {
  const [users, setUsers] = useState<AppUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'users'), orderBy('name'));
    const unsub = onSnapshot(q, (snap) => {
      setUsers(
        snap.docs.map((d) => ({
          id: d.id,
          name: d.data().name ?? '',
          email: d.data().email ?? '',
          role: d.data().role ?? '',
          region: d.data().region ?? '',
          isAdmin: d.data().isAdmin ?? false,
          level: d.data().level ?? 'Bronze',
        }))
      );
      setLoading(false);
    });
    return unsub;
  }, []);

  const setRole = async (userId: string, role: string) => {
    await updateDoc(doc(db, 'users', userId), { role });
  };

  const toggleAdmin = async (user: AppUser) => {
    if (
      !confirm(
        user.isAdmin
          ? `Retirer les droits admin de ${user.name} ?`
          : `Accorder les droits admin à ${user.name} ?`
      )
    ) return;
    await updateDoc(doc(db, 'users', user.id), { isAdmin: !user.isAdmin });
  };

  const filtered = users.filter(
    (u) =>
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.email.toLowerCase().includes(search.toLowerCase()) ||
      u.region.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <AdminLayout>
      <div className="p-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Utilisateurs</h1>
            <p className="text-gray-500 text-sm mt-1">{users.length} compte(s)</p>
          </div>
          <input
            type="search"
            placeholder="Rechercher…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 w-56"
          />
        </div>

        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="bg-white rounded-2xl h-16 animate-pulse" />
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 text-left">
                  <th className="px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Nom</th>
                  <th className="px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Région</th>
                  <th className="px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Rôle</th>
                  <th className="px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Niveau</th>
                  <th className="px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Admin</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map((u) => (
                  <tr key={u.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-700 font-bold text-sm">
                          {u.name[0]?.toUpperCase() ?? 'U'}
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{u.name}</p>
                          <p className="text-xs text-gray-400">{u.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-gray-600">{u.region || '—'}</td>
                    <td className="px-5 py-3.5">
                      <div className="relative inline-block">
                        <select
                          value={u.role}
                          onChange={(e) => setRole(u.id, e.target.value)}
                          className="appearance-none border border-gray-200 rounded-lg px-3 py-1.5 pr-7 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white cursor-pointer"
                        >
                          {ROLES.map((r) => (
                            <option key={r} value={r}>{ROLE_LABELS[r]}</option>
                          ))}
                        </select>
                        <ChevronDown size={13} className="absolute right-2 top-2.5 text-gray-400 pointer-events-none" />
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="text-xs font-medium bg-amber-50 text-amber-600 px-2.5 py-1 rounded-full">
                        {u.level}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      <button
                        onClick={() => toggleAdmin(u)}
                        className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                          u.isAdmin
                            ? 'bg-indigo-50 text-indigo-700 hover:bg-red-50 hover:text-red-600'
                            : 'bg-gray-100 text-gray-500 hover:bg-indigo-50 hover:text-indigo-700'
                        }`}
                      >
                        {u.isAdmin ? <Shield size={13} /> : <ShieldOff size={13} />}
                        {u.isAdmin ? 'Admin' : 'Standard'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filtered.length === 0 && (
              <div className="py-12 text-center text-gray-400 text-sm">Aucun utilisateur trouvé</div>
            )}
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
