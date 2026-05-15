import 'package:dio/dio.dart';
import '../core/config/learning360_config.dart';

/// Modèle brut retourné par l'API 360Learning pour un programme.
class L360Program {
  final String guid;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final int durationMinutes;
  final int moduleCount;
  final List<String> themes;
  final DateTime createdAt;

  const L360Program({
    required this.guid,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.durationMinutes,
    required this.moduleCount,
    required this.themes,
    required this.createdAt,
  });

  factory L360Program.fromJson(Map<String, dynamic> json) {
    // Durée : 360L renvoie en secondes sous "duration"
    final durSec = (json['duration'] as num?)?.toInt() ?? 0;
    return L360Program(
      guid: json['guid']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ??
          json['coverUrl']?.toString(),
      durationMinutes: (durSec / 60).ceil(),
      moduleCount: (json['pathSteps'] as List?)?.length ??
          (json['coursesCount'] as num?)?.toInt() ??
          0,
      themes: List<String>.from(
        (json['themes'] as List?)?.map((t) => t.toString()) ?? [],
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Progression d'un utilisateur sur un programme.
class L360Progress {
  final String programGuid;
  final double completionRate; // 0.0 → 1.0
  final int completedModules;
  final int totalModules;
  final DateTime? lastAccessAt;
  final bool isEnrolled;

  const L360Progress({
    required this.programGuid,
    required this.completionRate,
    required this.completedModules,
    required this.totalModules,
    this.lastAccessAt,
    required this.isEnrolled,
  });

  factory L360Progress.fromJson(Map<String, dynamic> json) {
    final rate = (json['completionRate'] ?? json['progress'] ?? 0.0);
    final total = (json['totalSteps'] ?? json['coursesCount'] ?? 0) as num;
    final done = (json['completedSteps'] ?? json['completedCourses'] ?? 0) as num;
    return L360Progress(
      programGuid:
          json['programGuid']?.toString() ?? json['guid']?.toString() ?? '',
      completionRate: (rate as num).toDouble().clamp(0.0, 1.0),
      completedModules: done.toInt(),
      totalModules: total.toInt(),
      lastAccessAt: json['lastAccessAt'] != null
          ? DateTime.tryParse(json['lastAccessAt'].toString())
          : null,
      isEnrolled: json['isEnrolled'] as bool? ?? true,
    );
  }

  factory L360Progress.notEnrolled(String programGuid) => L360Progress(
        programGuid: programGuid,
        completionRate: 0.0,
        completedModules: 0,
        totalModules: 0,
        isEnrolled: false,
      );
}

/// Client HTTP pour l'API 360Learning.
///
/// Doc officielle : https://developer.360learning.com/reference
///
/// Endpoints utilisés :
///   GET  /v1/company/{companyGuid}/programs           → catalogue
///   GET  /v1/company/{companyGuid}/programs/{guid}    → détail programme
///   GET  /v1/users/{userGuid}/enrollments             → progression utilisateur
///   POST /v1/users/{userGuid}/enrollments             → inscription
class Learning360Service {
  final Dio _dio;

  Learning360Service()
      : _dio = Dio(
          BaseOptions(
            baseUrl: Learning360Config.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'X-API-KEY': Learning360Config.apiKey,
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
    print('[360L] $msg');
  }

  // ── Programmes ────────────────────────────────────────────────────────────

  /// Récupère la liste de tous les programmes du catalogue.
  Future<List<L360Program>> getPrograms({int limit = 100}) async {
    final resp = await _dio.get(
      '/v1/company/${Learning360Config.companyGuid}/programs',
      queryParameters: {'limit': limit},
    );
    final data = resp.data as Map<String, dynamic>;
    final list = (data['programs'] ?? data['data'] ?? data) as List;
    return list
        .map((e) => L360Program.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Récupère le détail d'un programme (y compris les étapes).
  Future<L360Program?> getProgram(String programGuid) async {
    try {
      final resp = await _dio.get(
        '/v1/company/${Learning360Config.companyGuid}/programs/$programGuid',
      );
      return L360Program.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // ── Progression / Inscriptions ────────────────────────────────────────────

  /// Récupère toutes les inscriptions (+ progression) d'un utilisateur.
  /// Le [userGuid] est le GUID 360Learning (stocké dans le profil Firestore).
  Future<List<L360Progress>> getUserEnrollments(String userGuid) async {
    final resp = await _dio.get('/v1/users/$userGuid/enrollments');
    final data = resp.data as Map<String, dynamic>;
    final list = (data['enrollments'] ?? data['data'] ?? data) as List;
    return list
        .map((e) => L360Progress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Inscrit un utilisateur à un programme.
  Future<void> enrollUser({
    required String userGuid,
    required String programGuid,
  }) async {
    await _dio.post(
      '/v1/users/$userGuid/enrollments',
      data: {'programGuid': programGuid},
    );
  }

  /// Récupère le GUID 360Learning d'un utilisateur à partir de son email.
  Future<String?> getUserGuid(String email) async {
    try {
      final resp = await _dio.get(
        '/v1/company/${Learning360Config.companyGuid}/users',
        queryParameters: {'email': email},
      );
      final data = resp.data as Map<String, dynamic>;
      final list = (data['users'] ?? data['data'] ?? []) as List;
      if (list.isEmpty) return null;
      return (list.first as Map<String, dynamic>)['guid']?.toString();
    } catch (_) {
      return null;
    }
  }
}
