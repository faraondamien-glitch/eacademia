import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/pub_model.dart';
import '../../../core/constants/app_constants.dart';

class PubsRepository {
  final FirebaseFirestore _db;
  PubsRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<PubModel>> watchPubs(String role) {
    return _db
        .collection(AppConstants.colPubs)
        .where('targetRoles', arrayContains: role)
        .orderBy('broadcastDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PubModel.fromFirestore).toList());
  }

  Future<PubModel?> getPub(String id) async {
    final doc = await _db.collection(AppConstants.colPubs).doc(id).get();
    if (!doc.exists) return null;
    return PubModel.fromFirestore(doc);
  }
}

final pubsRepositoryProvider = Provider((ref) => PubsRepository());
