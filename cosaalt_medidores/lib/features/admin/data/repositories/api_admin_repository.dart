import 'dart:convert';
import 'package:http/http.dart' as http;

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
    final data = await _getJson(ApiConfig.motivosEndpoint);
    return ((data['motivos'] as List?) ?? const [])
        .map((e) => MotivoCatalogo.fromJson(e as Map<String, dynamic>))
        .toList();
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
          throw AdminApiException(
            body.length > 500 ? '${body.substring(0, 500)}...' : body,
          );
        }
        throw const AdminApiException('La API devolvio una respuesta no valida.');
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
