class Tecnico {
  const Tecnico({
    required this.id,
    required this.nombreCompleto,
    required this.rol,
    required this.activo,
    required this.tieneRutaAsignada,
  });

  final int id;
  final String nombreCompleto;
  final String rol;
  final bool activo;
  final bool tieneRutaAsignada;

  factory Tecnico.fromJson(Map<String, dynamic> json) {
    return Tecnico(
      id: json['id'] as int,
      nombreCompleto: json['nombreCompleto'] as String,
      rol: json['rol'] as String,
      activo: json['activo'] as bool,
      tieneRutaAsignada: json['tieneRutaAsignada'] as bool,
    );
  }
}

class TecnicosResponse {
  const TecnicosResponse({required this.tecnicos});

  final List<Tecnico> tecnicos;

  factory TecnicosResponse.fromJson(Map<String, dynamic> json) {
    return TecnicosResponse(
      tecnicos: (json['tecnicos'] as List)
          .map((t) => Tecnico.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
