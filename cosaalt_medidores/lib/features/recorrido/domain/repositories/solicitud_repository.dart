import '../entities/ruta_asignada.dart';
import '../entities/solicitud.dart';
import '../entities/tecnico.dart';

class SolicitudException implements Exception {
  const SolicitudException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AsignarRutaParams {
  const AsignarRutaParams({
    required this.idUsuarioAsignador,
    required this.idUsuarioTecnico,
    required this.solicitudes,
  });

  final int idUsuarioAsignador;
  final int idUsuarioTecnico;
  final List<Solicitud> solicitudes;
}

abstract interface class SolicitudRepository {
  Future<SolicitudesResponse> obtenerSolicitudes({String? filtro});
  Future<List<Tecnico>> obtenerTecnicos();
  Future<void> asignarRuta(AsignarRutaParams params);
  Future<List<RutaAsignada>> obtenerRutasTecnico(
    int idTecnico, {
    DateTime? fecha,
  });
  Future<RutaAsignada?> obtenerRutaActualTecnico(
    int idTecnico, {
    bool soloCache = false,
  });
  Future<List<RutaAsignada>> obtenerRutasActivas({DateTime? fecha});
  Future<RutaAsignada> obtenerRutaPorId(int idAsignacion);
}
