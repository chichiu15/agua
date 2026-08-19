namespace Cosaalt.API.Application.DTOs;

public record TecnicoDto(int Id, string NombreCompleto, string Rol, bool Activo, bool TieneRutaAsignada);

public record DetalleRutaRequestDto(
    string TipoOrigen,
    string IdOrigen,
    string SolicitudId,
    int OrdenVisita,
    double? Latitud,
    double? Longitud,
    string NombreCliente,
    string Direccion);

public record AsignarRutaRequestDto(
    int IdUsuarioAsignador,
    int IdUsuarioTecnico,
    DateTime FechaAsignacion,
    IReadOnlyList<DetalleRutaRequestDto> Detalles);

public record DetalleRutaResponseDto(
    int Id,
    string SolicitudId,
    string TipoOrigen,
    int OrdenVisita,
    string Estado,
    string NombreCliente,
    string Direccion,
    double? Latitud,
    double? Longitud,
    bool EsUrgente);

public record RutaAsignadaResponseDto(
    int IdAsignacion,
    int IdUsuarioTecnico,
    string NombreTecnico,
    DateTime FechaAsignacion,
    string Estado,
    int TotalParadas,
    IReadOnlyList<DetalleRutaResponseDto> Detalles);

public record RutasTecnicoResponseDto(
    IReadOnlyList<RutaAsignadaResponseDto> Rutas);
