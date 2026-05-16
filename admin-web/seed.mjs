/**
 * Script de seed v2 – champs alignés sur les modèles Flutter.
 * Usage : node seed.mjs
 */

import { initializeApp } from 'firebase/app';
import {
  getAuth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
} from 'firebase/auth';
import {
  getFirestore,
  collection,
  doc,
  setDoc,
  addDoc,
  getDocs,
  deleteDoc,
  Timestamp,
  query,
  where,
} from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyAEyipri8FOQ9KojuAhqAhU8Aaie1LH5Po',
  authDomain: 'eacademia-app.firebaseapp.com',
  projectId: 'eacademia-app',
  storageBucket: 'eacademia-app.firebasestorage.app',
  messagingSenderId: '893780722918',
  appId: '1:893780722918:web:e6f718bf82f5b05c046727',
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return Timestamp.fromDate(d);
}

async function clearCollection(colName) {
  const snap = await getDocs(collection(db, colName));
  for (const d of snap.docs) await deleteDoc(d.ref);
  console.log(`  🗑  ${colName} vidée (${snap.size} docs supprimés)`);
}

// ─── DONNÉES ────────────────────────────────────────────────────────────────

const USERS = [
  { email: 'sophie.martin@pharmacie-centrale.fr', password: 'Demo1234!', name: 'Sophie Martin',  role: 'pharmacien', region: 'Île-de-France',          level: 'Or',      points: 2340, isAdmin: false },
  { email: 'thomas.bernard@cabinet-med.fr',       password: 'Demo1234!', name: 'Thomas Bernard', role: 'medecin',    region: 'Auvergne-Rhône-Alpes',    level: 'Argent',  points: 1560, isAdmin: false },
  { email: 'claire.dupont@pharmacie-dupont.fr',   password: 'Demo1234!', name: 'Claire Dupont',  role: 'pharmacien', region: 'Occitanie',                level: 'Bronze',  points: 890,  isAdmin: false },
  { email: 'julien.moreau@kine-sport.fr',         password: 'Demo1234!', name: 'Julien Moreau',  role: 'kine',       region: 'Nouvelle-Aquitaine',       level: 'Or',      points: 3100, isAdmin: false },
  { email: 'camille.leroy@granions.fr',           password: 'Demo1234!', name: 'Camille Leroy',  role: 'commercial', region: 'Grand Est',                level: 'Platine', points: 4200, isAdmin: false },
  { email: 'marc.petit@pharmacie-bellevue.fr',    password: 'Demo1234!', name: 'Marc Petit',     role: 'pharmacien', region: 'Bretagne',                 level: 'Argent',  points: 1200, isAdmin: false },
  { email: 'lucie.garcia@cabinet-garcia.fr',      password: 'Demo1234!', name: 'Lucie Garcia',   role: 'medecin',    region: 'PACA',                     level: 'Bronze',  points: 450,  isAdmin: false },
  { email: 'antoine.roux@granions.fr',            password: 'Demo1234!', name: 'Antoine Roux',   role: 'commercial', region: 'Hauts-de-France',          level: 'Or',      points: 2900, isAdmin: true  },
];

// Produits — champs exacts du ProduitModel Flutter
const PRODUITS = [
  {
    id: 'granions-zinc',
    name: 'Granions de Zinc',
    range: 'Oligo-éléments',
    description: 'Le Zinc contribue au fonctionnement normal du système immunitaire et à la protection des cellules contre le stress oxydatif. Formule unique en solution buvable, hautement biodisponible.',
    composition: 'Gluconate de zinc 15 mg, Eau purifiée, Glycérol',
    indications: 'Système immunitaire · Peau et ongles · Vision · Fertilité',
    contraindications: 'Déconseillé en cas de traitement par antibiotiques (quinolones, tétracyclines). Ne pas dépasser la dose journalière recommandée.',
    tags: ['immunité', 'zinc', 'peau', 'oligoélément'],
    thumbnailUrl: 'https://images.unsplash.com/photo-1550572017-ea058cb8afe0?w=400',
    fichePdfUrl: '',
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
  {
    id: 'granions-magnesium',
    name: 'Granions Magnésium Marin',
    range: 'Minéraux',
    description: 'Le Magnésium contribue à réduire la fatigue et à un fonctionnement normal du système nerveux. Triple source de magnésium marin pour une absorption optimale toute la journée.',
    composition: 'Gluconate de magnésium 30 mg, Magnésium marin 100 mg, Vitamine B6 1,4 mg, Taurine 50 mg',
    indications: 'Fatigue · Stress · Sommeil · Crampes musculaires',
    contraindications: 'Insuffisance rénale sévère. Consulter un médecin en cas de traitement médicamenteux.',
    tags: ['magnésium', 'fatigue', 'stress', 'sommeil', 'nouveau'],
    thumbnailUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400',
    fichePdfUrl: '',
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
  {
    id: 'granions-selenium',
    name: 'Granions de Sélénium',
    range: 'Oligo-éléments',
    description: 'Le Sélénium contribue au maintien de cheveux normaux et à la protection des cellules contre le stress oxydatif. Source naturelle de sélénium organique.',
    composition: 'L-Sélénométhionine 50 µg, Vitamine E 12 mg',
    indications: 'Antioxydant · Cheveux et ongles · Thyroïde · Immunité',
    contraindications: 'Ne pas associer à d\'autres compléments contenant du sélénium. Grossesse : consulter un médecin.',
    tags: ['sélénium', 'antioxydant', 'cheveux', 'thyroïde'],
    thumbnailUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
    fichePdfUrl: '',
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
  {
    id: 'granions-cuivre',
    name: 'Granions de Cuivre',
    range: 'Oligo-éléments',
    description: 'Le Cuivre contribue au maintien des tissus conjonctifs normaux et au fonctionnement normal du système immunitaire. Recommandé en automne et hiver.',
    composition: 'Gluconate de cuivre 2 mg, Eau purifiée',
    indications: 'Articulations · Immunité · Pigmentation · Anti-infectieux',
    contraindications: 'Maladie de Wilson. Ne pas associer à des compléments à forte dose de Zinc sans avis médical.',
    tags: ['cuivre', 'articulations', 'immunité', 'oligoélément'],
    thumbnailUrl: 'https://images.unsplash.com/photo-1576086213369-97a306d36557?w=400',
    fichePdfUrl: '',
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
  {
    id: 'granions-vitamine-c',
    name: 'Granions Vitamine C 1000',
    range: 'Vitamines',
    description: 'La Vitamine C contribue à réduire la fatigue et à protéger les cellules contre le stress oxydatif. Formule liposomale brevetée pour une biodisponibilité maximale.',
    composition: 'Acide L-ascorbique 1000 mg, Lécithine de tournesol (liposomes)',
    indications: 'Fatigue · Immunité · Antioxydant · Synthèse du collagène',
    contraindications: 'Lithiase rénale oxalique. Hemochromatose. Drépanocytose.',
    tags: ['vitamine C', 'immunité', 'fatigue', 'antioxydant', 'nouveau'],
    thumbnailUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
    fichePdfUrl: '',
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
  {
    id: 'granions-manganese',
    name: 'Granions de Manganèse',
    range: 'Oligo-éléments',
    description: 'Le Manganèse contribue à un métabolisme énergétique normal et à la protection des cellules contre le stress oxydatif. Souvent associé au Zinc et au Cuivre.',
    composition: 'Gluconate de manganèse 2 mg, Eau purifiée',
    indications: 'Métabolisme · Antioxydant · Os et cartilages',
    contraindications: 'Insuffisance hépatique sévère. Pathologies du système nerveux.',
    tags: ['manganèse', 'métabolisme', 'os', 'oligoélément'],
    thumbnailUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400',
    fichePdfUrl: '',
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
];

// Pubs — champs exacts du PubModel Flutter
const PUBS = [
  {
    id: 'pub-zinc-immunite',
    title: 'Granions Zinc – Votre allié immunité',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    thumbnailUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600',
    channels: ['TF1', 'M6', 'France 2'],
    broadcastDate: daysAgo(90),
    isActive: true,
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
  {
    id: 'pub-magnesium-stress',
    title: 'Granions Magnésium Marin – Zéro stress',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    thumbnailUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=600',
    channels: ['YouTube', 'Instagram', 'TF1'],
    broadcastDate: daysAgo(30),
    isActive: true,
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
  {
    id: 'pub-gamme-complete',
    title: 'Granions – La gamme complète des oligo-éléments',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    thumbnailUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600',
    channels: ['Institutionnel'],
    broadcastDate: daysAgo(180),
    isActive: true,
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
];

// Packs — champs exacts du PackModel Flutter
const PACKS = [
  {
    id: 'pack-vitalite-printemps',
    name: 'Pack Vitalité Printemps',
    icon: '🌱',
    items: [
      { name: 'Granions de Zinc (30 ampoules)',          quantity: 1, unitPrice: 14.90 },
      { name: 'Granions Magnésium Marin (30 ampoules)',  quantity: 1, unitPrice: 16.50 },
      { name: 'Granions Vitamine C 1000 (20 sachets)',   quantity: 1, unitPrice: 22.90 },
    ],
    totalPrice: 54.30,
    discountPercent: 18.0,
    targetRoles: ['pharmacien', 'commercial'],
  },
  {
    id: 'pack-immunite-hiver',
    name: 'Pack Immunité Hiver',
    icon: '🛡️',
    items: [
      { name: 'Granions de Zinc (30 ampoules)',      quantity: 1, unitPrice: 14.90 },
      { name: 'Granions de Sélénium (30 ampoules)', quantity: 1, unitPrice: 15.20 },
      { name: 'Granions de Cuivre (30 ampoules)',   quantity: 1, unitPrice: 13.80 },
    ],
    totalPrice: 43.90,
    discountPercent: 14.0,
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
  {
    id: 'pack-stress-sommeil',
    name: 'Pack Stress & Sommeil',
    icon: '😴',
    items: [
      { name: 'Granions Magnésium Marin Complexe (30 ampoules)', quantity: 1, unitPrice: 16.50 },
      { name: 'Granions Mélatonine Retard 1,9 mg (30 comprimés)', quantity: 1, unitPrice: 21.90 },
    ],
    totalPrice: 38.40,
    discountPercent: 17.0,
    targetRoles: ['pharmacien', 'medecin', 'kine', 'commercial'],
  },
];

// Challenges
const CHALLENGES = [
  {
    id: 'challenge-zinc-q2',
    title: 'Sprint Zinc Q2',
    description: 'Atteignez votre objectif de vente Granions Zinc sur le 2ème trimestre. Les 3 premiers remportent des Granions Points et une formation offerte.',
    category: 'vente',
    objective: 1000,
    unit: 'boîtes vendues',
    rewardPoints: 500,
    rewardType: 'points',
    startDate: daysAgo(45),
    endDate: daysAgo(-15),
    status: 'active',
    participants: 47,
    opeazId: 'ch_zinc_q2_2026',
  },
  {
    id: 'challenge-magnesium-lancement',
    title: 'Lancement Magnésium Marin',
    description: 'Participez au lancement de la nouvelle formule Magnésium Marin Complexe : atteignez 200 ventes en mai.',
    category: 'vente',
    objective: 200,
    unit: 'boîtes vendues',
    rewardPoints: 250,
    rewardType: 'points',
    startDate: daysAgo(16),
    endDate: daysAgo(-14),
    status: 'active',
    participants: 32,
    opeazId: 'ch_mag_launch_2026',
  },
  {
    id: 'challenge-formation-immunite',
    title: 'Expert Immunité',
    description: 'Complétez les 3 modules de formation sur les oligo-éléments et l\'immunité pour décrocher le badge Expert.',
    category: 'formation',
    objective: 3,
    unit: 'modules complétés',
    rewardPoints: 300,
    rewardType: 'badge',
    startDate: daysAgo(30),
    endDate: daysAgo(-30),
    status: 'active',
    participants: 89,
    opeazId: 'ch_expert_immunite_2026',
  },
  {
    id: 'challenge-selenium-q1',
    title: 'Challenge Sélénium Q1',
    description: 'Challenge du premier trimestre 2026 sur les ventes de Granions Sélénium – terminé.',
    category: 'vente',
    objective: 800,
    unit: 'boîtes vendues',
    rewardPoints: 400,
    rewardType: 'points',
    startDate: daysAgo(120),
    endDate: daysAgo(1),
    status: 'completed',
    participants: 51,
    winner: 'Julien Moreau',
    opeazId: 'ch_selenium_q1_2026',
  },
];

const ACTUALITES = [
  {
    title: 'Lancement Granions Magnésium Marin Complexe',
    body: 'Nous avons le plaisir de vous présenter notre nouvelle formule enrichie en magnésium marin, vitamine B6 et taurine. Idéale pour les périodes de stress et de fatigue, cette formule innovante offre une absorption optimale grâce à sa triple association de sources de magnésium. Disponible dès maintenant en pharmacie.',
    category: 'produit',
    author: 'Équipe Granions',
    imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800',
    targetRoles: [],
    isPinned: true,
    publishedAt: daysAgo(2),
  },
  {
    title: 'Formation : Oligo-éléments et immunité – 3 nouveaux modules',
    body: 'Trois nouveaux modules e-learning sont désormais accessibles : "Le rôle du Zinc dans l\'immunité", "Sélénium et défenses antioxydantes" et "Cuivre et résistance aux infections". Chaque module compte pour votre progression et vos points de challenge.',
    category: 'info',
    author: 'Direction Formation',
    imageUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
    targetRoles: ['pharmacien', 'medecin'],
    isPinned: true,
    publishedAt: daysAgo(5),
  },
  {
    title: 'Challenge Q2 – Sprint Zinc : les résultats mi-parcours',
    body: 'À mi-parcours du challenge Sprint Zinc, Sophie Martin (Île-de-France) prend la tête du classement avec 847 boîtes vendues, suivie de Marc Petit (Bretagne) avec 693 boîtes. Le challenge se termine le 30 juin. Les 3 premiers gagnent une formation offerte et des Granions Points bonus.',
    category: 'commercial',
    author: 'Direction Commerciale',
    imageUrl: null,
    targetRoles: ['pharmacien', 'commercial'],
    isPinned: false,
    publishedAt: daysAgo(8),
  },
  {
    title: 'Étude clinique : Granions Sélénium et fatigue chronique',
    body: 'Une nouvelle étude publiée dans le Journal of Trace Elements in Medicine and Biology confirme l\'efficacité de notre formule sélénium organique dans la réduction de la fatigue chronique. L\'étude portant sur 240 patients montre une amélioration significative dès 4 semaines. Document complet dans la section Labo.',
    category: 'sante',
    author: 'Dr. Marie Fontaine – Directrice R&D',
    imageUrl: 'https://images.unsplash.com/photo-1576086213369-97a306d36557?w=800',
    targetRoles: ['medecin', 'pharmacien'],
    isPinned: false,
    publishedAt: daysAgo(12),
  },
  {
    title: 'Événement : Congrès Officinal – Stand Granions Hall B42',
    body: 'Retrouvez-nous au Congrès de l\'Officine 2026 les 19 et 20 juin à Paris Expo Porte de Versailles. Stand B42 : démonstrations des nouvelles gammes, ateliers conseil en oligo-éléments, et surprises pour les professionnels de santé.',
    category: 'evenement',
    author: 'Équipe Marketing',
    imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
    targetRoles: [],
    isPinned: false,
    publishedAt: daysAgo(15),
  },
  {
    title: 'Offre Pack Printemps – Conditions exceptionnelles jusqu\'au 30 juin',
    body: 'Bénéficiez de conditions tarifaires privilégiées sur notre Pack Vitalité Printemps : -18% pour toute commande de 6 boîtes minimum. Offre exclusivement réservée aux pharmacies partenaires EACADEMIA.',
    category: 'commercial',
    author: 'Direction Commerciale',
    imageUrl: null,
    targetRoles: ['pharmacien'],
    isPinned: false,
    publishedAt: daysAgo(20),
  },
  {
    title: 'Référentiel produit 2026 mis à jour',
    body: 'Le référentiel produit Granions 2026 est disponible dans la section Produits. Il intègre les nouvelles fiches techniques, les données ANSM actualisées et les argumentaires de vente révisés pour l\'ensemble de notre gamme.',
    category: 'info',
    author: 'Équipe Granions',
    imageUrl: null,
    targetRoles: [],
    isPinned: false,
    publishedAt: daysAgo(25),
  },
  {
    title: 'Webinaire phyto-aromathérapie – Inscription ouverte',
    body: 'Inscrivez-vous au webinaire "Phyto-aromathérapie et compléments minéraux" animé par le Dr. Claire Renaud le 28 mai à 18h30. Durée : 1h30. Places limitées à 50 participants. Attestation de formation remise à l\'issue.',
    category: 'evenement',
    author: 'Direction Formation',
    imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
    targetRoles: ['pharmacien', 'medecin', 'kine'],
    isPinned: false,
    publishedAt: daysAgo(30),
  },
];

const NOTIFICATIONS_HISTORY = [
  { title: 'Nouveaux modules de formation disponibles', body: '3 nouveaux modules sur les oligo-éléments et l\'immunité sont disponibles dans EACADEMIA.', target: 'all', type: 'formation', status: 'sent', sentBy: 'admin', sentAt: daysAgo(5) },
  { title: 'Sprint Zinc – Mi-parcours !', body: 'À mi-parcours du challenge Sprint Zinc, consultez votre classement dans EACADEMIA.', target: 'pharmacien', type: 'challenge', status: 'sent', sentBy: 'admin', sentAt: daysAgo(8) },
  { title: 'Nouvelle facture disponible', body: 'Votre facture est disponible dans votre espace EACADEMIA.', target: 'all', type: 'facture', status: 'sent', sentBy: 'admin', sentAt: daysAgo(25) },
];

// ─── SEED ───────────────────────────────────────────────────────────────────

async function seed() {
  console.log('🌱 Connexion à Firebase…');
  await signInWithEmailAndPassword(auth, 'test@eacademia.fr', 'Test1234!');
  console.log('✅ Connecté\n');

  // ── Nettoyage des collections
  console.log('🗑  Nettoyage…');
  await clearCollection('produits');
  await clearCollection('pubs');
  await clearCollection('packs');
  await clearCollection('commandes');
  await clearCollection('factures');
  await clearCollection('challenges');
  await clearCollection('leaderboard');
  await clearCollection('actualites');
  await clearCollection('notification_queue');

  // ── Users
  console.log('\n👥 Création des utilisateurs…');
  const userUids = {};
  for (const u of USERS) {
    try {
      const cred = await createUserWithEmailAndPassword(auth, u.email, u.password);
      await setDoc(doc(db, 'users', cred.user.uid), {
        name: u.name, email: u.email, role: u.role, region: u.region,
        level: u.level, points: u.points, isAdmin: u.isAdmin,
        createdAt: Timestamp.now(),
      });
      userUids[u.name] = cred.user.uid;
      console.log(`  ✅ ${u.name}`);
    } catch (e) {
      if (e.code === 'auth/email-already-in-use') {
        // Récupère l'UID depuis Firestore par email
        const snap = await getDocs(query(collection(db, 'users'), where('email', '==', u.email)));
        if (!snap.empty) userUids[u.name] = snap.docs[0].id;
        console.log(`  ⏭  ${u.name} (déjà existant)`);
      } else {
        console.error(`  ❌ ${u.name}: ${e.message}`);
      }
    }
    await signInWithEmailAndPassword(auth, 'test@eacademia.fr', 'Test1234!');
  }

  // ── Actualités
  console.log('\n📰 Actualités…');
  for (const a of ACTUALITES) {
    await addDoc(collection(db, 'actualites'), a);
    console.log(`  ✅ ${a.title.slice(0, 55)}`);
  }

  // ── Produits (champs ProduitModel)
  console.log('\n💊 Produits…');
  for (const p of PRODUITS) {
    await setDoc(doc(db, 'produits', p.id), { ...p, createdAt: Timestamp.now() });
    console.log(`  ✅ ${p.name}`);
  }

  // ── Pubs (champs PubModel)
  console.log('\n📺 Pubs…');
  for (const p of PUBS) {
    await setDoc(doc(db, 'pubs', p.id), { ...p });
    console.log(`  ✅ ${p.title}`);
  }

  // ── Packs (champs PackModel)
  console.log('\n📦 Packs…');
  for (const p of PACKS) {
    await setDoc(doc(db, 'packs', p.id), { ...p, createdAt: Timestamp.now() });
    console.log(`  ✅ ${p.name}`);
  }

  // ── Commandes (champs attendus par AdminCommandesScreen)
  console.log('\n🛒 Commandes…');
  const COMMANDES = [
    { packId: 'pack-vitalite-printemps', packTitle: 'Pack Vitalité Printemps', userName: 'Sophie Martin',  userRegion: 'Île-de-France',       quantity: 12, total: 534.0,  status: 'confirmed', comment: 'Livraison avant le 20 mai SVP.',                                      createdAt: daysAgo(3)  },
    { packId: 'pack-immunite-hiver',     packTitle: 'Pack Immunité Hiver',      userName: 'Marc Petit',     userRegion: 'Bretagne',             quantity: 6,  total: 227.4,  status: 'pending',   comment: '',                                                                   createdAt: daysAgo(1)  },
    { packId: 'pack-stress-sommeil',     packTitle: 'Pack Stress & Sommeil',    userName: 'Claire Dupont',  userRegion: 'Occitanie',            quantity: 8,  total: 255.2,  status: 'pending',   comment: 'Confirmer la disponibilité du Mélatonine avant validation.',          createdAt: daysAgo(0)  },
    { packId: 'pack-vitalite-printemps', packTitle: 'Pack Vitalité Printemps', userName: 'Julien Moreau',  userRegion: 'Nouvelle-Aquitaine',   quantity: 4,  total: 178.0,  status: 'confirmed', comment: '',                                                                   createdAt: daysAgo(7)  },
    { packId: 'pack-immunite-hiver',     packTitle: 'Pack Immunité Hiver',      userName: 'Lucie Garcia',   userRegion: 'PACA',                 quantity: 3,  total: 113.7,  status: 'cancelled', comment: 'Budget non disponible ce mois-ci, à reporter en septembre.',         createdAt: daysAgo(14) },
    { packId: 'pack-stress-sommeil',     packTitle: 'Pack Stress & Sommeil',    userName: 'Thomas Bernard', userRegion: 'Auvergne-Rhône-Alpes', quantity: 5,  total: 159.5,  status: 'confirmed', comment: '',                                                                   createdAt: daysAgo(10) },
  ];
  for (const c of COMMANDES) {
    await addDoc(collection(db, 'commandes'), c);
    console.log(`  ✅ ${c.packTitle} – ${c.userName}`);
  }

  // ── Factures (champs FactureModel : userId, reference, date, amount, status, pdfUrl)
  console.log('\n🧾 Factures…');
  const sophieUid  = userUids['Sophie Martin']  ?? 'unknown';
  const julienUid  = userUids['Julien Moreau']  ?? 'unknown';
  const thomasUid  = userUids['Thomas Bernard'] ?? 'unknown';
  const marcUid    = userUids['Marc Petit']     ?? 'unknown';
  const claireUid  = userUids['Claire Dupont']  ?? 'unknown';
  // On attribue aussi des factures au compte test
  const FACTURES = [
    { userId: sophieUid, reference: 'FAC-2026-0412', date: daysAgo(3),  amount: 534.0,  status: 'paid',    pdfUrl: '' },
    { userId: julienUid, reference: 'FAC-2026-0408', date: daysAgo(7),  amount: 178.0,  status: 'paid',    pdfUrl: '' },
    { userId: thomasUid, reference: 'FAC-2026-0401', date: daysAgo(10), amount: 159.5,  status: 'pending', pdfUrl: '' },
    { userId: marcUid,   reference: 'FAC-2026-0389', date: daysAgo(25), amount: 321.6,  status: 'paid',    pdfUrl: '' },
    { userId: claireUid, reference: 'FAC-2026-0375', date: daysAgo(40), amount: 89.4,   status: 'pending', pdfUrl: '' },
  ];
  for (const f of FACTURES) {
    await addDoc(collection(db, 'factures'), f);
    console.log(`  ✅ ${f.reference}`);
  }

  // ── Challenges
  console.log('\n🏆 Challenges…');
  for (const c of CHALLENGES) {
    await setDoc(doc(db, 'challenges', c.id), c);
    console.log(`  ✅ ${c.title}`);
  }

  // ── Leaderboard
  console.log('\n📊 Classement…');
  const LEADERBOARD = [
    { userName: 'Sophie Martin',  region: 'Île-de-France',          score: 847, points: 2340, rank: 1, challengeId: 'challenge-zinc-q2' },
    { userName: 'Marc Petit',     region: 'Bretagne',                score: 693, points: 1560, rank: 2, challengeId: 'challenge-zinc-q2' },
    { userName: 'Julien Moreau',  region: 'Nouvelle-Aquitaine',      score: 612, points: 3100, rank: 3, challengeId: 'challenge-zinc-q2' },
    { userName: 'Camille Leroy',  region: 'Grand Est',               score: 589, points: 4200, rank: 4, challengeId: 'challenge-zinc-q2' },
    { userName: 'Thomas Bernard', region: 'Auvergne-Rhône-Alpes',    score: 421, points: 1560, rank: 5, challengeId: 'challenge-zinc-q2' },
    { userName: 'Claire Dupont',  region: 'Occitanie',               score: 387, points: 890,  rank: 6, challengeId: 'challenge-zinc-q2' },
    { userName: 'Antoine Roux',   region: 'Hauts-de-France',         score: 312, points: 2900, rank: 7, challengeId: 'challenge-zinc-q2' },
    { userName: 'Lucie Garcia',   region: 'PACA',                    score: 201, points: 450,  rank: 8, challengeId: 'challenge-zinc-q2' },
  ];
  for (const e of LEADERBOARD) {
    await addDoc(collection(db, 'leaderboard'), { ...e, updatedAt: Timestamp.now() });
  }
  console.log(`  ✅ ${LEADERBOARD.length} entrées`);

  // ── Notifications
  console.log('\n🔔 Historique notifications…');
  for (const n of NOTIFICATIONS_HISTORY) {
    await addDoc(collection(db, 'notification_queue'), n);
    console.log(`  ✅ ${n.title}`);
  }

  console.log('\n🎉 Seed v2 terminé ! Toutes les données sont en place et correctement formatées.');
  process.exit(0);
}

seed().catch((e) => {
  console.error('❌ Erreur :', e.message);
  process.exit(1);
});
