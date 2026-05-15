/// Configuration de l'intégration Opeaz (plateforme de gamification).
///
/// Remplir ces valeurs dès réception des credentials Opeaz :
///   - [apiKey]      → clé API fournie par Opeaz (header Authorization)
///   - [companyId]   → identifiant de votre société sur Opeaz
///   - [baseUrl]     → URL de base de votre instance Opeaz
///
/// Pour les obtenir :
///   1. Contactez votre interlocuteur Opeaz ou support@opeaz.com
///   2. Demandez un accès API avec les scopes :
///      challenges:read, rankings:read, users:read, rewards:read
///   3. Récupérez votre Company ID dans les paramètres de votre espace admin
class OpeazConfig {
  // ── À remplir avec vos credentials réels ─────────────────────────────────
  static const String apiKey = 'REPLACE_WITH_OPEAZ_API_KEY';
  static const String companyId = 'REPLACE_WITH_OPEAZ_COMPANY_ID';
  static const String baseUrl = 'https://api.opeaz.com'; // À confirmer avec Opeaz
  // ─────────────────────────────────────────────────────────────────────────

  /// Indique si les credentials réels sont configurés
  static bool get isConfigured =>
      apiKey != 'REPLACE_WITH_OPEAZ_API_KEY' &&
      companyId != 'REPLACE_WITH_OPEAZ_COMPANY_ID';
}
