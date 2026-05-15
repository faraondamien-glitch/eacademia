import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/user_model.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null);

  void setUser(UserModel? user) => state = user;
  void clearUser() => state = null;
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>(
  (ref) => UserNotifier(),
);

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(userProvider)?.role;
});
