import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/api/auth_api.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../state/auth_state.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepositoryImpl authRepository(Ref ref) {
  return AuthRepositoryImpl(AuthApi(), SecureStorageService());
}

@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    _init();
    return const AuthInitial();
  }

  Future<void> _init() async {
    print('AuthControler: _init starting');
    state = const AuthLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final checkAuth = CheckAuthUseCase(repository);
      final isAuth = await checkAuth.execute();
      print('AuthControler: isAuth = $isAuth');
      if (isAuth) {
        final user = await repository.getUser();
        if (user != null) {
          state = Authenticated(user);
          // Connect socket if previously authenticated
          SocketService.instance.connect();
        } else {
          state = const Unauthenticated();
        }
      } else {
        state = const Unauthenticated();
      }
    } catch (e) {
      print('AuthControler: _init error = $e');
      state = const Unauthenticated();
    }
  }

  Future<void> login(String phone, String password) async {
    print('AuthControler: login starting for $phone');
    state = const AuthLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final loginUseCase = LoginUseCase(repository);
      final user = await loginUseCase.execute(phone: phone, password: password);
      print('AuthControler: login success for ${user.name}');
      state = Authenticated(user);
      // Connect socket on login
      SocketService.instance.connect();
    } catch (e) {
      print('AuthControler: login failed = $e');
      state = AuthError(e.toString());
    }
  }

  Future<void> signup({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
    required String email,
  }) async {
    state = const AuthLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final signupUseCase = SignupUseCase(repository);
      final user = await signupUseCase.execute(
        name: name,
        phone: phone,
        password: password,
        role: role,
        email: email,
      );
      state = Authenticated(user);
      // Connect socket on signup
      SocketService.instance.connect();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> requestOtp(String email) async {
    state = const AuthLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final requestOtpUseCase = RequestOtpUseCase(repository);
      await requestOtpUseCase.execute(email: email);
      state = const AuthPendingVerification();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    state = const AuthLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final verifyOtpUseCase = VerifyOtpUseCase(repository);
      final user = await verifyOtpUseCase.execute(email: email, otp: otp);
      state = Authenticated(user);
      // Connect socket on OTP verification success
      SocketService.instance.connect();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final logoutUseCase = LogoutUseCase(repository);
      await logoutUseCase.execute();
      state = const Unauthenticated();
      // Disconnect socket on logout
      SocketService.instance.disconnect();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  void updateCachedUser({String? name, String? phone}) {
    if (state is Authenticated) {
      final currentUser = (state as Authenticated).user;
      final updatedUser = User(
        id: currentUser.id,
        name: name ?? currentUser.name,
        phone: phone ?? currentUser.phone,
        email: currentUser.email,
        role: currentUser.role,
        status: currentUser.status,
        isEmailVerified: currentUser.isEmailVerified,
      );
      state = Authenticated(updatedUser);
    }
  }
}
