"use client";

import Link from "next/link";
import { useSession, signOut } from "next-auth/react";

export default function Navbar() {
  const { data: session, status } = useSession();
  const authed = status === "authenticated";

  return (
    <header className="sticky top-0 z-40 border-b border-slate-200 bg-white/90 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-2">
          <span className="grid h-9 w-9 place-items-center rounded-md bg-brand-600 font-bold text-white">G</span>
          <div className="leading-tight">
            <div className="font-semibold text-brand-700">Granions</div>
            <div className="text-[11px] uppercase tracking-wider text-slate-500">Espace Pro</div>
          </div>
        </Link>

        <nav className="hidden items-center gap-6 text-sm font-medium text-slate-700 md:flex">
          <Link href="/catalog" className="hover:text-brand-700">Catalogue</Link>
          <Link href="/orders" className="hover:text-brand-700">Commandes</Link>
          <Link href="/news" className="hover:text-brand-700">Actualités</Link>
          <Link href="/contact" className="hover:text-brand-700">Contact</Link>
        </nav>

        <div className="flex items-center gap-3 text-sm">
          {authed ? (
            <>
              <Link href="/dashboard" className="hidden text-slate-600 hover:text-brand-700 sm:inline">
                {session?.user?.name ?? "Mon compte"}
              </Link>
              <button
                onClick={() => signOut({ callbackUrl: "/" })}
                className="rounded-md border border-slate-300 px-3 py-1.5 text-slate-700 hover:bg-slate-50"
              >
                Déconnexion
              </button>
            </>
          ) : (
            <>
              <Link href="/login" className="text-slate-700 hover:text-brand-700">
                Connexion
              </Link>
              <Link
                href="/register"
                className="rounded-md bg-brand-600 px-3 py-1.5 font-medium text-white hover:bg-brand-700"
              >
                Créer un compte
              </Link>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
