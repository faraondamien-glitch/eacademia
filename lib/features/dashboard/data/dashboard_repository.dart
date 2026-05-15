import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';

class DashboardKpi {
  final int formationsEnCours;
  final int scoreChallenge;
  final int facturesEnAttente;
  final int nouveautes;

  const DashboardKpi({
    required this.formationsEnCours,
    required this.scoreChallenge,
    required this.facturesEnAttente,
    required this.nouveautes,
  });
}

class NotificationData {
  final String id;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;

  const NotificationData({
    required this.id,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory NotificationData.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationData(
      id: doc.id,
      message: d['message'] ?? '',
      type: d['type'] ?? 'info',
      read: d['read'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FormationInProgress {
  final String formationId;
  final String title;
  final double percentage;
  final int completedModules;
  final int totalModules;

  const FormationInProgress({
    required this.formationId,
    required this.title,
    required this.percentage,
    required this.completedModules,
    required this.totalModules,
  });
}

class DashboardRepository {
  final FirebaseFirestore _db;

  DashboardRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<NotificationData>> watchNotifications(String userId, String role) {
    return _db
        .collection(AppConstants.colNotifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((s) => s.docs.map(NotificationData.fromFirestore).toList());
  }

  // Récupère les 3 dernières notifs non lues + rôle
  Stream<List<NotificationData>> watchRecentNotifications(String userId) {
    return _db
        .collection(AppConstants.colNotifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .map((s) => s.docs.map(NotificationData.fromFirestore).toList());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection(AppConstants.colNotifications)
        .doc(notificationId)
        .update({'read': true});
  }

  Stream<List<FormationInProgress>> watchFormationsInProgress(String userId) {
    return _db
        .collection(AppConstants.colProgress)
        .where('userId', isEqualTo: userId)
        .where('percentage', isGreaterThan: 0)
        .where('percentage', isLessThan: 1)
        .orderBy('percentage', descending: false)
        .orderBy('lastAccess', descending: true)
        .limit(5)
        .snapshots()
        .asyncMap((snapshot) async {
      final results = <FormationInProgress>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final formationId = data['formationId'] as String? ?? '';
        final completedModules =
            List<String>.from(data['completedModules'] ?? []);
        final percentage = (data['percentage'] ?? 0.0).toDouble();

        // Récupère le titre de la formation
        final formationDoc = await _db
            .collection(AppConstants.colFormations)
            .doc(formationId)
            .get();
        if (!formationDoc.exists) continue;

        final formationData = formationDoc.data() as Map<String, dynamic>;
        final totalModules =
            (formationData['modules'] as List?)?.length ?? 1;

        results.add(FormationInProgress(
          formationId: formationId,
          title: formationData['title'] ?? '',
          percentage: percentage,
          completedModules: completedModules.length,
          totalModules: totalModules,
        ));
      }
      return results;
    });
  }

  Stream<DashboardKpi> watchKpi({
    required String userId,
    required String role,
  }) {
    // Stream combiné : formations en cours, factures en attente, nouveautés
    return _db
        .collection(AppConstants.colProgress)
        .where('userId', isEqualTo: userId)
        .where('percentage', isGreaterThan: 0)
        .where('percentage', isLessThan: 1)
        .snapshots()
        .asyncMap((progressSnap) async {
      final formationsEnCours = progressSnap.docs.length;

      // Factures en attente
      int facturesEnAttente = 0;
      try {
        final facturesSnap = await _db
            .collection(AppConstants.colFactures)
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();
        facturesEnAttente = facturesSnap.docs.length;
      } catch (_) {}

      // Nouveautés (formations ajoutées < 30 jours)
      int nouveautes = 0;
      try {
        final cutoff = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 30)),
        );
        final newSnap = await _db
            .collection(AppConstants.colFormations)
            .where('targetRoles', arrayContains: role)
            .where('dateAdded', isGreaterThan: cutoff)
            .get();
        nouveautes = newSnap.docs.length;
      } catch (_) {}

      // Score challenge
      int scoreChallenge = 0;
      try {
        final challengesSnap = await _db
            .collection(AppConstants.colChallenges)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();
        if (challengesSnap.docs.isNotEmpty) {
          final challengeId = challengesSnap.docs.first.id;
          final participantDoc = await _db
              .collection(AppConstants.colChallenges)
              .doc(challengeId)
              .collection(AppConstants.colParticipants)
              .doc(userId)
              .get();
          if (participantDoc.exists) {
            scoreChallenge =
                (participantDoc.data()?['score'] ?? 0) as int;
          }
        }
      } catch (_) {}

      return DashboardKpi(
        formationsEnCours: formationsEnCours,
        scoreChallenge: scoreChallenge,
        facturesEnAttente: facturesEnAttente,
        nouveautes: nouveautes,
      );
    });
  }
}

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());
