import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/formations_repository.dart';
import '../domain/formation_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class FormationDetailScreen extends ConsumerWidget {
  final String formationId;
  const FormationDetailScreen({super.key, required this.formationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final repo = ref.read(formationsRepositoryProvider);

    return FutureBuilder<FormationModel?>(
      future: repo.getFormation(formationId),
      builder: (context, formSnap) {
        if (formSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final formation = formSnap.data;
        if (formation == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Formation introuvable')),
          );
        }

        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: Text(formation.title)),
            body: const Center(child: Text('Non connecté')),
          );
        }

        return StreamBuilder<ProgressModel?>(
          stream: repo.watchProgress(user.uid, formationId),
          builder: (context, progressSnap) {
            final progress = progressSnap.data;
            final completed = progress?.completedModules ?? [];
            final total = formation.modules.length;
            final pct = total > 0 ? completed.length / total : 0.0;
            final isFinished = pct >= 1.0 && total > 0;

            // Premier module non complété
            int nextModuleIndex = formation.modules.indexWhere((m) {
              final id = m['id']?.toString() ??
                  'mod_${formation.modules.indexOf(m)}';
              return !completed.contains(id);
            });
            if (nextModuleIndex == -1) nextModuleIndex = 0;

            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  // AppBar avec header dégradé + progression
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    title: Text(
                      formation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _FormationHeader(
                        formation: formation,
                        progress: pct,
                        completedCount: completed.length,
                        totalCount: total,
                        isFinished: isFinished,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Méta-infos
                        _MetaRow(formation: formation),
                        const SizedBox(height: 16),

                        // Thème
                        if (formation.theme.isNotEmpty) ...[
                          Wrap(
                            children: [
                              Chip(label: Text(formation.theme)),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Description
                        Text(
                          formation.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 28),

                        // Liste des modules
                        Row(
                          children: [
                            Text(
                              'Modules',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            Text(
                              '${completed.length}/$total complétés',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ...formation.modules.asMap().entries.map((entry) {
                          final i = entry.key;
                          final mod = entry.value;
                          final modId =
                              mod['id']?.toString() ?? 'mod_$i';
                          final isDone = completed.contains(modId);
                          final isNext = i == nextModuleIndex && !isFinished;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ModuleItem(
                              index: i + 1,
                              title: mod['title']?.toString() ??
                                  'Module ${i + 1}',
                              description:
                                  mod['description']?.toString(),
                              duration: mod['durationMinutes'] as int?,
                              isCompleted: isDone,
                              isNext: isNext,
                              onTap: () => _openModule(
                                context: context,
                                ref: ref,
                                repo: repo,
                                userId: user.uid,
                                formationId: formationId,
                                modId: modId,
                                modTitle: mod['title']?.toString() ??
                                    'Module ${i + 1}',
                                completed: completed,
                                total: total,
                                isDone: isDone,
                              ),
                            ),
                          );
                        }),
                      ]),
                    ),
                  ),
                ],
              ),

              // Bouton flottant Commencer / Reprendre / Terminée
              bottomNavigationBar: _BottomCta(
                isFinished: isFinished,
                hasStarted: completed.isNotEmpty,
                onPressed: () => _openModule(
                  context: context,
                  ref: ref,
                  repo: repo,
                  userId: user.uid,
                  formationId: formationId,
                  modId: formation.modules[nextModuleIndex]['id']
                          ?.toString() ??
                      'mod_$nextModuleIndex',
                  modTitle: formation.modules[nextModuleIndex]['title']
                          ?.toString() ??
                      'Module ${nextModuleIndex + 1}',
                  completed: completed,
                  total: total,
                  isDone: false,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openModule({
    required BuildContext context,
    required WidgetRef ref,
    required FormationsRepository repo,
    required String userId,
    required String formationId,
    required String modId,
    required String modTitle,
    required List<String> completed,
    required int total,
    required bool isDone,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ModuleSheet(
        modId: modId,
        modTitle: modTitle,
        isDone: isDone,
        onMarkDone: () async {
          final updated = List<String>.from(completed);
          if (!updated.contains(modId)) updated.add(modId);
          await repo.updateProgress(
            userId: userId,
            formationId: formationId,
            completedModules: updated,
            totalModules: total,
          );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Header dégradé avec progression ─────────────────────────────────────────

class _FormationHeader extends StatelessWidget {
  final FormationModel formation;
  final double progress;
  final int completedCount;
  final int totalCount;
  final bool isFinished;

  const _FormationHeader({
    required this.formation,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.isFinished,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFinished
              ? [AppColors.successDark, AppColors.success]
              : [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Icône décorative
          Positioned(
            right: -20,
            bottom: -10,
            child: Icon(
              Icons.school,
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (totalCount > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            color: isFinished
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
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isFinished
                        ? '✓ Formation terminée'
                        : '$completedCount/$totalCount modules',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Méta-infos (durée, modules) ───────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final FormationModel formation;
  const _MetaRow({required this.formation});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetaChip(
          icon: Icons.access_time_outlined,
          label: Formatters.formatDuration(formation.durationMinutes),
        ),
        const SizedBox(width: 8),
        _MetaChip(
          icon: Icons.layers_outlined,
          label: '${formation.modules.length} modules',
        ),
        if (formation.isNew) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(6),
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

// ── Item de module ────────────────────────────────────────────────────────────

class _ModuleItem extends StatelessWidget {
  final int index;
  final String title;
  final String? description;
  final int? duration;
  final bool isCompleted;
  final bool isNext;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.index,
    required this.title,
    this.description,
    this.duration,
    required this.isCompleted,
    required this.isNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color leadColor = isCompleted
        ? AppColors.success
        : isNext
            ? AppColors.primary
            : AppColors.textDisabled;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Numéro / icône
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: leadColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: AppColors.success, size: 18)
                      : Text(
                          '$index',
                          style: TextStyle(
                            color: leadColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Titre + sous-titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isCompleted
                            ? AppColors.textSecondary
                            : theme.colorScheme.onSurface,
                        decoration: isCompleted
                            ? TextDecoration.none
                            : null,
                      ),
                    ),
                    if (description != null && description!.isNotEmpty)
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        isCompleted
                            ? 'Terminé'
                            : isNext
                                ? 'À faire maintenant'
                                : 'À venir',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isNext ? AppColors.primary : null,
                          fontWeight: isNext ? FontWeight.w600 : null,
                        ),
                      ),
                  ],
                ),
              ),

              // Durée + chevron
              if (duration != null) ...[
                Text(
                  Formatters.formatDuration(duration!),
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                isCompleted ? Icons.replay : Icons.play_arrow_outlined,
                color: leadColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bouton CTA bas de page ────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final bool isFinished;
  final bool hasStarted;
  final VoidCallback onPressed;

  const _BottomCta({
    required this.isFinished,
    required this.hasStarted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
        onPressed: onPressed,
        icon: Icon(isFinished
            ? Icons.replay
            : hasStarted
                ? Icons.play_arrow
                : Icons.school_outlined),
        label: Text(isFinished
            ? 'Revoir la formation'
            : hasStarted
                ? 'Reprendre'
                : 'Commencer'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFinished ? AppColors.success : AppColors.primary,
        ),
      ),
    );
  }
}

// ── Sheet de lecture de module ────────────────────────────────────────────────

class _ModuleSheet extends StatelessWidget {
  final String modId;
  final String modTitle;
  final bool isDone;
  final Future<void> Function() onMarkDone;

  const _ModuleSheet({
    required this.modId,
    required this.modTitle,
    required this.isDone,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Poignée
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Entête
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        modTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Placeholder contenu module
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_outline,
                                size: 56, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Contenu du module',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Contenu pédagogique',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Le contenu de ce module sera chargé depuis Firebase Storage '
                      '(vidéo, slides ou texte enrichi) en fonction du type défini '
                      'dans le document Firestore du module.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // Bouton marquer comme terminé
                    if (!isDone)
                      _MarkDoneButton(onPressed: onMarkDone)
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: AppColors.success),
                            SizedBox(width: 8),
                            Text(
                              'Module déjà terminé',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarkDoneButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  const _MarkDoneButton({required this.onPressed});

  @override
  State<_MarkDoneButton> createState() => _MarkDoneButtonState();
}

class _MarkDoneButtonState extends State<_MarkDoneButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              await widget.onPressed();
            },
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.check),
      label: const Text('Marquer comme terminé'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
      ),
    );
  }
}
