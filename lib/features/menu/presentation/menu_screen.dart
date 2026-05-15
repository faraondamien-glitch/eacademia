import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../core/theme/app_colors.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final modules = RolePermissions.getModules(user.role);

    // Entrées du menu (features hors nav principale)
    final menuItems = _menuEntries
        .where((e) => modules.contains(e.module))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Profil utilisateur ─────────────────────────────────────────
          _ProfileCard(user: user),
          const SizedBox(height: 20),

          // ── Grille des features ────────────────────────────────────────
          Text('Fonctionnalités',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, i) => _MenuTile(
              entry: menuItems[i],
              onTap: () => context.push(menuItems[i].route),
            ),
          ),
          const SizedBox(height: 28),

          // ── Actions secondaires ────────────────────────────────────────
          const Divider(),
          const SizedBox(height: 8),
          _SecondaryAction(
            icon: Icons.help_outline,
            label: 'Aide & Support',
            onTap: () {/* TODO: ouvrir FAQ ou chat */},
          ),
          _SecondaryAction(
            icon: Icons.privacy_tip_outlined,
            label: 'Confidentialité',
            onTap: () {/* TODO */},
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _SecondaryAction(
            icon: Icons.logout,
            label: 'Se déconnecter',
            color: AppColors.error,
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(userProvider.notifier).setUser(null);
    }
  }

  static const _menuEntries = [
    _MenuEntry('actualites', '/actualites', 'Actualités',
        Icons.newspaper_outlined, AppColors.primary),
    _MenuEntry('produits', '/produits', 'Produits',
        Icons.medication_outlined, Color(0xFF5C6BC0)),
    _MenuEntry('pubs', '/pubs', 'Pubs TV',
        Icons.tv_outlined, Color(0xFF26A69A)),
    _MenuEntry('packs', '/packs', 'Packs',
        Icons.inventory_2_outlined, Color(0xFFEF6C00)),
    _MenuEntry('factures', '/factures', 'Factures',
        Icons.receipt_long_outlined, Color(0xFF8D6E63)),
    _MenuEntry('labo', '/labo', 'Le Labo',
        Icons.biotech_outlined, Color(0xFF00897B)),
    _MenuEntry('analytics', '/analytics', 'Analytics',
        Icons.bar_chart_outlined, Color(0xFF7B1FA2)),
  ];
}

// ── Carte profil ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.role.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                if (user.region.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.region,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Niveau
          Column(
            children: [
              const Icon(Icons.stars, color: AppColors.secondary, size: 20),
              const SizedBox(height: 2),
              Text(
                user.level,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tuile de feature ──────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final _MenuEntry entry;
  final VoidCallback onTap;
  const _MenuTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: entry.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: entry.color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, color: entry.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              entry.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: entry.color,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action secondaire ─────────────────────────────────────────────────────────

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }
}

class _MenuEntry {
  final String module;
  final String route;
  final String label;
  final IconData icon;
  final Color color;
  const _MenuEntry(
      this.module, this.route, this.label, this.icon, this.color);
}
