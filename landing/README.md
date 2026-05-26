# Granions Longévité — Landing page

Single-page marketing site pour le complément alimentaire **Granions Longévité**.

Inspiré de la page Gamma `granions-longevite-l4cx84u.gamma.site` (le contenu a été réécrit ici, l'URL d'origine n'étant pas accessible depuis l'environnement).

## Stack

- Next.js 16 (App Router, static export)
- React 19
- TypeScript
- Tailwind CSS v4 (via `@tailwindcss/postcss`)
- `lucide-react` pour les icônes

## Démarrer

```bash
cd landing
npm install
npm run dev
```

Ouvrir <http://localhost:3000>.

## Build statique

```bash
npm run build
```

L'export statique est généré dans `landing/out/` (config `output: 'export'`), déployable sur n'importe quel CDN.

## Structure

```
landing/
├── app/
│   ├── layout.tsx       # Polices Inter + Fraunces, metadata
│   ├── page.tsx         # Composition des sections
│   └── globals.css      # Variables CSS, theme Tailwind, animations
└── components/
    ├── header.tsx       # Nav sticky
    ├── hero.tsx         # Titre + flacon stylisé en CSS pur
    ├── marquee.tsx      # Bandeau presse
    ├── benefits.tsx     # 4 piliers (énergie, mémoire, cardio, peau)
    ├── formula.tsx      # Tableau de composition
    ├── protocol.tsx     # 3 étapes (bilan, cure, suivi)
    ├── testimonials.tsx # 3 avis vérifiés
    ├── offer.tsx        # 3 plans tarifaires
    ├── faq.tsx          # 5 questions en <details>
    ├── final-cta.tsx    # CTA de fin
    └── footer.tsx
```

## Palette

| Token       | Valeur     | Usage                              |
| ----------- | ---------- | ---------------------------------- |
| primary     | `#1f4d3a`  | Vert profond (nature, sérieux)     |
| accent      | `#c9a86a`  | Or doux (haut de gamme)            |
| background  | `#fbf8f3`  | Crème chaud                        |
| surface-warm| `#f3ece0`  | Sections alternées                 |

## Notes

- Le flacon du Hero est entièrement rendu en CSS — pas d'image externe à charger.
- Les sections sont des composants serveur (pas de `'use client'`) : tout est statique.
- L'accordéon FAQ utilise `<details>` natif, donc fonctionne sans JS.
