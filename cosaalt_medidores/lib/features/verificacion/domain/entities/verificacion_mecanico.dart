import 'package:flutter/foundation.dart';

@immutable
class MecanicoDashboard {
  const MecanicoDashboard({
    required this.pendientes,
    required this.enCurso,
    required this.completadas,
    required this.cumple,
    required this.noCumple,
    required this.indeterminados,
    required this.total,
  });

  final int pendientes;
  final int enCurso;
  final int completadas;
  final int cumple;
  final int noCumple;
  final int indeterminados;
  final int total;

  factory MecanicoDashboard.fromJson(Map<String, dynamic> json) =>
      MecanicoDashboard(
        pendientes: _i(json['pendientes']),
        enCurso: _i(json['enCurso']),
        completadas: _i(json['completadas']),
        cumple: _i(json['cumple']),
        noCumple: _i(json['noCumple']),
        indeterminados: _i(json['indeterminados']),
        total: _i(json['total']),
      );
}

@immutable
class SolicitudVerificacion {
  const SolicitudVerificacion({
    required this.id,
    required this.tipoOrigen,
    required this.codCon,
    required this.nombreCliente,
    required this.direccion,
    this.categoria,
    this.numeroMedidor,
    this.marcaMedidor,
    this.motivoObservacion,
    required this.fechaSolicitud,
    required this.estado,
    required this.tomada,
  });

  final String id;
  final String tipoOrigen;
  final int codCon;
  final String nombreCliente;
  final String direccion;
  final String? categoria;
  final String? numeroMedidor;
  final String? marcaMedidor;
  final String? motivoObservacion;
  final DateTime fechaSolicitud;
  final String estado;
  final bool tomada;

  factory SolicitudVerificacion.fromJson(Map<String, dynamic> json) =>
      SolicitudVerificacion(
        id: _s(json['id']),
        tipoOrigen: _s(json['tipoOrigen']),
        codCon: _i(json['codCon']),
        nombreCliente: _s(json['nombreCliente']),
        direccion: _s(json['direccion']),
        categoria: _ns(json['categoria']),
        numeroMedidor: _ns(json['numeroMedidor']),
        marcaMedidor: _ns(json['marcaMedidor']),
        motivoObservacion: _ns(json['motivoObservacion']),
        fechaSolicitud: _dt(json['fechaSolicitud']),
        estado: _s(json['estado']),
        tomada: _b(json['tomada']),
      );
}

@immutable
class ParticipanteVerificacion {
  const ParticipanteVerificacion({
    this.id,
    required this.nombre,
    this.cargo,
    this.rol,
  });

  final int? id;
  final String nombre;
  final String? cargo;
  final String? rol;

  factory ParticipanteVerificacion.fromJson(Map<String, dynamic> json) =>
      ParticipanteVerificacion(
        id: int.tryParse('${json['id'] ?? ''}'),
        nombre: _s(json['nombre']),
        cargo: _ns(json['cargo']),
        rol: _ns(json['rol']),
      );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    if (cargo != null && cargo!.isNotEmpty) 'cargo': cargo,
    if (rol != null && rol!.isNotEmpty) 'rol': rol,
  };
}

@immutable
class EnsayoVerificacion {
  const EnsayoVerificacion({
    this.id,
    this.condiciones,
    this.lecturaInicial,
    this.lecturaFinal,
    this.volumenPatron,
    this.caudal,
    this.volumenRegistrado,
    this.error,
    this.fugas,
    this.observaciones,
    this.tipoPrueba,
    this.instrumentoBanco,
    this.identificacionBanco,
    this.trazabilidadCalibracion,
    this.capacidadNominalQ3,
    this.tipoCaudal,
    this.unidadCaudal,
    this.unidadVolumen,
    this.tipoFuga,

    // M6/M8:
    // snapshot histórico de la regla normativa aplicada.
    this.parametroNormativoCodigoAplicado,
    this.limiteNormativoAplicado,
  });

  final int? id;
  final String? condiciones;
  final double? lecturaInicial;
  final double? lecturaFinal;
  final double? volumenPatron;
  final double? caudal;
  final double? volumenRegistrado;
  final double? error;
  final bool? fugas;
  final String? observaciones;

  final String? tipoPrueba;
  final String? instrumentoBanco;
  final String? identificacionBanco;
  final String? trazabilidadCalibracion;
  final String? capacidadNominalQ3;
  final String? tipoCaudal;
  final String? unidadCaudal;
  final String? unidadVolumen;
  final String? tipoFuga;

  // M6/M8
  final String? parametroNormativoCodigoAplicado;
  final double? limiteNormativoAplicado;

  factory EnsayoVerificacion.fromJson(Map<String, dynamic> json) =>
      EnsayoVerificacion(
        id: int.tryParse('${json['id'] ?? ''}'),
        condiciones: _ns(json['condiciones']),
        lecturaInicial: _d(json['lecturaInicial']),
        lecturaFinal: _d(json['lecturaFinal']),
        volumenPatron: _d(json['volumenPatron']),
        caudal: _d(json['caudal']),
        volumenRegistrado: _d(json['volumenRegistrado']),
        error: _d(json['error']),
        fugas: _nb(json['fugas']),
        observaciones: _ns(json['observaciones']),
        tipoPrueba: _ns(json['tipoPrueba']),
        instrumentoBanco: _ns(json['instrumentoBanco']),
        identificacionBanco: _ns(json['identificacionBanco']),
        trazabilidadCalibracion: _ns(json['trazabilidadCalibracion']),
        capacidadNominalQ3: _ns(json['capacidadNominalQ3']),
        tipoCaudal: _ns(json['tipoCaudal']),
        unidadCaudal: _ns(json['unidadCaudal']),
        unidadVolumen: _ns(json['unidadVolumen']),
        tipoFuga: _ns(json['tipoFuga']),

        parametroNormativoCodigoAplicado: _ns(
          json['parametroNormativoCodigoAplicado'],
        ),

        limiteNormativoAplicado: _d(json['limiteNormativoAplicado']),
      );
}

@immutable
class DatosSocioMedidor {
  const DatosSocioMedidor({
    required this.codCon,
    required this.nombreCliente,
    required this.direccion,
    this.categoria,
    this.numeroDocumento,
    this.tipDocumento,
    this.ruc,
    this.numeroMedidor,
    this.marcaMedidor,
    this.fechaConexion,
    this.capacidadQ3,
    this.tipoMedidor,
    this.claseMedidor,
    this.diametroMedidor,
    this.regSoc,
    this.codConexion,
    this.lugarVerificacion,
    this.tipoEnsayo,
    this.motivoObservacion,
  });

  // codCon se conserva por compatibilidad con el contrato anterior.
  // Para M3 se usan regSoc y codConexion como conceptos separados.
  final int codCon;
  final String nombreCliente;
  final String direccion;
  final String? categoria;
  final String? numeroDocumento;
  final String? tipDocumento;
  final String? ruc;
  final String? numeroMedidor;
  final String? marcaMedidor;
  final DateTime? fechaConexion;
  final String? capacidadQ3;
  final String? tipoMedidor;
  final String? claseMedidor;
  final String? diametroMedidor;
  final int? regSoc;
  final int? codConexion;
  final String? lugarVerificacion;
  final String? tipoEnsayo;
  final String? motivoObservacion;

  factory DatosSocioMedidor.fromJson(Map<String, dynamic> json) =>
      DatosSocioMedidor(
        codCon: _i(json['codCon']),
        nombreCliente: _s(json['nombreCliente']),
        direccion: _s(json['direccion']),
        categoria: _ns(json['categoria']),
        numeroDocumento: _ns(json['numeroDocumento']),
        tipDocumento: _ns(json['tipDocumento']),
        ruc: _ns(json['ruc']),
        numeroMedidor: _ns(json['numeroMedidor']),
        marcaMedidor: _ns(json['marcaMedidor']),
        fechaConexion: _dtn(json['fechaConexion']),
        capacidadQ3: _ns(json['capacidadQ3']),
        tipoMedidor: _ns(json['tipoMedidor']),
        claseMedidor: _ns(json['claseMedidor']),
        diametroMedidor: _ns(json['diametroMedidor']),
        regSoc: json['regSoc'] == null ? null : _i(json['regSoc']),
        codConexion: json['codConexion'] == null
            ? null
            : _i(json['codConexion']),
        lugarVerificacion: _ns(json['lugarVerificacion']),
        tipoEnsayo: _ns(json['tipoEnsayo']),
        motivoObservacion: _ns(json['motivoObservacion']),
      );
}

@immutable
class VerificacionMecanico {
  const VerificacionMecanico({
    required this.id,
    required this.tipoOrigen,
    required this.idOrigen,
    required this.codCon,
    required this.idUsuarioMecanico,
    this.idMedidor,
    required this.fechaVerificacion,
    required this.estado,
    this.resultado,
    this.nombreCliente,
    this.nombreMecanico,
    this.ensayo,
    this.participantes = const [],
  });

  final int id;
  final String tipoOrigen;
  final String idOrigen;
  final int codCon;
  final int idUsuarioMecanico;
  final String? idMedidor;
  final DateTime fechaVerificacion;
  final String estado;
  final String? resultado;
  final String? nombreCliente;
  final String? nombreMecanico;
  final EnsayoVerificacion? ensayo;
  final List<ParticipanteVerificacion> participantes;

  bool get finalizada => estado == 'Completada';

  factory VerificacionMecanico.fromJson(Map<String, dynamic> json) =>
      VerificacionMecanico(
        id: _i(json['id']),
        tipoOrigen: _s(json['tipoOrigen']),
        idOrigen: _s(json['idOrigen']),
        codCon: _i(json['codCon']),
        idUsuarioMecanico: _i(json['idUsuarioMecanico']),
        idMedidor: _ns(json['idMedidor']),
        fechaVerificacion: _dt(json['fechaVerificacion']),
        estado: _s(json['estado']),
        resultado: _ns(json['resultado']),
        nombreCliente: _ns(json['nombreCliente']),
        nombreMecanico: _ns(json['nombreMecanico']),
        ensayo: json['ensayo'] is Map<String, dynamic>
            ? EnsayoVerificacion.fromJson(
                json['ensayo'] as Map<String, dynamic>,
              )
            : null,
        participantes: _list(
          json['participantes'],
          ParticipanteVerificacion.fromJson,
        ),
      );
}

@immutable
class CalculoEnsayo {
  const CalculoEnsayo({
    this.volumenRegistrado,
    this.volumenPatron,
    this.diferencia,
    this.errorConSigno,
    this.errorAbsoluto,
    this.limitePermitido,
    this.parametroNormativo,
    this.resultado,
  });

  final double? volumenRegistrado;
  final double? volumenPatron;
  final double? diferencia;
  final double? errorConSigno;
  final double? errorAbsoluto;
  final double? limitePermitido;
  final String? parametroNormativo;
  final String? resultado;

  factory CalculoEnsayo.fromJson(Map<String, dynamic> json) => CalculoEnsayo(
    volumenRegistrado: _d(json['volumenRegistrado']),
    volumenPatron: _d(json['volumenPatron']),
    diferencia: _d(json['diferencia']),
    errorConSigno: _d(json['errorConSigno']),
    errorAbsoluto: _d(json['errorAbsoluto']),
    limitePermitido: _d(json['limitePermitido']),
    parametroNormativo: _ns(json['parametroNormativo']),
    resultado: _ns(json['resultado']),
  );
}

@immutable
class EnsayoGuardadoResultado {
  const EnsayoGuardadoResultado({
    required this.idVerificacion,
    this.idEnsayo,
    this.volumenRegistrado,
    this.error,
    required this.mensaje,
    this.calculo,
  });

  final int idVerificacion;
  final int? idEnsayo;
  final double? volumenRegistrado;
  final double? error;
  final String mensaje;
  final CalculoEnsayo? calculo;

  factory EnsayoGuardadoResultado.fromJson(Map<String, dynamic> json) =>
      EnsayoGuardadoResultado(
        idVerificacion: _i(json['idVerificacion']),
        idEnsayo: int.tryParse('${json['idEnsayo'] ?? ''}'),
        volumenRegistrado: _d(json['volumenRegistrado']),
        error: _d(json['error']),
        mensaje: _s(json['mensaje']),
        calculo: json['calculo'] is Map<String, dynamic>
            ? CalculoEnsayo.fromJson(json['calculo'] as Map<String, dynamic>)
            : null,
      );
}

@immutable
class InformeVerificacion {
  const InformeVerificacion({
    required this.id,
    required this.idVerificacion,
    required this.nroInforme,
    required this.fechaEmision,
    this.rutaPdf,
    required this.firmado,
    required this.versionInforme,
    this.observaciones,
  });

  final int id;
  final int idVerificacion;
  final String nroInforme;
  final DateTime fechaEmision;
  final String? rutaPdf;
  final bool firmado;
  final int versionInforme;
  final String? observaciones;

  factory InformeVerificacion.fromJson(Map<String, dynamic> json) =>
      InformeVerificacion(
        id: _i(json['id']),
        idVerificacion: _i(json['idVerificacion']),
        nroInforme: _s(json['nroInforme']),
        fechaEmision: _dt(json['fechaEmision']),
        rutaPdf: _ns(json['rutaPdf']),
        firmado: _b(json['firmado']),
        versionInforme: _i(json['versionInforme']),
        observaciones: _ns(json['observaciones']),
      );
}

@immutable
class HistorialVerificacionItem {
  const HistorialVerificacionItem({
    required this.idVerificacion,
    required this.fecha,
    required this.estado,
    this.resultado,
    this.error,
    this.fugas,
    required this.codCon,
    required this.regSoc,
    this.codConexion,
    this.nombreCliente,
    this.numeroMedidor,
    this.marcaMedidor,
    this.idInforme,
    this.nroInforme,
    this.versionInforme,
    this.fechaEmisionInforme,
    this.informeFirmado,
    required this.estadoInforme,
    required this.tieneInforme,
  });

  final int idVerificacion;
  final DateTime fecha;
  final String estado;
  final String? resultado;
  final double? error;
  final bool? fugas;

  // Compatibilidad histórica del endpoint.
  final int codCon;

  // M9: datos separados correctamente.
  final int regSoc;
  final int? codConexion;

  final String? nombreCliente;
  final String? numeroMedidor;
  final String? marcaMedidor;

  // Última versión de informe emitida.
  final int? idInforme;
  final String? nroInforme;
  final int? versionInforme;
  final DateTime? fechaEmisionInforme;
  final bool? informeFirmado;
  final String estadoInforme;
  final bool tieneInforme;

  bool get enCurso => estado.toLowerCase() == 'encurso';
  bool get completada => estado.toLowerCase() == 'completada';

  factory HistorialVerificacionItem.fromJson(Map<String, dynamic> json) =>
      HistorialVerificacionItem(
        idVerificacion: _i(json['idVerificacion']),
        fecha: _dt(json['fecha']),
        estado: _s(json['estado']),
        resultado: _ns(json['resultado']),
        error: _d(json['error']),
        fugas: _nb(json['fugas']),
        codCon: _i(json['codCon']),
        regSoc: int.tryParse('${json['regSoc'] ?? ''}') ?? _i(json['codCon']),
        codConexion: int.tryParse('${json['codConexion'] ?? ''}'),
        nombreCliente: _ns(json['nombreCliente']),
        numeroMedidor: _ns(json['numeroMedidor']),
        marcaMedidor: _ns(json['marcaMedidor']),
        idInforme: int.tryParse('${json['idInforme'] ?? ''}'),
        nroInforme: _ns(json['nroInforme']),
        versionInforme: int.tryParse('${json['versionInforme'] ?? ''}'),
        fechaEmisionInforme: json['fechaEmisionInforme'] == null
            ? null
            : DateTime.tryParse('${json['fechaEmisionInforme']}'),
        informeFirmado: _nb(json['informeFirmado']),
        estadoInforme:
            _ns(json['estadoInforme']) ??
            (_b(json['tieneInforme'])
                ? (_b(json['informeFirmado']) ? 'Firmado' : 'Pendiente firma')
                : 'No emitido'),
        tieneInforme: _b(json['tieneInforme']),
      );
}

@immutable
class HistorialVerificacionResponse {
  const HistorialVerificacionResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  final int total;
  final int page;
  final int pageSize;
  final List<HistorialVerificacionItem> items;

  factory HistorialVerificacionResponse.fromJson(Map<String, dynamic> json) =>
      HistorialVerificacionResponse(
        total: _i(json['total']),
        page: _i(json['page']),
        pageSize: _i(json['pageSize']),
        items: _list(json['items'], HistorialVerificacionItem.fromJson),
      );
}

String _s(dynamic v) => v?.toString().trim() ?? '';

String? _ns(dynamic v) {
  final s = v?.toString().trim();

  return s == null || s.isEmpty ? null : s;
}

int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

bool _b(dynamic v) => v == true;

bool? _nb(dynamic v) =>
    v == null ? null : (v is bool ? v : v.toString().toLowerCase() == 'true');

DateTime _dt(dynamic v) => _dtn(v) ?? DateTime.fromMillisecondsSinceEpoch(0);

DateTime? _dtn(dynamic v) => v is String ? DateTime.tryParse(v) : null;

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  final raw = v as List?;

  if (raw == null) {
    return [];
  }

  return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
}
