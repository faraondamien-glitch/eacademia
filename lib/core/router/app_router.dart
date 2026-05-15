import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/formations/presentation/formations_screen.dart';
import '../../features/formations/presentation/formation_detail_screen.dart';
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
import '../../features/produits/presentation/pdf_viewer_screen.dart';
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
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, s) => const LoginScreen(),
      ),
      // Route partagée plein-écran (sans barre de nav) pour le viewer PDF
      GoRoute(
        path: '/pdf-viewer',
        name: 'pdf-viewer',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>;
          return PdfViewerScreen(
            url: extra['url']!,
            title: extra['title']!,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
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
                builder: (_, state) => FormationDetailScreen(
                  formationId: state.pathParameters['id']!,
                ),
              ),
            ],
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
                builder: (_, state) => PubPlayerScreen(
                  pubId: state.pathParameters['id']!,
                ),
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
                builder: (_, state) => PackDetailScreen(
                  packId: state.pathParameters['id']!,
                ),
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
            path: '/challenges',
            name: 'challenges',
            builder: (_, s) => const ChallengesScreen(),
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
        ],
      ),
    ],
  );
});

// Notifier léger : écoute le userProvider via Riverpod et notifie GoRouter
class _GoRouterNotifier extends ChangeNotifier {
  _GoRouterNotifier(Ref ref) {
    ref.listen<UserModel?>(userProvider, (_, _) => notifyListeners());
  }
}

// ── Shell adaptatif ──────────────────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return child;

    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final modules = RolePermissions.getModules(user.role);
    final navItems = _buildNavItems(modules);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getCurrentIndex(location, navItems);

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex < 0 ? 0 : currentIndex,
              extended: width >= 900,
              onDestinationSelected: (i) => context.go(navItems[i].route),
              destinations: navItems
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

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: (i) => context.go(navItems[i].route),
        items: navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.selectedIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  int _getCurrentIndex(String location, List<_NavItem> items) {
    for (var i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }

  static const _all = [
    _NavItem('dashboard', '/dashboard', 'Accueil', Icons.home_outlined, Icons.home),
    _NavItem('formations', '/formations', 'Formations', Icons.school_outlined, Icons.school),
    _NavItem('produits', '/produits', 'Produits', Icons.medication_outlined, Icons.medication),
    _NavItem('pubs', '/pubs', 'Pubs TV', Icons.tv_outlined, Icons.tv),
    _NavItem('packs', '/packs', 'Packs', Icons.inventory_2_outlined, Icons.inventory_2),
    _NavItem('challenges', '/challenges', 'Challenges', Icons.emoji_events_outlined, Icons.emoji_events),
    _NavItem('factures', '/factures', 'Factures', Icons.receipt_long_outlined, Icons.receipt_long),
    _NavItem('labo', '/labo', 'Le Labo', Icons.biotech_outlined, Icons.biotech),
  ];

  List<_NavItem> _buildNavItems(List<String> modules) =>
      _all.where((item) => modules.contains(item.module)).toList();
}

class _NavItem {
  final String module;
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem(this.module, this.route, this.label, this.icon, this.selectedIcon);
}
