namespace Cosaalt.API.Application.DTOs;

/// <summary>
/// Usuario de la aplicación (medidores.Usuarios) con su rol y nombre resuelto
/// desde el funcionario corporativo. Devuelve TODOS los roles (no solo técnicos).
/// </summary>
public record UsuarioDto(
    int Id,
    string NombreCompleto,
    string Rol,
    bool Activo,
    int? CodFunCorporativo);