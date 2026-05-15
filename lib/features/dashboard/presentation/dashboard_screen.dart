import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../data/dashboard_repository.dart';
import 'widgets/kpi_card.dart';
import 'widgets/notification_item.dart';
import 'widgets/formation_progress_item.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final repo = ref.read(dashboardRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EACADEMIA'),
        actions: [
          _NotificationBell(userId: user.uid, repo: repo),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeBanner(user: user),
              const SizedBox(height: 20),

              // KPI
              StreamBuilder<DashboardKpi>(
                stream: repo.watchKpi(userId: user.uid, role: user.role.value),
                builder: (context, snap) {
                  final kpi = snap.data;
                  return _KpiGrid(kpi: kpi, role: user.role);
                },
              ),
              const SizedBox(height: 24),

              // Notifications
              Row(
                children: [
                  Text('Notifications récentes',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _NotificationsList(userId: user.uid, repo: repo),
              const SizedBox(height: 24),

              // Formations en cours
              Row(
                children: [
                  Text('Formations en cours',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/formations'),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _FormationsInProgress(userId: user.uid, repo: repo),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bannière de bienvenue ────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final UserModel user;
  const _WelcomeBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${user.firstName} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.role.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.secondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  user.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grille KPI ───────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final DashboardKpi? kpi;
  final UserRole role;

  const _KpiGrid({required this.kpi, required this.role});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiEntry(
        title: 'Formations',
        value: kpi != null ? '${kpi!.formationsEnCours}' : '—',
        subtitle: 'en cours',
        icon: Icons.school_outlined,
        color: AppColors.primary,
        module: 'formations',
      ),
      if (RolePermissions.hasAccess(role, 'challenges'))
        _KpiEntry(
          title: 'Score',
          value: kpi != null ? '${kpi!.scoreChallenge}' : '—',
          subtitle: 'pts challenge',
          icon: Icons.emoji_events_outlined,
          color: AppColors.secondary,
          module: 'challenges',
        ),
      if (RolePermissions.hasAccess(role, 'factures'))
        _KpiEntry(
          title: 'Factures',
          value: kpi != null ? '${kpi!.facturesEnAttente}' : '—',
          subtitle: 'en attente',
          icon: Icons.receipt_long_outlined,
          color: AppColors.error,
          module: 'factures',
        ),
      _KpiEntry(
        title: 'Nouveautés',
        value: kpi != null ? '${kpi!.nouveautes}' : '—',
        subtitle: 'ce mois',
        icon: Icons.new_releases_outlined,
        color: AppColors.success,
        module: 'formations',
      ),
    ];

    final displayed = items.take(4).toList();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: displayed
          .map((e) => KpiCard(
                title: e.title,
                value: e.value,
                subtitle: e.subtitle,
                icon: e.icon,
                color: e.color,
              ))
          .toList(),
    );
  }
}

class _KpiEntry {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String module;

  const _KpiEntry({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.module,
  });
}

// ── Notifications ────────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final String userId;
  final DashboardRepository repo;

  const _NotificationBell({required this.userId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationData>>(
      stream: repo.watchRecentNotifications(userId),
      builder: (context, snap) {
        final unread = (snap.data ?? []).where((n) => !n.read).length;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final String userId;
  final DashboardRepository repo;

  const _NotificationsList({required this.userId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationData>>(
      stream: repo.watchRecentNotifications(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SkeletonList(count: 3, height: 64);
        }
        final notifications = snap.data ?? [];
        if (notifications.isEmpty) {
          return _EmptyCard(
            icon: Icons.notifications_none,
            message: 'Aucune notification',
          );
        }
        return Column(
          children: notifications
              .map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NotificationItem(
                      message: n.message,
                      type: n.type,
                      isRead: n.read,
                      timeAgo: _timeAgo(n.createdAt),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }
}

// ── Formations en cours ──────────────────────────────────────────────────────

class _FormationsInProgress extends StatelessWidget {
  final String userId;
  final DashboardRepository repo;

  const _FormationsInProgress({required this.userId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FormationInProgress>>(
      stream: repo.watchFormationsInProgress(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SkeletonList(count: 2, height: 80);
        }
        final formations = snap.data ?? [];
        if (formations.isEmpty) {
          return _EmptyCard(
            icon: Icons.school_outlined,
            message: 'Aucune formation en cours',
          );
        }
        return Column(
          children: formations
              .map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FormationProgressItem(
                      title: f.title,
                      progress: f.percentage,
                      progressLabel:
                          '${f.completedModules}/${f.totalModules} modules',
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ── Widgets utilitaires ──────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  final int count;
  final double height;

  const _SkeletonList({required this.count, required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
