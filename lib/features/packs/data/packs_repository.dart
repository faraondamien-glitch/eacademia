import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/pack_model.dart';
import '../../../core/constants/app_constants.dart';

class PacksRepository {
  final FirebaseFirestore _db;
  PacksRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<PackModel>> watchPacks(String role) {
    return _db
        .collection(AppConstants.colPacks)
        .where('targetRoles', arrayContains: role)
        .snapshots()
        .map((s) => s.docs.map(PackModel.fromFirestore).toList());
  }

  Future<PackModel?> getPack(String id) async {
    final doc = await _db.collection(AppConstants.colPacks).doc(id).get();
    if (!doc.exists) return null;
    return PackModel.fromFirestore(doc);
  }

  Future<void> placeOrder({
    required String userId,
    required String packId,
    required String packName,
    required int quantity,
    required String comment,
    required double totalAmount,
  }) async {
    await _db.collection(AppConstants.colOrders).add({
      'userId': userId,
      'packId': packId,
      'packName': packName,
      'quantity': quantity,
      'comment': comment,
      'totalAmount': totalAmount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final packsRepositoryProvider = Provider((ref) => PacksRepository());
