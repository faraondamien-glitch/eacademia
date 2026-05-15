import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/factures_repository.dart';
import '../domain/facture_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import 'widgets/facture_item.dart';

class FacturesScreen extends ConsumerStatefulWidget {
  const FacturesScreen({super.key});

  @override
  ConsumerState<FacturesScreen> createState() => _FacturesScreenState();
}

class _FacturesScreenState extends ConsumerState<FacturesScreen> {
  FactureStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();
    final repo = ref.read(facturesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Factures')),
      body: StreamBuilder<List<FactureModel>>(
        stream: repo.watchFactures(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const _FacturesSkeleton();
          }
          if (snap.hasError) {
            return _ErrorState(onRetry: () => setState(() {}));
          }

          final all = snap.data ?? [];
          final filtered = _filter == null
              ? all
              : all.where((f) => f.status == _filter).toList();

          final totalPaid = all
              .where((f) => f.status == FactureStatus.paid)
              .fold<double>(0, (sum, f) => sum + f.amount);
          final totalPending = all
              .where((f) => f.status == FactureStatus.pending)
              .fold<double>(0, (sum, f) => sum + f.amount);

          return Column(
            children: [
              // Résumé financier
              if (all.isNotEmpty)
                _SummaryBar(totalPaid: totalPaid, totalPending: totalPending),

              // Filtre
              _FilterBar(
                selected: _filter,
                pendingCount: all.where((f) => f.status == FactureStatus.pending).length,
                onSelected: (v) => setState(() => _filter = v),
              ),

              // Liste
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: filtered.isEmpty
                      ? _EmptyState(hasFilter: _filter != null)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) =>
                              FactureItem(facture: filtered[i]),
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

// ── Résumé financier ──────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final double totalPaid;
  final double totalPending;

  const _SummaryBar({required this.totalPaid, required this.totalPending});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: 'Payées',
              amount: totalPaid,
              color: AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
          Expanded(
            child: _SummaryCell(
              label: 'En attente',
              amount: totalPending,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCell({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Barre de filtres ──────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final FactureStatus? selected;
  final int pendingCount;
  final ValueChanged<FactureStatus?> onSelected;

  const _FilterBar({
    required this.selected,
    required this.pendingCount,
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
                const Text('En attente'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected == FactureStatus.pending
                          ? Colors.white
                          : AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected == FactureStatus.pending
                            ? AppColors.warning
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selected: selected == FactureStatus.pending,
            selectedColor: AppColors.warning,
            onSelected: (_) => onSelected(
                selected == FactureStatus.pending ? null : FactureStatus.pending),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Payées'),
            selected: selected == FactureStatus.paid,
            selectedColor: AppColors.success,
            onSelected: (_) => onSelected(
                selected == FactureStatus.paid ? null : FactureStatus.paid),
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
            hasFilter ? Icons.filter_list_off : Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Aucune facture dans ce filtre' : 'Aucune facture',
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
          const Text('Impossible de charger les factures.'),
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

class _FacturesSkeleton extends StatelessWidget {
  const _FacturesSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (_, i) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
