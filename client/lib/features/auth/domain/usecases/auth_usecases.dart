import '../repository_contract.dart';
import '../entities/user.dart';

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<User> execute({required String phone, required String password}) {
    if (phone.length < 10)
      throw Exception('Phone number must be at least 10 digits');
    if (password.length < 6)
      throw Exception('Password must be at least 6 characters');
    return _repository.login(phone: phone, password: password);
  }
}

class SignupUseCase {
  final AuthRepository _repository;
  SignupUseCase(this._repository);

  Future<User> execute({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
    String? email,
  }) {
    if (name.length < 2) throw Exception('Name must be at least 2 characters');
    if (phone.length < 10)
      throw Exception('Phone number must be at least 10 digits');
    if (password.length < 6)
      throw Exception('Password must be at least 6 characters');
    return _repository.signup(
      name: name,
      phone: phone,
      password: password,
      role: role,
      email: email,
    );
  }
}

class LogoutUseCase {
  final AuthRepository _repository;
  LogoutUseCase(this._repository);

  Future<void> execute() => _repository.logout();
}

class CheckAuthUseCase {
  final AuthRepository _repository;
  CheckAuthUseCase(this._repository);

  Future<bool> execute() => _repository.isAuthenticated();
}
