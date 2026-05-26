export function FinalCta() {
  return (
    <section className="mx-auto max-w-7xl px-6 py-24">
      <div className="relative overflow-hidden rounded-[2.5rem] bg-[color:var(--primary)] px-8 py-20 text-center text-white sm:px-16">
        <div className="absolute -left-20 -top-20 h-80 w-80 rounded-full bg-[color:var(--accent)]/20 blur-3xl" />
        <div className="absolute -bottom-20 -right-10 h-80 w-80 rounded-full bg-white/5 blur-3xl" />

        <div className="relative">
          <span className="text-xs uppercase tracking-[0.3em] text-[color:var(--accent)]">Offre de lancement</span>
          <h2 className="mt-5 font-serif text-4xl tracking-tight sm:text-6xl">
            Et si vos 60 ans
            <br />
            ressemblaient à vos 40 ?
          </h2>
          <p className="mx-auto mt-6 max-w-2xl text-lg text-white/70">
            Rejoignez les 12 480 personnes qui ont choisi de prendre soin de leur capital cellulaire — sérieusement,
            durablement, sans promesse de jouvence.
          </p>

          <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
            <a
              href="#offer"
              className="inline-flex items-center justify-center rounded-full bg-[color:var(--accent)] px-8 py-4 text-base font-medium text-[color:var(--primary-dark)] shadow-xl transition hover:-translate-y-0.5 hover:bg-white"
            >
              Démarrer ma cure — 39 €
            </a>
            <span className="text-sm text-white/60">Satisfait ou remboursé · 60 jours</span>
          </div>
        </div>
      </div>
    </section>
  );
}
