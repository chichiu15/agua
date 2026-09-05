import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isRestoring = false,
    this.errorMessage,
  });

  final AppUser? user;
  final bool isLoading;
  final bool isRestoring;
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
  bool _restoreStarted = false;

  @override
  AuthState build() {
    if (!_restoreStarted) {
      _restoreStarted = true;
      Future.microtask(_restoreSession);
    }
    return const AuthState(isRestoring: true);
  }

  Future<void> _restoreSession() async {
    try {
      final user = await ref.read(authRepositoryProvider).restoreSession();
      state = AuthState(user: user);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = AuthState(user: state.user, isLoading: true);

    try {
      final user = await ref.read(authRepositoryProvider).login(
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
    } catch (_) {
      state = const AuthState(
        errorMessage: 'Ocurrió un error inesperado al iniciar sesión.',
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }
}
