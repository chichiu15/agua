namespace Cosaalt.API.Application.DTOs;

public record UsuarioDto(
    int Id,
    string NombreCompleto,
    string NombreUsuario,
    string Rol,
    int IdRol,
    bool Activo,
    int? CodFunCorporativo,
    DateTime FechaCreacion);

public record RolDto(
    int Id,
    string Nombre,
    string? Descripcion,
    bool Activo);

public record CrearUsuarioRequestDto(
    int? CodFunCorporativo,
    string NombreUsuario,
    string Contrasena,
    int IdRol,
    bool Activo = true);

public record ActualizarUsuarioRequestDto(
    int? CodFunCorporativo,
    string NombreUsuario,
    string? Contrasena,
    int IdRol,
    bool Activo);
