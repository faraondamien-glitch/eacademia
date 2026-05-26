const press = [
  'Le Figaro Santé',
  'Marie Claire',
  'Top Santé',
  'Doctissimo',
  'L’Express',
  'Femme Actuelle',
  'Sciences & Avenir',
];

export function Marquee() {
  return (
    <section className="border-y border-black/5 bg-white/60 py-6">
      <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-center gap-x-10 gap-y-3 px-6 text-xs uppercase tracking-[0.25em] text-[color:var(--muted)]">
        <span className="text-[color:var(--accent-dark)]">Ils en parlent</span>
        {press.map((name) => (
          <span key={name} className="font-serif text-base normal-case tracking-normal text-[color:var(--foreground)]/70">
            {name}
          </span>
        ))}
      </div>
    </section>
  );
}
