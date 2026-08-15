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
