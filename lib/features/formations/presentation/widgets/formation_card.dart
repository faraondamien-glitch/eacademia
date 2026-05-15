import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/formation_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class FormationCard extends StatelessWidget {
  final FormationModel formation;
  final double? progress; // null = pas commencé
  final VoidCallback onTap;

  const FormationCard({
    super.key,
    required this.formation,
    required this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProgress = progress != null && progress! > 0;
    final isFinished = progress != null && progress! >= 1.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Vignette
                SizedBox(
                  width: 100,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      formation.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: formation.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, e, s) =>
                                  _Placeholder(theme: formation.theme),
                            )
                          : _Placeholder(theme: formation.theme),
                      if (isFinished)
                        Container(
                          color: AppColors.success.withValues(alpha: 0.85),
                          child: const Icon(Icons.check_circle,
                              color: Colors.white, size: 32),
                        ),
                    ],
                  ),
                ),

                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre + badge NOUVEAU
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                formation.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (formation.isNew) ...[
                              const SizedBox(width: 6),
                              _Badge(label: 'NOUVEAU', color: AppColors.success),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Durée + thème
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              Formatters.formatDuration(
                                  formation.durationMinutes),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: _Badge(
                                label: formation.theme,
                                color: AppColors.primary,
                                small: true,
                              ),
                            ),
                          ],
                        ),

                        // Statut progression textuel
                        if (hasProgress && !isFinished) ...[
                          const SizedBox(height: 4),
                          Text(
                            'En cours · ${(progress! * 100).round()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else if (isFinished) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Terminée',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),

            // Barre de progression en bas de la card
            if (hasProgress)
              LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                color: isFinished ? AppColors.success : AppColors.primary,
                minHeight: 4,
              ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String theme;
  const _Placeholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.school_outlined, color: AppColors.primary, size: 32),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const _Badge({
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: small ? 0.12 : 1.0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: small ? color : Colors.white,
          fontSize: small ? 10 : 9,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
