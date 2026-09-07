import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/api_config.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../domain/entities/verificacion_mecanico.dart';

class VerificacionApiException implements Exception {
  const VerificacionApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiVerificacionRepository {
  ApiVerificacionRepository({ApiAuthRepository? authRepository})
    : _authRepository = authRepository ?? ApiAuthRepository();

  final ApiAuthRepository _authRepository;

  Future<Map<String, String>> _headers() async {
    final token = await _authRepository.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<SolicitudVerificacion>> obtenerSolicitudes() async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesSolicitudesEndpoint}',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(
          response,
          fallback: 'Error al obtener las solicitudes.',
        ),
      );
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(SolicitudVerificacion.fromJson)
        .toList();
  }

  Future<int> tomarVerificacion({
    required String tipoOrigen,
    required String idOrigen,
    required int codCon,
    required int idUsuarioMecanico,
    String? idMedidor,
  }) async {
    final body = {
      'tipoOrigen': tipoOrigen,
      'idOrigen': idOrigen,
      'codCon': codCon,
      'idUsuarioMecanico': idUsuarioMecanico,
      if (idMedidor != null && idMedidor.trim().isNotEmpty)
        'idMedidor': idMedidor,
    };
    final response = await http
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesTomarEndpoint}',
          ),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(
          response,
          fallback: 'No se pudo tomar la verificacion.',
        ),
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['idVerificacion'] as num?)?.toInt() ?? 0;
  }

  Future<MecanicoDashboard> obtenerDashboard(int idMecanico) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/dashboard/$idMecanico',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(response, fallback: 'Error al obtener el dashboard.'),
      );
    }
    return MecanicoDashboard.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<VerificacionMecanico>> obtenerEnCurso(int idMecanico) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/mecanico/$idMecanico',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(
          response,
          fallback: 'No se pudieron cargar las verificaciones en curso.',
        ),
      );
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map(
          (item) => VerificacionMecanico.fromJson(item as Map<String, dynamic>),
        )
        .where(
          (v) => v.estado == 'EnCurso' && v.idUsuarioMecanico == idMecanico,
        )
        .toList();
  }

  Future<VerificacionMecanico> obtenerVerificacion(int id) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/$id',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(
          response,
          fallback: 'Error al obtener la verificacion.',
        ),
      );
    }
    return VerificacionMecanico.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DatosSocioMedidor> obtenerDatosSocioMedidor(int idVerificacion) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/$idVerificacion/datos',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(
          response,
          fallback: 'Error al obtener los datos del socio.',
        ),
      );
    }
    return DatosSocioMedidor.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CalculoEnsayo> calcularEnsayo(Map<String, dynamic> request) async {
    final response = await http
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesCalcularEndpoint}',
          ),
          headers: await _headers(),
          body: jsonEncode(request),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(response, fallback: 'No se pudo calcular el ensayo.'),
      );
    }
    return CalculoEnsayo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<EnsayoGuardadoResultado> guardarEnsayo(
    int idVerificacion,
    Map<String, dynamic> request,
  ) async {
    final response = await http
        .put(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/$idVerificacion/ensayo',
          ),
          headers: await _headers(),
          body: jsonEncode(request),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(response, fallback: 'No se pudo guardar el ensayo.'),
      );
    }
    return EnsayoGuardadoResultado.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<VerificacionMecanico> guardarParticipantes(
    int idVerificacion,
    List<ParticipanteVerificacion> participantes,
  ) async {
    final response = await http
        .put(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/$idVerificacion/participantes',
          ),
          headers: await _headers(),
          body: jsonEncode(participantes.map((p) => p.toJson()).toList()),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(
          response,
          fallback: 'No se pudieron guardar los participantes.',
        ),
      );
    }
    return VerificacionMecanico.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<VerificacionMecanico> finalizar(int idVerificacion) async {
    final response = await http
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/$idVerificacion/finalizar',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(
          response,
          fallback: 'No se pudo finalizar la verificacion.',
        ),
      );
    }
    return VerificacionMecanico.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<InformeVerificacion>> obtenerInformes(int idVerificacion) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/$idVerificacion/informes',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(response, fallback: 'Error al obtener los informes.'),
      );
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(InformeVerificacion.fromJson)
        .toList();
  }

  Future<InformeVerificacion> generarInforme(
    int idVerificacion, {
    String? observaciones,
    String? nombreResponsable,
  }) async {
    final body = {
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones,
      if (nombreResponsable != null && nombreResponsable.trim().isNotEmpty)
        'nombreResponsable': nombreResponsable,
    };
    final response = await http
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/$idVerificacion/informe',
          ),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 40));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(response, fallback: 'No se pudo generar el informe.'),
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final informe =
        (data['informe'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return InformeVerificacion.fromJson(informe);
  }

  Future<String> descargarInforme(int idInforme, String nroInforme) async {
    final bytes = await _obtenerPdfInforme(idInforme);

    final safe = nroInforme.trim().isEmpty
        ? 'informe_$idInforme'
        : nroInforme.trim();

    final safeName = safe.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    /*
   * Android:
   *
   * No dependemos del selector de guardado.
   * Guardamos en almacenamiento externo propio
   * de la aplicación.
   */
    if (Platform.isAndroid) {
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();

      final outputPath = p.join(directory.path, '$safeName.pdf');

      await File(outputPath).writeAsBytes(bytes, flush: true);

      return outputPath;
    }

    /*
   * Windows / escritorio:
   * el usuario elige dónde guardar.
   */
    final location = await getSaveLocation(
      suggestedName: '$safeName.pdf',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Documento PDF', extensions: ['pdf']),
      ],
    );

    if (location == null) {
      return '';
    }

    var outputPath = location.path;

    if (!outputPath.toLowerCase().endsWith('.pdf')) {
      outputPath = '$outputPath.pdf';
    }

    await File(outputPath).writeAsBytes(bytes, flush: true);

    return outputPath;
  }

  Future<String> prepararInformeTemporal(
    int idInforme,
    String nroInforme,
  ) async {
    final bytes = await _obtenerPdfInforme(idInforme);

    final safe = nroInforme.trim().isEmpty
        ? 'informe_$idInforme'
        : nroInforme.trim();

    final safeName = safe.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    final directory = await getTemporaryDirectory();

    final outputPath = p.join(directory.path, '$safeName.pdf');

    await File(outputPath).writeAsBytes(bytes, flush: true);

    return outputPath;
  }

  Future<List<int>> _obtenerPdfInforme(int idInforme) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/reportes/informes/$idInforme/pdf',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(response, fallback: 'No se pudo obtener el PDF.'),
      );
    }

    return response.bodyBytes;
  }

  Future<HistorialVerificacionResponse> obtenerHistorial(
    int idMecanico, {
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    String? resultado,
    String? buscar,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (desde != null) 'desde': _fechaQuery(desde),
      if (hasta != null) 'hasta': _fechaQuery(hasta),
      if (estado != null && estado.trim().isNotEmpty) 'estado': estado.trim(),
      if (resultado != null && resultado.trim().isNotEmpty)
        'resultado': resultado.trim(),
      if (buscar != null && buscar.trim().isNotEmpty) 'buscar': buscar.trim(),
    };
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.verificacionesEndpoint}/historial/$idMecanico',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw VerificacionApiException(
        _leerMensajeError(response, fallback: 'Error al obtener el historial.'),
      );
    }
    return HistorialVerificacionResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _fechaQuery(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
