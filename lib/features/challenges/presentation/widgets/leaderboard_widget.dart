import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/challenges_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/user_provider.dart';

class LeaderboardWidget extends ConsumerWidget {
  final String challengeId;
  const LeaderboardWidget({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(challengesRepositoryProvider);
    final currentUserId = ref.read(userProvider)?.uid ?? '';

    return StreamBuilder<List<LeaderboardEntry>>(
      stream: repo.watchLeaderboard(challengeId),
      builder: (context, snap) {
        final theme = Theme.of(context);

        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _LeaderboardSkeleton();
        }

        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.leaderboard_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('Aucun participant pour l\'instant',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ),
          );
        }

        // Top 3 podium (si au moins 3)
        final top3 = entries.take(3).toList();

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.leaderboard, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text('Classement', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text('Top ${entries.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),

              // Podium top 3
              if (top3.length >= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _Podium(
                    entries: top3,
                    currentUserId: currentUserId,
                  ),
                ),

              const Divider(height: 24),

              // Liste du reste
              ...entries.asMap().entries.map((e) {
                final rank = e.key + 1;
                final entry = e.value;
                final isMe = entry.userId == currentUserId;
                return _LeaderboardRow(
                  rank: rank,
                  entry: entry,
                  isCurrentUser: isMe,
                );
              }),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Podium top 3 ──────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String currentUserId;

  const _Podium({required this.entries, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // Ordre d'affichage visuel : 2e, 1er, 3e
    final order = entries.length >= 3
        ? [entries[1], entries[0], entries[2]]
        : [entries[0]];
    final heights = entries.length >= 3 ? [72.0, 96.0, 56.0] : [96.0];
    final ranks = entries.length >= 3 ? [2, 1, 3] : [1];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(order.length, (i) {
        final entry = order[i];
        final rank = ranks[i];
        final isMe = entry.userId == currentUserId;
        final podiumColor = rank == 1
            ? AppColors.secondary
            : rank == 2
                ? Colors.grey.shade400
                : const Color(0xFFCD7F32);

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar + nom
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: podiumColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: isMe
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: podiumColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.displayName.split(' ').first,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${entry.score} pts',
                style: TextStyle(
                    fontSize: 10, color: podiumColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),

              // Marche du podium
              Container(
                height: heights[i],
                decoration: BoxDecoration(
                  color: podiumColor.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Text(
                    rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Ligne classement ──────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color rankColor;
    if (rank == 1) {
      rankColor = AppColors.secondary;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isCurrentUser
          ? AppColors.primary.withValues(alpha: 0.06)
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: theme.textTheme.titleSmall?.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: (isCurrentUser ? AppColors.primary : AppColors.textSecondary)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.displayName.isNotEmpty
                    ? entry.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCurrentUser ? '${entry.displayName} (moi)' : entry.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            '${entry.score} pts',
            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _LeaderboardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
