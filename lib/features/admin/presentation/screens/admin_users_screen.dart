import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../features/auth/domain/user_model.dart';
import '../../../../core/theme/app_colors.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aucun utilisateur'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final user = UserModel.fromFirestore(docs[i]);
              return _UserTile(user: user);
            },
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(user.name),
        subtitle: Text('${user.email} · ${user.role.label}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.isAdmin)
              const Tooltip(
                message: 'Administrateur',
                child: Icon(Icons.admin_panel_settings,
                    size: 18, color: AppColors.secondary),
              ),
            PopupMenuButton<String>(
              onSelected: (v) => _handleAction(context, v, user),
              itemBuilder: (_) => [
                // Changer le rôle
                ...UserRole.values.map((r) => PopupMenuItem(
                      value: 'role_${r.value}',
                      enabled: user.role != r,
                      child: Row(children: [
                        Icon(Icons.swap_horiz,
                            size: 16,
                            color: user.role == r
                                ? AppColors.textDisabled
                                : null),
                        const SizedBox(width: 8),
                        Text('→ ${r.label}'),
                      ]),
                    )),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'toggle_admin',
                  child: Row(children: [
                    Icon(
                      user.isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.admin_panel_settings,
                      size: 16,
                      color: user.isAdmin ? AppColors.error : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isAdmin ? 'Retirer admin' : 'Rendre admin'),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, String action, UserModel user) async {
    final db = FirebaseFirestore.instance;
    if (action.startsWith('role_')) {
      final newRole = action.replaceFirst('role_', '');
      await db.collection('users').doc(user.uid).update({'role': newRole});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rôle mis à jour → $newRole')),
        );
      }
    } else if (action == 'toggle_admin') {
      await db
          .collection('users')
          .doc(user.uid)
          .update({'isAdmin': !user.isAdmin});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                user.isAdmin ? 'Droits admin retirés' : 'Utilisateur promu admin'),
          ),
        );
      }
    }
  }
}
