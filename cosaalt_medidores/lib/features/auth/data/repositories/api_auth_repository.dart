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

  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Usuario': username, 'Contrasena': password}),
    );

    if (response.statusCode == 401) {
      throw const AuthException('Usuario o contraseña incorrectos.');
    }

    if (response.statusCode != 200) {
      throw const AuthException('Error al conectar con el servidor.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final token = data['token'] as String;
    final userId = data['idUsuario'] as int;
    final fullName = data['nombreCompleto'] as String;
    final rol = data['rol'] as String;

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userRoleKey, value: rol);

    return AppUser(
      id: userId,
      username: username,
      fullName: fullName,
      role: UserRole.fromString(rol),
      active: true,
    );
  }

  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  Future<void> clearSession() async => _storage.deleteAll();
}
