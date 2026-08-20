import 'package:latlong2/latlong.dart';

enum TipoSolicitud { odeco, lectura, vencido }

class PuntoRecorrido {
  const PuntoRecorrido({
    required this.id,
    required this.direccion,
    required this.propietario,
    required this.numeroMedidor,
    required this.ubicacion,
    required this.tipo,
  });

  final int id;
  final String direccion;
  final String propietario;
  final String numeroMedidor;
  final LatLng ubicacion;
  final TipoSolicitud tipo;
}
