import { prisma } from "@/lib/prisma";

export default async function NewsPage() {
  const posts = await prisma.newsPost.findMany({ orderBy: { createdAt: "desc" } });

  return (
    <div className="mx-auto max-w-4xl px-4 py-12">
      <h1 className="text-2xl font-bold text-slate-800">Actualités &amp; formations</h1>
      <p className="mt-1 text-sm text-slate-600">
        Lancements, conditions commerciales, sessions de formation continue.
      </p>

      <div className="mt-10 space-y-8">
        {posts.length === 0 ? (
          <p className="text-sm text-slate-500">Aucune actualité disponible.</p>
        ) : (
          posts.map((p) => (
            <article
              key={p.id}
              id={p.slug}
              className="scroll-mt-24 rounded-xl border border-slate-200 bg-white p-6"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium uppercase tracking-wider text-accent-600">
                  {p.category}
                </span>
                <span className="text-xs text-slate-500">
                  {p.createdAt.toLocaleDateString("fr-FR", {
                    day: "2-digit",
                    month: "long",
                    year: "numeric",
                  })}
                </span>
              </div>
              <h2 className="mt-3 text-xl font-semibold text-slate-800">{p.title}</h2>
              <p className="mt-2 text-sm text-slate-600">{p.excerpt}</p>
              <p className="mt-4 text-sm leading-relaxed text-slate-700">{p.body}</p>
            </article>
          ))
        )}
      </div>
    </div>
  );
}
