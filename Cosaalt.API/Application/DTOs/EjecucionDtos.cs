namespace Cosaalt.API.Application.DTOs;

/// <summary>
/// Contrato compatible con el frontend actual. Los campos CodMedidor*/RegSoc son opcionales:
/// si no llegan, el backend los resuelve contra dbo.Medidor y la solicitud/ruta.
/// </summary>
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
    IReadOnlyList<EvidenciaFotoDto>? Evidencias,
    int? RegSoc = null,
    int? CodMedidorRetirado = null,
    int? CodMedidorInstalado = null,
    decimal? Latitud = null,
    decimal? Longitud = null);

public record EvidenciaFotoDto(string TipoFoto, string RutaArchivo);

public record EjecucionCambioResponseDto(
    int Id,
    string Mensaje,
    bool Sincronizado,
    bool YaExistia = false);

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
