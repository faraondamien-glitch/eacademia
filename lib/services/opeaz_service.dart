import 'package:dio/dio.dart';
import '../core/config/opeaz_config.dart';

// ── Modèles bruts Opeaz ───────────────────────────────────────────────────────

class OpeazChallenge {
  final String id;
  final String name;
  final String description;
  final String status; // 'active' | 'ended' | 'upcoming'
  final DateTime startDate;
  final DateTime endDate;
  final int objective;
  final String unit; // 'boîtes', 'CA', 'visites', etc.
  final OpeazReward reward;
  final List<String> targetProfiles;

  const OpeazChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.objective,
    required this.unit,
    required this.reward,
    required this.targetProfiles,
  });

  bool get isActive => status == 'active';

  factory OpeazChallenge.fromJson(Map<String, dynamic> json) {
    return OpeazChallenge(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      startDate: _parseDate(json['startDate'] ?? json['start_date']),
      endDate: _parseDate(json['endDate'] ?? json['end_date']),
      objective: (json['objective'] ?? json['target'] ?? 0) as int,
      unit: json['unit']?.toString() ?? '',
      reward: OpeazReward.fromJson(
        json['reward'] as Map<String, dynamic>? ?? {},
      ),
      targetProfiles:
          List<String>.from(json['targetProfiles'] ?? json['profiles'] ?? []),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}

class OpeazReward {
  final String type; // 'points' | 'gift' | 'voucher'
  final int points;
  final String? giftLabel;
  final String? imageUrl;

  const OpeazReward({
    required this.type,
    required this.points,
    this.giftLabel,
    this.imageUrl,
  });

  factory OpeazReward.fromJson(Map<String, dynamic> json) {
    return OpeazReward(
      type: json['type']?.toString() ?? 'points',
      points: (json['points'] ?? json['value'] ?? 0) as int,
      giftLabel: json['label']?.toString() ?? json['gift']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  String get displayLabel {
    if (giftLabel != null && giftLabel!.isNotEmpty) return giftLabel!;
    if (points > 0) return '$points pts';
    return type;
  }
}

/// Progression d'un utilisateur sur un challenge.
class OpeazUserProgress {
  final String challengeId;
  final int currentScore;
  final double progressRate; // 0.0 → 1.0
  final int rank;
  final int totalPoints; // points Opeaz cumulés
  final bool isWinner;

  const OpeazUserProgress({
    required this.challengeId,
    required this.currentScore,
    required this.progressRate,
    required this.rank,
    required this.totalPoints,
    required this.isWinner,
  });

  factory OpeazUserProgress.fromJson(
      Map<String, dynamic> json, String challengeId) {
    final score = (json['score'] ?? json['current'] ?? 0) as num;
    final target = (json['objective'] ?? json['target'] ?? 1) as num;
    return OpeazUserProgress(
      challengeId: challengeId,
      currentScore: score.toInt(),
      progressRate: target > 0
          ? (score / target).clamp(0.0, 1.0).toDouble()
          : 0.0,
      rank: (json['rank'] ?? 0) as int,
      totalPoints: (json['totalPoints'] ?? json['points'] ?? 0) as int,
      isWinner: json['isWinner'] as bool? ?? false,
    );
  }

  factory OpeazUserProgress.empty(String challengeId) => OpeazUserProgress(
        challengeId: challengeId,
        currentScore: 0,
        progressRate: 0.0,
        rank: 0,
        totalPoints: 0,
        isWinner: false,
      );
}

/// Entrée du leaderboard Opeaz.
class OpeazRankingEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int points;

  const OpeazRankingEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.points,
  });

  factory OpeazRankingEntry.fromJson(Map<String, dynamic> json, int index) {
    return OpeazRankingEntry(
      rank: (json['rank'] ?? index + 1) as int,
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ??
          json['name']?.toString() ??
          'Anonyme',
      avatarUrl: json['avatarUrl']?.toString(),
      score: (json['score'] ?? json['current'] ?? 0) as int,
      points: (json['points'] ?? 0) as int,
    );
  }
}

// ── Service HTTP ───────────────────────────────────────────────────────────────

/// Client HTTP pour l'API Opeaz.
///
/// Endpoints utilisés :
///   GET  /v1/companies/{companyId}/challenges                → liste
///   GET  /v1/companies/{companyId}/challenges/{id}           → détail
///   GET  /v1/companies/{companyId}/challenges/{id}/rankings  → leaderboard
///   GET  /v1/users/{userId}/progress                         → progression
///   GET  /v1/users/{userId}/rewards                          → récompenses
class OpeazService {
  final Dio _dio;

  OpeazService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: OpeazConfig.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Authorization': 'Bearer ${OpeazConfig.apiKey}',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => _log(o.toString()),
      ),
    );
  }

  static void _log(String msg) {
    // ignore: avoid_print
    print('[Opeaz] $msg');
  }

  // ── Challenges ─────────────────────────────────────────────────────────────

  Future<List<OpeazChallenge>> getChallenges() async {
    final resp = await _dio.get(
      '/v1/companies/${OpeazConfig.companyId}/challenges',
    );
    final data = resp.data as Map<String, dynamic>;
    final list = (data['challenges'] ?? data['data'] ?? data) as List;
    return list
        .map((e) => OpeazChallenge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OpeazChallenge?> getChallenge(String id) async {
    try {
      final resp = await _dio.get(
        '/v1/companies/${OpeazConfig.companyId}/challenges/$id',
      );
      return OpeazChallenge.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  Future<List<OpeazRankingEntry>> getRankings(
    String challengeId, {
    int limit = 10,
  }) async {
    final resp = await _dio.get(
      '/v1/companies/${OpeazConfig.companyId}/challenges/$challengeId/rankings',
      queryParameters: {'limit': limit},
    );
    final data = resp.data as Map<String, dynamic>;
    final list = (data['rankings'] ?? data['data'] ?? data) as List;
    return list
        .asMap()
        .entries
        .map((e) =>
            OpeazRankingEntry.fromJson(e.value as Map<String, dynamic>, e.key))
        .toList();
  }

  // ── Progression utilisateur ────────────────────────────────────────────────

  /// Récupère la progression de l'utilisateur sur tous ses challenges.
  Future<List<OpeazUserProgress>> getUserProgress(String opeazUserId) async {
    final resp = await _dio.get('/v1/users/$opeazUserId/progress');
    final data = resp.data as Map<String, dynamic>;
    final list = (data['progress'] ?? data['data'] ?? []) as List;
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      return OpeazUserProgress.fromJson(
        map,
        map['challengeId']?.toString() ?? '',
      );
    }).toList();
  }

  /// Récupère les récompenses obtenues par l'utilisateur.
  Future<List<Map<String, dynamic>>> getUserRewards(
      String opeazUserId) async {
    final resp = await _dio.get('/v1/users/$opeazUserId/rewards');
    final data = resp.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(
        data['rewards'] ?? data['data'] ?? []);
  }

  /// Résout l'ID Opeaz d'un utilisateur à partir de son email.
  Future<String?> getUserId(String email) async {
    try {
      final resp = await _dio.get(
        '/v1/companies/${OpeazConfig.companyId}/users',
        queryParameters: {'email': email},
      );
      final data = resp.data as Map<String, dynamic>;
      final list = (data['users'] ?? data['data'] ?? []) as List;
      if (list.isEmpty) return null;
      return (list.first as Map<String, dynamic>)['id']?.toString();
    } catch (_) {
      return null;
    }
  }
}
