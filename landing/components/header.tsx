import Link from 'next/link';

const nav = [
  { label: 'Bienfaits', href: '#benefits' },
  { label: 'Formule', href: '#formula' },
  { label: 'Protocole', href: '#protocol' },
  { label: 'Témoignages', href: '#testimonials' },
  { label: 'FAQ', href: '#faq' },
];

export function Header() {
  return (
    <header className="sticky top-0 z-40 border-b border-black/5 bg-[color:var(--background)]/85 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-6">
        <Link href="/" className="flex items-center gap-2 font-serif text-xl text-[color:var(--primary)]">
          <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-[color:var(--primary)] text-[color:var(--accent)]">
            G
          </span>
          Granions <span className="text-[color:var(--accent-dark)]">Longévité</span>
        </Link>

        <nav className="hidden items-center gap-8 text-sm text-[color:var(--muted)] md:flex">
          {nav.map((item) => (
            <a key={item.href} href={item.href} className="transition hover:text-[color:var(--primary)]">
              {item.label}
            </a>
          ))}
        </nav>

        <a
          href="#offer"
          className="inline-flex items-center rounded-full bg-[color:var(--primary)] px-5 py-2.5 text-sm font-medium text-white shadow-sm transition hover:bg-[color:var(--primary-dark)]"
        >
          Commander
        </a>
      </div>
    </header>
  );
}
