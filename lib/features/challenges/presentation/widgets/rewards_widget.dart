import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/opeaz_repository.dart';
import '../../../../core/theme/app_colors.dart';

/// Onglet "Récompenses" — affiche les gains Opeaz de l'utilisateur.
class RewardsWidget extends ConsumerWidget {
  final String userId;
  final String userEmail;

  const RewardsWidget({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(opeazRepositoryProvider).getRewards(
            userId: userId,
            userEmail: userEmail,
          ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rewards = snap.data ?? [];

        if (rewards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune récompense pour l\'instant',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Participez aux challenges pour gagner des points et des cadeaux',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        // Calcul du total points
        final totalPoints = rewards.fold<int>(
          0,
          (sum, r) => sum + ((r['points'] as num?)?.toInt() ?? 0),
        );

        return CustomScrollView(
          slivers: [
            // ── Total points ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _TotalPointsBanner(totalPoints: totalPoints),
              ),
            ),

            // ── Liste des récompenses ─────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RewardCard(reward: rewards[i]),
                  ),
                  childCount: rewards.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Bandeau total points ──────────────────────────────────────────────────────

class _TotalPointsBanner extends StatelessWidget {
  final int totalPoints;
  const _TotalPointsBanner({required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.secondary, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total de mes points Opeaz',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$totalPoints pts',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Carte récompense ──────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;
  const _RewardCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = reward['type'] as String? ?? 'points';
    final points = (reward['points'] as num?)?.toInt() ?? 0;
    final giftLabel = reward['giftLabel'] as String?;
    final status = reward['status'] as String? ?? 'credited';
    final challengeTitle = reward['challengeTitle'] as String? ?? '';
    final obtainedAt = reward['obtainedAt'] as String?;

    final isGift = type == 'gift' || type == 'voucher';
    final statusColor =
        status == 'delivered' || status == 'credited'
            ? AppColors.success
            : AppColors.secondary;
    final statusLabel = switch (status) {
      'credited' => 'Points crédités',
      'delivered' => 'Livré',
      'pending' => 'En cours',
      _ => status,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGift
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isGift ? Icons.card_giftcard : Icons.stars_rounded,
                color: isGift ? AppColors.secondary : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGift && giftLabel != null ? giftLabel : '$points pts',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    challengeTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (obtainedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(obtainedAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),

            // Badge statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}
