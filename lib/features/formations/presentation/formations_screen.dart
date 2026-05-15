import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/learning360_repository.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/learning360_config.dart';
import '../../../core/utils/formatters.dart';

class FormationsScreen extends ConsumerStatefulWidget {
  const FormationsScreen({super.key});

  @override
  ConsumerState<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends ConsumerState<FormationsScreen> {
  String? _selectedTheme;
  List<FormationWithProgress>? _catalog;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(learning360RepositoryProvider);
      final catalog = await repo.getCatalog(
        userId: user.uid,
        userEmail: user.email,
      );
      if (mounted) setState(() { _catalog = catalog; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les formations.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formations'),
        actions: [
          if (!Learning360Config.isConfigured)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('DÉMO', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                side: const BorderSide(color: Colors.orange),
                padding: EdgeInsets.zero,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _loadCatalog,
          ),
        ],
      ),
      body: _loading
          ? const _FormationsSkeleton()
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadCatalog)
              : _CatalogView(
                  catalog: _catalog ?? [],
                  selectedTheme: _selectedTheme,
                  onThemeSelected: (t) => setState(() => _selectedTheme = t),
                ),
    );
  }
}

// ── Vue principale avec filtres ───────────────────────────────────────────────

class _CatalogView extends StatelessWidget {
  final List<FormationWithProgress> catalog;
  final String? selectedTheme;
  final ValueChanged<String?> onThemeSelected;

  const _CatalogView({
    required this.catalog,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (catalog.isEmpty) {
      return const _EmptyState();
    }

    // Thèmes disponibles
    final themes = catalog
        .map((e) => e.formation.theme)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Filtrer
    final filtered = selectedTheme == null
        ? catalog
        : catalog.where((e) => e.formation.theme == selectedTheme).toList();

    // Stats globales
    final enrolled = catalog.where((e) => e.isEnrolled).length;
    final completed = catalog.where((e) => e.isCompleted).length;
    final avgProgress = enrolled > 0
        ? catalog
                .where((e) => e.isEnrolled)
                .map((e) => e.completionRate)
                .reduce((a, b) => a + b) /
            enrolled
        : 0.0;

    return CustomScrollView(
      slivers: [
        // ── Bandeau stats ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _StatsBar(
            total: catalog.length,
            enrolled: enrolled,
            completed: completed,
            avgProgress: avgProgress,
          ),
        ),

        // ── Filtres par thème ──────────────────────────────────────────────
        if (themes.isNotEmpty)
          SliverToBoxAdapter(
            child: _ThemeFilters(
              themes: themes,
              selected: selectedTheme,
              onSelect: onThemeSelected,
            ),
          ),

        // ── Liste des formations ───────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final item = filtered[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Formation360Card(
                    item: item,
                    onTap: () => context.push(
                      '/formations/${item.formation.id}',
                      extra: item,
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bandeau de stats globales ─────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total;
  final int enrolled;
  final int completed;
  final double avgProgress;

  const _StatsBar({
    required this.total,
    required this.enrolled,
    required this.completed,
    required this.avgProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatCell(value: '$total', label: 'formations'),
          _StatCell(value: '$enrolled', label: 'inscrit(s)'),
          _StatCell(value: '$completed', label: 'terminé(s)'),
          _StatCell(
            value: '${(avgProgress * 100).round()}%',
            label: 'progression moy.',
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Filtres par thème ─────────────────────────────────────────────────────────

class _ThemeFilters extends StatelessWidget {
  final List<String> themes;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _ThemeFilters({
    required this.themes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('Tous'),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          ...themes.map((t) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(t),
                  selected: selected == t,
                  onSelected: (_) => onSelect(selected == t ? null : t),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Carte formation 360Learning ───────────────────────────────────────────────

class Formation360Card extends StatelessWidget {
  final FormationWithProgress item;
  final VoidCallback onTap;

  const Formation360Card({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = item.formation;
    final progress = item.completionRate;
    final isCompleted = item.isCompleted;
    final isEnrolled = item.isEnrolled;

    Color statusColor = isCompleted
        ? AppColors.success
        : isEnrolled
            ? AppColors.primary
            : AppColors.textSecondary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : thème + badge statut
              Row(
                children: [
                  if (f.theme.isNotEmpty)
                    Expanded(
                      child: Text(
                        f.theme.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  if (f.isNew)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('NOUVEAU',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  _StatusBadge(
                    isCompleted: isCompleted,
                    isEnrolled: isEnrolled,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Titre
              Text(
                f.title,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                f.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Méta-infos
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(Formatters.formatDuration(f.durationMinutes),
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(Icons.layers_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${f.totalModules} modules',
                      style: theme.textTheme.bodySmall),
                  const Spacer(),
                  // Icône 360Learning
                  Icon(Icons.school_outlined,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.6)),
                  const SizedBox(width: 3),
                  Text('360Learning',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.6),
                      )),
                ],
              ),

              // Barre de progression (si inscrit)
              if (isEnrolled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              statusColor.withValues(alpha: 0.12),
                          color: statusColor,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isCompleted;
  final bool isEnrolled;
  const _StatusBadge({required this.isCompleted, required this.isEnrolled});

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 12, color: AppColors.success),
            SizedBox(width: 4),
            Text('Terminé',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (isEnrolled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, size: 12, color: AppColors.primary),
            SizedBox(width: 4),
            Text('En cours',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('Non inscrit',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── États ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined,
              size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Aucune formation disponible',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Le catalogue 360Learning apparaîtra ici',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormationsSkeleton extends StatelessWidget {
  const _FormationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 12, width: 80, color: base),
            const SizedBox(height: 10),
            Container(height: 16, width: double.infinity, color: base),
            const SizedBox(height: 6),
            Container(height: 16, width: 200, color: base),
            const SizedBox(height: 12),
            Container(height: 12, width: double.infinity, color: base),
            const SizedBox(height: 4),
            Container(height: 12, width: 160, color: base),
            const SizedBox(height: 12),
            Container(height: 5, width: double.infinity, color: base),
          ],
        ),
      ),
    );
  }
}
