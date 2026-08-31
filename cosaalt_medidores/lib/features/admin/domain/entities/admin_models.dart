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
  const MotivoCatalogo({required this.id, required this.descripcion});
  final int id;
  final String descripcion;
  factory MotivoCatalogo.fromJson(Map<String, dynamic> json) => MotivoCatalogo(
    id: json['id'] as int,
    descripcion: (json['descripcion'] as String?) ?? '',
  );
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
