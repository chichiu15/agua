import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/storage/local_cache_database.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../../recorrido/domain/entities/solicitud.dart';
import '../../domain/entities/cambio_medidor.dart';
import '../../domain/repositories/ejecucion_repository.dart';

class EjecucionRepositoryImpl implements EjecucionRepository {
  EjecucionRepositoryImpl({ApiAuthRepository? authRepository})
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
  Future<Solicitud> obtenerSolicitud(String solicitudId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.solicitudesEndpoint}/$solicitudId',
    );
    final key = 'solicitud_$solicitudId';

    try {
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw EjecucionException(
          _mensajeError(response, 'No se pudo cargar la solicitud.'),
        );
      }
      await _cache.writeJson(key, response.body);
      return Solicitud.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final cached = await _cache.readJson(key);
      if (cached != null) {
        return Solicitud.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
      if (e is EjecucionException) rethrow;
      throw const EjecucionException(
        'Sin conexión y esta solicitud no fue descargada previamente.',
      );
    }
  }

  @override
  Future<List<MotivoCambio>> obtenerMotivos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.motivosEndpoint}');
    const key = 'catalogo_motivos';
    try {
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw EjecucionException(
          _mensajeError(response, 'No se pudo cargar el catálogo de motivos.'),
        );
      }
      await _cache.writeJson(key, response.body);
      return _parseMotivos(response.body);
    } catch (e) {
      final cached = await _cache.readJson(key);
      if (cached != null) return _parseMotivos(cached);
      if (e is EjecucionException) rethrow;
      throw const EjecucionException(
        'No hay conexión y todavía no existe un catálogo de motivos descargado.',
      );
    }
  }

  @override
  Future<List<MedidorDisponible>> obtenerMedidoresDisponibles({String? buscar}) async {
    final query = <String, String>{'limite': '50'};
    if (buscar != null && buscar.trim().isNotEmpty) query['buscar'] = buscar.trim();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.medidoresDisponiblesEndpoint}',
    ).replace(queryParameters: query);
    final key = (buscar == null || buscar.trim().isEmpty)
        ? 'medidores_disponibles_recientes'
        : 'medidores_disponibles_busqueda_${buscar.trim().toLowerCase()}';

    try {
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw EjecucionException(
          _mensajeError(response, 'No se pudieron consultar medidores disponibles.'),
        );
      }
      await _cache.writeJson(key, response.body);
      if (buscar == null || buscar.trim().isEmpty) {
        await _cache.writeJson('medidores_disponibles_recientes', response.body);
      }
      return _filtrarYOrdenarMedidores(_parseMedidores(response.body), buscar);
    } catch (e) {
      final cached = await _cache.readJson(key) ??
          await _cache.readJson('medidores_disponibles_recientes');
      if (cached != null) {
        return _filtrarYOrdenarMedidores(_parseMedidores(cached), buscar);
      }
      if (e is EjecucionException) rethrow;
      throw const EjecucionException(
        'Sin conexión y todavía no se descargó una lista de medidores disponibles.',
      );
    }
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

  List<MotivoCambio> _parseMotivos(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    return (data['motivos'] as List? ?? const [])
        .map((m) => MotivoCambio.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  List<MedidorDisponible> _parseMedidores(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    return (data['medidores'] as List? ?? const [])
        .map((m) => MedidorDisponible.fromJson(m as Map<String, dynamic>))
        .where((m) => m.disponibilidad.toUpperCase() == 'L')
        .toList();
  }

  List<MedidorDisponible> _filtrarYOrdenarMedidores(
    List<MedidorDisponible> items,
    String? buscar,
  ) {
    final criterio = buscar?.trim().toLowerCase() ?? '';
    final filtrados = items.where((m) {
      if (criterio.isEmpty) return true;
      return m.serie.toLowerCase().contains(criterio) ||
          m.marca.toLowerCase().contains(criterio) ||
          m.codMedidor.toString().contains(criterio);
    }).toList();
    filtrados.sort((a, b) {
      final serie = a.serie.toLowerCase().compareTo(b.serie.toLowerCase());
      if (serie != 0) return serie;
      final marca = a.marca.toLowerCase().compareTo(b.marca.toLowerCase());
      return marca != 0 ? marca : a.codMedidor.compareTo(b.codMedidor);
    });
    return filtrados;
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
