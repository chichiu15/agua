abstract final class ApiConfig {
  static const String baseUrl = 'http://localhost:5034';

  static const String loginEndpoint = '/api/auth/login';
  static const String solicitudesEndpoint = '/api/solicitudes';
  static const String tecnicosEndpoint = '/api/usuarios/tecnicos';
  static const String rutasEndpoint = '/api/rutas';
  static const String motivosEndpoint = '/api/catalogos/motivos';
  static const String ejecucionesEndpoint = '/api/ejecuciones';
  static const String historialEndpoint = '/api/ejecuciones/historial';
  static const String evidenciasEndpoint = '/api/evidencias';
  static const String sincronizacionEndpoint = '/api/sincronizacion/procesar-cambios';
}
