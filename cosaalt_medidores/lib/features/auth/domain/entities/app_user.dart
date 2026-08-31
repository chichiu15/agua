enum UserRole {
  asignador,
  tecnico,
  administrador,
  mecanico;

  static UserRole fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'asignador':
        return UserRole.asignador;
      case 'tecnico':
      case 't\u00e9cnico':
        return UserRole.tecnico;
      case 'administrador':
      case 'admin':
        return UserRole.administrador;
      case 'mecanico':
      case 'mec\u00e1nico':
        return UserRole.mecanico;
      default:
        throw FormatException('Rol de usuario desconocido: $value');
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.active,
  });

  final int id;
  final String username;
  final String fullName;
  final UserRole role;
  final bool active;
}
