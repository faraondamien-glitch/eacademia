import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/formation_model.dart';
import '../../../core/constants/app_constants.dart';

class FormationsRepository {
  final FirebaseFirestore _db;

  FormationsRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<FormationModel>> watchFormations(String role) {
    return _db
        .collection(AppConstants.colFormations)
        .where('targetRoles', arrayContains: role)
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FormationModel.fromFirestore).toList());
  }

  Future<FormationModel?> getFormation(String id) async {
    final doc = await _db.collection(AppConstants.colFormations).doc(id).get();
    if (!doc.exists) return null;
    return FormationModel.fromFirestore(doc);
  }

  Stream<ProgressModel?> watchProgress(String userId, String formationId) {
    final docId = '${userId}_$formationId';
    return _db
        .collection(AppConstants.colProgress)
        .doc(docId)
        .snapshots()
        .map((s) => s.exists ? ProgressModel.fromFirestore(s) : null);
  }

  // Toute la progression d'un utilisateur → Map<formationId, ProgressModel>
  Stream<Map<String, ProgressModel>> watchAllProgress(String userId) {
    return _db
        .collection(AppConstants.colProgress)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      return {
        for (final doc in s.docs)
          (doc.data()['formationId'] as String? ?? doc.id):
              ProgressModel.fromFirestore(doc),
      };
    });
  }

  Future<void> updateProgress({
    required String userId,
    required String formationId,
    required List<String> completedModules,
    required int totalModules,
  }) async {
    final docId = '${userId}_$formationId';
    await _db.collection(AppConstants.colProgress).doc(docId).set({
      'userId': userId,
      'formationId': formationId,
      'completedModules': completedModules,
      'lastAccess': FieldValue.serverTimestamp(),
      'percentage':
          totalModules > 0 ? completedModules.length / totalModules : 0.0,
    }, SetOptions(merge: true));
  }
}

final formationsRepositoryProvider =
    Provider((ref) => FormationsRepository());
