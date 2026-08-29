enum TipoSolicitud { odeco, lectura }

class Solicitud {
  const Solicitud({
    required this.id,
    required this.tipoOrigen,
    required this.estado,
    required this.esUrgente,
    required this.esVencida,
    required this.codCon,
    required this.nombreCliente,
    required this.direccion,
    this.categoria,
    this.ruta,
    this.recorrido,
    this.numeroMedidor,
    this.marcaMedidor,
    this.lecturaAnterior,
    this.lecturaActual,
    this.consumo,
    this.motivoObservacion,
    required this.fechaSolicitud,
    this.folioOdeco,
    this.conclusionOdeco,
    this.latitud,
    this.longitud,
  });

  final String id;
  final String tipoOrigen;
  final String estado;
  final bool esUrgente;
  final bool esVencida;
  final int codCon;
  final String nombreCliente;
  final String direccion;
  final String? categoria;
  final String? ruta;
  final int? recorrido;
  final String? numeroMedidor;
  final String? marcaMedidor;
  final double? lecturaAnterior;
  final double? lecturaActual;
  final double? consumo;
  final String? motivoObservacion;
  final DateTime fechaSolicitud;
  final int? folioOdeco;
  final String? conclusionOdeco;
  final double? latitud;
  final double? longitud;

  TipoSolicitud get tipo => tipoOrigen.toUpperCase() == 'ODECO'
      ? TipoSolicitud.odeco
      : TipoSolicitud.lectura;

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: json['id'] as String,
      tipoOrigen: json['tipoOrigen'] as String,
      estado: json['estado'] as String,
      esUrgente: json['esUrgente'] as bool? ?? false,
      esVencida: json['esVencida'] as bool? ?? false,
      codCon: json['codCon'] as int,
      nombreCliente: json['nombreCliente'] as String,
      direccion: json['direccion'] as String,
      categoria: json['categoria'] as String?,
      ruta: json['ruta'] as String?,
      recorrido: json['recorrido'] as int?,
      numeroMedidor: json['numeroMedidor'] as String?,
      marcaMedidor: json['marcaMedidor'] as String?,
      lecturaAnterior: (json['lecturaAnterior'] as num?)?.toDouble(),
      lecturaActual: (json['lecturaActual'] as num?)?.toDouble(),
      consumo: (json['consumo'] as num?)?.toDouble(),
      motivoObservacion: json['motivoObservacion'] as String?,
      fechaSolicitud: DateTime.parse(json['fechaSolicitud'] as String),
      folioOdeco: json['folioOdeco'] as int?,
      conclusionOdeco: json['conclusionOdeco'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
    );
  }
}

class DashboardResumen {
  const DashboardResumen({
    required this.odecoUrgentes,
    required this.lecturasDelMes,
    required this.completadasHoy,
  });

  final int odecoUrgentes;
  final int lecturasDelMes;
  final int completadasHoy;

  factory DashboardResumen.fromJson(Map<String, dynamic> json) {
    return DashboardResumen(
      odecoUrgentes: json['odecoUrgentes'] as int,
      lecturasDelMes: json['lecturasDelMes'] as int,
      completadasHoy: json['completadasHoy'] as int,
    );
  }
}

class SolicitudesResponse {
  const SolicitudesResponse({required this.resumen, required this.solicitudes});

  final DashboardResumen resumen;
  final List<Solicitud> solicitudes;

  factory SolicitudesResponse.fromJson(Map<String, dynamic> json) {
    return SolicitudesResponse(
      resumen: DashboardResumen.fromJson(
        json['resumen'] as Map<String, dynamic>,
      ),
      solicitudes: (json['solicitudes'] as List)
          .map((s) => Solicitud.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
