import 'package:cloud_firestore/cloud_firestore.dart';

class FormationModel {
  final String id;
  final String title;
  final String description;
  final String theme;
  final int durationMinutes;

  /// Modules Firestore (utilisés en mode legacy sans 360Learning).
  final List<Map<String, dynamic>> modules;

  /// Nombre de modules (source 360Learning — prioritaire sur modules.length).
  final int? moduleCount;

  final DateTime dateAdded;
  final String thumbnailUrl;
  final List<String> targetRoles;

  /// GUID du programme côté 360Learning (null si source Firestore uniquement).
  final String? programGuid;

  const FormationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.durationMinutes,
    this.modules = const [],
    this.moduleCount,
    required this.dateAdded,
    required this.thumbnailUrl,
    required this.targetRoles,
    this.programGuid,
  });

  /// Nombre de modules effectif (360L en priorité, sinon liste Firestore).
  int get totalModules => moduleCount ?? modules.length;

  bool get isNew => DateTime.now().difference(dateAdded).inDays <= 30;

  /// Indique si cette formation est issue de 360Learning.
  bool get is360Learning => programGuid != null;

  factory FormationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FormationModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      theme: d['theme'] ?? '',
      durationMinutes: d['durationMinutes'] ?? 0,
      modules: List<Map<String, dynamic>>.from(d['modules'] ?? []),
      moduleCount: d['moduleCount'] as int?,
      dateAdded: (d['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      thumbnailUrl: d['thumbnailUrl'] ?? '',
      targetRoles: List<String>.from(d['targetRoles'] ?? []),
      programGuid: d['programGuid'] as String?,
    );
  }
}

class ProgressModel {
  final String userId;
  final String formationId;
  final List<String> completedModules;
  final DateTime lastAccess;
  final double percentage;

  const ProgressModel({
    required this.userId,
    required this.formationId,
    required this.completedModules,
    required this.lastAccess,
    required this.percentage,
  });

  factory ProgressModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProgressModel(
      userId: d['userId'] ?? '',
      formationId: d['formationId'] ?? '',
      completedModules: List<String>.from(d['completedModules'] ?? []),
      lastAccess: (d['lastAccess'] as Timestamp?)?.toDate() ?? DateTime.now(),
      percentage: (d['percentage'] ?? 0.0).toDouble(),
    );
  }
}
