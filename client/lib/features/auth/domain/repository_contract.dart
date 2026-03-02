import 'entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String phone, required String password});
  Future<User> signup({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
    String? email,
  });
  Future<void> logout();
  Future<bool> isAuthenticated();
}
