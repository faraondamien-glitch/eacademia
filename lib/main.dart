import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/notification_service.dart';
import 'shared/providers/user_provider.dart';
import 'shared/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Le handler background ne fonctionne pas sur web
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Cache Firestore offline (non disponible sur web)
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Connexion automatique test sur web
  if (kIsWeb) {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'marc.petit@pharmacie-bellevue.fr',
        password: 'Demo1234!',
      );
    } catch (_) {}
  } else {
    await NotificationService.initialize();
  }

  runApp(const ProviderScope(child: EAcademiaApp()));
}

class EAcademiaApp extends ConsumerWidget {
  const EAcademiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Fournit la référence router au service de notifications pour la navigation
    NotificationService.setRouter(router);

    // Souscrit aux topics FCM et sauvegarde le token dès que l'utilisateur est connu
    ref.listen(userProvider, (prev, next) {
      if (next != null && prev?.uid != next.uid) {
        NotificationService.saveToken(next.uid);
        NotificationService.subscribeToTopics(next.role);
      }
      // Nettoyage au logout
      if (prev != null && next == null) {
        NotificationService.unsubscribeAll(prev.role);
      }
    });

    return MaterialApp.router(
      title: 'EACADEMIA — Granions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
