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
import '../../../features/actualites/data/actualites_repository.dart';
import '../../../features/actualites/domain/actu_model.dart';
import '../../../features/actualites/presentation/widgets/actu_card.dart';

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

              // Fil d'actualités
              Row(
                children: [
                  Text('Actualités',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/actualites'),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ActualitesFeed(role: user.role.value),
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

// ── Section KPI (dépliable) ──────────────────────────────────────────────────

class _KpiGrid extends StatefulWidget {
  final DashboardKpi? kpi;
  final UserRole role;

  const _KpiGrid({required this.kpi, required this.role});

  @override
  State<_KpiGrid> createState() => _KpiGridState();
}

class _KpiGridState extends State<_KpiGrid> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_KpiEntry>[
      _KpiEntry(
        title: 'Formations',
        value: widget.kpi != null ? '${widget.kpi!.formationsEnCours}' : '—',
        subtitle: 'en cours',
        icon: Icons.school_outlined,
        color: AppColors.primary,
        module: 'formations',
      ),
      if (RolePermissions.hasAccess(widget.role, 'challenges'))
        _KpiEntry(
          title: 'Score',
          value: widget.kpi != null ? '${widget.kpi!.scoreChallenge}' : '—',
          subtitle: 'pts challenge',
          icon: Icons.emoji_events_outlined,
          color: AppColors.secondary,
          module: 'challenges',
        ),
      if (RolePermissions.hasAccess(widget.role, 'factures'))
        _KpiEntry(
          title: 'Factures',
          value: widget.kpi != null ? '${widget.kpi!.facturesEnAttente}' : '—',
          subtitle: 'en attente',
          icon: Icons.receipt_long_outlined,
          color: AppColors.error,
          module: 'factures',
        ),
      _KpiEntry(
        title: 'Nouveautés',
        value: widget.kpi != null ? '${widget.kpi!.nouveautes}' : '—',
        subtitle: 'ce mois',
        icon: Icons.new_releases_outlined,
        color: AppColors.success,
        module: 'formations',
      ),
    ].take(4).toList();

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        for (final e in items) ...[
                          _KpiMini(entry: e),
                          if (e != items.last) const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: items
                              .map((e) => KpiCard(
                                    title: e.title,
                                    value: e.value,
                                    subtitle: e.subtitle,
                                    icon: e.icon,
                                    color: e.color,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _KpiMini extends StatelessWidget {
  final _KpiEntry entry;
  const _KpiMini({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(entry.icon, color: entry.color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            entry.value,
            style: TextStyle(
              color: entry.color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            entry.title,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

// ── Fil d'actualités (aperçu 3 dernières) ────────────────────────────────────

class _ActualitesFeed extends ConsumerWidget {
  final String role;
  const _ActualitesFeed({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<ActuModel>>(
      stream: ref
          .read(actualitesRepositoryProvider)
          .watchActualites(role: role),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          final base =
              Theme.of(context).colorScheme.surfaceContainerHighest;
          return Column(
            children: List.generate(
              2,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(12),
                    )),
              ),
            ),
          );
        }

        final list = (snap.data ?? []).take(3).toList();

        if (list.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.newspaper_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  const Text('Aucune actualité pour le moment'),
                ],
              ),
            ),
          );
        }

        return Column(
          children: list
              .map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ActuCard(actu: a),
                  ))
              .toList(),
        );
      },
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
