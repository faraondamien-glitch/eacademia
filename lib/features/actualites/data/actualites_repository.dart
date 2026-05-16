import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/actu_model.dart';

class ActualitesRepository {
  final FirebaseFirestore _db;
  static const _col = 'actualites';

  ActualitesRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Stream principal : actualités ordonnées (épinglées d'abord, puis date).
  Stream<List<ActuModel>> watchActualites({
    String? role,
    ActuCategory? category,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection(_col)
        .orderBy('publishedAt', descending: true)
        .limit(50);

    return q.snapshots().map((snap) {
      var list = snap.docs.map(ActuModel.fromFirestore).toList();

      // Tri client : épinglées en tête (évite l'index composite Firestore)
      list.sort((a, b) {
        if (a.isPinned == b.isPinned) return 0;
        return a.isPinned ? -1 : 1;
      });

      // Filtre rôle côté client (Firestore ne supporte pas OR sur arrayContains)
      if (role != null) {
        list = list
            .where((a) =>
                a.targetRoles.isEmpty || a.targetRoles.contains(role))
            .toList();
      }

      // Filtre catégorie
      if (category != null) {
        list = list.where((a) => a.category == category).toList();
      }

      return list;
    });
  }

  /// Récupère une actualité par son ID.
  Future<ActuModel?> getActu(String id) async {
    final doc = await _db.collection(_col).doc(id).get();
    if (!doc.exists) return null;
    return ActuModel.fromFirestore(doc);
  }

  // ── Back-office ────────────────────────────────────────────────────────────

  /// Publie une nouvelle actualité.
  Future<String> publish(ActuModel actu) async {
    final ref = await _db.collection(_col).add(actu.toFirestore());
    return ref.id;
  }

  /// Met à jour une actualité existante.
  Future<void> update(ActuModel actu) async {
    await _db.collection(_col).doc(actu.id).update(actu.toFirestore());
  }

  /// Supprime une actualité.
  Future<void> delete(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  /// Épingle / dés-épingle.
  Future<void> togglePin(String id, bool isPinned) async {
    await _db.collection(_col).doc(id).update({'isPinned': isPinned});
  }
}

final actualitesRepositoryProvider =
    Provider((ref) => ActualitesRepository());
