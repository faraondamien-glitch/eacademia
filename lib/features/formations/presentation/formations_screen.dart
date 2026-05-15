import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/formations_repository.dart';
import '../domain/formation_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/formation_card.dart';

class FormationsScreen extends ConsumerStatefulWidget {
  const FormationsScreen({super.key});

  @override
  ConsumerState<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends ConsumerState<FormationsScreen> {
  String? _selectedTheme;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final repo = ref.read(formationsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Formations')),
      body: StreamBuilder<Map<String, ProgressModel>>(
        stream: repo.watchAllProgress(user.uid),
        builder: (context, progressSnap) {
          final progressMap = progressSnap.data ?? {};

          return StreamBuilder<List<FormationModel>>(
            stream: repo.watchFormations(user.role.value),
            builder: (context, formSnap) {
              // Skeleton loader au premier chargement
              if (formSnap.connectionState == ConnectionState.waiting &&
                  !formSnap.hasData) {
                return _FormationsSkeleton();
              }

              // Erreur avec retry
              if (formSnap.hasError) {
                return _ErrorState(
                  message: 'Impossible de charger les formations.',
                  onRetry: () => setState(() {}),
                );
              }

              final formations = formSnap.data ?? [];
              final themes = formations
                  .map((f) => f.theme)
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              final filtered = _selectedTheme == null
                  ? formations
                  : formations
                      .where((f) => f.theme == _selectedTheme)
                      .toList();

              return Column(
                children: [
                  if (themes.isNotEmpty)
                    _ThemeFilter(
                      themes: themes,
                      selected: _selectedTheme,
                      onSelected: (t) =>
                          setState(() => _selectedTheme = t),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: filtered.isEmpty
                          ? _EmptyState(hasFilter: _selectedTheme != null)
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, i) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final f = filtered[i];
                                final prog = progressMap[f.id];
                                return FormationCard(
                                  formation: f,
                                  progress: prog?.percentage,
                                  onTap: () =>
                                      context.push('/formations/${f.id}'),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Filtre par thème ─────────────────────────────────────────────────────────

class _ThemeFilter extends StatelessWidget {
  final List<String> themes;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _ThemeFilter({
    required this.themes,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: const Text('Tous'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          ...themes.map((t) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(t),
                  selected: selected == t,
                  onSelected: (_) =>
                      onSelected(selected == t ? null : t),
                ),
              )),
        ],
      ),
    );
  }
}

// ── États vides / erreur / skeleton ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.school_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Aucune formation dans ce thème'
                : 'Aucune formation disponible',
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
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
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

class _FormationsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final baseColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, idx) => Container(
        height: 96,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
