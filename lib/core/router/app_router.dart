import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/formations/presentation/formations_screen.dart';
import '../../features/formations/presentation/formation_detail_screen.dart';
import '../../features/formations/data/learning360_repository.dart';
import '../../features/produits/presentation/produits_screen.dart';
import '../../features/produits/presentation/produit_detail_screen.dart';
import '../../features/pubs/presentation/pubs_screen.dart';
import '../../features/pubs/presentation/pub_player_screen.dart';
import '../../features/packs/presentation/packs_screen.dart';
import '../../features/packs/presentation/pack_detail_screen.dart';
import '../../features/packs/presentation/commande_form_screen.dart';
import '../../features/challenges/presentation/challenges_screen.dart';
import '../../features/factures/presentation/factures_screen.dart';
import '../../features/labo/presentation/labo_screen.dart';
import '../../features/actualites/presentation/actualites_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/admin/presentation/screens/admin_actualites_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_commandes_screen.dart';
import '../../features/produits/presentation/pdf_viewer_screen.dart';
import '../../features/equipe/presentation/equipe_screen.dart';
import '../../shared/providers/user_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _GoRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(userProvider);
      final isLoggedIn = user != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/dashboard';
      // Guard admin : routes /admin/* accessibles uniquement si isAdmin
      if (state.matchedLocation.startsWith('/admin')) {
        final user = ref.read(userProvider);
        if (user == null || !user.isAdmin) return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, s) => const LoginScreen(),
      ),
      // Viewer PDF plein-écran (sans barre de nav)
      GoRoute(
        path: '/pdf-viewer',
        name: 'pdf-viewer',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>;
          return PdfViewerScreen(url: extra['url']!, title: extra['title']!);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // ── Nav principale ─────────────────────────────────────────────
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (_, s) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/formations',
            name: 'formations',
            builder: (_, s) => const FormationsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'formation-detail',
                builder: (_, state) {
                  final extra = state.extra;
                  return FormationDetailScreen(
                    formationId: state.pathParameters['id']!,
                    preloaded:
                        extra is FormationWithProgress ? extra : null,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/challenges',
            name: 'challenges',
            builder: (_, s) => const ChallengesScreen(),
          ),
          GoRoute(
            path: '/menu',
            name: 'menu',
            builder: (_, s) => const MenuScreen(),
          ),

          // ── Features accessibles depuis le Menu ────────────────────────
          GoRoute(
            path: '/actualites',
            name: 'actualites',
            builder: (_, s) => const ActualitesScreen(),
          ),
          GoRoute(
            path: '/produits',
            name: 'produits',
            builder: (_, s) => const ProduitsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'produit-detail',
                builder: (_, state) => ProduitDetailScreen(
                  produitId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/pubs',
            name: 'pubs',
            builder: (_, s) => const PubsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'pub-player',
                builder: (_, state) =>
                    PubPlayerScreen(pubId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/packs',
            name: 'packs',
            builder: (_, s) => const PacksScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'pack-detail',
                builder: (_, state) =>
                    PackDetailScreen(packId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'commander',
                    name: 'commande',
                    builder: (_, state) => CommandeFormScreen(
                      packId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/factures',
            name: 'factures',
            builder: (_, s) => const FacturesScreen(),
          ),
          GoRoute(
            path: '/labo',
            name: 'labo',
            builder: (_, s) => const LaboScreen(),
          ),
          GoRoute(
            path: '/equipe',
            name: 'equipe',
            builder: (_, s) => const EquipeScreen(),
          ),

          // ── Section Administration ─────────────────────────────────────
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (_, s) => const AdminScreen(),
            routes: [
              GoRoute(
                path: 'actualites',
                name: 'admin-actualites',
                builder: (_, s) => const AdminActualitesScreen(),
              ),
              GoRoute(
                path: 'users',
                name: 'admin-users',
                builder: (_, s) => const AdminUsersScreen(),
              ),
              GoRoute(
                path: 'notifications',
                name: 'admin-notifications',
                builder: (_, s) => const AdminNotificationsScreen(),
              ),
              GoRoute(
                path: 'commandes',
                name: 'admin-commandes',
                builder: (_, s) => const AdminCommandesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ── Notifier GoRouter ─────────────────────────────────────────────────────────

class _GoRouterNotifier extends ChangeNotifier {
  _GoRouterNotifier(Ref ref) {
    ref.listen<UserModel?>(userProvider, (_, _) => notifyListeners());
  }
}

// ── Shell avec navigation simplifiée ─────────────────────────────────────────

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  // 4 onglets fixes — pas dépendants du rôle
  static const _navItems = [
    _NavItem('/dashboard', 'Accueil', Icons.home_outlined, Icons.home),
    _NavItem('/formations', 'Formations', Icons.school_outlined, Icons.school),
    _NavItem('/challenges', 'Challenges',
        Icons.emoji_events_outlined, Icons.emoji_events),
    _NavItem('/menu', 'Menu', Icons.grid_view_outlined, Icons.grid_view),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return child;

    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);
    final width = MediaQuery.of(context).size.width;

    // ── Tablet : NavigationRail ────────────────────────────────────────────
    if (width >= 600) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              extended: width >= 900,
              leading: _LogoRail(extended: width >= 900),
              onDestinationSelected: (i) =>
                  context.go(_navItems[i].route),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // ── Mobile : NavigationBar (Material 3) ────────────────────────────────
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_navItems[i].route),
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  int _currentIndex(String location) {
    // Menu : toutes les pages "secondaires" pointent vers l'onglet Menu
    const menuRoutes = [
      '/menu', '/actualites', '/produits', '/pubs',
      '/packs', '/factures', '/labo', '/analytics', '/equipe',
    ];
    for (var i = 0; i < _navItems.length - 1; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    if (menuRoutes.any((r) => location.startsWith(r))) {
      return _navItems.length - 1; // onglet Menu
    }
    return 0;
  }
}

// ── Logo compact pour NavigationRail ─────────────────────────────────────────

class _LogoRail extends StatelessWidget {
  final bool extended;
  const _LogoRail({required this.extended});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _GranionsLogo(size: extended ? 40 : 32, showLabel: extended),
    );
  }
}

// ── Widget logo Granions (image ou fallback texte) ────────────────────────────

class _GranionsLogo extends StatelessWidget {
  final double size;
  final bool showLabel;
  const _GranionsLogo({this.size = 40, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    // Essaie de charger l'image — fallback automatique si absente
    return Image.asset(
      'assets/images/logo_granions.png',
      height: size,
      errorBuilder: (context, err, stack) => _TextLogo(size: size, showLabel: showLabel),
    );
  }
}

class _TextLogo extends StatelessWidget {
  final double size;
  final bool showLabel;
  const _TextLogo({required this.size, required this.showLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(size * 0.2),
          ),
          child: Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 10),
          Text(
            'GRANIONS',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: size * 0.35,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItem(this.route, this.label, this.icon, this.selectedIcon);
}
