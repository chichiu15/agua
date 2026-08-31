class AdminUsuario {
  const AdminUsuario({
    required this.id,
    required this.nombreCompleto,
    required this.nombreUsuario,
    required this.rol,
    required this.idRol,
    required this.activo,
    required this.codFunCorporativo,
    required this.fechaCreacion,
  });

  final int id;
  final String nombreCompleto;
  final String nombreUsuario;
  final String rol;
  final int idRol;
  final bool activo;
  final int? codFunCorporativo;
  final DateTime fechaCreacion;

  factory AdminUsuario.fromJson(Map<String, dynamic> json) => AdminUsuario(
    id: json['id'] as int,
    nombreCompleto: (json['nombreCompleto'] as String?) ?? '',
    nombreUsuario: (json['nombreUsuario'] as String?) ?? '',
    rol: (json['rol'] as String?) ?? '',
    idRol: (json['idRol'] as int?) ?? 0,
    activo: (json['activo'] as bool?) ?? false,
    codFunCorporativo: json['codFunCorporativo'] as int?,
    fechaCreacion: DateTime.tryParse((json['fechaCreacion'] as String?) ?? '') ?? DateTime(2000),
  );
}

class AdminRol {
  const AdminRol({required this.id, required this.nombre, this.descripcion, required this.activo});
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  factory AdminRol.fromJson(Map<String, dynamic> json) => AdminRol(
    id: json['id'] as int,
    nombre: (json['nombre'] as String?) ?? '',
    descripcion: json['descripcion'] as String?,
    activo: (json['activo'] as bool?) ?? false,
  );
}

class AdminFuncionario {
  const AdminFuncionario({required this.codFun, required this.nombreCompleto, this.alias, required this.activo});
  final int codFun;
  final String nombreCompleto;
  final String? alias;
  final bool activo;

  factory AdminFuncionario.fromJson(Map<String, dynamic> json) => AdminFuncionario(
    codFun: json['codFun'] as int,
    nombreCompleto: (json['nombreCompleto'] as String?) ?? '',
    alias: json['alias'] as String?,
    activo: (json['activo'] as bool?) ?? false,
  );
}

class MotivoCatalogo {
  const MotivoCatalogo({required this.id, required this.descripcion, this.detalle, required this.activo});
  final int id;
  final String descripcion;
  final String? detalle;
  final bool activo;
  factory MotivoCatalogo.fromJson(Map<String, dynamic> json) => MotivoCatalogo(
    id: (json['id'] as num).toInt(),
    descripcion: (json['descripcion'] as String?) ?? '',
    detalle: json['detalle'] as String?,
    activo: (json['activo'] as bool?) ?? true,
  );
}

class GuardarMotivoCatalogo {
  const GuardarMotivoCatalogo({required this.nombre, this.descripcion, required this.activo});
  final String nombre;
  final String? descripcion;
  final bool activo;
}

class MarcaCatalogo {
  const MarcaCatalogo({required this.id, required this.nombre, this.alias});
  final int id;
  final String nombre;
  final String? alias;
  factory MarcaCatalogo.fromJson(Map<String, dynamic> json) => MarcaCatalogo(
    id: json['id'] as int,
    nombre: (json['nombre'] as String?) ?? '',
    alias: json['alias'] as String?,
  );
}

class ParametroNormativo {
  const ParametroNormativo({
    required this.id,
    required this.codigo,
    this.descripcion,
    required this.errorMaxPermitido,
    this.caudalMin,
    this.caudalMax,
    this.vigenciaInicio,
    this.vigenciaFin,
    required this.activo,
  });
  final int id;
  final String codigo;
  final String? descripcion;
  final double errorMaxPermitido;
  final double? caudalMin;
  final double? caudalMax;
  final DateTime? vigenciaInicio;
  final DateTime? vigenciaFin;
  final bool activo;

  factory ParametroNormativo.fromJson(Map<String, dynamic> json) => ParametroNormativo(
    id: json['id'] as int,
    codigo: (json['codigo'] as String?) ?? '',
    descripcion: json['descripcion'] as String?,
    errorMaxPermitido: (json['errorMaxPermitido'] as num).toDouble(),
    caudalMin: (json['caudalMin'] as num?)?.toDouble(),
    caudalMax: (json['caudalMax'] as num?)?.toDouble(),
    vigenciaInicio: DateTime.tryParse((json['vigenciaInicio'] as String?) ?? ''),
    vigenciaFin: DateTime.tryParse((json['vigenciaFin'] as String?) ?? ''),
    activo: (json['activo'] as bool?) ?? false,
  );
}

class GuardarUsuario {
  const GuardarUsuario({required this.codFunCorporativo, required this.nombreUsuario, this.contrasena, required this.idRol, required this.activo});
  final int? codFunCorporativo;
  final String nombreUsuario;
  final String? contrasena;
  final int idRol;
  final bool activo;
}

class GuardarParametroNormativo {
  const GuardarParametroNormativo({required this.codigo, this.descripcion, required this.errorMaxPermitido, this.caudalMin, this.caudalMax, this.vigenciaInicio, this.vigenciaFin, required this.activo});
  final String codigo;
  final String? descripcion;
  final double errorMaxPermitido;
  final double? caudalMin;
  final double? caudalMax;
  final DateTime? vigenciaInicio;
  final DateTime? vigenciaFin;
  final bool activo;
}

class PagedData<T> {
  const PagedData({required this.items, required this.page, required this.pageSize, required this.totalItems, required this.totalPages});
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
}

class AdminCategoriaCantidad {
  const AdminCategoriaCantidad(this.categoria, this.cantidad);
  final String categoria;
  final int cantidad;
  factory AdminCategoriaCantidad.fromJson(Map<String, dynamic> j) => AdminCategoriaCantidad((j['categoria'] as String?) ?? '', (j['cantidad'] as num?)?.toInt() ?? 0);
}

class AdminActividad {
  const AdminActividad({required this.fecha, required this.tipo, required this.titulo, required this.detalle, this.estado});
  final DateTime fecha;
  final String tipo;
  final String titulo;
  final String detalle;
  final String? estado;
  factory AdminActividad.fromJson(Map<String, dynamic> j) => AdminActividad(
    fecha: _dt(j['fecha']) ?? DateTime(2000), tipo: (j['tipo'] as String?) ?? '', titulo: (j['titulo'] as String?) ?? '', detalle: (j['detalle'] as String?) ?? '', estado: j['estado'] as String?);
}

class AdminAlerta {
  const AdminAlerta({required this.tipo, required this.nivel, required this.titulo, required this.detalle, required this.cantidad});
  final String tipo, nivel, titulo, detalle;
  final int cantidad;
  factory AdminAlerta.fromJson(Map<String, dynamic> j) => AdminAlerta(tipo: (j['tipo'] as String?) ?? '', nivel: (j['nivel'] as String?) ?? '', titulo: (j['titulo'] as String?) ?? '', detalle: (j['detalle'] as String?) ?? '', cantidad: (j['cantidad'] as num?)?.toInt() ?? 0);
}

class AdminTecnicoResumen {
  const AdminTecnicoResumen({required this.idUsuario, required this.nombre, required this.activo, required this.rutasHoy, required this.paradasHoy, required this.paradasCompletadasHoy, required this.avancePorcentaje, this.ultimaEjecucionRecibida, required this.estadoOperacion});
  final int idUsuario, rutasHoy, paradasHoy, paradasCompletadasHoy;
  final String nombre, estadoOperacion;
  final bool activo;
  final double avancePorcentaje;
  final DateTime? ultimaEjecucionRecibida;
  factory AdminTecnicoResumen.fromJson(Map<String, dynamic> j) => AdminTecnicoResumen(
    idUsuario: (j['idUsuario'] as num?)?.toInt() ?? 0, nombre: (j['nombre'] as String?) ?? '', activo: (j['activo'] as bool?) ?? false,
    rutasHoy: (j['rutasHoy'] as num?)?.toInt() ?? 0, paradasHoy: (j['paradasHoy'] as num?)?.toInt() ?? 0,
    paradasCompletadasHoy: (j['paradasCompletadasHoy'] as num?)?.toInt() ?? 0, avancePorcentaje: (j['avancePorcentaje'] as num?)?.toDouble() ?? 0,
    ultimaEjecucionRecibida: _dt(j['ultimaEjecucionRecibida']), estadoOperacion: (j['estadoOperacion'] as String?) ?? '');
}

class AdminDashboard {
  const AdminDashboard({required this.solicitudesPendientes, required this.odecoPendientes, required this.odecoUrgentes, required this.odecoVencidas, required this.lecturaPendientes, required this.rutasActivasHoy, required this.tecnicosConRutaHoy, required this.cambiosEjecutadosHoy, required this.cambiosSincronizadosHoy, required this.verificacionesPendientes, required this.verificacionesEnCurso, required this.verificacionesCompletadas, required this.verificacionesCumple, required this.verificacionesNoCumple, required this.solicitudesPorEstado, required this.motivosCambioFrecuentes, required this.tecnicos, required this.actividadReciente, required this.alertas});
  final int solicitudesPendientes, odecoPendientes, odecoUrgentes, odecoVencidas, lecturaPendientes, rutasActivasHoy, tecnicosConRutaHoy, cambiosEjecutadosHoy, cambiosSincronizadosHoy, verificacionesPendientes, verificacionesEnCurso, verificacionesCompletadas, verificacionesCumple, verificacionesNoCumple;
  final List<AdminCategoriaCantidad> solicitudesPorEstado, motivosCambioFrecuentes;
  final List<AdminTecnicoResumen> tecnicos;
  final List<AdminActividad> actividadReciente;
  final List<AdminAlerta> alertas;
  factory AdminDashboard.fromJson(Map<String, dynamic> j) => AdminDashboard(
    solicitudesPendientes: _i(j['solicitudesPendientes']), odecoPendientes: _i(j['odecoPendientes']), odecoUrgentes: _i(j['odecoUrgentes']), odecoVencidas: _i(j['odecoVencidas']), lecturaPendientes: _i(j['lecturaPendientes']), rutasActivasHoy: _i(j['rutasActivasHoy']), tecnicosConRutaHoy: _i(j['tecnicosConRutaHoy']), cambiosEjecutadosHoy: _i(j['cambiosEjecutadosHoy']), cambiosSincronizadosHoy: _i(j['cambiosSincronizadosHoy']), verificacionesPendientes: _i(j['verificacionesPendientes']), verificacionesEnCurso: _i(j['verificacionesEnCurso']), verificacionesCompletadas: _i(j['verificacionesCompletadas']), verificacionesCumple: _i(j['verificacionesCumple']), verificacionesNoCumple: _i(j['verificacionesNoCumple']),
    solicitudesPorEstado: _list(j['solicitudesPorEstado'], AdminCategoriaCantidad.fromJson), motivosCambioFrecuentes: _list(j['motivosCambioFrecuentes'], AdminCategoriaCantidad.fromJson), tecnicos: _list(j['tecnicos'], AdminTecnicoResumen.fromJson), actividadReciente: _list(j['actividadReciente'], AdminActividad.fromJson), alertas: _list(j['alertas'], AdminAlerta.fromJson));
}

class AdminSolicitud {
  const AdminSolicitud({required this.id, required this.tipoOrigen, required this.fechaSolicitud, this.fechaLimite, required this.vencida, required this.diasTranscurridos, required this.codCon, required this.nombreCliente, required this.direccion, this.motivo, required this.prioridad, required this.estado, this.idTecnico, this.nombreTecnico, this.numeroMedidor, this.marcaMedidor, this.lecturaAnterior, this.lecturaActual, this.consumo, this.ultimaEjecucion, required this.tieneEjecucion});
  final String id, tipoOrigen, nombreCliente, direccion, prioridad, estado;
  final DateTime fechaSolicitud;
  final DateTime? fechaLimite, ultimaEjecucion;
  final bool vencida, tieneEjecucion;
  final int diasTranscurridos, codCon;
  final int? idTecnico;
  final String? motivo, nombreTecnico, numeroMedidor, marcaMedidor;
  final double? lecturaAnterior, lecturaActual, consumo;
  factory AdminSolicitud.fromJson(Map<String, dynamic> j) => AdminSolicitud(
    id: (j['id'] as String?) ?? '', tipoOrigen: (j['tipoOrigen'] as String?) ?? '', fechaSolicitud: _dt(j['fechaSolicitud']) ?? DateTime(2000), fechaLimite: _dt(j['fechaLimite']), vencida: (j['vencida'] as bool?) ?? false, diasTranscurridos: _i(j['diasTranscurridos']), codCon: _i(j['codCon']), nombreCliente: (j['nombreCliente'] as String?) ?? '', direccion: (j['direccion'] as String?) ?? '', motivo: j['motivo'] as String?, prioridad: (j['prioridad'] as String?) ?? '', estado: (j['estado'] as String?) ?? '', idTecnico: (j['idTecnico'] as num?)?.toInt(), nombreTecnico: j['nombreTecnico'] as String?, numeroMedidor: j['numeroMedidor'] as String?, marcaMedidor: j['marcaMedidor'] as String?, lecturaAnterior: _d(j['lecturaAnterior']), lecturaActual: _d(j['lecturaActual']), consumo: _d(j['consumo']), ultimaEjecucion: _dt(j['ultimaEjecucion']), tieneEjecucion: (j['tieneEjecucion'] as bool?) ?? false);
}

class AdminRutaDetalle {
  const AdminRutaDetalle({required this.idDetalle, required this.orden, required this.solicitudId, required this.tipoOrigen, required this.nombreCliente, required this.direccion, this.latitud, this.longitud, required this.estado, required this.ejecutada, this.fechaEjecucion});
  final int idDetalle, orden;
  final String solicitudId, tipoOrigen, nombreCliente, direccion, estado;
  final double? latitud, longitud;
  final bool ejecutada;
  final DateTime? fechaEjecucion;
  factory AdminRutaDetalle.fromJson(Map<String, dynamic> j) => AdminRutaDetalle(idDetalle: _i(j['idDetalle']), orden: _i(j['orden']), solicitudId: (j['solicitudId'] as String?) ?? '', tipoOrigen: (j['tipoOrigen'] as String?) ?? '', nombreCliente: (j['nombreCliente'] as String?) ?? '', direccion: (j['direccion'] as String?) ?? '', latitud: _d(j['latitud']), longitud: _d(j['longitud']), estado: (j['estado'] as String?) ?? '', ejecutada: (j['ejecutada'] as bool?) ?? false, fechaEjecucion: _dt(j['fechaEjecucion']));
}

class AdminRuta {
  const AdminRuta({required this.idAsignacion, required this.idTecnico, required this.nombreTecnico, required this.fechaAsignacion, required this.estado, required this.totalParadas, required this.completadas, required this.pendientes, required this.avancePorcentaje, this.ultimaEjecucionRecibida, required this.detalles});
  final int idAsignacion, idTecnico, totalParadas, completadas, pendientes;
  final String nombreTecnico, estado;
  final DateTime fechaAsignacion;
  final double avancePorcentaje;
  final DateTime? ultimaEjecucionRecibida;
  final List<AdminRutaDetalle> detalles;
  factory AdminRuta.fromJson(Map<String, dynamic> j) => AdminRuta(idAsignacion: _i(j['idAsignacion']), idTecnico: _i(j['idTecnico']), nombreTecnico: (j['nombreTecnico'] as String?) ?? '', fechaAsignacion: _dt(j['fechaAsignacion']) ?? DateTime(2000), estado: (j['estado'] as String?) ?? '', totalParadas: _i(j['totalParadas']), completadas: _i(j['completadas']), pendientes: _i(j['pendientes']), avancePorcentaje: _d(j['avancePorcentaje']) ?? 0, ultimaEjecucionRecibida: _dt(j['ultimaEjecucionRecibida']), detalles: _list(j['detalles'], AdminRutaDetalle.fromJson));
}

class AdminSincronizacionTecnico {
  const AdminSincronizacionTecnico({required this.idTecnico, required this.nombreTecnico, required this.activo, required this.rutasHoy, required this.paradasHoy, required this.paradasCompletadasHoy, required this.ejecucionesRecibidasHoy, required this.ejecucionesSincronizadasHoy, required this.ejecucionesPendientesServidor, required this.paradasCompletadasSinEjecucion, required this.ejecucionesSinParada, required this.ejecucionesDuplicadas, this.ultimaEjecucionRecibida, required this.estadoServidor, required this.alcance});
  final int idTecnico, rutasHoy, paradasHoy, paradasCompletadasHoy, ejecucionesRecibidasHoy, ejecucionesSincronizadasHoy, ejecucionesPendientesServidor, paradasCompletadasSinEjecucion, ejecucionesSinParada, ejecucionesDuplicadas;
  final String nombreTecnico, estadoServidor, alcance;
  final bool activo;
  final DateTime? ultimaEjecucionRecibida;
  factory AdminSincronizacionTecnico.fromJson(Map<String, dynamic> j) => AdminSincronizacionTecnico(idTecnico: _i(j['idTecnico']), nombreTecnico: (j['nombreTecnico'] as String?) ?? '', activo: (j['activo'] as bool?) ?? false, rutasHoy: _i(j['rutasHoy']), paradasHoy: _i(j['paradasHoy']), paradasCompletadasHoy: _i(j['paradasCompletadasHoy']), ejecucionesRecibidasHoy: _i(j['ejecucionesRecibidasHoy']), ejecucionesSincronizadasHoy: _i(j['ejecucionesSincronizadasHoy']), ejecucionesPendientesServidor: _i(j['ejecucionesPendientesServidor']), paradasCompletadasSinEjecucion: _i(j['paradasCompletadasSinEjecucion']), ejecucionesSinParada: _i(j['ejecucionesSinParada']), ejecucionesDuplicadas: _i(j['ejecucionesDuplicadas']), ultimaEjecucionRecibida: _dt(j['ultimaEjecucionRecibida']), estadoServidor: (j['estadoServidor'] as String?) ?? '', alcance: (j['alcance'] as String?) ?? '');
}

class AdminVerificacion {
  const AdminVerificacion({required this.idVerificacion, required this.tipoOrigen, required this.idOrigen, required this.codCon, required this.nombreCliente, this.numeroMedidor, required this.fecha, required this.idMecanico, required this.nombreMecanico, required this.estado, this.resultado, this.error, this.caudal, this.fugas, required this.tieneInforme, this.nroInforme, required this.informeFirmado});
  final int idVerificacion, codCon, idMecanico;
  final String tipoOrigen, idOrigen, nombreCliente, nombreMecanico, estado;
  final String? numeroMedidor, resultado, nroInforme;
  final DateTime fecha;
  final double? error, caudal;
  final bool? fugas;
  final bool tieneInforme, informeFirmado;
  factory AdminVerificacion.fromJson(Map<String, dynamic> j) => AdminVerificacion(idVerificacion: _i(j['idVerificacion']), tipoOrigen: (j['tipoOrigen'] as String?) ?? '', idOrigen: (j['idOrigen'] as String?) ?? '', codCon: _i(j['codCon']), nombreCliente: (j['nombreCliente'] as String?) ?? '', numeroMedidor: j['numeroMedidor'] as String?, fecha: _dt(j['fecha']) ?? DateTime(2000), idMecanico: _i(j['idMecanico']), nombreMecanico: (j['nombreMecanico'] as String?) ?? '', estado: (j['estado'] as String?) ?? '', resultado: j['resultado'] as String?, error: _d(j['error']), caudal: _d(j['caudal']), fugas: j['fugas'] as bool?, tieneInforme: (j['tieneInforme'] as bool?) ?? false, nroInforme: j['nroInforme'] as String?, informeFirmado: (j['informeFirmado'] as bool?) ?? false);
}

class AdminInformeVerificacion {
  const AdminInformeVerificacion({required this.idInforme, required this.nroInforme, required this.fechaEmision, this.fechaFirma, this.rutaPdf, required this.firmado, required this.repeticiones});
  final int idInforme, repeticiones;
  final String nroInforme;
  final DateTime fechaEmision;
  final DateTime? fechaFirma;
  final String? rutaPdf;
  final bool firmado;
  factory AdminInformeVerificacion.fromJson(Map<String, dynamic> j) => AdminInformeVerificacion(idInforme: _i(j['idInforme']), nroInforme: (j['nroInforme'] as String?) ?? '', fechaEmision: _dt(j['fechaEmision']) ?? DateTime(2000), fechaFirma: _dt(j['fechaFirma']), rutaPdf: j['rutaPdf'] as String?, firmado: (j['firmado'] as bool?) ?? false, repeticiones: _i(j['repeticiones']));
}

class AdminVerificacionDetalle {
  const AdminVerificacionDetalle({required this.resumen, required this.datosSocio, this.ensayo, required this.participantes, required this.informes});
  final AdminVerificacion resumen;
  final Map<String, dynamic> datosSocio;
  final Map<String, dynamic>? ensayo;
  final List<Map<String, dynamic>> participantes;
  final List<AdminInformeVerificacion> informes;
  factory AdminVerificacionDetalle.fromJson(Map<String, dynamic> j) => AdminVerificacionDetalle(
    resumen: AdminVerificacion.fromJson((j['resumen'] as Map?)?.cast<String, dynamic>() ?? {}),
    datosSocio: (j['datosSocio'] as Map?)?.cast<String, dynamic>() ?? {},
    ensayo: (j['ensayo'] as Map?)?.cast<String, dynamic>(),
    participantes: ((j['participantes'] as List?) ?? const []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(),
    informes: _list(j['informes'], AdminInformeVerificacion.fromJson));
}

class AdminMovimiento {
  const AdminMovimiento({required this.idEjecucion, required this.fechaHora, required this.tipoOrigen, required this.idOrigen, required this.codCon, required this.nombreCliente, required this.direccion, required this.numeroMedidorRetirado, this.marcaRetirado, required this.lecturaRetiro, required this.idMotivo, required this.motivo, required this.numeroMedidorInstalado, this.marcaInstalado, this.observaciones, this.latLong, required this.idTecnico, required this.nombreTecnico, required this.sincronizado, required this.evidencias, required this.fotos});
  final int idEjecucion, codCon, idMotivo, idTecnico, evidencias;
  final DateTime fechaHora;
  final String tipoOrigen, idOrigen, nombreCliente, direccion, numeroMedidorRetirado, motivo, numeroMedidorInstalado, nombreTecnico;
  final String? marcaRetirado, marcaInstalado, observaciones, latLong;
  final double lecturaRetiro;
  final bool sincronizado;
  final List<Map<String, dynamic>> fotos;
  factory AdminMovimiento.fromJson(Map<String, dynamic> j) => AdminMovimiento(idEjecucion: _i(j['idEjecucion']), fechaHora: _dt(j['fechaHora']) ?? DateTime(2000), tipoOrigen: (j['tipoOrigen'] as String?) ?? '', idOrigen: (j['idOrigen'] as String?) ?? '', codCon: _i(j['codCon']), nombreCliente: (j['nombreCliente'] as String?) ?? '', direccion: (j['direccion'] as String?) ?? '', numeroMedidorRetirado: (j['numeroMedidorRetirado'] as String?) ?? '', marcaRetirado: j['marcaRetirado'] as String?, lecturaRetiro: _d(j['lecturaRetiro']) ?? 0, idMotivo: _i(j['idMotivo']), motivo: (j['motivo'] as String?) ?? '', numeroMedidorInstalado: (j['numeroMedidorInstalado'] as String?) ?? '', marcaInstalado: j['marcaInstalado'] as String?, observaciones: j['observaciones'] as String?, latLong: j['latLong'] as String?, idTecnico: _i(j['idTecnico']), nombreTecnico: (j['nombreTecnico'] as String?) ?? '', sincronizado: (j['sincronizado'] as bool?) ?? false, evidencias: _i(j['evidencias']), fotos: ((j['fotos'] as List?) ?? const []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList());
}

class AdminMovimientoCorporativo {
  const AdminMovimientoCorporativo({required this.codCaMe, required this.codCon, required this.nombreCliente, required this.direccion, required this.numeroMedidor, this.marca, required this.vigente, this.idMotivo, this.motivo, this.descripcion, this.codOrdenTrabajo});
  final int codCaMe, codCon;
  final String nombreCliente, direccion, numeroMedidor;
  final String? marca, motivo, descripcion;
  final bool vigente;
  final int? idMotivo, codOrdenTrabajo;
  factory AdminMovimientoCorporativo.fromJson(Map<String, dynamic> j) => AdminMovimientoCorporativo(
    codCaMe: _i(j['codCaMe']),
    codCon: _i(j['codCon']),
    nombreCliente: (j['nombreCliente'] as String?) ?? '',
    direccion: (j['direccion'] as String?) ?? '',
    numeroMedidor: (j['numeroMedidor'] as String?) ?? '',
    marca: j['marca'] as String?,
    vigente: (j['vigente'] as bool?) ?? false,
    idMotivo: (j['idMotivo'] as num?)?.toInt(),
    motivo: j['motivo'] as String?,
    descripcion: j['descripcion'] as String?,
    codOrdenTrabajo: (j['codOrdenTrabajo'] as num?)?.toInt(),
  );
}

class AdminSerieTemporal {
  const AdminSerieTemporal(this.periodo, this.cantidad);
  final String periodo;
  final int cantidad;
  factory AdminSerieTemporal.fromJson(Map<String, dynamic> j) => AdminSerieTemporal((j['periodo'] as String?) ?? '', _i(j['cantidad']));
}

class AdminPersonaMetrica {
  const AdminPersonaMetrica({required this.idUsuario, required this.nombre, required this.rol, required this.atenciones, this.errorPromedio, required this.cumple, required this.noCumple});
  final int idUsuario, atenciones, cumple, noCumple;
  final String nombre, rol;
  final double? errorPromedio;
  factory AdminPersonaMetrica.fromJson(Map<String, dynamic> j) => AdminPersonaMetrica(idUsuario: _i(j['idUsuario']), nombre: (j['nombre'] as String?) ?? '', rol: (j['rol'] as String?) ?? '', atenciones: _i(j['atenciones']), errorPromedio: _d(j['errorPromedio']), cumple: _i(j['cumple']), noCumple: _i(j['noCumple']));
}

class AdminEstadisticas {
  const AdminEstadisticas({required this.totalCambios, required this.totalVerificaciones, required this.verificacionesCumple, required this.verificacionesNoCumple, required this.porcentajeCumple, required this.casosConFuga, this.errorPromedio, this.horasPromedioAtencion, required this.motivosCambio, required this.marcasRetiradas, required this.origenesCambio, required this.cambiosPorDia, required this.tecnicos, required this.mecanicos});
  final int totalCambios, totalVerificaciones, verificacionesCumple, verificacionesNoCumple, casosConFuga;
  final double porcentajeCumple;
  final double? errorPromedio, horasPromedioAtencion;
  final List<AdminCategoriaCantidad> motivosCambio, marcasRetiradas, origenesCambio;
  final List<AdminSerieTemporal> cambiosPorDia;
  final List<AdminPersonaMetrica> tecnicos, mecanicos;
  factory AdminEstadisticas.fromJson(Map<String, dynamic> j) => AdminEstadisticas(totalCambios: _i(j['totalCambios']), totalVerificaciones: _i(j['totalVerificaciones']), verificacionesCumple: _i(j['verificacionesCumple']), verificacionesNoCumple: _i(j['verificacionesNoCumple']), porcentajeCumple: _d(j['porcentajeCumple']) ?? 0, casosConFuga: _i(j['casosConFuga']), errorPromedio: _d(j['errorPromedio']), horasPromedioAtencion: _d(j['horasPromedioAtencion']), motivosCambio: _list(j['motivosCambio'], AdminCategoriaCantidad.fromJson), marcasRetiradas: _list(j['marcasRetiradas'], AdminCategoriaCantidad.fromJson), origenesCambio: _list(j['origenesCambio'], AdminCategoriaCantidad.fromJson), cambiosPorDia: _list(j['cambiosPorDia'], AdminSerieTemporal.fromJson), tecnicos: _list(j['tecnicos'], AdminPersonaMetrica.fromJson), mecanicos: _list(j['mecanicos'], AdminPersonaMetrica.fromJson));
}

int _i(dynamic value) => (value as num?)?.toInt() ?? 0;
double? _d(dynamic value) => (value as num?)?.toDouble();
DateTime? _dt(dynamic value) => value is String ? DateTime.tryParse(value) : null;
List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) => ((value as List?) ?? const []).whereType<Map>().map((e) => fromJson(e.cast<String, dynamic>())).toList();
