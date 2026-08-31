namespace Cosaalt.API.Application.DTOs;

public record PagedResultDto<T>(
    IReadOnlyList<T> Items,
    int Page,
    int PageSize,
    int TotalItems,
    int TotalPages);

public record AdminCategoriaCantidadDto(string Categoria, int Cantidad);

public record AdminActividadDto(
    DateTime Fecha,
    string Tipo,
    string Titulo,
    string Detalle,
    string? Estado);

public record AdminAlertaDto(
    string Tipo,
    string Nivel,
    string Titulo,
    string Detalle,
    int Cantidad);

public record AdminTecnicoResumenDto(
    int IdUsuario,
    string Nombre,
    bool Activo,
    int RutasHoy,
    int ParadasHoy,
    int ParadasCompletadasHoy,
    decimal AvancePorcentaje,
    DateTime? UltimaEjecucionRecibida,
    string EstadoOperacion);

public record AdminDashboardDto(
    int SolicitudesPendientes,
    int OdecoPendientes,
    int OdecoUrgentes,
    int OdecoVencidas,
    int LecturaPendientes,
    int RutasActivasHoy,
    int TecnicosConRutaHoy,
    int CambiosEjecutadosHoy,
    int CambiosSincronizadosHoy,
    int VerificacionesPendientes,
    int VerificacionesEnCurso,
    int VerificacionesCompletadas,
    int VerificacionesCumple,
    int VerificacionesNoCumple,
    IReadOnlyList<AdminCategoriaCantidadDto> SolicitudesPorEstado,
    IReadOnlyList<AdminCategoriaCantidadDto> MotivosCambioFrecuentes,
    IReadOnlyList<AdminTecnicoResumenDto> Tecnicos,
    IReadOnlyList<AdminActividadDto> ActividadReciente,
    IReadOnlyList<AdminAlertaDto> Alertas);

public record AdminSolicitudDto(
    string Id,
    string TipoOrigen,
    DateTime FechaSolicitud,
    DateTime? FechaLimite,
    bool Vencida,
    int DiasTranscurridos,
    int CodCon,
    string NombreCliente,
    string Direccion,
    string? Motivo,
    string Prioridad,
    string Estado,
    int? IdTecnico,
    string? NombreTecnico,
    string? NumeroMedidor,
    string? MarcaMedidor,
    decimal? LecturaAnterior,
    decimal? LecturaActual,
    decimal? Consumo,
    DateTime? UltimaEjecucion,
    bool TieneEjecucion);

public record AdminSolicitudFiltro(
    DateTime? Desde,
    DateTime? Hasta,
    string? Origen,
    string? Estado,
    string? Prioridad,
    int? TecnicoId,
    string? Buscar,
    int Page = 1,
    int PageSize = 25);

public record AdminRutaDetalleDto(
    int IdDetalle,
    int Orden,
    string SolicitudId,
    string TipoOrigen,
    string NombreCliente,
    string Direccion,
    double? Latitud,
    double? Longitud,
    string Estado,
    bool Ejecutada,
    DateTime? FechaEjecucion);

public record AdminRutaDto(
    int IdAsignacion,
    int IdTecnico,
    string NombreTecnico,
    DateTime FechaAsignacion,
    string Estado,
    int TotalParadas,
    int Completadas,
    int Pendientes,
    decimal AvancePorcentaje,
    DateTime? UltimaEjecucionRecibida,
    IReadOnlyList<AdminRutaDetalleDto> Detalles);

public record AdminRutaFiltro(
    DateTime? Fecha,
    int? TecnicoId,
    string? Estado,
    string? Buscar,
    int Page = 1,
    int PageSize = 20);

public record AdminSincronizacionTecnicoDto(
    int IdTecnico,
    string NombreTecnico,
    bool Activo,
    int RutasHoy,
    int ParadasHoy,
    int ParadasCompletadasHoy,
    int EjecucionesRecibidasHoy,
    int EjecucionesSincronizadasHoy,
    int EjecucionesPendientesServidor,
    int ParadasCompletadasSinEjecucion,
    int EjecucionesSinParada,
    int EjecucionesDuplicadas,
    DateTime? UltimaEjecucionRecibida,
    string EstadoServidor,
    string Alcance);

public record AdminVerificacionResumenDto(
    int IdVerificacion,
    string TipoOrigen,
    string IdOrigen,
    int CodCon,
    string NombreCliente,
    string? NumeroMedidor,
    DateTime Fecha,
    int IdMecanico,
    string NombreMecanico,
    string Estado,
    string? Resultado,
    decimal? Error,
    decimal? Caudal,
    bool? Fugas,
    bool TieneInforme,
    string? NroInforme,
    bool InformeFirmado);

public record AdminInformeVerificacionDto(
    int IdInforme,
    string NroInforme,
    DateTime FechaEmision,
    DateTime? FechaFirma,
    string? RutaPdf,
    bool Firmado,
    int Repeticiones);

public record AdminVerificacionDetalleDto(
    AdminVerificacionResumenDto Resumen,
    DatosSocioMedidorDto DatosSocio,
    EnsayoVerificacionDto? Ensayo,
    IReadOnlyList<ParticipanteVerificacionDto> Participantes,
    IReadOnlyList<AdminInformeVerificacionDto> Informes);

public record AdminVerificacionFiltro(
    DateTime? Desde,
    DateTime? Hasta,
    int? MecanicoId,
    string? Estado,
    string? Resultado,
    string? Buscar,
    bool? SoloConInforme,
    int Page = 1,
    int PageSize = 25);

public record AdminMovimientoDto(
    int IdEjecucion,
    DateTime FechaHora,
    string TipoOrigen,
    string IdOrigen,
    int CodCon,
    string NombreCliente,
    string Direccion,
    string NumeroMedidorRetirado,
    string? MarcaRetirado,
    decimal LecturaRetiro,
    int IdMotivo,
    string Motivo,
    string NumeroMedidorInstalado,
    string? MarcaInstalado,
    string? Observaciones,
    string? LatLong,
    int IdTecnico,
    string NombreTecnico,
    bool Sincronizado,
    int Evidencias,
    IReadOnlyList<EvidenciaHistorialDto> Fotos);

public record AdminMovimientoFiltro(
    DateTime? Desde,
    DateTime? Hasta,
    int? TecnicoId,
    int? MotivoId,
    string? Origen,
    string? Marca,
    bool? Sincronizado,
    string? Buscar,
    int Page = 1,
    int PageSize = 25);

/// <summary>
/// Fila del historial corporativo dbo.CambioMedidores.
/// IMPORTANTE: el mapeo actual de COSAALT no expone una fecha del movimiento,
/// por eso este DTO no inventa ni deriva una fecha. El estado vigente se toma
/// exclusivamente de EstCaMe. Es una vista de auditoria SOLO LECTURA.
/// </summary>
public record AdminMovimientoCorporativoDto(
    int CodCaMe,
    int CodCon,
    string NombreCliente,
    string Direccion,
    string NumeroMedidor,
    string? Marca,
    bool Vigente,
    int? IdMotivo,
    string? Motivo,
    string? Descripcion,
    int? CodOrdenTrabajo);

public record AdminMovimientoCorporativoFiltro(
    int? CodCon,
    bool? Vigente,
    int? MotivoId,
    string? Marca,
    string? Buscar,
    int Page = 1,
    int PageSize = 25);

public record AdminSerieTemporalDto(string Periodo, int Cantidad);

public record AdminPersonaMetricaDto(
    int IdUsuario,
    string Nombre,
    string Rol,
    int Atenciones,
    decimal? ErrorPromedio,
    int Cumple,
    int NoCumple);

public record AdminEstadisticasDto(
    int TotalCambios,
    int TotalVerificaciones,
    int VerificacionesCumple,
    int VerificacionesNoCumple,
    decimal PorcentajeCumple,
    int CasosConFuga,
    decimal? ErrorPromedio,
    decimal? HorasPromedioAtencion,
    IReadOnlyList<AdminCategoriaCantidadDto> MotivosCambio,
    IReadOnlyList<AdminCategoriaCantidadDto> MarcasRetiradas,
    IReadOnlyList<AdminCategoriaCantidadDto> OrigenesCambio,
    IReadOnlyList<AdminSerieTemporalDto> CambiosPorDia,
    IReadOnlyList<AdminPersonaMetricaDto> Tecnicos,
    IReadOnlyList<AdminPersonaMetricaDto> Mecanicos);

public record AdminEstadisticasFiltro(
    DateTime? Desde,
    DateTime? Hasta,
    int? TecnicoId,
    int? MecanicoId,
    int? MotivoId,
    string? Origen,
    string? Marca);
