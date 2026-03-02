import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/api/auth_api.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../state/auth_state.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepositoryImpl authRepository(AuthRepositoryRef ref) {
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
    state = const AuthLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final checkAuth = CheckAuthUseCase(repository);
      final isAuth = await checkAuth.execute();
      if (isAuth) {
        // Without a /me endpoint, restoring user from partial data
        state = const Authenticated(
          User(id: '', name: 'Farmer User', phone: '', role: UserRole.farmer),
        );
      } else {
        state = const Unauthenticated();
      }
    } catch (_) {
      state = const Unauthenticated();
    }
  }

  Future<void> login(String phone, String password) async {
    state = const AuthLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final loginUseCase = LoginUseCase(repository);
      final user = await loginUseCase.execute(phone: phone, password: password);
      state = Authenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signup({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
    String? email,
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
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}
