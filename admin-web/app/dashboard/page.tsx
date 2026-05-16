'use client';

import { useEffect, useState } from 'react';
import { collection, getCountFromServer, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { AdminLayout } from '@/components/admin-layout';
import { Users, Newspaper, ShoppingBag, Bell } from 'lucide-react';
import Link from 'next/link';

interface Stat {
  label: string;
  value: number | string;
  icon: React.ElementType;
  color: string;
  href: string;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stat[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [usersSnap, actusSnap, commandesSnap, pendingSnap] = await Promise.all([
          getCountFromServer(collection(db, 'users')),
          getCountFromServer(collection(db, 'actualites')),
          getCountFromServer(collection(db, 'commandes')),
          getCountFromServer(query(collection(db, 'commandes'), where('status', '==', 'pending'))),
        ]);

        setStats([
          {
            label: 'Utilisateurs',
            value: usersSnap.data().count,
            icon: Users,
            color: 'bg-indigo-50 text-indigo-600',
            href: '/users',
          },
          {
            label: 'Actualités publiées',
            value: actusSnap.data().count,
            icon: Newspaper,
            color: 'bg-emerald-50 text-emerald-600',
            href: '/actualites',
          },
          {
            label: 'Commandes totales',
            value: commandesSnap.data().count,
            icon: ShoppingBag,
            color: 'bg-amber-50 text-amber-600',
            href: '/commandes',
          },
          {
            label: 'Commandes en attente',
            value: pendingSnap.data().count,
            icon: Bell,
            color: 'bg-rose-50 text-rose-600',
            href: '/commandes',
          },
        ]);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  return (
    <AdminLayout>
      <div className="p-8">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-500 text-sm mt-1">Vue d&apos;ensemble de la plateforme</p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          {loading
            ? Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="bg-white rounded-2xl p-5 animate-pulse h-24" />
              ))
            : stats.map(({ label, value, icon: Icon, color, href }) => (
                <Link
                  key={label}
                  href={href}
                  className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100 hover:shadow-md transition-shadow flex items-center gap-4"
                >
                  <div className={`p-3 rounded-xl ${color}`}>
                    <Icon size={20} />
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-gray-900">{value}</p>
                    <p className="text-xs text-gray-500">{label}</p>
                  </div>
                </Link>
              ))}
        </div>

        {/* Quick links */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <h2 className="font-semibold text-gray-900 mb-4">Actions rapides</h2>
          <div className="flex flex-wrap gap-3">
            <Link
              href="/actualites"
              className="inline-flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-indigo-700 transition-colors"
            >
              <Newspaper size={16} />
              Publier une actualité
            </Link>
            <Link
              href="/notifications"
              className="inline-flex items-center gap-2 bg-[#1A1A2E] text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-indigo-900 transition-colors"
            >
              <Bell size={16} />
              Envoyer une notification
            </Link>
            <Link
              href="/commandes"
              className="inline-flex items-center gap-2 border border-gray-200 text-gray-700 px-4 py-2 rounded-xl text-sm font-medium hover:bg-gray-50 transition-colors"
            >
              <ShoppingBag size={16} />
              Voir les commandes
            </Link>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
}
