const faqs = [
  {
    q: 'À quel âge commencer ?',
    a: 'Les premiers signes du vieillissement cellulaire apparaissent vers 35 ans. Granions Longévité est conçu pour les adultes à partir de 40 ans, mais peut être utile dès 30 ans en cas de fatigue chronique ou de stress oxydatif élevé.',
  },
  {
    q: 'Combien de temps avant de ressentir les effets ?',
    a: 'La majorité des utilisateurs rapportent un regain d’énergie dès la 3ᵉ semaine. Les effets cognitifs et esthétiques (peau, cheveux) se manifestent plutôt entre 6 et 12 semaines, le temps du renouvellement cellulaire.',
  },
  {
    q: 'Peut-on associer Granions Longévité à un traitement médical ?',
    a: 'Le complément ne remplace pas un médicament. En cas de traitement anticoagulant, hypotenseur ou immunosuppresseur, demandez l’avis de votre médecin — le resvératrol peut interagir avec certaines molécules.',
  },
  {
    q: 'D’où viennent les ingrédients ?',
    a: 'Le NMN est produit par fermentation en Suisse. Les oligo-éléments sont extraits en Vendée selon le procédé Granions®. Le resvératrol provient de renouée du Japon cultivée sans pesticides en Bretagne.',
  },
  {
    q: 'Que se passe-t-il si je ne ressens rien ?',
    a: 'Vous êtes remboursé intégralement pendant 60 jours, même flacon entamé. Un simple e-mail suffit. Pas de petites lignes, pas de questions.',
  },
];

export function Faq() {
  return (
    <section id="faq" className="bg-[color:var(--surface-warm)] py-24">
      <div className="mx-auto max-w-4xl px-6">
        <div className="text-center">
          <span className="text-xs uppercase tracking-[0.3em] text-[color:var(--accent-dark)]">Questions fréquentes</span>
          <h2 className="mt-4 font-serif text-4xl tracking-tight text-[color:var(--primary-dark)] sm:text-5xl">
            Tout ce qu&apos;on nous demande.
          </h2>
        </div>

        <div className="mt-12 divide-y divide-black/10 overflow-hidden rounded-3xl border border-black/10 bg-white">
          {faqs.map((f, i) => (
            <details key={i} className="group px-7 py-6 [&_summary::-webkit-details-marker]:hidden">
              <summary className="flex cursor-pointer items-center justify-between gap-6">
                <span className="font-serif text-lg text-[color:var(--primary-dark)]">{f.q}</span>
                <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full border border-[color:var(--primary)]/20 text-[color:var(--primary)] transition group-open:rotate-45">
                  +
                </span>
              </summary>
              <p className="mt-4 text-[15px] leading-relaxed text-[color:var(--muted)]">{f.a}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}
