import { Star } from 'lucide-react';

const testimonials = [
  {
    name: 'Catherine, 58 ans',
    city: 'Lyon',
    rating: 5,
    quote:
      'Après deux mois, je me lève sans la fatigue d&apos;avant. Ma kiné a même remarqué que mes articulations étaient moins raides. C&apos;est devenu un rituel non négociable.',
  },
  {
    name: 'Jean-Marc, 64 ans',
    city: 'Bordeaux',
    rating: 5,
    quote:
      'J&apos;ai testé pas mal de compléments. Celui-ci se distingue par la transparence des dosages et le suivi par un vrai naturopathe. Du sérieux.',
  },
  {
    name: 'Sophie, 47 ans',
    city: 'Paris',
    rating: 5,
    quote:
      'Mes cheveux ont retrouvé du volume au bout du 3e mois. Je ne pensais pas que ça viendrait de l&apos;intérieur. Bluffée.',
  },
];

export function Testimonials() {
  return (
    <section id="testimonials" className="bg-[color:var(--primary)] py-24 text-white">
      <div className="mx-auto max-w-7xl px-6">
        <div className="mx-auto max-w-3xl text-center">
          <span className="text-xs uppercase tracking-[0.3em] text-[color:var(--accent)]">Témoignages vérifiés</span>
          <h2 className="mt-4 font-serif text-4xl tracking-tight sm:text-5xl">
            12 480 personnes ont déjà tenté l&apos;expérience.
          </h2>
          <p className="mt-5 text-lg text-white/70">
            Note moyenne 4,8 / 5 sur Trustpilot — avis non modifiables, vérifiés par achat.
          </p>
        </div>

        <div className="mt-16 grid gap-6 md:grid-cols-3">
          {testimonials.map((t) => (
            <figure
              key={t.name}
              className="rounded-3xl border border-white/10 bg-white/5 p-7 backdrop-blur transition hover:bg-white/10"
            >
              <div className="flex gap-0.5 text-[color:var(--accent)]">
                {Array.from({ length: t.rating }).map((_, i) => (
                  <Star key={i} className="h-4 w-4 fill-current" />
                ))}
              </div>
              <blockquote
                className="mt-5 font-serif text-lg leading-relaxed text-white/90"
                dangerouslySetInnerHTML={{ __html: `« ${t.quote} »` }}
              />
              <figcaption className="mt-6 text-sm text-white/60">
                <span className="font-medium text-white">{t.name}</span> · {t.city}
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
