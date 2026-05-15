class AppConstants {
  AppConstants._();

  // Layout breakpoints
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1200.0;

  // Firestore collections
  static const String colUsers = 'users';
  static const String colFormations = 'formations';
  static const String colProgress = 'progress';
  static const String colProduits = 'produits';
  static const String colPubs = 'pubs';
  static const String colPacks = 'packs';
  static const String colOrders = 'orders';
  static const String colChallenges = 'challenges';
  static const String colParticipants = 'participants';
  static const String colFactures = 'factures';
  static const String colNotifications = 'notifications';
  static const String colLaboContent = 'labo_content';

  // Secure storage keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';

  // Durée badge "NOUVEAU" en jours
  static const int newBadgeDays = 30;

  // Pagination
  static const int pageSize = 20;

  // FCM topics
  static const String topicAll = 'all';
  static const String topicPharmacien = 'pharmacien';
  static const String topicMedecin = 'medecin';
  static const String topicKine = 'kine';
  static const String topicCommercial = 'commercial';
}
