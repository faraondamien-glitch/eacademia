import type { Metadata } from "next";
import "./globals.css";
import Providers from "@/components/SessionProvider";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Granions Pro — Espace professionnels de santé",
  description:
    "Portail réservé aux pharmaciens et professionnels de santé : catalogue, commandes, formations et actualités Granions.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body className="flex min-h-screen flex-col">
        <Providers>
          <Navbar />
          <main className="flex-1">{children}</main>
          <Footer />
        </Providers>
      </body>
    </html>
  );
}
