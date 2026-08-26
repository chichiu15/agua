import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/api_config.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../../recorrido/domain/entities/solicitud.dart';
import '../../domain/entities/cambio_medidor.dart';
import '../../domain/repositories/ejecucion_repository.dart';

class EjecucionRepositoryImpl implements EjecucionRepository {
  EjecucionRepositoryImpl({ApiAuthRepository? authRepository})
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
  Future<Solicitud> obtenerSolicitud(String solicitudId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.solicitudesEndpoint}/$solicitudId',
    );

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw EjecucionException(
        _mensajeError(response, 'No se pudo cargar la solicitud.'),
      );
    }

    return Solicitud.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<MotivoCambio>> obtenerMotivos() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.motivosEndpoint}',
    );

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw EjecucionException(
        _mensajeError(response, 'No se pudo cargar el catálogo de motivos.'),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['motivos'] as List? ?? const [])
        .map((m) => MotivoCambio.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> guardarLocal(CambioMedidorDraft draft) async {
    final docs = await getApplicationDocumentsDirectory();
    final carpeta = Directory(
      p.join(docs.path, 'cosaalt_medidores', 'pendientes'),
    );
    await carpeta.create(recursive: true);

    final archivo = File(p.join(carpeta.path, '${draft.localId}.json'));
    await archivo.writeAsString(
      const JsonEncoder.withIndent('  ').convert(draft.toJson()),
      flush: true,
    );

    return archivo.path;
  }

  String _mensajeError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final value = body['mensaje'] ?? body['message'] ?? body['title'];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    } catch (_) {}
    return fallback;
  }
}
