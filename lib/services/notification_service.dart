import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/domain/user_model.dart';

// Doit être une fonction top-level (exigence Firebase Messaging)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé par le framework avant cet appel.
  // On ne peut pas afficher de notification locale ici sur iOS ; Android la
  // montre automatiquement si le manifest est configuré.
}

const _channelId = 'eacademia_main';
const _channelName = 'EACADEMIA';

class NotificationService {
  NotificationService._();

  static final _local = FlutterLocalNotificationsPlugin();
  static final _fcm = FirebaseMessaging.instance;

  // Référence au router injectée depuis EAcademiaApp.build
  static GoRouter? _router;
  static void setRouter(GoRouter router) => _router = router;

  // ── Initialisation ─────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    // Demande de permission (iOS / Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    // Canal Android haute importance
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications EACADEMIA',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init plugin local
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Tap sur notif locale → navigation
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          _router?.go(payload);
        }
      },
    );

    // Foreground : afficher une notif locale
    FirebaseMessaging.onMessage.listen(_onForeground);

    // App ouverte depuis notif (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    // App lancée depuis une notif (état killed)
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Délai court pour laisser le router s'initialiser
      await Future.delayed(const Duration(milliseconds: 600));
      _onOpened(initial);
    }
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  static void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    final route = _routeFromData(message.data);
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: route,
    );
  }

  static void _onOpened(RemoteMessage message) {
    final route = _routeFromData(message.data);
    _router?.go(route);
  }

  // ── Routing basé sur la data FCM ───────────────────────────────────────────

  static String _routeFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    return switch (type) {
      'formation' when id != null => '/formations/$id',
      'formation' => '/formations',
      'challenge' => '/challenges',
      'facture' => '/factures',
      'pack' when id != null => '/packs/$id',
      'pack' => '/packs',
      'pub' when id != null => '/pubs/$id',
      'pub' => '/pubs',
      _ => '/dashboard',
    };
  }

  // ── Token & topics ─────────────────────────────────────────────────────────

  /// Sauvegarde le token FCM dans le document Firestore de l'utilisateur.
  static Future<void> saveToken(String userId) async {
    final token = await _fcm.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(userId)
        .set({'fcmToken': token}, SetOptions(merge: true));

    // Mise à jour automatique si le token est renouvelé
    _fcm.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(userId)
          .set({'fcmToken': newToken}, SetOptions(merge: true));
    });
  }

  /// Abonne l'utilisateur aux topics FCM correspondant à son rôle.
  static Future<void> subscribeToTopics(UserRole role) async {
    // Topic commun à tous les utilisateurs
    await _fcm.subscribeToTopic(AppConstants.topicAll);

    // Topic spécifique au rôle
    final roleTopic = switch (role) {
      UserRole.pharmacien  => AppConstants.topicPharmacien,
      UserRole.preparateur => AppConstants.topicPharmacien, // même topic que pharmacien
      UserRole.medecin     => AppConstants.topicMedecin,
      UserRole.kine        => AppConstants.topicKine,
      UserRole.commercial  => AppConstants.topicCommercial,
    };
    await _fcm.subscribeToTopic(roleTopic);
  }

  /// Désabonnement (appel au logout)
  static Future<void> unsubscribeAll(UserRole role) async {
    await _fcm.unsubscribeFromTopic(AppConstants.topicAll);
    final roleTopic = switch (role) {
      UserRole.pharmacien  => AppConstants.topicPharmacien,
      UserRole.preparateur => AppConstants.topicPharmacien,
      UserRole.medecin     => AppConstants.topicMedecin,
      UserRole.kine        => AppConstants.topicKine,
      UserRole.commercial  => AppConstants.topicCommercial,
    };
    await _fcm.unsubscribeFromTopic(roleTopic);
  }

  static Future<String?> getToken() => _fcm.getToken();
}
