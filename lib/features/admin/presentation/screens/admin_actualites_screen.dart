import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/actualites/data/actualites_repository.dart';
import '../../../../features/actualites/domain/actu_model.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AdminActualitesScreen extends ConsumerWidget {
  const AdminActualitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(actualitesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualités'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, repo, null),
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
      body: StreamBuilder<List<ActuModel>>(
        stream: repo.watchActualites(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper_outlined,
                      size: 64,
                      color: AppColors.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Aucune actualité publiée'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context, repo, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer la première'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ActuAdminTile(
              actu: list[i],
              onEdit: () => _openForm(context, repo, list[i]),
              onDelete: () => _confirmDelete(context, repo, list[i]),
              onTogglePin: () =>
                  repo.togglePin(list[i].id, !list[i].isPinned),
            ),
          );
        },
      ),
    );
  }

  void _openForm(
      BuildContext context, ActualitesRepository repo, ActuModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ActuForm(repo: repo, existing: existing),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ActualitesRepository repo, ActuModel actu) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text(actu.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) await repo.delete(actu.id);
  }
}

// ── Ligne liste admin ─────────────────────────────────────────────────────────

class _ActuAdminTile extends StatelessWidget {
  final ActuModel actu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const _ActuAdminTile({
    required this.actu,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _categoryColor(actu.category).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_categoryIcon(actu.category),
              color: _categoryColor(actu.category), size: 20),
        ),
        title: Row(
          children: [
            if (actu.isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.push_pin, size: 13, color: AppColors.primary),
              ),
            Expanded(
              child: Text(actu.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        subtitle: Text(
          '${actu.category.label} · ${_formatDate(actu.publishedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'pin') onTogglePin();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 16),
                SizedBox(width: 8),
                Text('Modifier'),
              ]),
            ),
            PopupMenuItem(
              value: 'pin',
              child: Row(children: [
                Icon(
                  actu.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(actu.isPinned ? 'Dés-épingler' : 'Épingler'),
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text('Supprimer', style: TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(ActuCategory c) => switch (c) {
        ActuCategory.produit => AppColors.primary,
        ActuCategory.evenement => AppColors.secondary,
        ActuCategory.commercial => AppColors.success,
        ActuCategory.sante => const Color(0xFF00BCD4),
        ActuCategory.info => AppColors.textSecondary,
      };

  IconData _categoryIcon(ActuCategory c) => switch (c) {
        ActuCategory.produit => Icons.medication_outlined,
        ActuCategory.evenement => Icons.event_outlined,
        ActuCategory.commercial => Icons.trending_up_outlined,
        ActuCategory.sante => Icons.health_and_safety_outlined,
        ActuCategory.info => Icons.info_outline,
      };

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Formulaire création / édition ─────────────────────────────────────────────

class _ActuForm extends ConsumerStatefulWidget {
  final ActualitesRepository repo;
  final ActuModel? existing;

  const _ActuForm({required this.repo, this.existing});

  @override
  ConsumerState<_ActuForm> createState() => _ActuFormState();
}

class _ActuFormState extends ConsumerState<_ActuForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _authorCtrl;
  late ActuCategory _category;
  late bool _isPinned;
  final Set<String> _targetRoles = {};
  bool _saving = false;

  static const _allRoles = [
    ('pharmacien', 'Pharmacien'),
    ('medecin', 'Médecin'),
    ('kine', 'Kinésithérapeute'),
    ('commercial', 'Commercial'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _bodyCtrl = TextEditingController(text: e?.body ?? '');
    _imageCtrl = TextEditingController(text: e?.imageUrl ?? '');
    _authorCtrl = TextEditingController(
        text: e?.author ?? ref.read(userProvider)?.name ?? 'Granions');
    _category = e?.category ?? ActuCategory.info;
    _isPinned = e?.isPinned ?? false;
    if (e != null) _targetRoles.addAll(e.targetRoles);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final actu = ActuModel(
        id: widget.existing?.id ?? '',
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        category: _category,
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        publishedAt: widget.existing?.publishedAt ?? DateTime.now(),
        targetRoles: _targetRoles.toList(),
        isPinned: _isPinned,
      );

      if (widget.existing != null) {
        await widget.repo.update(actu);
      } else {
        await widget.repo.publish(actu);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null
                ? '✅ Actualité mise à jour'
                : '✅ Actualité publiée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.98,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Poignée + titre
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Text(isEdit ? 'Modifier l\'actualité' : 'Publier une actualité',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(isEdit ? 'Enregistrer' : 'Publier',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      // Catégorie
                      Text('Catégorie',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ActuCategory.values.map((cat) => ChoiceChip(
                          label: Text(cat.label),
                          selected: _category == cat,
                          onSelected: (_) => setState(() => _category = cat),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Titre
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(labelText: 'Titre *'),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),

                      // Corps
                      TextFormField(
                        controller: _bodyCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Contenu *',
                            alignLabelWithHint: true),
                        maxLines: 6,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),

                      // Image URL
                      TextFormField(
                        controller: _imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'URL image (optionnel)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),

                      // Auteur
                      TextFormField(
                        controller: _authorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Auteur',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Audience
                      Text('Audience (vide = tous)',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _allRoles.map((r) {
                          final (val, label) = r;
                          return FilterChip(
                            label: Text(label),
                            selected: _targetRoles.contains(val),
                            onSelected: (v) => setState(() {
                              v
                                  ? _targetRoles.add(val)
                                  : _targetRoles.remove(val);
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Épingler
                      SwitchListTile(
                        title: const Text('Épingler en tête de fil'),
                        value: _isPinned,
                        onChanged: (v) => setState(() => _isPinned = v),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
