import { ShieldCheck, Leaf, Award } from 'lucide-react';

export function Hero() {
  return (
    <section className="bg-radial-hero relative overflow-hidden">
      <div className="mx-auto grid max-w-7xl gap-16 px-6 pb-24 pt-20 md:grid-cols-2 md:pt-28">
        <div className="flex flex-col justify-center">
          <span className="inline-flex w-fit items-center gap-2 rounded-full border border-[color:var(--accent)]/40 bg-white/60 px-4 py-1.5 text-xs font-medium uppercase tracking-[0.18em] text-[color:var(--accent-dark)]">
            <Leaf className="h-3.5 w-3.5" /> Nouvelle formule 2026
          </span>

          <h1 className="mt-6 font-serif text-5xl leading-[1.05] tracking-tight text-[color:var(--primary-dark)] sm:text-6xl md:text-7xl">
            Vivre plus longtemps,
            <br />
            <span className="italic text-[color:var(--accent-dark)]">vivre mieux.</span>
          </h1>

          <p className="mt-6 max-w-xl text-lg leading-relaxed text-[color:var(--muted)]">
            Granions Longévité associe <strong className="text-[color:var(--foreground)]">9 oligo-éléments brevetés</strong>,
            du NMN et du resvératrol pour soutenir l&apos;énergie cellulaire, la mémoire et la vitalité — jour après
            jour, après 40 ans.
          </p>

          <div className="mt-10 flex flex-col gap-4 sm:flex-row">
            <a
              href="#offer"
              className="inline-flex items-center justify-center rounded-full bg-[color:var(--primary)] px-7 py-4 text-base font-medium text-white shadow-lg shadow-[color:var(--primary)]/20 transition hover:-translate-y-0.5 hover:bg-[color:var(--primary-dark)]"
            >
              Découvrir le programme — 39 €
            </a>
            <a
              href="#formula"
              className="inline-flex items-center justify-center rounded-full border border-[color:var(--primary)]/20 px-7 py-4 text-base font-medium text-[color:var(--primary)] transition hover:border-[color:var(--primary)]/40 hover:bg-white/60"
            >
              Voir la formule
            </a>
          </div>

          <ul className="mt-12 flex flex-wrap gap-x-8 gap-y-4 text-sm text-[color:var(--muted)]">
            <li className="flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-[color:var(--primary)]" />
              Fabriqué en France
            </li>
            <li className="flex items-center gap-2">
              <Award className="h-4 w-4 text-[color:var(--primary)]" />
              Brevet Granions® depuis 1948
            </li>
            <li className="flex items-center gap-2">
              <Leaf className="h-4 w-4 text-[color:var(--primary)]" />
              Sans OGM · Sans gluten
            </li>
          </ul>
        </div>

        <div className="relative flex items-center justify-center">
          <div className="absolute inset-0 -z-10 mx-auto h-[420px] w-[420px] translate-y-8 rounded-full bg-[radial-gradient(ellipse_at_center,rgba(201,168,106,0.35)_0%,transparent_70%)]" />
          <div className="animate-float-slow">
            <div className="relative">
              <div className="bottle-cap absolute left-1/2 top-0 z-10 h-12 w-28 -translate-x-1/2 rounded-t-md" />
              <div className="bottle relative mt-10 flex h-[420px] w-56 flex-col items-center justify-between overflow-hidden rounded-2xl px-4 py-10 text-center text-white">
                <div className="shine absolute inset-y-0 left-0 w-full opacity-50" />
                <div className="relative z-10">
                  <div className="text-[10px] uppercase tracking-[0.4em] text-[color:var(--accent)]">Granions</div>
                  <div className="mt-2 font-serif text-3xl leading-none">Longévité</div>
                  <div className="mx-auto mt-3 h-px w-12 bg-[color:var(--accent)]/70" />
                  <div className="mt-3 text-[10px] uppercase tracking-[0.3em] text-white/70">
                    NMN · Resvératrol
                    <br />
                    Oligo-éléments
                  </div>
                </div>
                <div className="relative z-10 space-y-1">
                  <div className="font-serif text-2xl text-[color:var(--accent)]">60</div>
                  <div className="text-[10px] uppercase tracking-[0.3em] text-white/70">gélules vegan</div>
                </div>
              </div>
            </div>
          </div>

          <div className="absolute bottom-6 left-6 hidden rounded-2xl border border-white/60 bg-white/80 px-5 py-4 shadow-xl backdrop-blur md:block">
            <div className="flex items-center gap-3">
              <div className="flex -space-x-2">
                <div className="h-9 w-9 rounded-full border-2 border-white bg-gradient-to-br from-amber-200 to-amber-400" />
                <div className="h-9 w-9 rounded-full border-2 border-white bg-gradient-to-br from-emerald-200 to-emerald-500" />
                <div className="h-9 w-9 rounded-full border-2 border-white bg-gradient-to-br from-rose-200 to-rose-400" />
              </div>
              <div className="text-sm">
                <div className="font-medium text-[color:var(--foreground)]">12 480 clients</div>
                <div className="text-xs text-[color:var(--muted)]">★★★★★ 4,8 / 5 sur Trustpilot</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
