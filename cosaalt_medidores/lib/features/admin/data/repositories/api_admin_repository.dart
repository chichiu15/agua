import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';

import '../../../../core/config/api_config.dart';
import '../../domain/entities/admin_models.dart';

class AdminApiException implements Exception {
  const AdminApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiAdminRepository {
  Future<List<AdminUsuario>> obtenerUsuarios() async {
    final data = await _getJson(ApiConfig.usuariosEndpoint);
    return ((data['usuarios'] as List?) ?? const [])
        .map((e) => AdminUsuario.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminRol>> obtenerRoles() async {
    final data = await _getJson('${ApiConfig.usuariosEndpoint}/roles');
    return ((data['roles'] as List?) ?? const [])
        .map((e) => AdminRol.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminFuncionario>> obtenerFuncionarios() async {
    final data = await _getJson('${ApiConfig.usuariosEndpoint}/funcionarios');
    return ((data['funcionarios'] as List?) ?? const [])
        .map((e) => AdminFuncionario.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminUsuario> crearUsuario(GuardarUsuario value) async {
    if (value.contrasena == null || value.contrasena!.isEmpty) {
      throw const AdminApiException('La contrasena es obligatoria al crear el usuario.');
    }
    final data = await _sendJson(
      'POST',
      ApiConfig.usuariosEndpoint,
      {
        'codFunCorporativo': value.codFunCorporativo,
        'nombreUsuario': value.nombreUsuario,
        'contrasena': value.contrasena,
        'idRol': value.idRol,
        'activo': value.activo,
      },
    );
    return AdminUsuario.fromJson(data);
  }

  Future<AdminUsuario> actualizarUsuario(int id, GuardarUsuario value) async {
    final data = await _sendJson(
      'PUT',
      '${ApiConfig.usuariosEndpoint}/$id',
      {
        'codFunCorporativo': value.codFunCorporativo,
        'nombreUsuario': value.nombreUsuario,
        'contrasena': value.contrasena,
        'idRol': value.idRol,
        'activo': value.activo,
      },
    );
    return AdminUsuario.fromJson(data);
  }

  Future<List<MotivoCatalogo>> obtenerMotivos() async {
    final data = await _getJson('${ApiConfig.motivosEndpoint}?incluirInactivos=true');
    return ((data['motivos'] as List?) ?? const [])
        .map((e) => MotivoCatalogo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MotivoCatalogo> crearMotivo(GuardarMotivoCatalogo value) async {
    final data = await _sendJson('POST', ApiConfig.motivosEndpoint, {
      'nombre': value.nombre,
      'descripcion': value.descripcion,
      'activo': value.activo,
    });
    return MotivoCatalogo.fromJson(data);
  }

  Future<MotivoCatalogo> actualizarMotivo(int id, GuardarMotivoCatalogo value) async {
    final data = await _sendJson('PUT', '${ApiConfig.motivosEndpoint}/$id', {
      'nombre': value.nombre,
      'descripcion': value.descripcion,
      'activo': value.activo,
    });
    return MotivoCatalogo.fromJson(data);
  }

  Future<MotivoCatalogo> cambiarEstadoMotivo(int id, bool activo) async {
    final data = await _sendJson('PATCH', '${ApiConfig.motivosEndpoint}/$id/estado', {'activo': activo});
    return MotivoCatalogo.fromJson(data);
  }

  Future<List<MarcaCatalogo>> obtenerMarcas() async {
    final data = await _getJson(ApiConfig.marcasEndpoint);
    return ((data['marcas'] as List?) ?? const [])
        .map((e) => MarcaCatalogo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParametroNormativo>> obtenerParametros() async {
    final data = await _getJson(ApiConfig.parametrosNormativosEndpoint);
    return ((data['parametros'] as List?) ?? const [])
        .map((e) => ParametroNormativo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ParametroNormativo> obtenerParametroVigente(double caudal, {DateTime? fecha}) async {
    final query = <String, String>{'caudal': caudal.toString()};
    if (fecha != null) query['fecha'] = fecha.toIso8601String();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.parametrosNormativosEndpoint}/vigente')
        .replace(queryParameters: query);
    final response = await http.get(uri);
    final data = _decode(response);
    return ParametroNormativo.fromJson(data);
  }

  Future<ParametroNormativo> crearParametro(GuardarParametroNormativo value) async {
    final data = await _sendJson('POST', ApiConfig.parametrosNormativosEndpoint, _paramBody(value));
    return ParametroNormativo.fromJson(data);
  }

  Future<ParametroNormativo> actualizarParametro(int id, GuardarParametroNormativo value) async {
    final data = await _sendJson('PUT', '${ApiConfig.parametrosNormativosEndpoint}/$id', _paramBody(value));
    return ParametroNormativo.fromJson(data);
  }

  Future<ParametroNormativo> cambiarEstadoParametro(int id, bool activo) async {
    final data = await _sendJson('PATCH', '${ApiConfig.parametrosNormativosEndpoint}/$id/estado', {'activo': activo});
    return ParametroNormativo.fromJson(data);
  }

  Map<String, dynamic> _paramBody(GuardarParametroNormativo v) => {
    'codigo': v.codigo,
    'descripcion': v.descripcion,
    'errorMaxPermitido': v.errorMaxPermitido,
    'caudalMin': v.caudalMin,
    'caudalMax': v.caudalMax,
    'vigenciaInicio': v.vigenciaInicio?.toIso8601String(),
    'vigenciaFin': v.vigenciaFin?.toIso8601String(),
    'activo': v.activo,
  };



  Future<AdminDashboard> obtenerDashboard({DateTime? desde, DateTime? hasta}) async {
    final query = <String, String>{};
    if (desde != null) query['desde'] = desde.toIso8601String();
    if (hasta != null) query['hasta'] = hasta.toIso8601String();
    final data = await _getJsonUri(_uri(ApiConfig.adminDashboardEndpoint, query));
    return AdminDashboard.fromJson(data);
  }

  Future<PagedData<AdminSolicitud>> obtenerSolicitudesAdmin({
    DateTime? desde, DateTime? hasta, String? origen, String? estado, String? prioridad,
    int? tecnicoId, String? buscar, int page = 1, int pageSize = 25,
  }) async {
    final q = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    if (desde != null) q['desde'] = desde.toIso8601String();
    if (hasta != null) q['hasta'] = hasta.toIso8601String();
    if (origen != null && origen.isNotEmpty && origen != 'Todos') q['origen'] = origen;
    if (estado != null && estado.isNotEmpty && estado != 'Todos') q['estado'] = estado;
    if (prioridad != null && prioridad.isNotEmpty && prioridad != 'Todas') q['prioridad'] = prioridad;
    if (tecnicoId != null) q['tecnicoId'] = '$tecnicoId';
    if (buscar != null && buscar.trim().isNotEmpty) q['buscar'] = buscar.trim();
    final data = await _getJsonUri(_uri(ApiConfig.adminSolicitudesEndpoint, q));
    return _paged(data, AdminSolicitud.fromJson);
  }

  Future<PagedData<AdminRuta>> obtenerRutasAdmin({DateTime? fecha, int? tecnicoId, String? estado, String? buscar, int page = 1, int pageSize = 20}) async {
    final q = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    if (fecha != null) q['fecha'] = fecha.toIso8601String();
    if (tecnicoId != null) q['tecnicoId'] = '$tecnicoId';
    if (estado != null && estado.isNotEmpty && estado != 'Todos') q['estado'] = estado;
    if (buscar != null && buscar.trim().isNotEmpty) q['buscar'] = buscar.trim();
    final data = await _getJsonUri(_uri(ApiConfig.adminRutasEndpoint, q));
    return _paged(data, AdminRuta.fromJson);
  }

  Future<AdminRuta> obtenerRutaAdmin(int id) async {
    final data = await _getJson('${ApiConfig.adminRutasEndpoint}/$id');
    return AdminRuta.fromJson(data);
  }

  Future<List<AdminSincronizacionTecnico>> obtenerSincronizacionAdmin({DateTime? fecha}) async {
    final q = <String, String>{};
    if (fecha != null) q['fecha'] = fecha.toIso8601String();
    final data = await _getJsonUri(_uri(ApiConfig.adminSincronizacionEndpoint, q));
    return ((data['tecnicos'] as List?) ?? const []).whereType<Map>().map((e) => AdminSincronizacionTecnico.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<PagedData<AdminVerificacion>> obtenerVerificacionesAdmin({
    DateTime? desde, DateTime? hasta, int? mecanicoId, String? estado, String? resultado,
    String? buscar, bool? soloConInforme, int page = 1, int pageSize = 25,
  }) async {
    final q = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    if (desde != null) q['desde'] = desde.toIso8601String();
    if (hasta != null) q['hasta'] = hasta.toIso8601String();
    if (mecanicoId != null) q['mecanicoId'] = '$mecanicoId';
    if (estado != null && estado.isNotEmpty && estado != 'Todos') q['estado'] = estado;
    if (resultado != null && resultado.isNotEmpty && resultado != 'Todos') q['resultado'] = resultado;
    if (buscar != null && buscar.trim().isNotEmpty) q['buscar'] = buscar.trim();
    if (soloConInforme != null) q['soloConInforme'] = '$soloConInforme';
    final data = await _getJsonUri(_uri(ApiConfig.adminVerificacionesEndpoint, q));
    return _paged(data, AdminVerificacion.fromJson);
  }

  Future<AdminVerificacionDetalle> obtenerVerificacionDetalle(int id) async {
    final data = await _getJson('${ApiConfig.adminVerificacionesEndpoint}/$id');
    return AdminVerificacionDetalle.fromJson(data);
  }

  Future<PagedData<AdminMovimiento>> obtenerMovimientos({
    DateTime? desde, DateTime? hasta, int? tecnicoId, int? motivoId, String? origen,
    String? marca, bool? sincronizado, String? buscar, int page = 1, int pageSize = 25,
  }) async {
    final data = await _getJsonUri(_uri(ApiConfig.reportesMovimientosEndpoint, _movQuery(
      desde: desde, hasta: hasta, tecnicoId: tecnicoId, motivoId: motivoId, origen: origen,
      marca: marca, sincronizado: sincronizado, buscar: buscar, page: page, pageSize: pageSize,
    )));
    return _paged(data, AdminMovimiento.fromJson);
  }

  Future<PagedData<AdminMovimientoCorporativo>> obtenerHistoricoCorporativo({
    int? codCon, bool? vigente, int? motivoId, String? marca, String? buscar,
    int page = 1, int pageSize = 25,
  }) async {
    final data = await _getJsonUri(_uri(ApiConfig.reportesHistoricoCorporativoEndpoint, _historicoQuery(
      codCon: codCon, vigente: vigente, motivoId: motivoId, marca: marca, buscar: buscar,
      page: page, pageSize: pageSize,
    )));
    return _paged(data, AdminMovimientoCorporativo.fromJson);
  }

  Future<AdminEstadisticas> obtenerEstadisticas({DateTime? desde, DateTime? hasta, int? tecnicoId, int? mecanicoId, int? motivoId, String? origen, String? marca}) async {
    final q = <String, String>{};
    if (desde != null) q['desde'] = desde.toIso8601String();
    if (hasta != null) q['hasta'] = hasta.toIso8601String();
    if (tecnicoId != null) q['tecnicoId'] = '$tecnicoId';
    if (mecanicoId != null) q['mecanicoId'] = '$mecanicoId';
    if (motivoId != null) q['motivoId'] = '$motivoId';
    if (origen != null && origen.isNotEmpty && origen != 'Todos') q['origen'] = origen;
    if (marca != null && marca.trim().isNotEmpty) q['marca'] = marca.trim();
    return AdminEstadisticas.fromJson(await _getJsonUri(_uri(ApiConfig.reportesEstadisticasEndpoint, q)));
  }

  Future<String> exportarMovimientos({required bool pdf, DateTime? desde, DateTime? hasta, int? tecnicoId, int? motivoId, String? origen, String? marca, bool? sincronizado, String? buscar}) async {
    final endpoint = pdf ? '${ApiConfig.reportesMovimientosEndpoint}/pdf' : '${ApiConfig.reportesMovimientosEndpoint}/excel';
    final uri = _uri(endpoint, _movQuery(desde: desde, hasta: hasta, tecnicoId: tecnicoId, motivoId: motivoId, origen: origen, marca: marca, sincronizado: sincronizado, buscar: buscar));
    final response = await http.get(uri);
    final ext = pdf ? 'pdf' : 'xlsx';
    return _guardarDescarga(response, 'movimiento_medidores_${DateTime.now().millisecondsSinceEpoch}.$ext');
  }

  Future<String> exportarHistoricoCorporativo({
    required bool pdf, int? codCon, bool? vigente, int? motivoId, String? marca, String? buscar,
  }) async {
    final endpoint = pdf
        ? '${ApiConfig.reportesHistoricoCorporativoEndpoint}/pdf'
        : '${ApiConfig.reportesHistoricoCorporativoEndpoint}/excel';
    final response = await http.get(_uri(endpoint, _historicoQuery(
      codCon: codCon, vigente: vigente, motivoId: motivoId, marca: marca, buscar: buscar,
    )));
    final ext = pdf ? 'pdf' : 'xlsx';
    return _guardarDescarga(response, 'historico_corporativo_${DateTime.now().millisecondsSinceEpoch}.$ext');
  }

  Future<String> exportarVerificaciones({
    required bool pdf, DateTime? desde, DateTime? hasta, int? mecanicoId,
    String? estado, String? resultado, String? buscar, bool? soloConInforme,
  }) async {
    final endpoint = pdf ? '${ApiConfig.reportesVerificacionesEndpoint}/pdf' : '${ApiConfig.reportesVerificacionesEndpoint}/excel';
    final q = <String, String>{};
    if (desde != null) q['desde'] = desde.toIso8601String();
    if (hasta != null) q['hasta'] = hasta.toIso8601String();
    if (mecanicoId != null) q['mecanicoId'] = '$mecanicoId';
    if (estado != null && estado.isNotEmpty && estado != 'Todos') q['estado'] = estado;
    if (resultado != null && resultado.isNotEmpty && resultado != 'Todos') q['resultado'] = resultado;
    if (buscar != null && buscar.trim().isNotEmpty) q['buscar'] = buscar.trim();
    if (soloConInforme != null) q['soloConInforme'] = '$soloConInforme';
    final response = await http.get(_uri(endpoint, q));
    final ext = pdf ? 'pdf' : 'xlsx';
    return _guardarDescarga(response, 'verificaciones_${DateTime.now().millisecondsSinceEpoch}.$ext');
  }

  Future<String> descargarInformeTecnico(int idInforme, String nroInforme) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/reportes/informes/$idInforme/pdf'));
    final safe = nroInforme.trim().isEmpty ? 'informe_$idInforme' : nroInforme.trim();
    return _guardarDescarga(response, '$safe.pdf');
  }

  Future<String> descargarArchivoServidor(String ruta, {String? nombreSugerido}) async {
    final trimmed = ruta.trim();
    if (trimmed.isEmpty) throw const AdminApiException('El informe no tiene una ruta PDF asociada.');
    final uri = trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? Uri.parse(trimmed)
        : Uri.parse('${ApiConfig.baseUrl}${trimmed.startsWith('/') ? trimmed : '/$trimmed'}');
    final response = await http.get(uri);
    final rawName = nombreSugerido?.trim();
    final pathName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final fileName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (pathName.isNotEmpty ? pathName : 'informe_${DateTime.now().millisecondsSinceEpoch}.pdf');
    return _guardarDescarga(response, fileName);
  }

  Future<String> _guardarDescarga(http.Response response, String fileName) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        _decode(response);
      } catch (e) {
        throw AdminApiException(e.toString());
      }
      throw const AdminApiException('No se pudo generar el archivo solicitado.');
    }

    final safeName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final extension = safeName.toLowerCase().endsWith('.pdf') ? 'pdf' : 'xlsx';
    final group = XTypeGroup(
      label: extension == 'pdf' ? 'Documento PDF' : 'Libro de Excel',
      extensions: [extension],
    );

    final location = await getSaveLocation(
      suggestedName: safeName,
      acceptedTypeGroups: [group],
    );
    if (location == null) return '';

    var outputPath = location.path;
    if (!outputPath.toLowerCase().endsWith('.$extension')) {
      outputPath = '$outputPath.$extension';
    }
    final file = File(outputPath);
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  Map<String, String> _historicoQuery({int? codCon, bool? vigente, int? motivoId, String? marca, String? buscar, int? page, int? pageSize}) {
    final q = <String, String>{};
    if (codCon != null) q['codCon'] = '$codCon';
    if (vigente != null) q['vigente'] = '$vigente';
    if (motivoId != null) q['motivoId'] = '$motivoId';
    if (marca != null && marca.trim().isNotEmpty) q['marca'] = marca.trim();
    if (buscar != null && buscar.trim().isNotEmpty) q['buscar'] = buscar.trim();
    if (page != null) q['page'] = '$page';
    if (pageSize != null) q['pageSize'] = '$pageSize';
    return q;
  }

  Map<String, String> _movQuery({DateTime? desde, DateTime? hasta, int? tecnicoId, int? motivoId, String? origen, String? marca, bool? sincronizado, String? buscar, int? page, int? pageSize}) {
    final q = <String, String>{};
    if (desde != null) q['desde'] = desde.toIso8601String();
    if (hasta != null) q['hasta'] = hasta.toIso8601String();
    if (tecnicoId != null) q['tecnicoId'] = '$tecnicoId';
    if (motivoId != null) q['motivoId'] = '$motivoId';
    if (origen != null && origen.isNotEmpty && origen != 'Todos') q['origen'] = origen;
    if (marca != null && marca.trim().isNotEmpty) q['marca'] = marca.trim();
    if (sincronizado != null) q['sincronizado'] = '$sincronizado';
    if (buscar != null && buscar.trim().isNotEmpty) q['buscar'] = buscar.trim();
    if (page != null) q['page'] = '$page';
    if (pageSize != null) q['pageSize'] = '$pageSize';
    return q;
  }

  Uri _uri(String endpoint, Map<String, String> query) => Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(queryParameters: query.isEmpty ? null : query);

  Future<Map<String, dynamic>> _getJsonUri(Uri uri) async => _decode(await http.get(uri));

  PagedData<T> _paged<T>(Map<String, dynamic> data, T Function(Map<String, dynamic>) fromJson) => PagedData<T>(
    items: ((data['items'] as List?) ?? const []).whereType<Map>().map((e) => fromJson(e.cast<String, dynamic>())).toList(),
    page: (data['page'] as num?)?.toInt() ?? 1,
    pageSize: (data['pageSize'] as num?)?.toInt() ?? 25,
    totalItems: (data['totalItems'] as num?)?.toInt() ?? 0,
    totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
  );

  Future<Map<String, dynamic>> _getJson(String endpoint) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint'));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _sendJson(String method, String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final encoded = jsonEncode(body);
    final headers = {'Content-Type': 'application/json'};
    final response = switch (method) {
      'POST' => await http.post(uri, headers: headers, body: encoded),
      'PUT' => await http.put(uri, headers: headers, body: encoded),
      'PATCH' => await http.patch(uri, headers: headers, body: encoded),
      _ => throw const AdminApiException('Metodo HTTP no soportado.'),
    };
    return _decode(response);
  }

  String _friendlyHttpError(int statusCode) {
    return switch (statusCode) {
      400 => 'La solicitud contiene datos no validos. Revise la informacion ingresada.',
      401 => 'Su sesion no es valida. Vuelva a iniciar sesion.',
      403 => 'No tiene permisos para realizar esta operacion.',
      404 => 'No se encontro la informacion solicitada.',
      409 => 'La operacion no pudo completarse porque existe un conflicto con los datos actuales.',
      >= 500 => 'No se pudo completar la operacion en el servidor. Intente nuevamente o contacte al area de Informatica.',
      _ => 'No se pudo completar la operacion. Intente nuevamente.',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.trim();
    Map<String, dynamic> data = {};

    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } on FormatException {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          // Nunca mostrar stack traces o detalles internos de ASP.NET al personal.
          throw AdminApiException(_friendlyHttpError(response.statusCode));
        }
        throw const AdminApiException('No se pudo interpretar la respuesta del servidor. Intente nuevamente.');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminApiException(
        (data['mensaje'] as String?) ??
            (data['message'] as String?) ??
            'Error ${response.statusCode} al comunicarse con la API.',
      );
    }
    return data;
  }
}
