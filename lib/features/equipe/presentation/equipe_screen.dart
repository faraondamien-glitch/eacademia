import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/equipe_repository.dart';

class EquipeScreen extends ConsumerWidget {
  const EquipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(userProvider);
    if (manager == null) return const SizedBox.shrink();

    final repo = ref.read(equipeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Équipe'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddForm(context, manager, repo),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Ajouter un préparateur'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: repo.watchTeam(manager.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final team = snap.data ?? [];

          if (team.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined,
                      size: 64,
                      color: AppColors.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Aucun préparateur dans votre équipe',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddForm(context, manager, repo),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Ajouter le premier'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Bandeau récap
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group, color: Colors.white, size: 32),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${team.length} préparateur${team.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          manager.region.isNotEmpty
                              ? 'Pharmacie · ${manager.region}'
                              : 'Votre pharmacie',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Liste
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: team.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _TeamMemberTile(
                    member: team[i],
                    onRemove: () => _confirmRemove(context, repo, team[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddForm(
      BuildContext context, UserModel manager, EquipeRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddPreparateurForm(manager: manager, repo: repo),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, EquipeRepository repo, UserModel member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer de l\'équipe ?'),
        content: Text(
            '${member.name} ne fera plus partie de votre équipe. Son compte sera conservé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok == true) await repo.removeFromTeam(member.uid);
  }
}

// ── Tuile membre ──────────────────────────────────────────────────────────────

class _TeamMemberTile extends StatelessWidget {
  final UserModel member;
  final VoidCallback onRemove;

  const _TeamMemberTile({required this.member, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : 'P',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(member.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          member.email,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'remove') onRemove();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(children: [
                Icon(Icons.person_remove_outlined,
                    size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text('Retirer de l\'équipe',
                    style: TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulaire ajout ──────────────────────────────────────────────────────────

class _AddPreparateurForm extends ConsumerStatefulWidget {
  final UserModel manager;
  final EquipeRepository repo;

  const _AddPreparateurForm({required this.manager, required this.repo});

  @override
  ConsumerState<_AddPreparateurForm> createState() =>
      _AddPreparateurFormState();
}

class _AddPreparateurFormState extends ConsumerState<_AddPreparateurForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repo.addPreparateur(
        managerId: widget.manager.uid,
        managerRegion: widget.manager.region,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${_nameCtrl.text.trim()} ajouté(e) à votre équipe'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String msg = 'Erreur lors de la création';
        if (e.toString().contains('email-already-in-use')) {
          msg = 'Cet email est déjà utilisé';
        } else if (e.toString().contains('weak-password')) {
          msg = 'Mot de passe trop faible (6 caractères minimum)';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
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
                    Text('Ajouter un préparateur',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Créer',
                              style:
                                  TextStyle(fontWeight: FontWeight.w700)),
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
                      // Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Le préparateur pourra se connecter avec cet email et ce mot de passe. Il aura accès aux formations, aux actualités et au catalogue produits, mais pas aux factures ni aux challenges.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nom
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Mot de passe
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          helperText: '6 caractères minimum',
                        ),
                        obscureText: _obscurePassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (v.length < 6) {
                            return '6 caractères minimum';
                          }
                          return null;
                        },
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
