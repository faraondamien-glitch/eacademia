import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? secureStorage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user == null) return null;
    final user = await _fetchUserProfile(credential.user!.uid);
    if (user != null) {
      await _secureStorage.write(key: AppConstants.keyUserId, value: user.uid);
      await _secureStorage.write(key: AppConstants.keyUserEmail, value: user.email);
    }
    return user;
  }

  Future<UserModel?> getStoredUser() async {
    final uid = await _secureStorage.read(key: AppConstants.keyUserId);
    if (uid == null || _auth.currentUser == null) return null;
    return _fetchUserProfile(uid);
  }

  Future<UserModel?> _fetchUserProfile(String uid) async {
    final doc = await _firestore.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await _secureStorage.deleteAll();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
