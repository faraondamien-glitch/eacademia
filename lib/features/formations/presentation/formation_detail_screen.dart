import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/learning360_repository.dart';
import '../domain/formation_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class FormationDetailScreen extends ConsumerWidget {
  final String formationId;
  final FormationWithProgress? preloaded; // passé via extra de GoRouter

  const FormationDetailScreen({
    super.key,
    required this.formationId,
    this.preloaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (preloaded != null) {
      return _DetailView(item: preloaded!, user: user);
    }

    // Fallback : on recharge le catalogue si on arrive directement sur cet écran
    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Non connecté')),
      );
    }

    return FutureBuilder<List<FormationWithProgress>>(
      future: ref.read(learning360RepositoryProvider).getCatalog(
            userId: user.uid,
            userEmail: user.email,
          ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final item = snap.data?.where((e) => e.formation.id == formationId).firstOrNull;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Formation introuvable')),
          );
        }
        return _DetailView(item: item, user: user);
      },
    );
  }
}

// ── Vue principale ────────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  final FormationWithProgress item;
  final dynamic user;

  const _DetailView({required this.item, required this.user});

  @override
  Widget build(BuildContext context) {
    final f = item.formation;
    final progress = item.completionRate;
    final isCompleted = item.isCompleted;
    final isEnrolled = item.isEnrolled;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar dégradé ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            foregroundColor: Colors.white,
            title: Text(
              f.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(
                formation: f,
                progress: progress,
                isCompleted: isCompleted,
                isEnrolled: isEnrolled,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Méta-infos
                _MetaRow(formation: f),
                const SizedBox(height: 20),

                // Thème
                if (f.theme.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(f.theme),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Description
                Text(
                  f.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Progression détaillée (si inscrit)
                if (isEnrolled) ...[
                  _ProgressSection(item: item),
                  const SizedBox(height: 24),
                ],

                // Infos 360Learning
                _L360InfoCard(item: item),
              ]),
            ),
          ),
        ],
      ),

      // ── CTA bas de page ────────────────────────────────────────────────────
      bottomNavigationBar: _BottomCta(
        isCompleted: isCompleted,
        isEnrolled: isEnrolled,
        playerUrl: item.playerUrl,
        formation: f,
        user: user,
      ),
    );
  }
}

// ── Header dégradé ────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final FormationModel formation;
  final double progress;
  final bool isCompleted;
  final bool isEnrolled;

  const _HeroHeader({
    required this.formation,
    required this.progress,
    required this.isCompleted,
    required this.isEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorA = isCompleted ? AppColors.successDark : AppColors.primaryDark;
    final Color colorB = isCompleted ? AppColors.success : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorA, colorB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -10,
            child: Icon(
              Icons.school,
              size: 150,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge source
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '360Learning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (isEnrolled) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            color: isCompleted
                                ? Colors.white
                                : AppColors.secondary,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCompleted
                        ? '✓ Formation terminée'
                        : '${completedModulesCount(progress, formation.totalModules)} / ${formation.totalModules} modules',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ] else
                  Text(
                    'Non inscrit — cliquez sur Commencer pour démarrer',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int completedModulesCount(double rate, int total) =>
      (rate * total).round();
}

// ── Section progression ───────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final FormationWithProgress item;
  const _ProgressSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = item.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ma progression', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _ProgCell(
              value: '${p.completedModules}',
              label: 'modules terminés',
              color: AppColors.success,
            ),
            _ProgCell(
              value: '${p.totalModules - p.completedModules}',
              label: 'restants',
              color: AppColors.primary,
            ),
            _ProgCell(
              value: '${(p.completionRate * 100).round()}%',
              label: 'complété',
              color: item.isCompleted
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ],
        ),
        if (p.lastAccessAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Dernier accès : ${Formatters.formatDate(p.lastAccessAt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _ProgCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info card 360Learning ─────────────────────────────────────────────────────

class _L360InfoCard extends StatelessWidget {
  final FormationWithProgress item;
  const _L360InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.open_in_new_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contenu hébergé sur 360Learning',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Le bouton ci-dessous ouvre votre espace de formation '
                  'directement dans 360Learning.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

// ── Méta-infos ────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final FormationModel formation;
  const _MetaRow({required this.formation});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(
          icon: Icons.access_time_outlined,
          label: Formatters.formatDuration(formation.durationMinutes),
        ),
        _MetaChip(
          icon: Icons.layers_outlined,
          label: '${formation.totalModules} modules',
        ),
        if (formation.isNew)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'NOUVEAU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── CTA bas de page ───────────────────────────────────────────────────────────

class _BottomCta extends ConsumerStatefulWidget {
  final bool isCompleted;
  final bool isEnrolled;
  final String playerUrl;
  final FormationModel formation;
  final dynamic user;

  const _BottomCta({
    required this.isCompleted,
    required this.isEnrolled,
    required this.playerUrl,
    required this.formation,
    required this.user,
  });

  @override
  ConsumerState<_BottomCta> createState() => _BottomCtaState();
}

class _BottomCtaState extends ConsumerState<_BottomCta> {
  bool _loading = false;

  Future<void> _open() async {
    setState(() => _loading = true);
    try {
      String url = widget.playerUrl;

      // Si non inscrit et API configurée → inscrire d'abord
      if (!widget.isEnrolled && widget.user != null) {
        final repo = ref.read(learning360RepositoryProvider);
        url = await repo.enrollAndGetUrl(
          userId: widget.user.uid,
          userEmail: widget.user.email,
          programGuid: widget.formation.programGuid ?? widget.formation.id,
        );
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir : $url')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isCompleted ? AppColors.success : AppColors.primary;
    final IconData ico = widget.isCompleted
        ? Icons.replay
        : widget.isEnrolled
            ? Icons.play_arrow
            : Icons.school_outlined;
    final String label = widget.isCompleted
        ? 'Revoir la formation'
        : widget.isEnrolled
            ? 'Reprendre sur 360Learning'
            : 'Commencer sur 360Learning';

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _open,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(ico),
        label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: bg),
      ),
    );
  }
}
