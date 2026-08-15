namespace Cosaalt.API.Application.DTOs;

public record SincronizacionRequestDto(
    int IdUsuario,
    IReadOnlyList<EjecucionCambioRequestDto> Ejecuciones);

public record SincronizacionResponseDto(
    int TotalRecibidos,
    int ProcesadosOk,
    int Errores,
    IReadOnlyList<int> IdsEjecucion,
    string Mensaje);

public record SincronizacionEstadoDto(
    int PendientesLocal,
    bool ApiDisponible,
    DateTime? UltimaSincronizacion);
