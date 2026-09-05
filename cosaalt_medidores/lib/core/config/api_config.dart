import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Windows: localhost.
  /// Emulador Android: 10.0.2.2 apunta al localhost de la PC.
  /// Celular fisico por USB (recomendado):
  /// adb -s ID reverse tcp:5034 tcp:5034
  /// flutter run -d ID --dart-define=API_BASE_URL=http://127.0.0.1:5034
  /// Alternativa por Wi-Fi: usar la IP LAN de la PC.
  static String get baseUrl {
    if (_definedBaseUrl.trim().isNotEmpty) {
      return _definedBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    }
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5034';
    return 'http://localhost:5034';
  }

  static const String loginEndpoint = '/api/auth/login';
  static const String solicitudesEndpoint = '/api/solicitudes';
  static const String usuariosEndpoint = '/api/usuarios';
  static const String tecnicosEndpoint = '/api/usuarios/tecnicos';
  static const String rutasEndpoint = '/api/rutas';
  static const String motivosEndpoint = '/api/catalogos/motivos';
  static const String marcasEndpoint = '/api/catalogos/marcas';
  static const String medidoresDisponiblesEndpoint = '/api/catalogos/medidores-disponibles';
  static const String parametrosNormativosEndpoint = '/api/parametros-normativos';
  static const String ejecucionesEndpoint = '/api/ejecuciones';
  static const String historialEndpoint = '/api/ejecuciones/historial';
  static const String evidenciasEndpoint = '/api/evidencias';
  static const String sincronizacionEndpoint = '/api/sincronizacion/procesar-cambios';

  static const String adminDashboardEndpoint = '/api/admin/dashboard';
  static const String adminSolicitudesEndpoint = '/api/admin/solicitudes';
  static const String adminRutasEndpoint = '/api/admin/rutas';
  static const String adminSincronizacionEndpoint = '/api/admin/sincronizacion';
  static const String adminVerificacionesEndpoint = '/api/admin/verificaciones';
  static const String reportesMovimientosEndpoint = '/api/reportes/movimientos';
  static const String reportesHistoricoCorporativoEndpoint = '/api/reportes/historico-corporativo';
  static const String reportesVerificacionesEndpoint = '/api/reportes/verificaciones';
  static const String reportesEstadisticasEndpoint = '/api/reportes/estadisticas';
}
