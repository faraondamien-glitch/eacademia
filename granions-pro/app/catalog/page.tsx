import { prisma } from "@/lib/prisma";
import CatalogClient from "./CatalogClient";

export default async function CatalogPage() {
  const products = await prisma.product.findMany({ orderBy: { name: "asc" } });
  const categories = Array.from(new Set(products.map((p) => p.category))).sort();
  return <CatalogClient products={products} categories={categories} />;
}
