import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/produit_model.dart';
import '../../../core/constants/app_constants.dart';

class ProduitsRepository {
  final FirebaseFirestore _db;
  ProduitsRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<ProduitModel>> watchProduits(String role) {
    return _db
        .collection(AppConstants.colProduits)
        .where('targetRoles', arrayContains: role)
        .snapshots()
        .map((s) => s.docs.map(ProduitModel.fromFirestore).toList());
  }

  Future<ProduitModel?> getProduit(String id) async {
    final doc = await _db.collection(AppConstants.colProduits).doc(id).get();
    if (!doc.exists) return null;
    return ProduitModel.fromFirestore(doc);
  }
}

final produitsRepositoryProvider = Provider((ref) => ProduitsRepository());
