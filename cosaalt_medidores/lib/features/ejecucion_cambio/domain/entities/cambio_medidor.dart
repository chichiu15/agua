class MotivoCambio {
  const MotivoCambio({required this.id, required this.descripcion});

  final int id;
  final String descripcion;

  factory MotivoCambio.fromJson(Map<String, dynamic> json) => MotivoCambio(
    id: (json['id'] as num).toInt(),
    descripcion: (json['descripcion'] as String? ?? '').trim(),
  );
}

class MedidorDisponible {
  const MedidorDisponible({
    required this.codMedidor,
    required this.serie,
    required this.marca,
    this.tipo,
    this.capacidad,
    this.diametro,
    this.codigoEstado,
    this.estado,
    required this.disponibilidad,
  });

  final int codMedidor;
  final String serie;
  final String marca;
  final String? tipo;
  final String? capacidad;
  final String? diametro;
  final int? codigoEstado;
  final String? estado;
  final String disponibilidad;

  String get etiqueta => '$serie · $marca · Cód. $codMedidor';

  bool get estaLibre => disponibilidad.trim().toUpperCase() == 'L';
  bool get estaPerfecto => codigoEstado == 5 || estado?.trim().toUpperCase() == 'PERFECTO';

  factory MedidorDisponible.fromJson(Map<String, dynamic> json) => MedidorDisponible(
    codMedidor: (json['codMedidor'] as num).toInt(),
    serie: (json['serie'] as String? ?? '').trim(),
    marca: (json['marca'] as String? ?? '').trim(),
    tipo: (json['tipo'] as String?)?.trim(),
    capacidad: (json['capacidad'] as String?)?.trim(),
    diametro: (json['diametro'] as String?)?.trim(),
    codigoEstado: (json['codigoEstado'] as num?)?.toInt(),
    estado: (json['estado'] as String?)?.trim(),
    disponibilidad: (json['disponibilidad'] as String? ?? '').trim(),
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
    required this.codCon,
    required this.nombreSocio,
    required this.direccion,
    required this.numeroMedidorRetirado,
    required this.marcaRetirado,
    required this.lecturaRetiro,
    required this.idMotivo,
    required this.codMedidorInstalado,
    required this.numeroMedidorInstalado,
    required this.marcaInstalado,
    required this.observaciones,
    this.fotoMedidorRetirado,
    this.fotoMedidorNuevo,
    this.latitud,
    this.longitud,
  });

  final String localId;
  final String solicitudId;
  final String tipoOrigen;
  final String idOrigen;
  final int idUsuarioApp;
  final DateTime fechaHoraEjecucion;
  final int codCon;
  final String nombreSocio;
  final String direccion;
  final String numeroMedidorRetirado;
  final String? marcaRetirado;
  final double lecturaRetiro;
  final int idMotivo;

  /// Código institucional de dbo.Medidor. Es nullable únicamente para poder
  /// leer archivos locales antiguos creados antes de incorporar este campo.
  final int? codMedidorInstalado;
  final String numeroMedidorInstalado;
  final String marcaInstalado;
  final String? observaciones;
  final String? fotoMedidorRetirado;
  final String? fotoMedidorNuevo;
  final double? latitud;
  final double? longitud;

  String? get observacionesApi {
    final detalle = observaciones?.trim();
    return (detalle == null || detalle.isEmpty) ? null : detalle;
  }

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'solicitudId': solicitudId,
    'tipoOrigen': tipoOrigen,
    'idOrigen': idOrigen,
    'idUsuarioApp': idUsuarioApp,
    'fechaHoraEjecucion': fechaHoraEjecucion.toIso8601String(),
    'codCon': codCon,
    'nombreSocio': nombreSocio,
    'direccion': direccion,
    'numeroMedidorRetirado': numeroMedidorRetirado,
    'marcaRetirado': marcaRetirado,
    'lecturaRetiro': lecturaRetiro,
    'idMotivo': idMotivo,
    'codMedidorInstalado': codMedidorInstalado,
    'numeroMedidorInstalado': numeroMedidorInstalado,
    'marcaInstalado': marcaInstalado,
    'observaciones': observaciones,
    'fotoMedidorRetirado': fotoMedidorRetirado,
    'fotoMedidorNuevo': fotoMedidorNuevo,
    'latitud': latitud,
    'longitud': longitud,
    'sincronizado': false,
  };
}
