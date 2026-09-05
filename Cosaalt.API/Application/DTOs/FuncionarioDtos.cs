namespace Cosaalt.API.Application.DTOs;

/// <summary>
/// Persona corporativa disponible para vincular opcionalmente un usuario de la app.
/// El nombre del DTO se conserva por compatibilidad con el frontend existente.
/// CodFun corresponde a dbo.PERSONAS.CodPer.
/// </summary>
public record FuncionarioDto(
    int CodFun,
    string NombreCompleto,
    string? Alias,
    bool Activo);
