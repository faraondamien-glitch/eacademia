import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/actualites_repository.dart';
import '../domain/actu_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/actu_card.dart';

class ActualitesScreen extends ConsumerStatefulWidget {
  const ActualitesScreen({super.key});

  @override
  ConsumerState<ActualitesScreen> createState() => _ActualitesScreenState();
}

class _ActualitesScreenState extends ConsumerState<ActualitesScreen> {
  ActuCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final repo = ref.read(actualitesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Actualités')),
      body: Column(
        children: [
          // ── Filtres catégorie ────────────────────────────────────────────
          _CategoryFilters(
            selected: _selectedCategory,
            onSelect: (c) => setState(() => _selectedCategory = c),
          ),

          // ── Fil d'actualité ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<ActuModel>>(
              stream: repo.watchActualites(
                role: user.role.value,
                category: _selectedCategory,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const _ActuSkeleton();
                }
                if (snap.hasError) {
                  return const _ErrorState();
                }

                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const _EmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: list.length,
                    separatorBuilder: (context, i) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) => ActuCard(actu: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

// ── Filtres catégorie ─────────────────────────────────────────────────────────

class _CategoryFilters extends StatelessWidget {
  final ActuCategory? selected;
  final ValueChanged<ActuCategory?> onSelect;

  const _CategoryFilters({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Toutes'),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          ...ActuCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat.label),
                selected: selected == cat,
                onSelected: (_) =>
                    onSelect(selected == cat ? null : cat),
                avatar: Icon(_categoryIcon(cat), size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(ActuCategory cat) => switch (cat) {
        ActuCategory.produit => Icons.medication_outlined,
        ActuCategory.evenement => Icons.event_outlined,
        ActuCategory.commercial => Icons.trending_up_outlined,
        ActuCategory.sante => Icons.health_and_safety_outlined,
        ActuCategory.info => Icons.info_outline,
      };
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
          Icon(Icons.newspaper_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Aucune actualité pour le moment',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Les actualités Granions apparaîtront ici',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Impossible de charger les actualités.',
          style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _ActuSkeleton extends StatelessWidget {
  const _ActuSkeleton();
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) => Container(
        height: i == 0 ? 220 : 140,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
