import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/produits_repository.dart';
import '../domain/produit_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/produit_card.dart';

class ProduitsScreen extends ConsumerStatefulWidget {
  const ProduitsScreen({super.key});

  @override
  ConsumerState<ProduitsScreen> createState() => _ProduitsScreenState();
}

class _ProduitsScreenState extends ConsumerState<ProduitsScreen> {
  String? _selectedRange;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();
    final repo = ref.read(produitsRepositoryProvider);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _SearchBar(
            controller: _searchCtrl,
            onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
          ),
        ),
      ),
      body: StreamBuilder<List<ProduitModel>>(
        stream: repo.watchProduits(user.role.value),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return _ProduitsSkeleton(isTablet: isTablet);
          }
          if (snap.hasError) {
            return _ErrorState(onRetry: () => setState(() {}));
          }

          final all = snap.data ?? [];
          final ranges = all
              .map((p) => p.range)
              .where((r) => r.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          // Filtres cumulatifs : gamme + recherche
          final filtered = all.where((p) {
            final matchRange =
                _selectedRange == null || p.range == _selectedRange;
            final matchSearch = _searchQuery.isEmpty ||
                p.name.toLowerCase().contains(_searchQuery) ||
                p.range.toLowerCase().contains(_searchQuery) ||
                p.tags.any((t) => t.toLowerCase().contains(_searchQuery));
            return matchRange && matchSearch;
          }).toList();

          return Column(
            children: [
              if (ranges.isNotEmpty)
                _RangeFilter(
                  ranges: ranges,
                  selected: _selectedRange,
                  onSelected: (r) => setState(() => _selectedRange = r),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: filtered.isEmpty
                      ? _EmptyState(
                          hasFilter:
                              _selectedRange != null || _searchQuery.isNotEmpty,
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTablet ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final p = filtered[i];
                            return ProduitCard(
                              produit: p,
                              onTap: () => context.push('/produits/${p.id}'),
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

// ── Barre de recherche ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }
}

// ── Filtre par gamme ─────────────────────────────────────────────────────────

class _RangeFilter extends StatelessWidget {
  final List<String> ranges;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _RangeFilter(
      {required this.ranges, required this.selected, required this.onSelected});

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
          ...ranges.map((r) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(r),
                  selected: selected == r,
                  onSelected: (_) => onSelected(selected == r ? null : r),
                ),
              )),
        ],
      ),
    );
  }
}

// ── États ────────────────────────────────────────────────────────────────────

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
            hasFilter ? Icons.search_off : Icons.medication_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Aucun produit trouvé' : 'Aucun produit disponible',
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
          const Text('Impossible de charger les produits.'),
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

class _ProduitsSkeleton extends StatelessWidget {
  final bool isTablet;
  const _ProduitsSkeleton({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
