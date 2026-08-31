import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../../ejecucion_cambio/domain/entities/cambio_medidor.dart';

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiSyncRepository {
  ApiSyncRepository({ApiAuthRepository? authRepository})
    : _authRepository = authRepository ?? ApiAuthRepository();

  final ApiAuthRepository _authRepository;

  Future<Map<String, String>> _headers() async {
    final token = await _authRepository.getToken();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future<String> _subirFoto(
    File archivo,
    String tipoFoto,
    String idOrigen,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.evidenciasEndpoint}/upload'),
    );

    request.headers.addAll(await _headers());
    request.fields['tipoFoto'] = tipoFoto;
    request.fields['idOrigen'] = idOrigen;
    request.files.add(
      await http.MultipartFile.fromPath('archivo', archivo.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw SyncException('Error al subir foto: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['rutaArchivo'] as String;
  }

  Future<int> sincronizarBatch(List<CambioMedidorDraft> drafts) async {
    final ejecuciones = <Map<String, dynamic>>[];

    for (final draft in drafts) {
      String? rutaRetirado;
      String? rutaNuevo;

      final archivoRetirado = File(draft.fotoMedidorRetirado);
      if (await archivoRetirado.exists()) {
        rutaRetirado = await _subirFoto(
          archivoRetirado,
          'MedidorRetirado',
          draft.idOrigen,
        );
      }

      final archivoNuevo = File(draft.fotoMedidorNuevo);
      if (await archivoNuevo.exists()) {
        rutaNuevo = await _subirFoto(
          archivoNuevo,
          'MedidorNuevo',
          draft.idOrigen,
        );
      }

      ejecuciones.add({
        'tipoOrigen': draft.tipoOrigen,
        'idOrigen': draft.idOrigen,
        'idUsuarioApp': draft.idUsuarioApp,
        'fechaHoraEjecucion': draft.fechaHoraEjecucion.toIso8601String(),
        'numeroMedidorRetirado': draft.numeroMedidorRetirado,
        'marcaRetirado': draft.marcaRetirado,
        'lecturaRetiro': draft.lecturaRetiro,
        'idMotivo': draft.idMotivo,
        'numeroMedidorInstalado': draft.numeroMedidorInstalado,
        'marcaInstalado': draft.marcaInstalado,
        'observacionesInstalacion': draft.observacionesApi,
        'latLong': draft.latitud != null && draft.longitud != null
            ? '${draft.latitud},${draft.longitud}'
            : null,
        'evidencias': [
          if (rutaRetirado != null)
            {'tipoFoto': 'MedidorRetirado', 'rutaArchivo': rutaRetirado},
          if (rutaNuevo != null)
            {'tipoFoto': 'MedidorNuevo', 'rutaArchivo': rutaNuevo},
        ],
      });
    }

    final userId = drafts.isNotEmpty ? drafts.first.idUsuarioApp : 0;
    final body = {'idUsuario': userId, 'ejecuciones': ejecuciones};

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sincronizacionEndpoint}'),
      headers: {'Content-Type': 'application/json', ...await _headers()},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw SyncException('Error en sincronización: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return result['procesadosOk'] as int? ?? 0;
  }
}
