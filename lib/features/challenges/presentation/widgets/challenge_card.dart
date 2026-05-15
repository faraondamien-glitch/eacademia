import 'package:flutter/material.dart';
import '../../domain/challenge_model.dart';
import '../../data/opeaz_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

/// Carte challenge Opeaz enrichie avec progression utilisateur.
class OpeazChallengeCard extends StatelessWidget {
  final ChallengeWithProgress item;
  const OpeazChallengeCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ChallengeCard(
      challenge: item.challenge,
      progressRate: item.progressRate,
      currentScore: item.currentScore,
      userRank: item.userRank,
      isWinner: item.isWinner,
    );
  }
}

/// Carte challenge de base (utilisable avec ou sans données Opeaz).
class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final double progressRate;
  final int currentScore;
  final int userRank;
  final bool isWinner;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.progressRate = 0.0,
    this.currentScore = 0,
    this.userRank = 0,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = challenge.endDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft >= 0 && daysLeft <= 7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : titre + badge statut
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: challenge.isActive
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.textDisabled.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: challenge.isActive
                        ? AppColors.primary
                        : AppColors.textDisabled,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title, style: theme.textTheme.titleMedium),
                      if (challenge.subtitle.isNotEmpty)
                        Text(challenge.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: challenge.isActive
                        ? AppColors.success
                        : AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    challenge.isActive ? 'ACTIF' : 'TERMINÉ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Objectif + date
            Row(
              children: [
                Expanded(
                  child: _MetaCell(
                    icon: Icons.flag_outlined,
                    label: 'Objectif',
                    value: '${challenge.objective} ${challenge.unit}',
                  ),
                ),
                Expanded(
                  child: _MetaCell(
                    icon: Icons.calendar_today_outlined,
                    label: 'Échéance',
                    value: Formatters.formatDate(challenge.endDate),
                    valueColor:
                        isUrgent && challenge.isActive ? AppColors.error : null,
                  ),
                ),
              ],
            ),

            // Jours restants (urgence)
            if (daysLeft >= 0 && challenge.isActive) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isUrgent ? AppColors.error : AppColors.success)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUrgent ? Icons.timer_outlined : Icons.schedule,
                      size: 14,
                      color: isUrgent ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      daysLeft == 0
                          ? 'Dernier jour !'
                          : '$daysLeft jour${daysLeft > 1 ? 's' : ''} restant${daysLeft > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUrgent ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Progression Opeaz ─────────────────────────────────────
            if (currentScore > 0 || progressRate > 0) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ma progression',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '$currentScore / ${challenge.objective} ${challenge.unit}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: progressRate >= 1.0
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressRate.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            color: progressRate >= 1.0
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (userRank > 0) ...[
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          '#$userRank',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: userRank <= 3
                                ? AppColors.secondary
                                : AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'rang',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  if (isWinner) ...[
                    const SizedBox(width: 8),
                    const Text('🏆', style: TextStyle(fontSize: 22)),
                  ],
                ],
              ),
            ],

            // Récompense
            if (challenge.reward.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(challenge.reward,
                          style: theme.textTheme.bodySmall),
                    ),
                    if (challenge.rewardPoints > 0)
                      Text(
                        '${challenge.rewardPoints} pts',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaCell({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  )),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
