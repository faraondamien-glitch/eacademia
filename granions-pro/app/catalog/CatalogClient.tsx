"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useSession } from "next-auth/react";

type Product = {
  id: string;
  sku: string;
  name: string;
  category: string;
  shortDesc: string;
  description: string;
  priceCents: number;
  packSize: string;
  stock: number;
};

export default function CatalogClient({
  products,
  categories,
}: {
  products: Product[];
  categories: string[];
}) {
  const router = useRouter();
  const { status } = useSession();
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState<string | null>(null);
  const [cart, setCart] = useState<Record<string, number>>({});
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const filtered = useMemo(() => {
    return products.filter((p) => {
      if (category && p.category !== category) return false;
      if (query) {
        const q = query.toLowerCase();
        return (
          p.name.toLowerCase().includes(q) ||
          p.sku.toLowerCase().includes(q) ||
          p.shortDesc.toLowerCase().includes(q)
        );
      }
      return true;
    });
  }, [products, query, category]);

  const cartItems = Object.entries(cart)
    .map(([id, qty]) => {
      const p = products.find((x) => x.id === id);
      return p ? { product: p, qty } : null;
    })
    .filter(Boolean) as { product: Product; qty: number }[];

  const total = cartItems.reduce((s, i) => s + i.product.priceCents * i.qty, 0);

  function addToCart(id: string) {
    setCart((c) => ({ ...c, [id]: (c[id] ?? 0) + 1 }));
  }

  function setQty(id: string, qty: number) {
    setCart((c) => {
      const next = { ...c };
      if (qty <= 0) delete next[id];
      else next[id] = qty;
      return next;
    });
  }

  async function submitOrder() {
    if (status !== "authenticated") {
      router.push("/login");
      return;
    }
    setSubmitting(true);
    setMessage(null);
    const items = cartItems.map((i) => ({ productId: i.product.id, quantity: i.qty }));
    const res = await fetch("/api/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ items }),
    });
    setSubmitting(false);
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      setMessage(data.error ?? "Erreur lors de la commande.");
      return;
    }
    setCart({});
    setMessage("Commande envoyée avec succès. Retrouvez-la dans Mes commandes.");
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-12">
      <h1 className="text-2xl font-bold text-slate-800">Catalogue</h1>
      <p className="mt-1 text-sm text-slate-600">
        {products.length} références — réservé aux professionnels de santé.
      </p>

      <div className="mt-6 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <input
          type="search"
          placeholder="Rechercher un produit, un SKU..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="w-full rounded-md border border-slate-300 px-3 py-2 md:max-w-sm"
        />
        <div className="flex flex-wrap gap-2">
          <CategoryChip active={category === null} onClick={() => setCategory(null)}>
            Toutes
          </CategoryChip>
          {categories.map((c) => (
            <CategoryChip key={c} active={category === c} onClick={() => setCategory(c)}>
              {c}
            </CategoryChip>
          ))}
        </div>
      </div>

      <div className="mt-8 grid gap-6 lg:grid-cols-[1fr_320px]">
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {filtered.map((p) => (
            <article key={p.id} className="flex flex-col rounded-xl border border-slate-200 bg-white p-5">
              <div className="flex items-start justify-between">
                <span className="text-xs font-medium uppercase tracking-wider text-accent-600">
                  {p.category}
                </span>
                <span className="text-xs text-slate-400">{p.sku}</span>
              </div>
              <h3 className="mt-2 font-semibold text-slate-800">{p.name}</h3>
              <p className="mt-1 text-sm text-slate-600">{p.shortDesc}</p>
              <div className="mt-3 text-xs text-slate-500">{p.packSize}</div>
              <div className="mt-auto flex items-center justify-between pt-4">
                <div className="text-lg font-semibold text-brand-700">
                  {(p.priceCents / 100).toFixed(2)} €
                </div>
                <button
                  onClick={() => addToCart(p.id)}
                  className="rounded-md bg-brand-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-brand-700"
                >
                  Ajouter
                </button>
              </div>
            </article>
          ))}
          {filtered.length === 0 && (
            <p className="col-span-full text-sm text-slate-500">Aucun produit ne correspond.</p>
          )}
        </div>

        <aside className="rounded-xl border border-slate-200 bg-white p-5 lg:sticky lg:top-20 lg:self-start">
          <h2 className="font-semibold text-slate-800">Panier</h2>
          {cartItems.length === 0 ? (
            <p className="mt-3 text-sm text-slate-500">Votre panier est vide.</p>
          ) : (
            <ul className="mt-3 space-y-3 text-sm">
              {cartItems.map(({ product, qty }) => (
                <li key={product.id} className="flex items-center justify-between gap-2">
                  <div className="min-w-0">
                    <div className="truncate font-medium text-slate-800">{product.name}</div>
                    <div className="text-xs text-slate-500">
                      {(product.priceCents / 100).toFixed(2)} € × {qty}
                    </div>
                  </div>
                  <input
                    type="number"
                    min={0}
                    value={qty}
                    onChange={(e) => setQty(product.id, parseInt(e.target.value || "0", 10))}
                    className="w-16 rounded-md border border-slate-300 px-2 py-1 text-right text-sm"
                  />
                </li>
              ))}
            </ul>
          )}
          <div className="mt-5 flex items-center justify-between border-t border-slate-100 pt-4">
            <span className="text-sm text-slate-600">Total HT</span>
            <span className="text-lg font-semibold text-brand-700">
              {(total / 100).toFixed(2)} €
            </span>
          </div>
          <button
            onClick={submitOrder}
            disabled={cartItems.length === 0 || submitting}
            className="mt-4 w-full rounded-md bg-brand-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50"
          >
            {submitting ? "Envoi..." : "Valider la commande"}
          </button>
          {message && <p className="mt-3 text-sm text-slate-600">{message}</p>}
        </aside>
      </div>
    </div>
  );
}

function CategoryChip({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className={
        active
          ? "rounded-full bg-brand-600 px-3 py-1 text-sm font-medium text-white"
          : "rounded-full border border-slate-300 bg-white px-3 py-1 text-sm text-slate-700 hover:border-brand-400"
      }
    >
      {children}
    </button>
  );
}
