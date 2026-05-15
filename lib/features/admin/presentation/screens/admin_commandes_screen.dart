import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class AdminCommandesScreen extends StatefulWidget {
  const AdminCommandesScreen({super.key});

  @override
  State<AdminCommandesScreen> createState() => _AdminCommandesScreenState();
}

class _AdminCommandesScreenState extends State<AdminCommandesScreen> {
  String _statusFilter = 'all';

  static const _statuses = [
    ('all', 'Toutes'),
    ('pending', 'En attente'),
    ('confirmed', 'Confirmées'),
    ('cancelled', 'Annulées'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes packs'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtres statut
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _statuses.map((s) {
                final (val, label) = s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _statusFilter == val,
                    onSelected: (_) =>
                        setState(() => _statusFilter = val),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Aucune commande',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (context, i) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _CommandeTile(doc: docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query q = FirebaseFirestore.instance
        .collection('commandes')
        .orderBy('createdAt', descending: true);
    if (_statusFilter != 'all') {
      q = q.where('status', isEqualTo: _statusFilter);
    }
    return q.snapshots();
  }
}

class _CommandeTile extends StatelessWidget {
  final DocumentSnapshot doc;
  const _CommandeTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final status = d['status'] as String? ?? 'pending';
    final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
    final total = (d['total'] as num?)?.toDouble() ?? 0.0;
    final qty = (d['quantity'] as num?)?.toInt() ?? 1;

    final statusColor = switch (status) {
      'confirmed' => AppColors.success,
      'cancelled' => AppColors.error,
      _ => Colors.orange,
    };

    final statusLabel = switch (status) {
      'confirmed' => 'Confirmée',
      'cancelled' => 'Annulée',
      _ => 'En attente',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d['packTitle'] as String? ?? 'Pack',
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(d['userName'] as String? ?? 'Inconnu',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 12),
                Icon(Icons.inventory_2_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Qté : $qty',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  Formatters.formatCurrency(total),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            if (d['comment'] != null &&
                (d['comment'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '"${d['comment']}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                Formatters.formatDate(createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            // Actions
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _updateStatus(doc.id, 'cancelled'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error)),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateStatus(doc.id, 'confirmed'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                      child: const Text('Confirmer'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('commandes')
        .doc(id)
        .update({'status': status});
  }
}
