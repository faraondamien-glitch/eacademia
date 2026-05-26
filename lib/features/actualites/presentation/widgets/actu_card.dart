import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/actu_model.dart';
import '../../../../core/theme/app_colors.dart';

class ActuCard extends StatelessWidget {
  final ActuModel actu;

  const ActuCard({super.key, required this.actu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasImage = actu.imageUrl != null && actu.imageUrl!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vignette (optionnelle) ─────────────────────────────────
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: CachedNetworkImage(
                      imageUrl: actu.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (context, url, err) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppColors.textDisabled, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // ── En-tête : catégorie + épingle + date ──────────────────
                  Row(
                    children: [
                      _CategoryBadge(category: actu.category),
                      if (actu.isPinned) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.push_pin,
                            size: 14, color: AppColors.primary),
                      ],
                      const Spacer(),
                      Text(
                        _formatDate(actu.publishedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Titre ──────────────────────────────────────────────────
                  Text(
                    actu.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // ── Corps (aperçu 2 lignes) ────────────────────────────────
                  Text(
                    actu.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // ── Auteur ─────────────────────────────────────────────────
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          actu.author.isNotEmpty
                              ? actu.author[0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        actu.author,
                        style: theme.textTheme.labelSmall,
                      ),
                      if (actu.targetRoles.isNotEmpty) ...[
                        const Spacer(),
                        Icon(Icons.lock_outline,
                            size: 12,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text(
                          actu.targetRoles.join(', '),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ActuDetailSheet(actu: actu),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ── Badge catégorie ───────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final ActuCategory category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _style(ActuCategory c) => switch (c) {
        ActuCategory.produit =>
          (AppColors.primary, Icons.medication_outlined),
        ActuCategory.evenement =>
          (AppColors.secondary, Icons.event_outlined),
        ActuCategory.commercial =>
          (AppColors.success, Icons.trending_up_outlined),
        ActuCategory.sante =>
          (const Color(0xFF00BCD4), Icons.health_and_safety_outlined),
        ActuCategory.info => (AppColors.textSecondary, Icons.info_outline),
      };
}

// ── Feuille de détail ─────────────────────────────────────────────────────────

class _ActuDetailSheet extends StatelessWidget {
  final ActuModel actu;
  const _ActuDetailSheet({required this.actu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Poignée
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _CategoryBadge(category: actu.category),
                  const SizedBox(height: 12),
                  Text(actu.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          actu.author.isNotEmpty
                              ? actu.author[0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(actu.author,
                          style: theme.textTheme.labelMedium),
                      const Spacer(),
                      Text(
                        '${actu.publishedAt.day.toString().padLeft(2, '0')}/${actu.publishedAt.month.toString().padLeft(2, '0')}/${actu.publishedAt.year}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  if (actu.imageUrl != null &&
                      actu.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: actu.imageUrl!,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    actu.body,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
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
