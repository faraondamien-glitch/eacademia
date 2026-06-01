import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/providers/theme_provider.dart';
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
          // ── Administration (isAdmin uniquement) ────────────────────────
          if (user.isAdmin) ...[
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 20),
              ),
              title: const Text('Administration',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Gérer le contenu & les utilisateurs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin'),
              contentPadding: EdgeInsets.zero,
            ),
          ],

          const Divider(),
          const SizedBox(height: 8),
          _ThemeTile(
            mode: ref.watch(themeModeProvider),
            onSelect: (m) => ref.read(themeModeProvider.notifier).set(m),
          ),
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

          // ── Contact ────────────────────────────────────────────────────
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),
          const _ContactSection(),
          const SizedBox(height: 8),
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
    _MenuEntry('equipe', '/equipe', 'Mon Équipe',
        Icons.group_outlined, Color(0xFF0288D1)),
    _MenuEntry('analytics', '/analytics', 'Analytics',
        Icons.bar_chart_outlined, Color(0xFF7B1FA2)),
  ];
}

// ── Carte profil ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel user;
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
                if ((user.pharmacyName ?? user.region).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.pharmacyName ?? user.region,
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

// ── Sélecteur de thème ────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onSelect;
  const _ThemeTile({required this.mode, required this.onSelect});

  static const _labels = {
    ThemeMode.light: 'Clair',
    ThemeMode.dark: 'Sombre',
    ThemeMode.system: 'Système',
  };

  static const _icons = {
    ThemeMode.light: Icons.light_mode_outlined,
    ThemeMode.dark: Icons.dark_mode_outlined,
    ThemeMode.system: Icons.brightness_auto_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_icons[mode], size: 22),
      title: const Text('Thème'),
      subtitle: Text(_labels[mode] ?? ''),
      trailing: const Icon(Icons.chevron_right, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
      onTap: () => _openPicker(context),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choisir le thème',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
            ),
            for (final m in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: m,
                groupValue: mode,
                onChanged: (v) => Navigator.pop(ctx, v),
                title: Text(_labels[m]!),
                secondary: Icon(_icons[m]),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) onSelect(picked);
  }
}

// ── Section Contact ───────────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Contact', style: theme.textTheme.labelLarge),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              _ContactTile(
                icon: Icons.medical_services_outlined,
                label: 'Service médical',
                value: 'medical@granions.fr',
                onTap: () =>
                    launchUrl(Uri.parse('mailto:medical@granions.fr')),
                isFirst: true,
              ),
              const Divider(height: 1, indent: 56),
              _ContactTile(
                icon: Icons.handshake_outlined,
                label: 'Délégués commerciaux',
                value: 'commercial@granions.fr',
                onTap: () =>
                    launchUrl(Uri.parse('mailto:commercial@granions.fr')),
              ),
              const Divider(height: 1, indent: 56),
              _ContactTile(
                icon: Icons.phone_outlined,
                label: 'Standard',
                value: '+33 4 92 96 00 00',
                onTap: () =>
                    launchUrl(Uri.parse('tel:+33492960000')),
              ),
              const Divider(height: 1, indent: 56),
              _ContactTile(
                icon: Icons.location_on_outlined,
                label: 'Siège social',
                value: 'Mougins — Sophia Antipolis\nAlpes-Maritimes (06)',
                onTap: () => launchUrl(Uri.parse(
                    'https://maps.google.com/?q=Granions,Mougins')),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () =>
                launchUrl(Uri.parse('https://www.granions.fr')),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('granions.fr'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                  const SizedBox(height: 1),
                  Text(value,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 16,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
