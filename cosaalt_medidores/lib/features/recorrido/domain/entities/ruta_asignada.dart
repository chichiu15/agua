class DetalleRutaAsignada {
  const DetalleRutaAsignada({
    required this.id,
    required this.solicitudId,
    required this.tipoOrigen,
    required this.ordenVisita,
    required this.estado,
    required this.nombreCliente,
    required this.direccion,
    this.latitud,
    this.longitud,
    required this.esUrgente,
    this.registroSocio,
    this.numeroMedidor,
  });

  final int id;
  final String solicitudId;
  final String tipoOrigen;
  final int ordenVisita;
  final String estado;
  final String nombreCliente;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final bool esUrgente;
  final int? registroSocio;
  final String? numeroMedidor;

  bool get completada => estado.toLowerCase() == 'completada';

  factory DetalleRutaAsignada.fromJson(Map<String, dynamic> json) {
    return DetalleRutaAsignada(
      id: json['id'] as int,
      solicitudId: json['solicitudId'] as String,
      tipoOrigen: json['tipoOrigen'] as String,
      ordenVisita: json['ordenVisita'] as int,
      estado: json['estado'] as String,
      nombreCliente: json['nombreCliente'] as String,
      direccion: json['direccion'] as String,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      esUrgente: json['esUrgente'] as bool? ?? false,
      registroSocio: json['registroSocio'] as int?,
      numeroMedidor: json['numeroMedidor'] as String?,
    );
  }
}

class RutaAsignada {
  const RutaAsignada({
    required this.idAsignacion,
    required this.idUsuarioTecnico,
    required this.nombreTecnico,
    required this.fechaAsignacion,
    required this.estado,
    required this.totalParadas,
    required this.detalles,
  });

  final int idAsignacion;
  final int idUsuarioTecnico;
  final String nombreTecnico;
  final DateTime fechaAsignacion;
  final String estado;
  final int totalParadas;
  final List<DetalleRutaAsignada> detalles;

  int get completadas => detalles.where((d) => d.completada).length;
  int get pendientes => totalParadas - completadas;
  double get progreso => totalParadas == 0 ? 0 : completadas / totalParadas;

  factory RutaAsignada.fromJson(Map<String, dynamic> json) {
    return RutaAsignada(
      idAsignacion: json['idAsignacion'] as int,
      idUsuarioTecnico: json['idUsuarioTecnico'] as int,
      nombreTecnico: json['nombreTecnico'] as String,
      fechaAsignacion: DateTime.parse(json['fechaAsignacion'] as String),
      estado: json['estado'] as String,
      totalParadas: json['totalParadas'] as int,
      detalles:
          (json['detalles'] as List? ?? const [])
              .map(
                (d) => DetalleRutaAsignada.fromJson(d as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.ordenVisita.compareTo(b.ordenVisita)),
    );
  }
}

class RutasTecnicoResponse {
  const RutasTecnicoResponse({required this.rutas});
  final List<RutaAsignada> rutas;

  factory RutasTecnicoResponse.fromJson(Map<String, dynamic> json) {
    return RutasTecnicoResponse(
      rutas: (json['rutas'] as List? ?? const [])
          .map((r) => RutaAsignada.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
