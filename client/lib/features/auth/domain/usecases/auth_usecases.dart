import '../repository_contract.dart';
import '../entities/user.dart';

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<User> execute({required String phone, required String password}) {
    if (phone.length < 10) {
      throw Exception('Phone number must be at least 10 digits');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
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
    required String email,
  }) async {
    if (name.length < 2) {
      throw Exception('Name must be at least 2 characters');
    }
    if (phone.length < 10) {
      throw Exception('Phone number must be at least 10 digits');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    return await _repository.signup(
      name: name,
      phone: phone,
      password: password,
      role: role,
      email: email,
    );
  }
}

class RequestOtpUseCase {
  final AuthRepository _repository;
  RequestOtpUseCase(this._repository);

  Future<void> execute({required String email}) {
    return _repository.requestOtp(email: email);
  }
}

class VerifyOtpUseCase {
  final AuthRepository _repository;
  VerifyOtpUseCase(this._repository);

  Future<User> execute({required String email, required String otp}) {
    if (otp.length != 6) {
      throw Exception('OTP must be 6 digits');
    }
    return _repository.verifyOtp(email: email, otp: otp);
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
