import '../../../recorrido/domain/entities/solicitud.dart';
import '../entities/cambio_medidor.dart';

class EjecucionException implements Exception {
  const EjecucionException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class EjecucionRepository {
  Future<Solicitud> obtenerSolicitud(String solicitudId);
  Future<List<MotivoCambio>> obtenerMotivos();
  Future<List<MedidorDisponible>> obtenerMedidoresDisponibles({String? buscar});
  Future<String> guardarLocal(CambioMedidorDraft draft);
}
