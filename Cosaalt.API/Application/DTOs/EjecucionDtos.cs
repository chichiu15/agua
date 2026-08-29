namespace Cosaalt.API.Application.DTOs;

public record EjecucionCambioRequestDto(
    string TipoOrigen,
    string IdOrigen,
    int IdUsuarioApp,
    DateTime FechaHoraEjecucion,
    string NumeroMedidorRetirado,
    string? MarcaRetirado,
    decimal LecturaRetiro,
    int IdMotivo,
    string NumeroMedidorInstalado,
    string? MarcaInstalado,
    string? ObservacionesInstalacion,
    string? LatLong,
    IReadOnlyList<EvidenciaFotoDto>? Evidencias);

public record EvidenciaFotoDto(string TipoFoto, string RutaArchivo);

public record EjecucionCambioResponseDto(
    int Id,
    string Mensaje,
    bool Sincronizado);

public record EvidenciaHistorialDto(
    string TipoFoto,
    string RutaArchivo);

public record EjecucionHistorialDto(
    int IdEjecucion,
    string TipoOrigen,
    string IdOrigen,
    string SolicitudId,
    DateTime FechaHoraEjecucion,
    int? CodCon,
    string? NombreCliente,
    string? Direccion,
    string NumeroMedidorRetirado,
    string? MarcaRetirado,
    decimal LecturaRetiro,
    string NumeroMedidorInstalado,
    string? MarcaInstalado,
    string? Observaciones,
    string? NombreTecnico,
    string? MotivoDescripcion,
    IReadOnlyList<EvidenciaHistorialDto> Evidencias);
