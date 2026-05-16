import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user_model.dart';
import '../../../firebase_options.dart';

class EquipeRepository {
  final FirebaseFirestore _db;
  EquipeRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Stream des préparateurs rattachés à un pharmacien.
  Stream<List<UserModel>> watchTeam(String managerId) {
    return _db
        .collection('users')
        .where('managerId', isEqualTo: managerId)
        .where('role', isEqualTo: 'preparateur')
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList());
  }

  /// Crée un compte préparateur sans déconnecter le pharmacien.
  /// Utilise une instance Firebase secondaire temporaire.
  Future<void> addPreparateur({
    required String managerId,
    required String managerRegion,
    required String name,
    required String email,
    required String password,
  }) async {
    // Instance secondaire pour créer le compte sans toucher à la session principale
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crée le doc Firestore du préparateur
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'preparateur',
        'region': managerRegion,
        'level': 'Débutant',
        'points': 0,
        'isAdmin': false,
        'managerId': managerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();
    } finally {
      await secondaryApp?.delete();
    }
  }

  /// Retire un préparateur de l'équipe (supprime le lien managerId).
  Future<void> removeFromTeam(String preparateurId) async {
    await _db.collection('users').doc(preparateurId).update({
      'managerId': FieldValue.delete(),
    });
  }

  /// Supprime le compte préparateur de Firestore (sans supprimer l'auth).
  Future<void> deletePreparateur(String preparateurId) async {
    await _db.collection('users').doc(preparateurId).delete();
  }
}

final equipeRepositoryProvider = Provider((ref) => EquipeRepository());
