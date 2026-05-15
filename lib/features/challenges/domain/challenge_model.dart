import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeModel {
  final String id;
  final String title;
  final String subtitle;
  final int objective;
  final String unit;
  final DateTime endDate;
  final String reward;
  final String status;
  final List<String> targetRoles;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.objective,
    required this.unit,
    required this.endDate,
    required this.reward,
    required this.status,
    required this.targetRoles,
  });

  bool get isActive => status == 'active';

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChallengeModel(
      id: doc.id,
      title: d['title'] ?? '',
      subtitle: d['subtitle'] ?? '',
      objective: d['objective'] ?? 0,
      unit: d['unit'] ?? '',
      endDate: (d['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reward: d['reward'] ?? '',
      status: d['status'] ?? 'active',
      targetRoles: List<String>.from(d['targetRoles'] ?? []),
    );
  }
}
