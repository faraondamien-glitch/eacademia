import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/challenges_repository.dart';
import '../domain/challenge_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/challenge_card.dart';
import 'widgets/leaderboard_widget.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();
    final repo = ref.read(challengesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
          ],
        ),
      ),
      body: StreamBuilder<List<ChallengeModel>>(
        stream: repo.watchChallenges(user.role.value),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const _ChallengesSkeleton();
          }
          if (snap.hasError) {
            return _ErrorState(onRetry: () => setState(() {}));
          }

          final all = snap.data ?? [];
          final actifs = all.where((c) => c.isActive).toList();
          final termines = all.where((c) => !c.isActive).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ActiveTab(challenges: actifs),
              _TerminatedTab(challenges: termines),
            ],
          );
        },
      ),
    );
  }
}

// ── Onglet En cours ───────────────────────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  final List<ChallengeModel> challenges;
  const _ActiveTab({required this.challenges});

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const _EmptyState(
        icon: Icons.emoji_events_outlined,
        message: 'Aucun challenge en cours',
      );
    }

    // Le premier challenge actif sert de référence pour le leaderboard
    final leaderboardChallengeId = challenges.first.id;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Challenges actifs
          ...challenges.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChallengeCard(challenge: c),
              )),

          const SizedBox(height: 8),

          // Leaderboard du premier challenge actif
          Text(
            'Classement — ${challenges.first.title}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          LeaderboardWidget(challengeId: leaderboardChallengeId),
        ],
      ),
    );
  }
}

// ── Onglet Terminés ───────────────────────────────────────────────────────────

class _TerminatedTab extends StatelessWidget {
  final List<ChallengeModel> challenges;
  const _TerminatedTab({required this.challenges});

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        message: 'Aucun challenge terminé',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length,
        separatorBuilder: (_, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => ChallengeCard(challenge: challenges[i]),
      ),
    );
  }
}

// ── États ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            message,
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
          const Text('Impossible de charger les challenges.'),
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

class _ChallengesSkeleton extends StatelessWidget {
  const _ChallengesSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
