import 'package:cloud_firestore/cloud_firestore.dart';

class InAppChallengeModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'formations_completed' | 'formations_theme'
  final int target;
  final String? themeFilter;
  final int rewardPoints;
  final bool active;
  final DateTime? endDate;
  final List<String> targetRoles;

  const InAppChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.themeFilter,
    required this.rewardPoints,
    required this.active,
    this.endDate,
    required this.targetRoles,
  });

  factory InAppChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InAppChallengeModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      type: d['type'] ?? 'formations_completed',
      target: (d['target'] as num?)?.toInt() ?? 1,
      themeFilter: d['themeFilter'] as String?,
      rewardPoints: (d['rewardPoints'] as num?)?.toInt() ?? 0,
      active: d['active'] ?? true,
      endDate: (d['endDate'] as Timestamp?)?.toDate(),
      targetRoles: List<String>.from(d['targetRoles'] ?? []),
    );
  }
}

class InAppChallengeWithProgress {
  final InAppChallengeModel challenge;
  final int current;

  const InAppChallengeWithProgress({
    required this.challenge,
    required this.current,
  });

  double get progressRate =>
      (current / challenge.target).clamp(0.0, 1.0);

  bool get isCompleted => current >= challenge.target;
}
