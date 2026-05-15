import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/facture_model.dart';
import '../../../core/constants/app_constants.dart';

class FacturesRepository {
  final FirebaseFirestore _db;
  FacturesRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<FactureModel>> watchFactures(String userId) {
    return _db
        .collection(AppConstants.colFactures)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FactureModel.fromFirestore).toList());
  }
}

final facturesRepositoryProvider = Provider((ref) => FacturesRepository());
