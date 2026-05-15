/// Configuration de l'intégration 360Learning.
///
/// Remplir ces valeurs dès réception des credentials 360Learning :
///   - [apiKey]       → clé API fournie par 360Learning (header X-API-KEY)
///   - [companyGuid]  → GUID de votre compte entreprise (visible dans l'URL admin)
///   - [subdomain]    → sous-domaine de votre instance (ex: "granions")
///
/// Pour les obtenir :
///   1. Connectez-vous sur votre espace admin 360Learning
///   2. Paramètres → Intégrations → API → Générer une clé
///   3. Notez le GUID entreprise affiché dans l'URL admin
class Learning360Config {
  // ── À remplir avec vos credentials réels ─────────────────────────────────
  static const String apiKey = 'REPLACE_WITH_360LEARNING_API_KEY';
  static const String companyGuid = 'REPLACE_WITH_COMPANY_GUID';
  static const String subdomain = 'granions'; // ex: granions.360learning.com
  // ─────────────────────────────────────────────────────────────────────────

  static const String baseUrl = 'https://api.360learning.com';

  /// URL du player pour ouvrir une formation dans le navigateur
  static String playerUrl(String programGuid) =>
      'https://$subdomain.360learning.com/learner/course/$programGuid';

  /// Indique si les credentials réels sont configurés
  static bool get isConfigured =>
      apiKey != 'REPLACE_WITH_360LEARNING_API_KEY' &&
      companyGuid != 'REPLACE_WITH_COMPANY_GUID';
}
