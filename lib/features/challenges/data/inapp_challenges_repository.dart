import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/inapp_challenge_model.dart';
import '../../../core/constants/app_constants.dart';

class InAppChallengesRepository {
  final FirebaseFirestore _db;

  InAppChallengesRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Stream des challenges actifs (sans calcul progression)
  Stream<List<InAppChallengeModel>> watchChallenges(String role) {
    return _db
        .collection('inapp_challenges')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final all = snap.docs.map(InAppChallengeModel.fromFirestore).toList();
      // Filtre côté client pour éviter l'index composite
      return all
          .where((c) =>
              c.targetRoles.isEmpty || c.targetRoles.contains(role))
          .toList();
    });
  }

  /// Calcul de progression pour un challenge donné
  Future<int> getProgress({
    required String userId,
    required InAppChallengeModel challenge,
  }) => _computeProgress(userId: userId, challenge: challenge);

  Future<int> _computeProgress({
    required String userId,
    required InAppChallengeModel challenge,
  }) async {
    try {
      switch (challenge.type) {
        case 'formations_completed':
          // Nombre de formations terminées (percentage >= 1.0)
          final snap = await _db
              .collection(AppConstants.colProgress)
              .where('userId', isEqualTo: userId)
              .where('percentage', isGreaterThanOrEqualTo: 1.0)
              .get();
          return snap.docs.length;

        case 'formations_started':
          // Nombre de formations commencées
          final snap = await _db
              .collection(AppConstants.colProgress)
              .where('userId', isEqualTo: userId)
              .where('percentage', isGreaterThan: 0)
              .get();
          return snap.docs.length;

        case 'formations_theme':
          // Formations terminées d'un thème donné
          if (challenge.themeFilter == null) return 0;
          final formationsSnap = await _db
              .collection(AppConstants.colFormations)
              .where('theme', isEqualTo: challenge.themeFilter)
              .get();
          final formationIds =
              formationsSnap.docs.map((d) => d.id).toSet();

          final progressSnap = await _db
              .collection(AppConstants.colProgress)
              .where('userId', isEqualTo: userId)
              .where('percentage', isGreaterThanOrEqualTo: 1.0)
              .get();

          return progressSnap.docs
              .where((d) =>
                  formationIds.contains(d.data()['formationId'] as String?))
              .length;

        default:
          return 0;
      }
    } catch (_) {
      return 0;
    }
  }
}

final inappChallengesRepositoryProvider =
    Provider((ref) => InAppChallengesRepository());
