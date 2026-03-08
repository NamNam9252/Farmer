import 'entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String phone, required String password});
  Future<User> signup({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
    required String email,
  });
  Future<void> requestOtp({required String email});
  Future<User> verifyOtp({required String email, required String otp});
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<User?> getUser();
}
