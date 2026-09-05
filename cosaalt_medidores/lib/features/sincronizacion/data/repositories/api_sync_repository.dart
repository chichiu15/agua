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

class SyncItemResult {
  const SyncItemResult({
    required this.localId,
    required this.tipoOrigen,
    required this.idOrigen,
    required this.ok,
    this.idEjecucion,
    this.yaExistia = false,
    this.error,
  });

  final String localId;
  final String tipoOrigen;
  final String idOrigen;
  final bool ok;
  final int? idEjecucion;
  final bool yaExistia;
  final String? error;
}

class SyncBatchResult {
  const SyncBatchResult({required this.items});
  final List<SyncItemResult> items;

  int get procesadosOk => items.where((x) => x.ok).length;
  int get errores => items.where((x) => !x.ok).length;
}

typedef SyncProgressCallback = void Function(
  int completedSteps,
  int totalSteps,
  String status,
);

class ApiSyncRepository {
  ApiSyncRepository({ApiAuthRepository? authRepository})
      : _authRepository = authRepository ?? ApiAuthRepository();

  final ApiAuthRepository _authRepository;

  Future<Map<String, String>> _headers() async {
    final token = await _authRepository.getToken();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future<String> _subirFoto(File archivo, String tipoFoto, String idOrigen) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.evidenciasEndpoint}/upload'),
    );
    request.headers.addAll(await _headers());
    request.fields['tipoFoto'] = tipoFoto;
    request.fields['idOrigen'] = idOrigen;
    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw SyncException(_mensajeError(response, 'No se pudo subir una fotografía.'));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['rutaArchivo'] as String;
  }

  Future<SyncBatchResult> sincronizarBatch(
    List<CambioMedidorDraft> drafts, {
    SyncProgressCallback? onProgress,
  }) async {
    final resultadosLocales = <SyncItemResult>[];
    final ejecuciones = <Map<String, dynamic>>[];
    final enviados = <String, CambioMedidorDraft>{};
    final photoCount = drafts.fold<int>(
      0,
      (total, draft) =>
          total +
          (draft.fotoMedidorRetirado?.trim().isNotEmpty == true ? 1 : 0) +
          (draft.fotoMedidorNuevo?.trim().isNotEmpty == true ? 1 : 0),
    );
    final totalSteps = drafts.length + photoCount + 1;
    var completedSteps = 0;
    onProgress?.call(0, totalSteps, 'Preparando ${drafts.length} trabajo(s)...');

    for (final draft in drafts) {
      try {
        final evidencias = <Map<String, dynamic>>[];
        final fotoRetirado = draft.fotoMedidorRetirado?.trim();
        if (fotoRetirado != null && fotoRetirado.isNotEmpty) {
          final archivoRetirado = File(fotoRetirado);
          if (await archivoRetirado.exists()) {
            onProgress?.call(completedSteps, totalSteps, 'Subiendo foto del medidor retirado...');
            final ruta = await _subirFoto(archivoRetirado, 'MedidorRetirado', draft.idOrigen);
            evidencias.add({'tipoFoto': 'MedidorRetirado', 'rutaArchivo': ruta});
          }
          completedSteps++;
          onProgress?.call(completedSteps, totalSteps, 'Foto procesada');
        }

        final fotoNuevo = draft.fotoMedidorNuevo?.trim();
        if (fotoNuevo != null && fotoNuevo.isNotEmpty) {
          final archivoNuevo = File(fotoNuevo);
          if (await archivoNuevo.exists()) {
            onProgress?.call(completedSteps, totalSteps, 'Subiendo foto del medidor instalado...');
            final ruta = await _subirFoto(archivoNuevo, 'MedidorNuevo', draft.idOrigen);
            evidencias.add({'tipoFoto': 'MedidorNuevo', 'rutaArchivo': ruta});
          }
          completedSteps++;
          onProgress?.call(completedSteps, totalSteps, 'Foto procesada');
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
          'regSoc': draft.codCon,
          if (draft.codMedidorInstalado != null && draft.codMedidorInstalado! > 0)
            'codMedidorInstalado': draft.codMedidorInstalado,
          'latitud': draft.latitud,
          'longitud': draft.longitud,
          'evidencias': evidencias,
        });
        enviados[_key(draft.tipoOrigen, draft.idOrigen)] = draft;
        completedSteps++;
        onProgress?.call(
          completedSteps,
          totalSteps,
          'Preparado ${ejecuciones.length} de ${drafts.length}',
        );
      } on SyncException catch (e) {
        resultadosLocales.add(SyncItemResult(
          localId: draft.localId,
          tipoOrigen: draft.tipoOrigen,
          idOrigen: draft.idOrigen,
          ok: false,
          error: e.message,
        ));
      } catch (_) {
        resultadosLocales.add(SyncItemResult(
          localId: draft.localId,
          tipoOrigen: draft.tipoOrigen,
          idOrigen: draft.idOrigen,
          ok: false,
          error: 'No se pudo preparar este trabajo para sincronización.',
        ));
      }
    }

    if (ejecuciones.isEmpty) return SyncBatchResult(items: resultadosLocales);

    final userId = drafts.isNotEmpty ? drafts.first.idUsuarioApp : 0;
    onProgress?.call(completedSteps, totalSteps, 'Registrando cambios en el servidor...');
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sincronizacionEndpoint}'),
          headers: {'Content-Type': 'application/json', ...await _headers()},
          body: jsonEncode({'idUsuario': userId, 'ejecuciones': ejecuciones}),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw SyncException(_mensajeError(response, 'El servidor rechazó la sincronización.'));
    }
    completedSteps++;
    onProgress?.call(completedSteps, totalSteps, 'Confirmación recibida');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final serverResults = body['resultados'] as List? ?? const [];
    final recibidos = <String>{};

    for (final raw in serverResults) {
      final item = raw as Map<String, dynamic>;
      final tipo = item['tipoOrigen']?.toString() ?? '';
      final origen = item['idOrigen']?.toString() ?? '';
      final key = _key(tipo, origen);
      final draft = enviados[key];
      if (draft == null) continue;
      recibidos.add(key);
      resultadosLocales.add(SyncItemResult(
        localId: draft.localId,
        tipoOrigen: tipo,
        idOrigen: origen,
        ok: item['ok'] as bool? ?? false,
        idEjecucion: (item['idEjecucion'] as num?)?.toInt(),
        yaExistia: item['yaExistia'] as bool? ?? false,
        error: item['error']?.toString(),
      ));
    }

    for (final entry in enviados.entries) {
      if (recibidos.contains(entry.key)) continue;
      resultadosLocales.add(SyncItemResult(
        localId: entry.value.localId,
        tipoOrigen: entry.value.tipoOrigen,
        idOrigen: entry.value.idOrigen,
        ok: false,
        error: 'El servidor no devolvió confirmación para este trabajo.',
      ));
    }

    return SyncBatchResult(items: resultadosLocales);
  }

  String _key(String tipo, String origen) => '${tipo.trim().toUpperCase()}|${origen.trim()}';

  String _mensajeError(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data['mensaje'] ?? data['message'] ?? data['title'];
        if (message is String && message.trim().isNotEmpty) return message.trim();
      }
    } catch (_) {}
    return fallback;
  }
}
