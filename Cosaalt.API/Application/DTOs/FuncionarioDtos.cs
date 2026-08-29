namespace Cosaalt.API.Application.DTOs;

/// <summary>
/// Funcionario real de COSAALT (lectura de dbo.Funcionarios + dbo.Personas).
/// </summary>
public record FuncionarioDto(
    int CodFun,
    string NombreCompleto,
    string? Alias,
    bool Activo);