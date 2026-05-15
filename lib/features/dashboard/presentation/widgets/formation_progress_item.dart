import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FormationProgressItem extends StatelessWidget {
  final String title;
  final double progress;
  final String progressLabel;

  const FormationProgressItem({
    super.key,
    required this.title,
    required this.progress,
    required this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(progressLabel, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
