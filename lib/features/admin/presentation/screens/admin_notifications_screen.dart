import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// L'admin rédige une notification → elle est écrite dans `notification_queue`.
/// Une Cloud Function Firebase (à déployer séparément) lit cette collection
/// et appelle l'API FCM pour envoyer la notif.
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all'; // 'all' | rôle
  String _type = 'info'; // pour le routing in-app
  bool _sending = false;

  static const _targets = [
    ('all', 'Tous les utilisateurs'),
    ('pharmacien', 'Pharmaciens'),
    ('medecin', 'Médecins'),
    ('kine', 'Kinésithérapeutes'),
    ('commercial', 'Commerciaux'),
  ];

  static const _types = [
    ('info', 'Information générale'),
    ('formation', 'Nouvelle formation'),
    ('challenge', 'Challenge'),
    ('facture', 'Facture'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final user = ref.read(userProvider);
      await FirebaseFirestore.instance.collection('notification_queue').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'target': _target, // topic FCM à cibler
        'type': _type,
        'sentBy': user?.uid ?? 'admin',
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending', // → 'sent' ou 'error' par la Cloud Function
      });

      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() { _sending = false; _target = 'all'; _type = 'info'; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification mise en file d\'envoi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications push'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info Cloud Function
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Les notifications sont envoyées via une Cloud Function Firebase. '
                    'Le formulaire écrit dans notification_queue ; '
                    'la fonction se charge de l\'envoi FCM.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audience
                Text('Destinataires', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _targets.map((t) {
                    final (val, label) = t;
                    return ChoiceChip(
                      label: Text(label),
                      selected: _target == val,
                      onSelected: (_) => setState(() => _target = val),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Type
                Text('Type de notification', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((t) {
                    final (val, label) = t;
                    return ChoiceChip(
                      label: Text(label),
                      selected: _type == val,
                      onSelected: (_) => setState(() => _type = val),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Titre
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titre de la notification *',
                    hintText: 'Ex : Nouvelle formation disponible',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),

                // Corps
                TextFormField(
                  controller: _bodyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Message *',
                    hintText: 'Contenu de la notification…',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 28),

                // Bouton envoyer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: const Text('Envoyer la notification'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 12),

          // Historique
          Text('Historique récent', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _NotificationHistory(),
        ],
      ),
    );
  }
}

class _NotificationHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notification_queue')
          .orderBy('sentAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('Aucune notification envoyée',
              style: TextStyle(color: AppColors.textSecondary));
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final status = d['status'] as String? ?? 'pending';
            final statusColor = switch (status) {
              'sent' => AppColors.success,
              'error' => AppColors.error,
              _ => Colors.orange,
            };
            return ListTile(
              dense: true,
              leading: Icon(Icons.notifications_outlined,
                  color: statusColor, size: 20),
              title: Text(d['title'] ?? '',
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                  '${d['target'] ?? 'all'} · ${d['type'] ?? ''}',
                  style: const TextStyle(fontSize: 11)),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
