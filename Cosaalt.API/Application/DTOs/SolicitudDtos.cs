namespace Cosaalt.API.Application.DTOs;

public record SolicitudBandejaDto(
    string Id,
    string TipoOrigen,
    string Estado,
    bool EsUrgente,
    bool EsVencida,
    int RegistroSocio,
    string NombreCliente,
    string Direccion,
    string? Categoria,
    string? Ruta,
    int? Recorrido,
    string? NumeroMedidor,
    string? MarcaMedidor,
    decimal? LecturaAnterior,
    decimal? LecturaActual,
    decimal? Consumo,
    string? MotivoObservacion,
    DateTime FechaSolicitud,
    int? FolioOdeco,
    string? ConclusionOdeco,
    double? Latitud,
    double? Longitud);

public record DashboardResumenDto(
    int OdecoUrgentes,
    int LecturasDelMes,
    int CompletadasHoy);

public record SolicitudesResponseDto(
    DashboardResumenDto Resumen,
    IReadOnlyList<SolicitudBandejaDto> Solicitudes);
