export function Footer() {
  return (
    <footer className="border-t border-black/5 bg-[color:var(--background)]">
      <div className="mx-auto grid max-w-7xl gap-10 px-6 py-16 md:grid-cols-4">
        <div className="md:col-span-2">
          <div className="flex items-center gap-2 font-serif text-xl text-[color:var(--primary)]">
            <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-[color:var(--primary)] text-[color:var(--accent)]">
              G
            </span>
            Granions <span className="text-[color:var(--accent-dark)]">Longévité</span>
          </div>
          <p className="mt-4 max-w-md text-sm leading-relaxed text-[color:var(--muted)]">
            Laboratoire Granions — 12 rue des Oligo-éléments, 85000 La Roche-sur-Yon. Pionnier des oligo-éléments en France depuis 1948.
          </p>
        </div>

        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-[color:var(--accent-dark)]">Produit</div>
          <ul className="mt-4 space-y-2 text-sm text-[color:var(--muted)]">
            <li><a href="#formula" className="hover:text-[color:var(--primary)]">Formule</a></li>
            <li><a href="#protocol" className="hover:text-[color:var(--primary)]">Protocole</a></li>
            <li><a href="#offer" className="hover:text-[color:var(--primary)]">Tarifs</a></li>
            <li><a href="#faq" className="hover:text-[color:var(--primary)]">FAQ</a></li>
          </ul>
        </div>

        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-[color:var(--accent-dark)]">Légal</div>
          <ul className="mt-4 space-y-2 text-sm text-[color:var(--muted)]">
            <li><a href="#" className="hover:text-[color:var(--primary)]">Mentions légales</a></li>
            <li><a href="#" className="hover:text-[color:var(--primary)]">CGV</a></li>
            <li><a href="#" className="hover:text-[color:var(--primary)]">Politique de confidentialité</a></li>
            <li><a href="#" className="hover:text-[color:var(--primary)]">Cookies</a></li>
          </ul>
        </div>
      </div>

      <div className="border-t border-black/5">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-3 px-6 py-6 text-xs text-[color:var(--muted)] md:flex-row">
          <p>© {new Date().getFullYear()} Laboratoire Granions. Tous droits réservés.</p>
          <p className="max-w-2xl text-center md:text-right">
            Les compléments alimentaires ne se substituent pas à une alimentation variée et équilibrée, ni à un mode de vie sain.
          </p>
        </div>
      </div>
    </footer>
  );
}
