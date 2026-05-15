import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/actualites_repository.dart';
import '../domain/actu_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';

class PublishActuScreen extends ConsumerStatefulWidget {
  const PublishActuScreen({super.key});

  @override
  ConsumerState<PublishActuScreen> createState() => _PublishActuScreenState();
}

class _PublishActuScreenState extends ConsumerState<PublishActuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();

  ActuCategory _category = ActuCategory.info;
  bool _isPinned = false;
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
    final user = ref.read(userProvider);
    _authorCtrl.text = user?.name ?? 'Granions';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(actualitesRepositoryProvider);
      final actu = ActuModel(
        id: '',
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        category: _category,
        imageUrl:
            _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        publishedAt: DateTime.now(),
        targetRoles: _targetRoles.toList(),
        isPinned: _isPinned,
      );
      await repo.publish(actu);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Actualité publiée'),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier une actualité'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _publish,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text('Publier',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Catégorie ──────────────────────────────────────────────────
            Text('Catégorie', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ActuCategory.values.map((cat) {
                final selected = _category == cat;
                return ChoiceChip(
                  label: Text(cat.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Titre ──────────────────────────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex : Lancement Granions Sélénium Bio',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Titre requis' : null,
            ),
            const SizedBox(height: 16),

            // ── Corps ──────────────────────────────────────────────────────
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Contenu *',
                hintText:
                    'Rédigez votre actualité ici...',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Contenu requis' : null,
            ),
            const SizedBox(height: 16),

            // ── Image URL ──────────────────────────────────────────────────
            TextFormField(
              controller: _imageCtrl,
              decoration: const InputDecoration(
                labelText: 'URL de l\'image (optionnel)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // ── Auteur ─────────────────────────────────────────────────────
            TextFormField(
              controller: _authorCtrl,
              decoration: const InputDecoration(
                labelText: 'Auteur',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),

            // ── Audience cible ─────────────────────────────────────────────
            Text('Audience cible', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              'Laisser vide = visible par tous',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _allRoles.map((r) {
                final (val, label) = r;
                final selected = _targetRoles.contains(val);
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    v ? _targetRoles.add(val) : _targetRoles.remove(val);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Épingler ───────────────────────────────────────────────────
            SwitchListTile(
              title: const Text('Épingler en tête de fil'),
              subtitle:
                  const Text('L\'actu apparaîtra toujours en premier'),
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            // ── Bouton publier ─────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _saving ? null : _publish,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Publier maintenant'),
            ),
          ],
        ),
      ),
    );
  }
}
