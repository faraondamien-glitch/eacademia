import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  const adminPwd = await bcrypt.hash("demo1234", 10);
  await prisma.user.upsert({
    where: { email: "demo@pharmacie.fr" },
    update: {},
    create: {
      email: "demo@pharmacie.fr",
      passwordHash: adminPwd,
      fullName: "Pharmacien Démo",
      pharmacyName: "Pharmacie de la Place",
      finessCode: "750000000",
      role: "PRO",
    },
  });

  const products = [
    {
      sku: "GRN-MAG-30",
      name: "Magnésium Marin 300 mg",
      category: "Oligo-éléments",
      shortDesc: "Fatigue passagère, équilibre nerveux.",
      description:
        "Complément alimentaire à base de magnésium marin hautement assimilable. Contribue à réduire la fatigue et au fonctionnement normal du système nerveux. 30 comprimés.",
      priceCents: 890,
      packSize: "30 comprimés",
      stock: 240,
    },
    {
      sku: "GRN-ZNC-60",
      name: "Zinc Bisglycinate",
      category: "Oligo-éléments",
      shortDesc: "Immunité, peau et phanères.",
      description:
        "Zinc sous forme bisglycinate pour une assimilation optimale. Contribue au fonctionnement normal du système immunitaire et au maintien d'une peau normale.",
      priceCents: 1190,
      packSize: "60 gélules",
      stock: 180,
    },
    {
      sku: "GRN-VITD-20",
      name: "Vitamine D3 1000 UI",
      category: "Vitamines",
      shortDesc: "Os, dents, immunité.",
      description:
        "Vitamine D3 cholécalciférol d'origine végétale. Contribue au maintien d'une ossature normale et au fonctionnement normal du système immunitaire.",
      priceCents: 990,
      packSize: "20 ml gouttes",
      stock: 320,
    },
    {
      sku: "GRN-FER-30",
      name: "Fer Liposomal",
      category: "Oligo-éléments",
      shortDesc: "Tonus, lutte contre la fatigue.",
      description:
        "Fer liposomé pour une meilleure tolérance digestive. Contribue à la formation normale des globules rouges et de l'hémoglobine.",
      priceCents: 1490,
      packSize: "30 gélules",
      stock: 140,
    },
    {
      sku: "GRN-OMG-60",
      name: "Oméga 3 EPA/DHA",
      category: "Acides gras",
      shortDesc: "Cœur, cerveau, vision.",
      description:
        "Huile de poisson sauvage purifiée, riche en EPA et DHA. Contribue à une fonction cardiaque normale.",
      priceCents: 1890,
      packSize: "60 capsules",
      stock: 95,
    },
    {
      sku: "GRN-PRB-14",
      name: "Probiotiques Confort+",
      category: "Microbiote",
      shortDesc: "Équilibre intestinal.",
      description:
        "Mélange de 8 souches microbiotiques, 10 milliards d'UFC par gélule. Cure de 14 jours.",
      priceCents: 1590,
      packSize: "14 gélules",
      stock: 200,
    },
    {
      sku: "GRN-MEL-30",
      name: "Mélatonine 1.9 mg",
      category: "Sommeil",
      shortDesc: "Endormissement, décalage horaire.",
      description:
        "Mélatonine dosée à 1.9 mg. Contribue à réduire le temps d'endormissement.",
      priceCents: 990,
      packSize: "30 comprimés",
      stock: 260,
    },
    {
      sku: "GRN-CRT-90",
      name: "Curcuma Bio Phytosome",
      category: "Phytothérapie",
      shortDesc: "Confort articulaire.",
      description:
        "Extrait de curcuma standardisé, technologie phytosome pour une biodisponibilité accrue.",
      priceCents: 2190,
      packSize: "90 gélules",
      stock: 75,
    },
  ];

  for (const p of products) {
    await prisma.product.upsert({
      where: { sku: p.sku },
      update: {},
      create: p,
    });
  }

  const news = [
    {
      title: "Nouvelle gamme microbiote disponible en officine",
      slug: "nouvelle-gamme-microbiote",
      excerpt:
        "Une formulation multi-souches pour répondre aux attentes croissantes de vos patients sur l'équilibre intestinal.",
      body:
        "Nous lançons une nouvelle ligne de probiotiques en pharmacie, formulée avec huit souches microbiotiques sélectionnées. Disponible dès ce mois-ci chez votre grossiste habituel et en commande directe sur l'espace pro.",
      category: "Lancement produit",
    },
    {
      title: "Formation continue : oligo-éléments et conseil officinal",
      slug: "formation-oligo-elements",
      excerpt:
        "Inscrivez-vous à la prochaine session de formation dédiée au conseil en oligothérapie.",
      body:
        "Sessions en visio de 1h30, ouvertes aux pharmaciens et préparateurs. Au programme : physiologie, indications, cas comptoir. Attestation délivrée en fin de session.",
      category: "Formation",
    },
    {
      title: "Conditions commerciales du second semestre",
      slug: "conditions-commerciales-s2",
      excerpt:
        "Découvrez les nouvelles remises de gamme et opérations promotionnelles à partir de juillet.",
      body:
        "Téléchargez le document récapitulatif dans votre espace pro. Votre délégué reste à votre disposition pour toute question.",
      category: "Commercial",
    },
  ];

  for (const n of news) {
    await prisma.newsPost.upsert({
      where: { slug: n.slug },
      update: {},
      create: n,
    });
  }

  console.log("Seed terminé.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
