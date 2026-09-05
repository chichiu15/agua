import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _usernameKey = 'username';
  static const _fullNameKey = 'full_name';

  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');

    late final http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'Usuario': username, 'Contrasena': password}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthException(
        'No se pudo conectar con la API en ${ApiConfig.baseUrl}.',
      );
    }

    if (response.statusCode == 401) {
      throw const AuthException('Usuario o contraseña incorrectos.');
    }

    if (response.statusCode != 200) {
      throw AuthException(_readError(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final userId = (data['idUsuario'] as num).toInt();
    final fullName = (data['nombreCompleto'] as String?)?.trim();
    final rol = data['rol'] as String;

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userRoleKey, value: rol);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(
      key: _fullNameKey,
      value: (fullName == null || fullName.isEmpty) ? username : fullName,
    );

    return AppUser(
      id: userId,
      username: username,
      fullName: (fullName == null || fullName.isEmpty) ? username : fullName,
      role: UserRole.fromString(rol),
      active: true,
    );
  }

  @override
  Future<AppUser?> restoreSession() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _userIdKey),
      _storage.read(key: _userRoleKey),
      _storage.read(key: _usernameKey),
      _storage.read(key: _fullNameKey),
    ]);

    final token = values[0];
    final id = int.tryParse(values[1] ?? '');
    final role = values[2];
    final username = values[3];
    final fullName = values[4];

    if (token == null || token.isEmpty || id == null || role == null || username == null) {
      return null;
    }

    try {
      return AppUser(
        id: id,
        username: username,
        fullName: (fullName == null || fullName.trim().isEmpty)
            ? username
            : fullName.trim(),
        role: UserRole.fromString(role),
        active: true,
      );
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  @override
  Future<void> logout() => _storage.deleteAll();

  String _readError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final value = body['mensaje'] ?? body['message'] ?? body['title'];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    } catch (_) {}
    return 'Error al conectar con el servidor.';
  }
}
