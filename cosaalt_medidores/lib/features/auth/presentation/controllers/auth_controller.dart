import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);

    try {
      final repository = ref.read(authRepositoryProvider);

      final user = await repository.login(
        username: username,
        password: password,
      );

      if (!user.active) {
        state = const AuthState(
          errorMessage: 'El usuario se encuentra inhabilitado.',
        );
        return;
      }

      state = AuthState(user: user);
    } on AuthException catch (error) {
      state = AuthState(errorMessage: error.message);
    } catch (e) {
      print('ERROR LOGIN: $e');
      state = const AuthState(
        errorMessage: 'Ocurrió un error inesperado al iniciar sesión.',
      );
    }
  }

  void logout() {
    final repository = ref.read(authRepositoryProvider);
    if (repository is ApiAuthRepository) {
      repository.clearSession();
    }
    state = const AuthState();
  }
}
