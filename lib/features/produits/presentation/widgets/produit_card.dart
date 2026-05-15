import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/produit_model.dart';
import '../../../../core/theme/app_colors.dart';

class ProduitCard extends StatelessWidget {
  final ProduitModel produit;
  final VoidCallback onTap;

  const ProduitCard({super.key, required this.produit, required this.onTap});

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
            // Image produit
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  produit.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: produit.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, e, s) => _Placeholder(),
                        )
                      : _Placeholder(),

                  // Badge PDF disponible
                  if (produit.fichePdfUrl.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf,
                                size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Infos texte
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      produit.range,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (produit.tags.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: produit.tags.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.07),
      child: Center(
        child: Icon(
          Icons.medication_outlined,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
