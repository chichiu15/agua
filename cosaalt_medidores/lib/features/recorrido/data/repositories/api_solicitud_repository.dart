import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../domain/entities/ruta_asignada.dart';
import '../../domain/entities/solicitud.dart';
import '../../domain/entities/tecnico.dart';
import '../../domain/repositories/solicitud_repository.dart';

class ApiSolicitudRepository implements SolicitudRepository {
  ApiSolicitudRepository({ApiAuthRepository? authRepository})
      : _authRepository = authRepository ?? ApiAuthRepository();

  final ApiAuthRepository _authRepository;

  Future<Map<String, String>> _headers() async {
    final token = await _authRepository.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<SolicitudesResponse> obtenerSolicitudes({String? filtro}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.solicitudesEndpoint}',
    ).replace(queryParameters: filtro != null ? {'filtro': filtro} : null);

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw SolicitudException(
        _leerMensajeError(response, fallback: 'Error al obtener solicitudes.'),
      );
    }

    return SolicitudesResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<Tecnico>> obtenerTecnicos() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.tecnicosEndpoint}',
    );

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw SolicitudException(
        _leerMensajeError(response, fallback: 'Error al obtener técnicos.'),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TecnicosResponse.fromJson(data).tecnicos;
  }

  @override
  Future<void> asignarRuta(AsignarRutaParams params) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.rutasEndpoint}/asignar',
    );

    final body = {
      'idUsuarioAsignador': params.idUsuarioAsignador,
      'idUsuarioTecnico': params.idUsuarioTecnico,
      'fechaAsignacion': DateTime.now().toIso8601String(),
      'detalles': params.solicitudes.asMap().entries.map((entry) {
        final index = entry.key;
        final s = entry.value;
        return {
          'tipoOrigen': s.tipoOrigen,
          'idOrigen': s.folioOdeco?.toString() ?? s.id.replaceFirst('LEC-', ''),
          'solicitudId': s.id,
          'ordenVisita': index + 1,
          'latitud': s.latitud,
          'longitud': s.longitud,
          'nombreCliente': s.nombreCliente,
          'direccion': s.direccion,
        };
      }).toList(),
    };

    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw SolicitudException(
        _leerMensajeError(response, fallback: 'Error al asignar la ruta.'),
      );
    }
  }

  @override
  Future<List<RutaAsignada>> obtenerRutasTecnico(
    int idTecnico, {
    DateTime? fecha,
  }) async {
    final query = <String, String>{};
    if (fecha != null) {
      query['fecha'] =
          '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.rutasEndpoint}/tecnico/$idTecnico',
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw SolicitudException(
        _leerMensajeError(response, fallback: 'Error al obtener las rutas del técnico.'),
      );
    }

    return RutasTecnicoResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    ).rutas;
  }

  @override
  Future<RutaAsignada> obtenerRutaPorId(int idAsignacion) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.rutasEndpoint}/$idAsignacion',
    );

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw SolicitudException(
        _leerMensajeError(response, fallback: 'Error al obtener el detalle de la ruta.'),
      );
    }

    return RutaAsignada.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _leerMensajeError(
    http.Response response, {
    required String fallback,
  }) {
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
