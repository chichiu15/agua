class EvidenciaHistorial {
  const EvidenciaHistorial({required this.tipoFoto, required this.rutaArchivo});

  final String tipoFoto;
  final String rutaArchivo;

  factory EvidenciaHistorial.fromJson(Map<String, dynamic> json) =>
      EvidenciaHistorial(
        tipoFoto: json['tipoFoto'] as String? ?? '',
        rutaArchivo: json['rutaArchivo'] as String? ?? '',
      );
}

class EjecucionHistorial {
  const EjecucionHistorial({
    required this.idEjecucion,
    required this.tipoOrigen,
    required this.idOrigen,
    required this.solicitudId,
    required this.fechaHoraEjecucion,
    required this.codCon,
    required this.nombreCliente,
    required this.direccion,
    required this.numeroMedidorRetirado,
    required this.marcaRetirado,
    required this.lecturaRetiro,
    required this.numeroMedidorInstalado,
    required this.marcaInstalado,
    required this.observaciones,
    required this.nombreTecnico,
    required this.motivoDescripcion,
    required this.evidencias,
  });

  final int idEjecucion;
  final String tipoOrigen;
  final String idOrigen;
  final String solicitudId;
  final DateTime fechaHoraEjecucion;
  final int? codCon;
  final String? nombreCliente;
  final String? direccion;
  final String numeroMedidorRetirado;
  final String? marcaRetirado;
  final double lecturaRetiro;
  final String numeroMedidorInstalado;
  final String? marcaInstalado;
  final String? observaciones;
  final String? nombreTecnico;
  final String? motivoDescripcion;
  final List<EvidenciaHistorial> evidencias;

  factory EjecucionHistorial.fromJson(Map<String, dynamic> json) =>
      EjecucionHistorial(
        idEjecucion: json['idEjecucion'] as int,
        tipoOrigen: json['tipoOrigen'] as String? ?? '',
        idOrigen: json['idOrigen'] as String? ?? '',
        solicitudId: json['solicitudId'] as String? ?? '',
        fechaHoraEjecucion: DateTime.parse(
          json['fechaHoraEjecucion'] as String,
        ),
        codCon: json['codCon'] as int?,
        nombreCliente: json['nombreCliente'] as String?,
        direccion: json['direccion'] as String?,
        numeroMedidorRetirado: json['numeroMedidorRetirado'] as String? ?? '',
        marcaRetirado: json['marcaRetirado'] as String?,
        lecturaRetiro: (json['lecturaRetiro'] as num?)?.toDouble() ?? 0,
        numeroMedidorInstalado: json['numeroMedidorInstalado'] as String? ?? '',
        marcaInstalado: json['marcaInstalado'] as String?,
        observaciones: json['observaciones'] as String?,
        nombreTecnico: json['nombreTecnico'] as String?,
        motivoDescripcion: json['motivoDescripcion'] as String?,
        evidencias: (json['evidencias'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(EvidenciaHistorial.fromJson)
            .toList(),
      );
}
