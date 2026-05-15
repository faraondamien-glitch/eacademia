import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/challenge_model.dart';
import '../../../core/config/opeaz_config.dart';
import '../../../services/opeaz_service.dart';

// ── Modèles enrichis ───────────────────────────────────────────────────────────

/// Challenge + progression de l'utilisateur courant fusionnés.
class ChallengeWithProgress {
  final ChallengeModel challenge;
  final OpeazUserProgress? userProgress;
  final OpeazReward? reward;

  const ChallengeWithProgress({
    required this.challenge,
    this.userProgress,
    this.reward,
  });

  double get progressRate => userProgress?.progressRate ?? 0.0;
  int get currentScore => userProgress?.currentScore ?? 0;
  int get userRank => userProgress?.rank ?? 0;
  int get totalPoints => userProgress?.totalPoints ?? 0;
  bool get isWinner => userProgress?.isWinner ?? false;
  bool get hasStarted => currentScore > 0;
}

/// Entrée du leaderboard enrichie pour l'affichage.
class LeaderboardEntryOpeaz {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int points;

  const LeaderboardEntryOpeaz({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.points,
  });
}

// ── Repository ────────────────────────────────────────────────────────────────

/// Orchestre les données Opeaz (challenges + progression + leaderboard).
///
/// Stratégie :
///   - Si [OpeazConfig.isConfigured] → appels API réels
///   - Sinon → données mock réalistes (pour dev/démo)
///
/// L'ID Opeaz de l'utilisateur est mis en cache dans Firestore sous
/// `users/{userId}.opeazId`.
class OpeazRepository {
  final OpeazService _service;
  final FirebaseFirestore _db;

  OpeazRepository({OpeazService? service, FirebaseFirestore? db})
      : _service = service ?? OpeazService(),
        _db = db ?? FirebaseFirestore.instance;

  // ── API publique ───────────────────────────────────────────────────────────

  /// Récupère tous les challenges avec la progression de l'utilisateur.
  Future<List<ChallengeWithProgress>> getChallenges({
    required String userId,
    required String userEmail,
  }) async {
    if (!OpeazConfig.isConfigured) return _mockChallenges();

    final opeazId = await _resolveOpeazId(userId, userEmail);

    final challenges = await _service.getChallenges();

    List<OpeazUserProgress> progressList = [];
    if (opeazId != null) {
      try {
        progressList = await _service.getUserProgress(opeazId);
      } catch (_) {}
    }
    final progressMap = {for (final p in progressList) p.challengeId: p};

    return challenges.map((c) {
      final model = _opeazToModel(c);
      return ChallengeWithProgress(
        challenge: model,
        userProgress: progressMap[c.id],
        reward: c.reward,
      );
    }).toList();
  }

  /// Récupère le leaderboard d'un challenge.
  Future<List<LeaderboardEntryOpeaz>> getLeaderboard(
    String challengeId, {
    int limit = 10,
  }) async {
    if (!OpeazConfig.isConfigured) return _mockLeaderboard(challengeId);

    final rankings = await _service.getRankings(challengeId, limit: limit);
    return rankings
        .map((r) => LeaderboardEntryOpeaz(
              rank: r.rank,
              userId: r.userId,
              displayName: r.displayName,
              avatarUrl: r.avatarUrl,
              score: r.score,
              points: r.points,
            ))
        .toList();
  }

  /// Récupère les récompenses de l'utilisateur.
  Future<List<Map<String, dynamic>>> getRewards({
    required String userId,
    required String userEmail,
  }) async {
    if (!OpeazConfig.isConfigured) return _mockRewards();

    final opeazId = await _resolveOpeazId(userId, userEmail);
    if (opeazId == null) return [];
    return _service.getUserRewards(opeazId);
  }

  // ── Résolution ID Opeaz ────────────────────────────────────────────────────

  Future<String?> _resolveOpeazId(String userId, String email) async {
    final doc = await _db.collection('users').doc(userId).get();
    final cached = doc.data()?['opeazId'] as String?;
    if (cached != null && cached.isNotEmpty) return cached;

    final id = await _service.getUserId(email);
    if (id != null) {
      await _db.collection('users').doc(userId).update({'opeazId': id});
    }
    return id;
  }

  // ── Mapping ────────────────────────────────────────────────────────────────

  ChallengeModel _opeazToModel(OpeazChallenge c) {
    return ChallengeModel(
      id: c.id,
      title: c.name,
      subtitle: c.description,
      objective: c.objective,
      unit: c.unit,
      endDate: c.endDate,
      reward: c.reward.displayLabel,
      status: c.status,
      targetRoles: c.targetProfiles,
      opeazId: c.id,
      rewardPoints: c.reward.points,
      rewardType: c.reward.type,
    );
  }

  // ── Données mock ───────────────────────────────────────────────────────────

  static const _mockDelay = Duration(milliseconds: 700);

  Future<List<ChallengeWithProgress>> _mockChallenges() async {
    await Future.delayed(_mockDelay);
    return [
      ChallengeWithProgress(
        challenge: ChallengeModel(
          id: 'ch-001',
          title: 'Sprint Granions Zinc',
          subtitle:
              'Vendez 50 boîtes de Granions de Zinc d\'ici la fin du mois '
              'et remportez des points exclusifs.',
          objective: 50,
          unit: 'boîtes',
          endDate: DateTime.now().add(const Duration(days: 12)),
          reward: '500 pts + Cadeau',
          status: 'active',
          targetRoles: const ['pharmacien'],
          opeazId: 'ch-001',
          rewardPoints: 500,
          rewardType: 'gift',
        ),
        userProgress: const OpeazUserProgress(
          challengeId: 'ch-001',
          currentScore: 32,
          progressRate: 0.64,
          rank: 4,
          totalPoints: 1280,
          isWinner: false,
        ),
        reward: const OpeazReward(
          type: 'gift',
          points: 500,
          giftLabel: 'Bon cadeau Amazon 50€',
        ),
      ),
      ChallengeWithProgress(
        challenge: ChallengeModel(
          id: 'ch-002',
          title: 'Challenge Magnésium Q1',
          subtitle:
              'Atteignez 80 boîtes de Granions de Magnésium vendues '
              'sur le trimestre. Les 3 premiers remportent un week-end spa.',
          objective: 80,
          unit: 'boîtes',
          endDate: DateTime.now().add(const Duration(days: 47)),
          reward: 'Week-end spa',
          status: 'active',
          targetRoles: const ['pharmacien', 'commercial'],
          opeazId: 'ch-002',
          rewardPoints: 1000,
          rewardType: 'gift',
        ),
        userProgress: const OpeazUserProgress(
          challengeId: 'ch-002',
          currentScore: 12,
          progressRate: 0.15,
          rank: 18,
          totalPoints: 240,
          isWinner: false,
        ),
        reward: const OpeazReward(
          type: 'gift',
          points: 1000,
          giftLabel: 'Week-end spa pour 2 (Top 3)',
        ),
      ),
      ChallengeWithProgress(
        challenge: ChallengeModel(
          id: 'ch-003',
          title: 'Lancement Granions Sélénium',
          subtitle:
              'Challenge de lancement : soyez parmi les 5 premiers '
              'à atteindre 20 ventes de Granions Sélénium.',
          objective: 20,
          unit: 'boîtes',
          endDate: DateTime.now().subtract(const Duration(days: 15)),
          reward: '300 pts',
          status: 'ended',
          targetRoles: const ['pharmacien'],
          opeazId: 'ch-003',
          rewardPoints: 300,
          rewardType: 'points',
        ),
        userProgress: const OpeazUserProgress(
          challengeId: 'ch-003',
          currentScore: 22,
          progressRate: 1.0,
          rank: 3,
          totalPoints: 300,
          isWinner: true,
        ),
        reward: const OpeazReward(type: 'points', points: 300),
      ),
    ];
  }

  Future<List<LeaderboardEntryOpeaz>> _mockLeaderboard(
      String challengeId) async {
    await Future.delayed(_mockDelay);

    final data = {
      'ch-001': [
        ('Sophie M.', 49, 1960),
        ('Thomas R.', 46, 1840),
        ('Julie B.', 41, 1640),
        ('Vous', 32, 1280),
        ('Marc L.', 29, 1160),
        ('Anne-Claire V.', 26, 1040),
        ('Pierre D.', 22, 880),
        ('Nathalie F.', 19, 760),
        ('Christophe S.', 15, 600),
        ('Émilie G.', 11, 440),
      ],
      'ch-002': [
        ('Thomas R.', 68, 1360),
        ('Marc L.', 55, 1100),
        ('Sophie M.', 48, 960),
        ('Julie B.', 38, 760),
        ('Christophe S.', 35, 700),
        ('Pierre D.', 28, 560),
        ('Nathalie F.', 24, 480),
        ('Anne-Claire V.', 20, 400),
        ('Émilie G.', 17, 340),
        ('Paul T.', 15, 300),
        ('Françoise B.', 13, 260),
        ('Vous', 12, 240),
      ],
    };

    final entries = data[challengeId] ?? data['ch-001']!;
    return entries.asMap().entries.map((e) {
      final (name, score, points) = e.value;
      return LeaderboardEntryOpeaz(
        rank: e.key + 1,
        userId: 'mock-${e.key}',
        displayName: name,
        score: score,
        points: points,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _mockRewards() async {
    await Future.delayed(_mockDelay);
    return [
      {
        'challengeTitle': 'Lancement Granions Sélénium',
        'type': 'points',
        'points': 300,
        'obtainedAt': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
        'status': 'credited',
      },
      {
        'challengeTitle': 'Sprint Zinc Automne 2024',
        'type': 'gift',
        'giftLabel': 'Bon cadeau Amazon 30€',
        'points': 0,
        'obtainedAt': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
        'status': 'delivered',
      },
    ];
  }
}

final opeazRepositoryProvider = Provider((ref) => OpeazRepository());
