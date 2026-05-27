import Link from "next/link";
import { prisma } from "@/lib/prisma";

export default async function HomePage() {
  const [productCount, latestNews] = await Promise.all([
    prisma.product.count().catch(() => 0),
    prisma.newsPost.findMany({ orderBy: { createdAt: "desc" }, take: 3 }).catch(() => []),
  ]);

  return (
    <>
      <section className="relative overflow-hidden bg-gradient-to-br from-brand-700 via-brand-600 to-brand-500 text-white">
        <div className="mx-auto max-w-7xl px-4 py-20 md:py-28">
          <div className="max-w-2xl">
            <span className="inline-block rounded-full bg-white/15 px-3 py-1 text-xs font-medium uppercase tracking-wider">
              Espace réservé aux professionnels de santé
            </span>
            <h1 className="mt-5 text-4xl font-bold leading-tight md:text-5xl">
              Le portail Granions dédié aux pharmaciens.
            </h1>
            <p className="mt-5 text-lg text-brand-50/90">
              Passez vos commandes, accédez à la documentation produit, suivez l'actualité de la
              marque et inscrivez-vous aux formations en quelques clics.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                href="/register"
                className="rounded-md bg-white px-5 py-3 font-medium text-brand-700 hover:bg-brand-50"
              >
                Créer mon compte pro
              </Link>
              <Link
                href="/login"
                className="rounded-md border border-white/40 px-5 py-3 font-medium text-white hover:bg-white/10"
              >
                Je me connecte
              </Link>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-16">
        <div className="grid gap-6 md:grid-cols-3">
          {[
            {
              title: "Catalogue complet",
              desc: `${productCount} références disponibles : oligo-éléments, vitamines, phytothérapie, microbiote.`,
              href: "/catalog",
              cta: "Voir le catalogue",
            },
            {
              title: "Commandes en ligne",
              desc: "Passez commande 24/7 directement depuis votre espace, suivez vos livraisons et retrouvez l'historique.",
              href: "/orders",
              cta: "Mes commandes",
            },
            {
              title: "Formations & actualités",
              desc: "Sessions de formation continue, nouveautés produits et conditions commerciales en temps réel.",
              href: "/news",
              cta: "Découvrir",
            },
          ].map((card) => (
            <div key={card.title} className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
              <h3 className="text-lg font-semibold text-brand-700">{card.title}</h3>
              <p className="mt-2 text-sm text-slate-600">{card.desc}</p>
              <Link href={card.href} className="mt-4 inline-block text-sm font-medium text-brand-600 hover:text-brand-700">
                {card.cta} →
              </Link>
            </div>
          ))}
        </div>
      </section>

      <section className="bg-slate-50">
        <div className="mx-auto max-w-7xl px-4 py-16">
          <div className="flex items-end justify-between">
            <h2 className="text-2xl font-bold text-slate-800">Dernières actualités</h2>
            <Link href="/news" className="text-sm font-medium text-brand-600 hover:text-brand-700">
              Tout voir →
            </Link>
          </div>
          <div className="mt-8 grid gap-6 md:grid-cols-3">
            {latestNews.length === 0 ? (
              <p className="text-sm text-slate-500">Aucune actualité pour le moment.</p>
            ) : (
              latestNews.map((post) => (
                <article key={post.id} className="rounded-xl border border-slate-200 bg-white p-6">
                  <span className="text-xs font-medium uppercase tracking-wider text-accent-600">
                    {post.category}
                  </span>
                  <h3 className="mt-2 font-semibold text-slate-800">{post.title}</h3>
                  <p className="mt-2 text-sm text-slate-600">{post.excerpt}</p>
                  <Link href={`/news#${post.slug}`} className="mt-3 inline-block text-sm font-medium text-brand-600 hover:text-brand-700">
                    Lire la suite →
                  </Link>
                </article>
              ))
            )}
          </div>
        </div>
      </section>
    </>
  );
}
