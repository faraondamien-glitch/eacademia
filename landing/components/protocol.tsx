const steps = [
  {
    n: '01',
    title: 'Bilan personnalisé',
    body: 'Répondez à 12 questions en ligne. Notre algorithme évalue votre âge biologique estimé et vos priorités.',
  },
  {
    n: '02',
    title: 'Cure de 3 mois',
    body: '2 gélules le matin, au petit-déjeuner. Pendant 90 jours, le temps qu&apos;une nouvelle génération cellulaire s&apos;installe.',
  },
  {
    n: '03',
    title: 'Suivi & ajustement',
    body: 'Un naturopathe diplômé vous accompagne par message. Nouveau bilan offert au bout de 90 jours.',
  },
];

export function Protocol() {
  return (
    <section id="protocol" className="mx-auto max-w-7xl px-6 py-24">
      <div className="mx-auto max-w-3xl text-center">
        <span className="text-xs uppercase tracking-[0.3em] text-[color:var(--accent-dark)]">Le protocole</span>
        <h2 className="mt-4 font-serif text-4xl tracking-tight text-[color:var(--primary-dark)] sm:text-5xl">
          Un accompagnement, pas juste un flacon.
        </h2>
      </div>

      <div className="mt-16 grid gap-8 md:grid-cols-3">
        {steps.map((s, i) => (
          <div key={s.n} className="relative">
            {i < steps.length - 1 && (
              <div className="absolute left-14 top-8 hidden h-px w-[calc(100%-3rem)] bg-gradient-to-r from-[color:var(--accent)] to-transparent md:block" />
            )}
            <div className="relative rounded-3xl border border-black/5 bg-white p-7 shadow-sm">
              <div className="inline-flex h-14 w-14 items-center justify-center rounded-2xl bg-[color:var(--primary)] font-serif text-xl text-[color:var(--accent)]">
                {s.n}
              </div>
              <h3 className="mt-5 font-serif text-xl text-[color:var(--primary-dark)]">{s.title}</h3>
              <p
                className="mt-3 text-sm leading-relaxed text-[color:var(--muted)]"
                dangerouslySetInnerHTML={{ __html: s.body }}
              />
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
