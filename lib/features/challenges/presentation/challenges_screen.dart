import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/opeaz_repository.dart';
import '../data/inapp_challenges_repository.dart';
import '../domain/inapp_challenge_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/opeaz_config.dart';
import 'widgets/challenge_card.dart';
import 'widgets/opeaz_leaderboard_widget.dart';
import 'widgets/rewards_widget.dart';
import 'widgets/inapp_challenge_card.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<ChallengeWithProgress>? _challenges;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(userProvider);
    if (user == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(opeazRepositoryProvider);
      final data = await repo.getChallenges(
        userId: user.uid,
        userEmail: user.email,
      );
      if (mounted) setState(() { _challenges = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les challenges.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        actions: [
          if (!OpeazConfig.isConfigured)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('DÉMO', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                side: const BorderSide(color: Colors.orange),
                padding: EdgeInsets.zero,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loading ? null : _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Opeaz'),
            Tab(text: 'Formations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Onglet Opeaz ─────────────────────────────────────────────────
          _loading
              ? const _ChallengesSkeleton()
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _loadData)
                  : _OpeazTab(challenges: _challenges ?? [], user: user),

          // ── Onglet Formations (in-app) ───────────────────────────────────
          _FormationsTab(user: user),
        ],
      ),
    );
  }
}

// ── Onglet Opeaz ─────────────────────────────────────────────────────────────

class _OpeazTab extends StatefulWidget {
  final List<ChallengeWithProgress> challenges;
  final dynamic user;

  const _OpeazTab({required this.challenges, required this.user});

  @override
  State<_OpeazTab> createState() => _OpeazTabState();
}

class _OpeazTabState extends State<_OpeazTab>
    with SingleTickerProviderStateMixin {
  late final TabController _sub;

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actifs =
        widget.challenges.where((c) => c.challenge.isActive).toList();
    final termines =
        widget.challenges.where((c) => !c.challenge.isActive).toList();

    return Column(
      children: [
        TabBar(
          controller: _sub,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
            Tab(text: 'Récompenses'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _sub,
            children: [
              _ActiveTab(challenges: actifs, user: widget.user),
              _TerminatedTab(challenges: termines),
              RewardsWidget(
                  userId: widget.user.uid, userEmail: widget.user.email),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Onglet Formations (in-app challenges) ────────────────────────────────────

class _FormationsTab extends StatefulWidget {
  final dynamic user;
  const _FormationsTab({required this.user});

  @override
  State<_FormationsTab> createState() => _FormationsTabState();
}

class _FormationsTabState extends State<_FormationsTab> {
  List<InAppChallengeWithProgress>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = InAppChallengesRepository();
      final snap = await FirebaseFirestore.instance
          .collection('inapp_challenges')
          .get();
      final challenges = snap.docs.map(InAppChallengeModel.fromFirestore).toList();

      final items = await Future.wait(
        challenges.map((c) async {
          final current = await repo.getProgress(
            userId: widget.user.uid,
            challenge: c,
          );
          return InAppChallengeWithProgress(challenge: c, current: current);
        }),
      );

      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const _ChallengesSkeleton();
    if (_error != null) {
      return _ErrorState(message: 'Erreur : $_error', onRetry: _load);
    }

    final items = _items ?? [];
    final totalPoints = items
        .where((i) => i.isCompleted)
        .fold(0, (sum, i) => sum + i.challenge.rewardPoints);
    final euroValue = (totalPoints * 0.5);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Bannière ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suivi formations',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        '${items.where((i) => i.isCompleted).length} / ${items.length} objectifs atteints',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Liste des challenges ───────────────────────────────────────
          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 56,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('Aucun challenge disponible',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else ...[
            Text('Objectifs', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InAppChallengeCard(item: item),
                )),
          ],

          // ── Cagnotte ──────────────────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.card_giftcard,
                          color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ma cagnotte',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CagnotteMetric(
                        label: 'Points gagnés',
                        value: '$totalPoints pts',
                        icon: Icons.stars_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: AppColors.secondary.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _CagnotteMetric(
                        label: 'Carte cadeau',
                        value: '${euroValue % 1 == 0 ? euroValue.toInt() : euroValue.toStringAsFixed(1)} €',
                        icon: Icons.redeem,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1 point = 0,50 € · Cumulez des points en complétant vos objectifs',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet En cours ───────────────────────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  final List<ChallengeWithProgress> challenges;
  final dynamic user;

  const _ActiveTab({required this.challenges, required this.user});

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const _EmptyState(
        icon: Icons.emoji_events_outlined,
        message: 'Aucun challenge en cours',
        sub: 'Revenez bientôt pour de nouveaux défis Granions',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Score total Opeaz ──────────────────────────────────────────
          _OpeazScoreBanner(challenges: challenges),
          const SizedBox(height: 16),

          // ── Challenges actifs ──────────────────────────────────────────
          ...challenges.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OpeazChallengeCard(item: c),
            ),
          ),

          const SizedBox(height: 8),

          // ── Leaderboard du challenge principal ─────────────────────────
          Text(
            'Classement — ${challenges.first.challenge.title}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          OpeazLeaderboardWidget(
            challengeId: challenges.first.challenge.id,
            currentUserId: user?.uid ?? '',
          ),
        ],
      ),
    );
  }
}

// ── Onglet Terminés ───────────────────────────────────────────────────────────

class _TerminatedTab extends StatelessWidget {
  final List<ChallengeWithProgress> challenges;
  const _TerminatedTab({required this.challenges});

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        message: 'Aucun challenge terminé',
        sub: 'Vos challenges passés apparaîtront ici',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => OpeazChallengeCard(item: challenges[i]),
    );
  }
}

// ── Bandeau score Opeaz ───────────────────────────────────────────────────────

class _OpeazScoreBanner extends StatelessWidget {
  final List<ChallengeWithProgress> challenges;
  const _OpeazScoreBanner({required this.challenges});

  @override
  Widget build(BuildContext context) {
    final totalPoints =
        challenges.fold(0, (sum, c) => sum + c.totalPoints);
    final bestRank = challenges
        .where((c) => c.userRank > 0)
        .map((c) => c.userRank)
        .fold<int>(999, (a, b) => a < b ? a : b);
    final winners = challenges.where((c) => c.isWinner).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Logo Opeaz placeholder
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emoji_events,
                color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mon score Opeaz',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (bestRank < 999)
                _MiniStat(
                  label: 'Meilleur rank',
                  value: '#$bestRank',
                  color: AppColors.secondary,
                ),
              if (winners > 0)
                _MiniStat(
                  label: 'Gagnés',
                  value: '$winners 🏆',
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── États ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(sub,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Métrique cagnotte ─────────────────────────────────────────────────────────

class _CagnotteMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CagnotteMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ChallengesSkeleton extends StatelessWidget {
  const _ChallengesSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) => Container(
        height: 180,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
