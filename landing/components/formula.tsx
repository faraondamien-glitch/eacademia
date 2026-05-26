const ingredients = [
  { name: 'NMN (Nicotinamide Mononucléotide)', amount: '250 mg', role: 'Précurseur du NAD+, énergie cellulaire' },
  { name: 'Trans-resvératrol', amount: '150 mg', role: 'Polyphénol issu de la renouée du Japon' },
  { name: 'Zinc bisglycinate', amount: '10 mg', role: 'Fonctions cognitives & immunitaires' },
  { name: 'Sélénium L-méthionine', amount: '55 µg', role: 'Protection contre le stress oxydatif' },
  { name: 'Cuivre Granions®', amount: '1 mg', role: 'Système cardio-vasculaire' },
  { name: 'Manganèse Granions®', amount: '2 mg', role: 'Formation du tissu conjonctif' },
  { name: 'Silicium organique', amount: '40 mg', role: 'Collagène, peau, articulations' },
  { name: 'Coenzyme Q10 ubiquinol', amount: '50 mg', role: 'Forme active, mitochondries' },
  { name: 'Vitamine D3 végétale', amount: '25 µg', role: 'Os, muscles, immunité' },
];

export function Formula() {
  return (
    <section id="formula" className="bg-[color:var(--surface-warm)] py-24">
      <div className="mx-auto grid max-w-7xl gap-16 px-6 lg:grid-cols-[1fr_1.2fr]">
        <div className="lg:sticky lg:top-28 lg:self-start">
          <span className="text-xs uppercase tracking-[0.3em] text-[color:var(--accent-dark)]">La formule</span>
          <h2 className="mt-4 font-serif text-4xl tracking-tight text-[color:var(--primary-dark)] sm:text-5xl">
            9 actifs, zéro compromis.
          </h2>
          <p className="mt-5 text-lg text-[color:var(--muted)]">
            Chaque gélule contient un dosage cliniquement utile — pas de poudre de perlimpinpin, pas de remplissage.
            Les oligo-éléments utilisent le brevet Granions® qui garantit une assimilation jusqu&apos;à 4× supérieure
            aux sels minéraux classiques.
          </p>

          <div className="mt-8 rounded-2xl border border-[color:var(--accent)]/30 bg-white/60 p-6">
            <div className="text-xs uppercase tracking-[0.25em] text-[color:var(--accent-dark)]">Engagement qualité</div>
            <ul className="mt-3 space-y-2 text-sm text-[color:var(--foreground)]">
              <li>· Analysé par lot — pureté &gt; 99,5 %</li>
              <li>· Gélules végétales d&apos;origine pullulan</li>
              <li>· Sans dioxyde de titane, sans nanoparticules</li>
              <li>· Conditionné en Vendée (laboratoire ISO 22000)</li>
            </ul>
          </div>
        </div>

        <div className="overflow-hidden rounded-3xl border border-black/5 bg-white shadow-sm">
          <div className="border-b border-black/5 px-7 py-5">
            <div className="flex items-baseline justify-between">
              <span className="font-serif text-xl text-[color:var(--primary-dark)]">Composition · 2 gélules</span>
              <span className="text-xs uppercase tracking-[0.2em] text-[color:var(--muted)]">par dose</span>
            </div>
          </div>
          <ul>
            {ingredients.map((ing) => (
              <li
                key={ing.name}
                className="flex items-center justify-between gap-6 border-b border-black/5 px-7 py-5 last:border-b-0"
              >
                <div>
                  <div className="font-medium text-[color:var(--foreground)]">{ing.name}</div>
                  <div className="mt-0.5 text-sm text-[color:var(--muted)]">{ing.role}</div>
                </div>
                <div className="shrink-0 rounded-full bg-[color:var(--primary)]/8 px-3 py-1 font-mono text-sm text-[color:var(--primary)]">
                  {ing.amount}
                </div>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
