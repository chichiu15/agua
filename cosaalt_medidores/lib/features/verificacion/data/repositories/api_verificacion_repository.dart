import 'dart:async';
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

/// M10: transforma cualquier error técnico en un mensaje apto para usuario.
/// No expone SocketException, ClientException, stack traces ni detalles SQL.
String mensajeVerificacionError(
  Object error, {
  String fallback =
      'No se pudo completar la operación. Intente nuevamente.',
}) {
  if (error is VerificacionApiException) {
    return _mensajeSeguro(error.message, fallback: fallback);
  }

  if (error is TimeoutException) {
    return 'No se pudo conectar con el servidor. Verifique la red o VPN e intente nuevamente.';
  }

  if (error is SocketException || error is http.ClientException) {
    return 'No se pudo conectar con el servidor. Verifique la red o VPN e intente nuevamente.';
  }

  if (error is FileSystemException) {
    return 'No se pudo guardar o acceder al archivo. Verifique los permisos e intente nuevamente.';
  }

  if (error is FormatException) {
    return 'El servidor devolvió una respuesta no válida. Intente nuevamente.';
  }

  return _mensajeSeguro(error.toString(), fallback: fallback);
}

String _mensajeSeguro(
  String? value, {
  required String fallback,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return fallback;

  final lower = text.toLowerCase();

  if (lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('connection refused') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection reset') ||
      lower.contains('network is unreachable') ||
      lower.contains('timed out') ||
      lower.contains('timeoutexception')) {
    return 'No se pudo conectar con el servidor. Verifique la red o VPN e intente nuevamente.';
  }

  if (lower.contains('sqlexception') ||
      lower.contains('microsoft.data') ||
      lower.contains('system.data') ||
      lower.contains('stack trace') ||
      lower.contains('#0 ') ||
      lower.contains(' at ')) {
    return fallback;
  }

  var clean = text;
  const prefixes = <String>[
    'Exception: ',
    'VerificacionApiException: ',
  ];

  for (final prefix in prefixes) {
    if (clean.startsWith(prefix)) {
      clean = clean.substring(prefix.length).trim();
    }
  }

  return clean.isEmpty ? fallback : clean;
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
    String? cargoResponsable,
    String? nombreDestinatario,
    String? cargoDestinatario,
    String? referencia,
    String? lugarVerificacion,
    String? tipoEnsayoTexto,
    String? descripcionTecnica,
    String? conclusionAdicional,
    String? recomendacion,
  }) async {
    final body = {
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones,
      if (nombreResponsable != null && nombreResponsable.trim().isNotEmpty)
        'nombreResponsable': nombreResponsable,
      if (cargoResponsable != null && cargoResponsable.trim().isNotEmpty)
        'cargoResponsable': cargoResponsable,
      if (nombreDestinatario != null && nombreDestinatario.trim().isNotEmpty)
        'nombreDestinatario': nombreDestinatario,
      if (cargoDestinatario != null && cargoDestinatario.trim().isNotEmpty)
        'cargoDestinatario': cargoDestinatario,
      if (referencia != null && referencia.trim().isNotEmpty)
        'referencia': referencia,
      if (lugarVerificacion != null && lugarVerificacion.trim().isNotEmpty)
        'lugarVerificacion': lugarVerificacion,
      if (tipoEnsayoTexto != null && tipoEnsayoTexto.trim().isNotEmpty)
        'tipoEnsayoTexto': tipoEnsayoTexto,
      if (descripcionTecnica != null && descripcionTecnica.trim().isNotEmpty)
        'descripcionTecnica': descripcionTecnica,
      if (conclusionAdicional != null && conclusionAdicional.trim().isNotEmpty)
        'conclusionAdicional': conclusionAdicional,
      if (recomendacion != null && recomendacion.trim().isNotEmpty)
        'recomendacion': recomendacion,
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

  String _leerMensajeError(
    http.Response response, {
    required String fallback,
  }) {
    String? mensajeServidor;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final mensaje =
            body['mensaje'] ?? body['message'] ?? body['title'];
        if (mensaje is String && mensaje.trim().isNotEmpty) {
          mensajeServidor = mensaje.trim();
        }
      }
    } catch (_) {
      // La respuesta puede no ser JSON. Nunca mostramos el body crudo.
    }

    if (mensajeServidor != null) {
      final seguro = _mensajeSeguro(
        mensajeServidor,
        fallback: fallback,
      );
      if (seguro != fallback || !_pareceTecnico(mensajeServidor)) {
        return seguro;
      }
    }

    switch (response.statusCode) {
      case 401:
      case 403:
        return 'Su sesión no está autorizada. Inicie sesión nuevamente.';
      case 408:
      case 504:
        return 'No se pudo conectar con el servidor. Intente nuevamente.';
      case 503:
        return 'La VPN o la base institucional no están disponibles.';
      case 409:
        return mensajeServidor == null
            ? 'La operación no puede completarse porque los datos cambiaron.'
            : _mensajeSeguro(mensajeServidor, fallback: fallback);
      default:
        return fallback;
    }
  }

  bool _pareceTecnico(String value) {
    final lower = value.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('stack') ||
        lower.contains('microsoft.data') ||
        lower.contains('system.') ||
        lower.contains('sql') ||
        lower.contains('#0 ');
  }
}
