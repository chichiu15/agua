import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/storage/local_cache_database.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../domain/entities/ruta_asignada.dart';
import '../../domain/entities/solicitud.dart';
import '../../domain/entities/tecnico.dart';
import '../../domain/repositories/solicitud_repository.dart';

class ApiSolicitudRepository implements SolicitudRepository {
  ApiSolicitudRepository({ApiAuthRepository? authRepository})
    : _authRepository = authRepository ?? ApiAuthRepository();

  final ApiAuthRepository _authRepository;
  final LocalCacheDatabase _cache = LocalCacheDatabase.instance;

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

    try {
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw SolicitudException(
          _leerMensajeError(response, fallback: 'Error al obtener solicitudes.'),
        );
      }
      await _cache.writeJson('solicitudes_bandeja', response.body);
      return SolicitudesResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final cached = await _cache.readJson('solicitudes_bandeja');
      if (cached != null) {
        return SolicitudesResponse.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      }
      if (e is SolicitudException) rethrow;
      throw SolicitudException(
        'No hay conexión con la API y todavía no existe una bandeja descargada en el dispositivo.',
      );
    }
  }

  @override
  Future<List<Tecnico>> obtenerTecnicos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tecnicosEndpoint}');

    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 25));
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
          'idOrigen': s.folioOdeco?.toString() ?? _normalizarIdOrigen(s),
          'solicitudId': s.id,
          'ordenVisita': index + 1,
          'latitud': s.latitud,
          'longitud': s.longitud,
          'nombreCliente': s.nombreCliente,
          'direccion': s.direccion,
        };
      }).toList(),
    };

    final response = await http
        .post(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 35));

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
    final cacheKey = fecha == null
        ? 'rutas_tecnico_$idTecnico'
        : 'rutas_tecnico_${idTecnico}_${query['fecha']}';

    try {
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw SolicitudException(
          _leerMensajeError(
            response,
            fallback: 'Error al obtener las rutas del técnico.',
          ),
        );
      }

      await _cache.writeJson(cacheKey, response.body);
      final parsed = RutasTecnicoResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Descargamos el detalle completo de cada solicitud para que el técnico
      // pueda abrir el formulario de cambio aun cuando se quede sin Internet.
      await _prefetchSolicitudes(parsed.rutas);
      await _prefetchCatalogosCampo();
      return parsed.rutas;
    } catch (e) {
      final cached = await _cache.readJson(cacheKey) ??
          (fecha == null ? null : await _cache.readJson('rutas_tecnico_$idTecnico'));
      if (cached != null) {
        return RutasTecnicoResponse.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        ).rutas;
      }
      if (e is SolicitudException) rethrow;
      throw SolicitudException(
        'No hay conexión y todavía no se descargó una ruta para este técnico.',
      );
    }
  }

  @override
  Future<RutaAsignada?> obtenerRutaActualTecnico(
    int idTecnico, {
    bool soloCache = false,
  }) async {
    final cacheKey = 'ruta_actual_tecnico_$idTecnico';

    if (soloCache) {
      final cached = await _cache.readJson(cacheKey);
      if (cached == null) return null;
      return RutaAsignada.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.rutasEndpoint}/tecnico/$idTecnico/actual',
    );
    try {
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw SolicitudException(
          _leerMensajeError(response, fallback: 'Error al obtener la ruta actual.'),
        );
      }
      await _cache.writeJson(cacheKey, response.body);
      final ruta = RutaAsignada.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      await _cache.writeJson('ruta_${ruta.idAsignacion}', response.body);
      await _prefetchSolicitudes([ruta]);
      await _prefetchCatalogosCampo();
      return ruta;
    } catch (e) {
      final cached = await _cache.readJson(cacheKey);
      if (cached != null) {
        return RutaAsignada.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
      if (e is SolicitudException) rethrow;
      throw const SolicitudException(
        'No hay conexion y todavia no existe una ruta descargada para este tecnico.',
      );
    }
  }

  @override
  Future<List<RutaAsignada>> obtenerRutasActivas({DateTime? fecha}) async {
    final query = <String, String>{};
    if (fecha != null) {
      query['fecha'] =
          '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.rutasEndpoint}/activas',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw SolicitudException(
        _leerMensajeError(response, fallback: 'Error al obtener rutas activas.'),
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
    final cacheKey = 'ruta_$idAsignacion';

    try {
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw SolicitudException(
          _leerMensajeError(
            response,
            fallback: 'Error al obtener el detalle de la ruta.',
          ),
        );
      }
      await _cache.writeJson(cacheKey, response.body);
      final ruta = RutaAsignada.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      await _prefetchSolicitudes([ruta]);
      await _prefetchCatalogosCampo();
      return ruta;
    } catch (e) {
      final cached = await _cache.readJson(cacheKey);
      if (cached != null) {
        return RutaAsignada.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      }
      if (e is SolicitudException) rethrow;
      throw SolicitudException('No se pudo consultar la ruta y no existe copia local.');
    }
  }

  Future<void> _prefetchSolicitudes(List<RutaAsignada> rutas) async {
    for (final detalle in rutas.expand((r) => r.detalles)) {
      try {
        final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.solicitudesEndpoint}/${detalle.solicitudId}',
        );
        final response = await http
            .get(uri, headers: await _headers())
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) {
          await _cache.writeJson('solicitud_${detalle.solicitudId}', response.body);
        }
      } catch (_) {
        // La descarga de la ruta no debe fallar por un detalle auxiliar.
      }
    }
  }


  Future<void> _prefetchCatalogosCampo() async {
    try {
      final motivos = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.motivosEndpoint}'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 12));
      if (motivos.statusCode == 200) {
        await _cache.writeJson('catalogo_motivos', motivos.body);
      }
    } catch (_) {}

    try {
      final medidores = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.medidoresDisponiblesEndpoint}?limite=50'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));
      if (medidores.statusCode == 200) {
        await _cache.writeJson('medidores_disponibles_recientes', medidores.body);
      }
    } catch (_) {}
  }

  String _normalizarIdOrigen(Solicitud s) {
    if (s.id.startsWith('ODECO-')) return s.id.substring(6);
    if (s.id.startsWith('LEC-')) return s.id.substring(4);
    return s.id;
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
