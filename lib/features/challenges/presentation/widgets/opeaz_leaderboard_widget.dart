import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/opeaz_repository.dart';
import '../../../../core/theme/app_colors.dart';

class OpeazLeaderboardWidget extends ConsumerWidget {
  final String challengeId;
  final String currentUserId;

  const OpeazLeaderboardWidget({
    super.key,
    required this.challengeId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<LeaderboardEntryOpeaz>>(
      future: ref
          .read(opeazRepositoryProvider)
          .getLeaderboard(challengeId, limit: 10),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LeaderboardSkeleton();
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Classement non disponible',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final entries = snap.data!;
        final top3 = entries.take(3).toList();
        final rest = entries.skip(3).toList();

        return Column(
          children: [
            // Podium top 3
            _Podium(top3: top3),
            const SizedBox(height: 12),

            // Reste du classement
            if (rest.isNotEmpty)
              Card(
                child: Column(
                  children: rest
                      .map((e) => _LeaderboardRow(
                            entry: e,
                            isCurrentUser: e.userId == currentUserId ||
                                e.displayName == 'Vous',
                          ))
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<LeaderboardEntryOpeaz> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    final medals = ['🥇', '🥈', '🥉'];
    final heights = [80.0, 60.0, 50.0];
    final order = top3.length >= 3 ? [1, 0, 2] : [0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map((i) {
        if (i >= top3.length) return const Expanded(child: SizedBox());
        final e = top3[i];
        return Expanded(
          child: Column(
            children: [
              Text(medals[i], style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                e.displayName.split(' ').first,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${e.score} unités',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                height: heights[i],
                decoration: BoxDecoration(
                  color: _podiumColor(i),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: Center(
                  child: Text(
                    '#${e.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _podiumColor(int i) {
    return switch (i) {
      0 => const Color(0xFFFFD700),
      1 => const Color(0xFFC0C0C0),
      _ => const Color(0xFFCD7F32),
    };
  }
}

// ── Ligne de classement ───────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntryOpeaz entry;
  final bool isCurrentUser;

  const _LeaderboardRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: isCurrentUser
          ? AppColors.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Rang
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Avatar initiales
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.primary
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.displayName.isNotEmpty
                    ? entry.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: isCurrentUser
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nom
          Expanded(
            child: Text(
              isCurrentUser ? '${entry.displayName} (vous)' : entry.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w700 : null,
                color: isCurrentUser ? AppColors.primary : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score + points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score} unités',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (entry.points > 0)
                Text(
                  '${entry.points} pts',
                  style: const TextStyle(
                      color: AppColors.secondary, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [80.0, 110.0, 70.0].map((h) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              )).toList(),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(height: 44, color: base),
          ),
        ),
      ],
    );
  }
}
