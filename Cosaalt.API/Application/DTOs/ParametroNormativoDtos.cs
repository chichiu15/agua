namespace Cosaalt.API.Application.DTOs;

public record ParametroNormativoDto(
    int Id,
    string Codigo,
    string? Descripcion,
    decimal ErrorMaxPermitido,
    decimal? CaudalMin,
    decimal? CaudalMax,
    DateTime? VigenciaInicio,
    DateTime? VigenciaFin,
    bool Activo);

public record GuardarParametroNormativoRequestDto(
    string Codigo,
    string? Descripcion,
    decimal ErrorMaxPermitido,
    decimal? CaudalMin,
    decimal? CaudalMax,
    DateTime? VigenciaInicio,
    DateTime? VigenciaFin,
    bool Activo);

public record CambiarEstadoParametroRequestDto(bool Activo);
