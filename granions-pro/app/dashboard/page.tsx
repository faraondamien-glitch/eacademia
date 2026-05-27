import { redirect } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect("/login");

  const userId = (session.user as { id: string }).id;
  const [user, orders] = await Promise.all([
    prisma.user.findUnique({ where: { id: userId } }),
    prisma.order.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 5,
      include: { items: true },
    }),
  ]);

  return (
    <div className="mx-auto max-w-7xl px-4 py-12">
      <h1 className="text-2xl font-bold text-slate-800">
        Bonjour {user?.fullName?.split(" ")[0] ?? ""}
      </h1>
      <p className="mt-1 text-sm text-slate-600">
        {user?.pharmacyName ? `${user.pharmacyName} · ` : ""}{user?.email}
      </p>

      <div className="mt-8 grid gap-4 md:grid-cols-3">
        <StatCard label="Commandes totales" value={orders.length.toString()} />
        <StatCard label="Statut compte" value={user?.role ?? "PRO"} />
        <StatCard label="Code FINESS" value={user?.finessCode ?? "—"} />
      </div>

      <div className="mt-10 grid gap-6 md:grid-cols-3">
        <QuickLink href="/catalog" title="Catalogue" desc="Parcourir les références" />
        <QuickLink href="/orders" title="Mes commandes" desc="Historique et statuts" />
        <QuickLink href="/news" title="Actualités" desc="Lancements et formations" />
      </div>

      <section className="mt-10">
        <div className="flex items-end justify-between">
          <h2 className="text-lg font-semibold text-slate-800">Dernières commandes</h2>
          <Link href="/orders" className="text-sm font-medium text-brand-600 hover:text-brand-700">
            Tout voir →
          </Link>
        </div>
        <div className="mt-4 overflow-hidden rounded-lg border border-slate-200">
          <table className="min-w-full divide-y divide-slate-200 text-sm">
            <thead className="bg-slate-50 text-left text-xs uppercase tracking-wider text-slate-500">
              <tr>
                <th className="px-4 py-3">Référence</th>
                <th className="px-4 py-3">Date</th>
                <th className="px-4 py-3">Articles</th>
                <th className="px-4 py-3">Montant</th>
                <th className="px-4 py-3">Statut</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 bg-white">
              {orders.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-6 text-center text-slate-500">
                    Aucune commande pour le moment.
                  </td>
                </tr>
              ) : (
                orders.map((o) => (
                  <tr key={o.id}>
                    <td className="px-4 py-3 font-mono text-xs">{o.id.slice(0, 8)}</td>
                    <td className="px-4 py-3">{o.createdAt.toLocaleDateString("fr-FR")}</td>
                    <td className="px-4 py-3">{o.items.reduce((s, i) => s + i.quantity, 0)}</td>
                    <td className="px-4 py-3">{(o.totalCents / 100).toFixed(2)} €</td>
                    <td className="px-4 py-3">
                      <span className="rounded-full bg-brand-50 px-2 py-1 text-xs font-medium text-brand-700">
                        {o.status}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      <div className="text-xs uppercase tracking-wider text-slate-500">{label}</div>
      <div className="mt-2 text-2xl font-semibold text-slate-800">{value}</div>
    </div>
  );
}

function QuickLink({ href, title, desc }: { href: string; title: string; desc: string }) {
  return (
    <Link href={href} className="block rounded-xl border border-slate-200 bg-white p-5 hover:border-brand-400">
      <div className="font-semibold text-brand-700">{title}</div>
      <div className="mt-1 text-sm text-slate-600">{desc}</div>
    </Link>
  );
}
