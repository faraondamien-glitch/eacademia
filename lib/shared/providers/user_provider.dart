import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/user_model.dart';

// ── BYPASS LOGIN POUR TEST ────────────────────────────────────────────────────
final _testUser = UserModel(
  uid: 'aRxiAIrutxdbt2NO1Jo2C5p1Ozv2',
  name: 'Marc Petit',
  email: 'marc.petit@pharmacie-bellevue.fr',
  role: UserRole.pharmacien,
  region: 'Bretagne',
  level: 'Argent',
  createdAt: DateTime(2026, 5, 15),
  isAdmin: false,
  pharmacyName: 'Pharmacie Bellevue',
);
// ─────────────────────────────────────────────────────────────────────────────

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(_testUser);

  void setUser(UserModel? user) => state = user;
  void clearUser() => state = null;
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>(
  (ref) => UserNotifier(),
);

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(userProvider)?.role;
});
