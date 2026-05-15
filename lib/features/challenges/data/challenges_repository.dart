import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/challenge_model.dart';
import '../../../core/constants/app_constants.dart';

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int score;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.score,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      userId: doc.id,
      displayName: d['displayName'] as String? ?? 'Inconnu',
      score: (d['score'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChallengesRepository {
  final FirebaseFirestore _db;
  ChallengesRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<ChallengeModel>> watchChallenges(String role) {
    return _db
        .collection(AppConstants.colChallenges)
        .where('targetRoles', arrayContains: role)
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ChallengeModel.fromFirestore).toList());
  }

  Stream<List<LeaderboardEntry>> watchLeaderboard(String challengeId) {
    return _db
        .collection(AppConstants.colChallenges)
        .doc(challengeId)
        .collection(AppConstants.colParticipants)
        .orderBy('score', descending: true)
        .limit(10)
        .snapshots()
        .map((s) => s.docs.map(LeaderboardEntry.fromFirestore).toList());
  }
}

final challengesRepositoryProvider = Provider((ref) => ChallengesRepository());
