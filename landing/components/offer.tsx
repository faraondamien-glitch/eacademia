import { Check } from 'lucide-react';

const plans = [
  {
    name: 'Découverte',
    duration: '1 mois',
    price: '39',
    perDay: '1,30 €',
    features: ['1 flacon · 60 gélules', 'Livraison offerte dès 50 €', 'Suivi par e-mail'],
    cta: 'Choisir Découverte',
    featured: false,
  },
  {
    name: 'Cure complète',
    duration: '3 mois',
    price: '99',
    perDay: '1,10 €',
    save: 'Économisez 18 €',
    features: [
      '3 flacons · 180 gélules',
      'Livraison express offerte',
      'Bilan personnalisé inclus',
      'Suivi par naturopathe',
    ],
    cta: 'Choisir la cure',
    featured: true,
  },
  {
    name: 'Abonnement',
    duration: 'Tous les 3 mois',
    price: '79',
    perDay: '0,88 €',
    save: '-20 % à vie',
    features: [
      '3 flacons livrés trimestriellement',
      'Annulation libre, sans engagement',
      'Bilan annuel offert',
      'Accès au club Granions',
    ],
    cta: 'M’abonner',
    featured: false,
  },
];

export function Offer() {
  return (
    <section id="offer" className="mx-auto max-w-7xl px-6 py-24">
      <div className="mx-auto max-w-3xl text-center">
        <span className="text-xs uppercase tracking-[0.3em] text-[color:var(--accent-dark)]">Choisissez votre programme</span>
        <h2 className="mt-4 font-serif text-4xl tracking-tight text-[color:var(--primary-dark)] sm:text-5xl">
          Commencez aujourd&apos;hui. Annulez quand vous voulez.
        </h2>
        <p className="mt-5 text-lg text-[color:var(--muted)]">
          Satisfait ou remboursé pendant 60 jours, même flacon entamé.
        </p>
      </div>

      <div className="mt-16 grid gap-6 lg:grid-cols-3">
        {plans.map((plan) => (
          <div
            key={plan.name}
            className={`relative flex flex-col rounded-3xl border p-8 transition ${
              plan.featured
                ? 'border-[color:var(--accent)] bg-[color:var(--primary)] text-white shadow-2xl shadow-[color:var(--primary)]/30 lg:-translate-y-4 lg:scale-[1.03]'
                : 'border-black/10 bg-white text-[color:var(--foreground)] shadow-sm hover:-translate-y-1 hover:shadow-lg'
            }`}
          >
            {plan.featured && (
              <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-[color:var(--accent)] px-4 py-1 text-xs font-semibold uppercase tracking-wider text-[color:var(--primary-dark)]">
                Le plus choisi
              </span>
            )}

            <div className="font-serif text-2xl">{plan.name}</div>
            <div className={`text-sm ${plan.featured ? 'text-white/70' : 'text-[color:var(--muted)]'}`}>
              {plan.duration}
            </div>

            <div className="mt-6 flex items-baseline gap-1">
              <span className="font-serif text-5xl">{plan.price}</span>
              <span className={`text-lg ${plan.featured ? 'text-white/80' : 'text-[color:var(--muted)]'}`}>€</span>
            </div>
            <div className={`mt-1 text-sm ${plan.featured ? 'text-white/70' : 'text-[color:var(--muted)]'}`}>
              soit {plan.perDay} / jour
            </div>
            {plan.save && (
              <div className={`mt-2 inline-flex w-fit rounded-full px-3 py-1 text-xs font-medium ${
                plan.featured ? 'bg-[color:var(--accent)] text-[color:var(--primary-dark)]' : 'bg-[color:var(--accent)]/20 text-[color:var(--accent-dark)]'
              }`}>
                {plan.save}
              </div>
            )}

            <ul className={`mt-7 space-y-3 text-sm ${plan.featured ? 'text-white/90' : 'text-[color:var(--foreground)]'}`}>
              {plan.features.map((f) => (
                <li key={f} className="flex items-start gap-2">
                  <Check className={`mt-0.5 h-4 w-4 shrink-0 ${plan.featured ? 'text-[color:var(--accent)]' : 'text-[color:var(--primary)]'}`} />
                  {f}
                </li>
              ))}
            </ul>

            <a
              href="#"
              className={`mt-8 inline-flex items-center justify-center rounded-full px-6 py-3.5 text-sm font-medium transition ${
                plan.featured
                  ? 'bg-[color:var(--accent)] text-[color:var(--primary-dark)] hover:bg-[color:var(--accent-dark)] hover:text-white'
                  : 'bg-[color:var(--primary)] text-white hover:bg-[color:var(--primary-dark)]'
              }`}
            >
              {plan.cta}
            </a>
          </div>
        ))}
      </div>
    </section>
  );
}
