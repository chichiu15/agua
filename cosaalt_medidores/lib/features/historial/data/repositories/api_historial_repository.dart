import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../domain/entities/ejecucion_historial.dart';

class HistorialException implements Exception {
  const HistorialException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiHistorialRepository {
  ApiHistorialRepository({ApiAuthRepository? authRepository})
    : _authRepository = authRepository ?? ApiAuthRepository();

  final ApiAuthRepository _authRepository;

  Future<Map<String, String>> _headers() async {
    final token = await _authRepository.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<EjecucionHistorial>> obtenerHistorial() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.historialEndpoint}');

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw HistorialException(
        _leerMensajeError(response, fallback: 'Error al obtener el historial.'),
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(EjecucionHistorial.fromJson)
        .toList();
  }

  String _leerMensajeError(http.Response response, {required String fallback}) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final mensaje = body['mensaje'] ?? body['message'] ?? body['title'];
        if (mensaje is String && mensaje.trim().isNotEmpty) return mensaje;
      }
    } catch (_) {}
    return fallback;
  }
}
