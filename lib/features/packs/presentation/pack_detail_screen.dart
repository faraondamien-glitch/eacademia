import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/packs_repository.dart';
import '../domain/pack_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class PackDetailScreen extends ConsumerWidget {
  final String packId;
  const PackDetailScreen({super.key, required this.packId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(packsRepositoryProvider);

    return FutureBuilder<PackModel?>(
      future: repo.getPack(packId),
      builder: (context, snap) {
        final pack = snap.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(pack?.name ?? 'Pack promotionnel'),
          ),
          body: () {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _DetailSkeleton();
            }
            if (pack == null) {
              return const Center(child: Text('Pack introuvable'));
            }
            return _PackDetailBody(pack: pack);
          }(),
          bottomNavigationBar: pack == null
              ? null
              : _OrderBar(pack: pack, packId: packId),
        );
      },
    );
  }
}

// ── Corps ─────────────────────────────────────────────────────────────────────

class _PackDetailBody extends StatelessWidget {
  final PackModel pack;
  const _PackDetailBody({required this.pack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = pack.discountPercent > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // En-tête hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pack.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${pack.items.length} produit${pack.items.length > 1 ? 's' : ''} inclus',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDiscount)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${pack.discountPercent.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Titre section produits
        Text('Produits inclus', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),

        // Table des produits
        Card(
          child: Column(
            children: [
              // En-tête tableau
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Produit',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text('Qté',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text('Prix unit.',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Lignes produits
              ...pack.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isLast = idx == pack.items.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Puce numérotée
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(item.name,
                                style: theme.textTheme.bodyMedium),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '×${item.quantity}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              Formatters.formatCurrency(item.unitPrice),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 50),
                  ],
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Récapitulatif prix
        Text('Récapitulatif', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),

        Card(
          color: AppColors.success.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (hasDiscount) ...[
                  _PriceRow(
                    label: 'Prix catalogue',
                    value: Formatters.formatCurrency(pack.totalPrice),
                    isStrikethrough: true,
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: 'Remise ${pack.discountPercent.round()} %',
                    value:
                        '- ${Formatters.formatCurrency(pack.totalPrice * pack.discountPercent / 100)}',
                    valueColor: AppColors.success,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(),
                  ),
                ],
                _PriceRow(
                  label: 'Total pack',
                  value: Formatters.formatCurrency(pack.discountedPrice),
                  valueColor: AppColors.success,
                  isBold: true,
                  fontSize: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Prix row ──────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final double fontSize;
  final bool isStrikethrough;

  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.fontSize = 15,
    this.isStrikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: isStrikethrough ? AppColors.textSecondary : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? (isStrikethrough ? AppColors.textSecondary : null),
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}

// ── Barre commander ───────────────────────────────────────────────────────────

class _OrderBar extends StatelessWidget {
  final PackModel pack;
  final String packId;

  const _OrderBar({required this.pack, required this.packId});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.formatCurrency(pack.discountedPrice),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
              if (pack.discountPercent > 0)
                Text(
                  'économie de ${Formatters.formatCurrency(pack.totalPrice - pack.discountedPrice)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/packs/$packId/commander'),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Commander ce pack'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
            height: 100,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 24),
        Container(
            height: 16,
            width: 120,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 12),
        Container(
            height: 200,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 20),
        Container(
            height: 16,
            width: 120,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 12),
        Container(
            height: 120,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12))),
      ],
    );
  }
}
