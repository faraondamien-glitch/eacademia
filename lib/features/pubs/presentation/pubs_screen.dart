import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/pubs_repository.dart';
import '../domain/pub_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class PubsScreen extends ConsumerStatefulWidget {
  const PubsScreen({super.key});

  @override
  ConsumerState<PubsScreen> createState() => _PubsScreenState();
}

class _PubsScreenState extends ConsumerState<PubsScreen> {
  // null = toutes, true = en diffusion, false = archivées
  bool? _filterActive;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();
    final repo = ref.read(pubsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicités TV')),
      body: StreamBuilder<List<PubModel>>(
        stream: repo.watchPubs(user.role.value),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const _PubsSkeleton();
          }
          if (snap.hasError) {
            return _ErrorState(onRetry: () => setState(() {}));
          }

          final all = snap.data ?? [];
          final filtered = _filterActive == null
              ? all
              : all.where((p) => p.isActive == _filterActive).toList();

          final activeCount = all.where((p) => p.isActive).length;

          return Column(
            children: [
              // Filtre En diffusion / Toutes
              _FilterBar(
                selected: _filterActive,
                activeCount: activeCount,
                onSelected: (v) => setState(() => _filterActive = v),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: filtered.isEmpty
                      ? _EmptyState(hasFilter: _filterActive != null)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final pub = filtered[i];
                            return _PubCard(
                              pub: pub,
                              onTap: () => context.push('/pubs/${pub.id}'),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Barre de filtre ───────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final bool? selected;
  final int activeCount;
  final ValueChanged<bool?> onSelected;

  const _FilterBar({
    required this.selected,
    required this.activeCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: const Text('Toutes'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('En diffusion'),
                if (activeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected == true
                          ? Colors.white
                          : AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected == true
                            ? AppColors.success
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selected: selected == true,
            selectedColor: AppColors.success,
            onSelected: (_) =>
                onSelected(selected == true ? null : true),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Archivées'),
            selected: selected == false,
            onSelected: (_) =>
                onSelected(selected == false ? null : false),
          ),
        ],
      ),
    );
  }
}

// ── Card publicité ────────────────────────────────────────────────────────────

class _PubCard extends StatelessWidget {
  final PubModel pub;
  final VoidCallback onTap;

  const _PubCard({required this.pub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail 16/9
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image ou fond coloré
                  pub.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: pub.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, e, s) => _VideoPlaceholder(),
                        )
                      : _VideoPlaceholder(),

                  // Bouton play centré
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 32),
                    ),
                  ),

                  // Badge EN DIFFUSION
                  if (pub.isActive)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _LiveBadge(),
                    ),

                  // Date en bas à droite
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        Formatters.formatDate(pub.broadcastDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Infos texte
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pub.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.tv_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          pub.channels.join(' · '),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.video_library_outlined,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'EN DIFFUSION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── États ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.tv_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Aucune publicité dans ce filtre'
                : 'Aucune publicité disponible',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('Impossible de charger les publicités.'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _PubsSkeleton extends StatelessWidget {
  const _PubsSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) => Container(
        height: 220,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
