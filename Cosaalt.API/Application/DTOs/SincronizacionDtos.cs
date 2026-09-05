namespace Cosaalt.API.Application.DTOs;

public record SincronizacionRequestDto(
    int IdUsuario,
    IReadOnlyList<EjecucionCambioRequestDto> Ejecuciones);

public record SincronizacionItemResultadoDto(
    string TipoOrigen,
    string IdOrigen,
    bool Ok,
    int? IdEjecucion,
    bool YaExistia,
    string? Error);

public record SincronizacionResponseDto(
    int TotalRecibidos,
    int ProcesadosOk,
    int Errores,
    IReadOnlyList<int> IdsEjecucion,
    string Mensaje,
    IReadOnlyList<SincronizacionItemResultadoDto> Resultados);

public record SincronizacionEstadoDto(
    int PendientesLocal,
    bool ApiDisponible,
    DateTime? UltimaSincronizacion);
