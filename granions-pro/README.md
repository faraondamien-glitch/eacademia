# Granions Pro

Portail B2B original (Next.js 14 + Tailwind + Prisma/SQLite + NextAuth) pour un espace réservé aux professionnels de santé. Contenu, design et architecture rédigés de zéro.

## Démarrer

```bash
cd granions-pro
cp .env.example .env        # ajuster NEXTAUTH_SECRET
npm install
npx prisma db push          # crée la base SQLite
npm run db:seed             # crée le compte démo + catalogue + actus
npm run dev
```

Ouvrir http://localhost:3000

### Compte démo

- Email : `demo@pharmacie.fr`
- Mot de passe : `demo1234`

## Structure

- `app/` — pages App Router (accueil, login, register, dashboard, catalog, orders, news, contact)
- `app/api/` — routes API (auth, products, orders)
- `components/` — Navbar, Footer, SessionProvider
- `lib/` — client Prisma, config NextAuth
- `prisma/` — schéma et seed

## Stack

- Next.js 14 (App Router, Server Components)
- Tailwind CSS
- Prisma + SQLite (dev) — remplaçable par Postgres en prod
- NextAuth (Credentials provider, JWT)
- Zod (validation)
- bcryptjs (hash de mot de passe)

## Avertissement

Maquette fonctionnelle à but de démonstration : pas d'usage commercial direct, branding et contenu à valider/compléter avant mise en production.
