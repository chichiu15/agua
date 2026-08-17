import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    // Simula el tiempo que demoraría una petición HTTP real.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final normalizedUsername = username.trim().toLowerCase();

    // MOCK temporal de ASIGNADOR
    if (normalizedUsername == 'asignador1' && password == '123456') {
      return const AppUser(
        id: 1,
        username: 'asignador1',
        fullName: 'Encargado de Cambios',
        role: UserRole.asignador,
        active: true,
      );
    }

    // MOCK temporal de TÉCNICO
    if (normalizedUsername == 'tecnico1' && password == '123456') {
      return const AppUser(
        id: 2,
        username: 'tecnico1',
        fullName: 'Técnico COSAALT',
        role: UserRole.tecnico,
        active: true,
      );
    }

    throw const AuthException('Usuario o contraseña incorrectos.');
  }
}
