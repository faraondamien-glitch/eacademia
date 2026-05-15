import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/formation_model.dart';
import '../../../core/config/learning360_config.dart';
import '../../../services/learning360_service.dart';

/// Fusionne le catalogue 360Learning avec la progression utilisateur
/// et expose des [FormationModel] enrichis.
///
/// Stratégie :
///   - Si [Learning360Config.isConfigured] → appels API réels
///   - Sinon → données mock réalistes (pour dev/démo)
///
/// La progression est mise en cache dans Firestore sous
/// `users/{userId}/l360_progress/{programGuid}` pour un accès hors-ligne.
class Learning360Repository {
  final Learning360Service _service;
  final FirebaseFirestore _db;

  Learning360Repository({
    Learning360Service? service,
    FirebaseFirestore? db,
  })  : _service = service ?? Learning360Service(),
        _db = db ?? FirebaseFirestore.instance;

  // ── API publique ──────────────────────────────────────────────────────────

  /// Récupère le catalogue complet avec la progression de [userId].
  ///
  /// [userEmail] sert à résoudre le GUID 360Learning si non encore connu.
  Future<List<FormationWithProgress>> getCatalog({
    required String userId,
    required String userEmail,
    String? roleFilter,
  }) async {
    if (!Learning360Config.isConfigured) {
      return _mockCatalog(userId);
    }

    // 1. Résoudre le GUID 360Learning (mis en cache Firestore)
    final userGuid = await _resolveUserGuid(userId, userEmail);

    // 2. Catalogue de programmes
    final programs = await _service.getPrograms();

    // 3. Progression utilisateur (peut échouer si non inscrit)
    List<L360Progress> enrollments = [];
    if (userGuid != null) {
      try {
        enrollments = await _service.getUserEnrollments(userGuid);
      } catch (_) {
        // Utilisateur jamais inscrit → liste vide
      }
    }

    // 4. Index de progression par programGuid
    final progressMap = {for (final e in enrollments) e.programGuid: e};

    // 5. Mapper vers FormationWithProgress
    final result = programs.map((p) {
      final prog = progressMap[p.guid] ??
          L360Progress.notEnrolled(p.guid);
      return FormationWithProgress(
        formation: _programToFormation(p),
        progress: prog,
        playerUrl: Learning360Config.playerUrl(p.guid),
        userGuid: userGuid,
      );
    }).toList();

    // 6. Mettre à jour le cache Firestore en arrière-plan
    _cacheProgress(userId, enrollments);

    return result;
  }

  /// Inscrit l'utilisateur courant à un programme et ouvre le player.
  /// Retourne l'URL du player 360Learning à ouvrir.
  Future<String> enrollAndGetUrl({
    required String userId,
    required String userEmail,
    required String programGuid,
  }) async {
    final url = Learning360Config.playerUrl(programGuid);
    if (!Learning360Config.isConfigured) return url;

    final userGuid = await _resolveUserGuid(userId, userEmail);
    if (userGuid != null) {
      try {
        await _service.enrollUser(
          userGuid: userGuid,
          programGuid: programGuid,
        );
      } catch (_) {
        // Déjà inscrit ou erreur non bloquante
      }
    }
    return url;
  }

  // ── Résolution GUID ───────────────────────────────────────────────────────

  Future<String?> _resolveUserGuid(String userId, String email) async {
    // Cache Firestore
    final userDoc = await _db.collection('users').doc(userId).get();
    final cached = userDoc.data()?['l360Guid'] as String?;
    if (cached != null && cached.isNotEmpty) return cached;

    // Appel API
    final guid = await _service.getUserGuid(email);
    if (guid != null) {
      // Stocker pour les prochains appels
      await _db
          .collection('users')
          .doc(userId)
          .update({'l360Guid': guid});
    }
    return guid;
  }

  // ── Cache Firestore ───────────────────────────────────────────────────────

  Future<void> _cacheProgress(
      String userId, List<L360Progress> enrollments) async {
    final batch = _db.batch();
    for (final e in enrollments) {
      final ref = _db
          .collection('users')
          .doc(userId)
          .collection('l360_progress')
          .doc(e.programGuid);
      batch.set(ref, {
        'completionRate': e.completionRate,
        'completedModules': e.completedModules,
        'totalModules': e.totalModules,
        'lastAccessAt': e.lastAccessAt != null
            ? Timestamp.fromDate(e.lastAccessAt!)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  FormationModel _programToFormation(L360Program p) {
    return FormationModel(
      id: p.guid,
      title: p.title,
      description: p.description,
      theme: p.themes.isNotEmpty ? p.themes.first : '',
      durationMinutes: p.durationMinutes,
      moduleCount: p.moduleCount,
      dateAdded: p.createdAt,
      thumbnailUrl: p.thumbnailUrl ?? '',
      targetRoles: const [], // 360L ne filtre pas par rôle côté API
      programGuid: p.guid,
    );
  }

  // ── Données mock ──────────────────────────────────────────────────────────

  static const _mockDelay = Duration(milliseconds: 800);

  Future<List<FormationWithProgress>> _mockCatalog(String userId) async {
    await Future.delayed(_mockDelay);
    return [
      FormationWithProgress(
        formation: FormationModel(
          id: 'mock-001',
          title: 'Initiation aux oligo-éléments Granions',
          description:
              'Découvrez les fondamentaux des oligo-éléments et leur rôle '
              'dans les métabolismes clés. Formation indispensable pour conseiller '
              'efficacement vos patients.',
          theme: 'Pharmacologie',
          durationMinutes: 45,
          moduleCount: 6,
          dateAdded: DateTime.now().subtract(const Duration(days: 5)),
          thumbnailUrl: '',
          targetRoles: const ['pharmacien', 'medecin'],
          programGuid: 'mock-001',
        ),
        progress: const L360Progress(
          programGuid: 'mock-001',
          completionRate: 0.67,
          completedModules: 4,
          totalModules: 6,
          isEnrolled: true,
        ),
        playerUrl: 'https://granions.360learning.com/learner/course/mock-001',
        userGuid: null,
      ),
      FormationWithProgress(
        formation: FormationModel(
          id: 'mock-002',
          title: 'Zinc & immunité — argumentaire patient',
          description:
              'Maîtrisez l\'argumentaire scientifique autour du zinc pour '
              'accompagner vos patients pendant les périodes hivernales. '
              'Inclut des cas pratiques de conseil.',
          theme: 'Conseil officinal',
          durationMinutes: 30,
          moduleCount: 4,
          dateAdded: DateTime.now().subtract(const Duration(days: 2)),
          thumbnailUrl: '',
          targetRoles: const ['pharmacien'],
          programGuid: 'mock-002',
        ),
        progress: const L360Progress(
          programGuid: 'mock-002',
          completionRate: 0.0,
          completedModules: 0,
          totalModules: 4,
          isEnrolled: false,
        ),
        playerUrl: 'https://granions.360learning.com/learner/course/mock-002',
        userGuid: null,
      ),
      FormationWithProgress(
        formation: FormationModel(
          id: 'mock-003',
          title: 'Magnésium marin : spécificités et posologies',
          description:
              'Comprendre les différentes formes de magnésium, leurs '
              'biodisponibilités comparées et les indications prioritaires. '
              'Mise à jour avec les dernières données cliniques 2024.',
          theme: 'Nutrition',
          durationMinutes: 60,
          moduleCount: 8,
          dateAdded: DateTime.now().subtract(const Duration(days: 18)),
          thumbnailUrl: '',
          targetRoles: const ['pharmacien', 'medecin', 'kine'],
          programGuid: 'mock-003',
        ),
        progress: const L360Progress(
          programGuid: 'mock-003',
          completionRate: 1.0,
          completedModules: 8,
          totalModules: 8,
          isEnrolled: true,
        ),
        playerUrl: 'https://granions.360learning.com/learner/course/mock-003',
        userGuid: null,
      ),
      FormationWithProgress(
        formation: FormationModel(
          id: 'mock-004',
          title: 'Silicium organique — nouvelles indications',
          description:
              'Formation avancée sur le silicium organique Granions : '
              'mécanismes d\'action, nouvelles études, protocoles '
              'anti-âge et applications locomotrices.',
          theme: 'Dermatologie',
          durationMinutes: 50,
          moduleCount: 5,
          dateAdded: DateTime.now().subtract(const Duration(days: 30)),
          thumbnailUrl: '',
          targetRoles: const ['pharmacien', 'medecin'],
          programGuid: 'mock-004',
        ),
        progress: const L360Progress(
          programGuid: 'mock-004',
          completionRate: 0.2,
          completedModules: 1,
          totalModules: 5,
          isEnrolled: true,
        ),
        playerUrl: 'https://granions.360learning.com/learner/course/mock-004',
        userGuid: null,
      ),
    ];
  }
}

/// Formation + progression 360Learning fusionnées.
class FormationWithProgress {
  final FormationModel formation;
  final L360Progress progress;
  final String playerUrl;
  final String? userGuid;

  const FormationWithProgress({
    required this.formation,
    required this.progress,
    required this.playerUrl,
    this.userGuid,
  });

  double get completionRate => progress.completionRate;
  bool get isEnrolled => progress.isEnrolled;
  bool get isCompleted => progress.completionRate >= 1.0;
}

final learning360RepositoryProvider =
    Provider((ref) => Learning360Repository());
