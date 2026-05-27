import Link from "next/link";

export default function Footer() {
  return (
    <footer className="mt-20 border-t border-slate-200 bg-slate-50">
      <div className="mx-auto grid max-w-7xl gap-8 px-4 py-12 md:grid-cols-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="grid h-9 w-9 place-items-center rounded-md bg-brand-600 font-bold text-white">G</span>
            <div className="font-semibold text-brand-700">Granions Pro</div>
          </div>
          <p className="mt-3 text-sm text-slate-600">
            Le portail réservé aux professionnels de santé pour commander, se former et suivre l'actualité de la marque.
          </p>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-slate-800">Navigation</h4>
          <ul className="mt-3 space-y-2 text-sm text-slate-600">
            <li><Link href="/catalog" className="hover:text-brand-700">Catalogue</Link></li>
            <li><Link href="/orders" className="hover:text-brand-700">Mes commandes</Link></li>
            <li><Link href="/news" className="hover:text-brand-700">Actualités</Link></li>
            <li><Link href="/contact" className="hover:text-brand-700">Contact</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-slate-800">Compte</h4>
          <ul className="mt-3 space-y-2 text-sm text-slate-600">
            <li><Link href="/login" className="hover:text-brand-700">Connexion</Link></li>
            <li><Link href="/register" className="hover:text-brand-700">Créer un compte</Link></li>
            <li><Link href="/dashboard" className="hover:text-brand-700">Tableau de bord</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-slate-800">Mentions</h4>
          <ul className="mt-3 space-y-2 text-sm text-slate-600">
            <li>Espace réservé aux professionnels de santé</li>
            <li>Les compléments alimentaires ne se substituent pas à une alimentation variée et équilibrée</li>
          </ul>
        </div>
      </div>
      <div className="border-t border-slate-200 py-4 text-center text-xs text-slate-500">
        © {new Date().getFullYear()} Granions Pro — Démo
      </div>
    </footer>
  );
}
