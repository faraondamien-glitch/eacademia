import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/packs_repository.dart';
import '../domain/pack_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class PacksScreen extends ConsumerWidget {
  const PacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();
    final repo = ref.read(packsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Packs promotionnels')),
      body: StreamBuilder<List<PackModel>>(
        stream: repo.watchPacks(user.role.value),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const _PacksSkeleton();
          }
          if (snap.hasError) {
            return _ErrorState(
              onRetry: () {},
            );
          }

          final packs = snap.data ?? [];

          if (packs.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: packs.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _PackCard(
                pack: packs[i],
                onTap: () => context.push('/packs/${packs[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Card pack ─────────────────────────────────────────────────────────────────

class _PackCard extends StatelessWidget {
  final PackModel pack;
  final VoidCallback onTap;

  const _PackCard({required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = pack.discountPercent > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // En-tête colorée
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.12),
                    AppColors.secondary.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pack.name, style: theme.textTheme.titleMedium),
                        Text(
                          '${pack.items.length} produit${pack.items.length > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${pack.discountPercent.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Corps : items + prix
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  // Liste compacte des produits
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: pack.items.take(3).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.name} ×${item.quantity}',
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      }).toList()
                        ..addAll(pack.items.length > 3
                            ? [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${pack.items.length - 3} autres',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              ]
                            : []),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Prix
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasDiscount)
                        Text(
                          Formatters.formatCurrency(pack.totalPrice),
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Text(
                        Formatters.formatCurrency(pack.discountedPrice),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
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

// ── États ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Aucun pack disponible',
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
          const Text('Impossible de charger les packs.'),
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

class _PacksSkeleton extends StatelessWidget {
  const _PacksSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) => Container(
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
