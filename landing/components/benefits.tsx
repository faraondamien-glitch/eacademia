import { Brain, HeartPulse, Sparkles, Zap } from 'lucide-react';

const benefits = [
  {
    icon: Zap,
    title: 'Énergie cellulaire',
    body: 'Le NMN soutient la production naturelle de NAD+, le carburant des mitochondries. Vous ressentez la différence dès 3 semaines.',
  },
  {
    icon: Brain,
    title: 'Mémoire & clarté',
    body: 'Le zinc et le sélénium contribuent au fonctionnement cognitif normal et à la protection des cellules contre le stress oxydatif.',
  },
  {
    icon: HeartPulse,
    title: 'Système cardio-vasculaire',
    body: 'Le resvératrol et le cuivre participent au maintien d’une fonction cardiaque saine et à l’élasticité des vaisseaux.',
  },
  {
    icon: Sparkles,
    title: 'Peau, cheveux, ongles',
    body: 'Silicium et manganèse soutiennent la formation du collagène. Une jeunesse qui se voit, aussi.',
  },
];

export function Benefits() {
  return (
    <section id="benefits" className="mx-auto max-w-7xl px-6 py-24">
      <div className="mx-auto max-w-3xl text-center">
        <span className="text-xs uppercase tracking-[0.3em] text-[color:var(--accent-dark)]">Pourquoi Granions Longévité</span>
        <h2 className="mt-4 font-serif text-4xl tracking-tight text-[color:var(--primary-dark)] sm:text-5xl">
          4 piliers pour ralentir l&apos;horloge biologique
        </h2>
        <p className="mt-5 text-lg text-[color:var(--muted)]">
          Une formule conçue avec le Pr. Lefèvre, gérontologue, pour agir simultanément sur les principaux marqueurs
          du vieillissement.
        </p>
      </div>

      <div className="mt-16 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {benefits.map(({ icon: Icon, title, body }) => (
          <div
            key={title}
            className="group relative overflow-hidden rounded-3xl border border-black/5 bg-white p-7 shadow-sm transition hover:-translate-y-1 hover:shadow-xl"
          >
            <div className="absolute right-4 top-4 h-24 w-24 rounded-full bg-[color:var(--accent)]/10 transition group-hover:scale-125" />
            <div className="relative">
              <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-[color:var(--primary)]/10 text-[color:var(--primary)]">
                <Icon className="h-6 w-6" />
              </div>
              <h3 className="mt-5 font-serif text-xl text-[color:var(--primary-dark)]">{title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-[color:var(--muted)]">{body}</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
