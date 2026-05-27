import { redirect } from "next/navigation";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export default async function OrdersPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect("/login");

  const userId = (session.user as { id: string }).id;
  const orders = await prisma.order.findMany({
    where: { userId },
    include: { items: { include: { product: true } } },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div className="mx-auto max-w-7xl px-4 py-12">
      <h1 className="text-2xl font-bold text-slate-800">Mes commandes</h1>
      <p className="mt-1 text-sm text-slate-600">
        Historique complet de vos commandes passées sur l'espace pro.
      </p>

      {orders.length === 0 ? (
        <p className="mt-10 rounded-lg border border-dashed border-slate-300 bg-slate-50 px-6 py-12 text-center text-sm text-slate-500">
          Vous n'avez pas encore passé de commande.
        </p>
      ) : (
        <div className="mt-8 space-y-4">
          {orders.map((o) => (
            <details
              key={o.id}
              className="group rounded-xl border border-slate-200 bg-white p-5 open:shadow-sm"
            >
              <summary className="flex cursor-pointer list-none items-center justify-between gap-4">
                <div>
                  <div className="font-mono text-xs text-slate-500">#{o.id.slice(0, 8)}</div>
                  <div className="mt-1 font-semibold text-slate-800">
                    {o.createdAt.toLocaleDateString("fr-FR", {
                      day: "2-digit",
                      month: "long",
                      year: "numeric",
                    })}
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-700">
                    {o.status}
                  </span>
                  <span className="text-lg font-semibold text-brand-700">
                    {(o.totalCents / 100).toFixed(2)} €
                  </span>
                  <span className="text-slate-400 group-open:rotate-180">▾</span>
                </div>
              </summary>

              <table className="mt-4 min-w-full divide-y divide-slate-100 text-sm">
                <thead className="text-left text-xs uppercase tracking-wider text-slate-500">
                  <tr>
                    <th className="py-2">Produit</th>
                    <th className="py-2">SKU</th>
                    <th className="py-2 text-right">Quantité</th>
                    <th className="py-2 text-right">PU</th>
                    <th className="py-2 text-right">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {o.items.map((it) => (
                    <tr key={it.id}>
                      <td className="py-2">{it.product.name}</td>
                      <td className="py-2 font-mono text-xs text-slate-500">{it.product.sku}</td>
                      <td className="py-2 text-right">{it.quantity}</td>
                      <td className="py-2 text-right">{(it.priceCents / 100).toFixed(2)} €</td>
                      <td className="py-2 text-right">
                        {((it.priceCents * it.quantity) / 100).toFixed(2)} €
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </details>
          ))}
        </div>
      )}
    </div>
  );
}
