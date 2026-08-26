class MotivoCambio {
  const MotivoCambio({required this.id, required this.descripcion});

  final int id;
  final String descripcion;

  factory MotivoCambio.fromJson(Map<String, dynamic> json) => MotivoCambio(
        id: json['id'] as int,
        descripcion: json['descripcion'] as String,
      );
}

class CambioMedidorDraft {
  const CambioMedidorDraft({
    required this.localId,
    required this.solicitudId,
    required this.tipoOrigen,
    required this.idOrigen,
    required this.idUsuarioApp,
    required this.fechaHoraEjecucion,
    required this.registroSocio,
    required this.nombreSocio,
    required this.direccion,
    required this.numeroMedidorRetirado,
    required this.marcaRetirado,
    required this.lecturaRetiro,
    required this.idMotivo,
    required this.numeroMedidorInstalado,
    required this.marcaInstalado,
    required this.estadoMedidorInstalado,
    required this.observaciones,
    required this.fotoMedidorRetirado,
    required this.fotoMedidorNuevo,
    this.latitud,
    this.longitud,
  });

  final String localId;
  final String solicitudId;
  final String tipoOrigen;
  final String idOrigen;
  final int idUsuarioApp;
  final DateTime fechaHoraEjecucion;
  final int registroSocio;
  final String nombreSocio;
  final String direccion;
  final String numeroMedidorRetirado;
  final String? marcaRetirado;
  final double lecturaRetiro;
  final int idMotivo;
  final String numeroMedidorInstalado;
  final String marcaInstalado;
  final String estadoMedidorInstalado;
  final String? observaciones;
  final String fotoMedidorRetirado;
  final String fotoMedidorNuevo;
  final double? latitud;
  final double? longitud;

  String get observacionesApi {
    final detalle = observaciones?.trim();
    if (detalle == null || detalle.isEmpty) {
      return 'Estado: $estadoMedidorInstalado';
    }
    return 'Estado: $estadoMedidorInstalado. $detalle';
  }

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'solicitudId': solicitudId,
        'tipoOrigen': tipoOrigen,
        'idOrigen': idOrigen,
        'idUsuarioApp': idUsuarioApp,
        'fechaHoraEjecucion': fechaHoraEjecucion.toIso8601String(),
        'registroSocio': registroSocio,
        'nombreSocio': nombreSocio,
        'direccion': direccion,
        'numeroMedidorRetirado': numeroMedidorRetirado,
        'marcaRetirado': marcaRetirado,
        'lecturaRetiro': lecturaRetiro,
        'idMotivo': idMotivo,
        'numeroMedidorInstalado': numeroMedidorInstalado,
        'marcaInstalado': marcaInstalado,
        'estadoMedidorInstalado': estadoMedidorInstalado,
        'observaciones': observaciones,
        'observacionesApi': observacionesApi,
        'fotoMedidorRetirado': fotoMedidorRetirado,
        'fotoMedidorNuevo': fotoMedidorNuevo,
        'latitud': latitud,
        'longitud': longitud,
        'sincronizado': false,
      };
}
