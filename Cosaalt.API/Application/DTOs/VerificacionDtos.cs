namespace Cosaalt.API.Application.DTOs;

public record EnsayoVerificacionDto(
    int? Id,
    string? Condiciones,
    decimal? LecturaInicial,
    decimal? LecturaFinal,
    decimal? VolumenPatron,
    decimal? Caudal,
    decimal? VolumenRegistrado,
    decimal? Error,
    bool? Fugas,
    string? Observaciones,
    string? TipoPrueba = null,
    string? InstrumentoBanco = null,
    string? IdentificacionBanco = null,
    string? TrazabilidadCalibracion = null,
    string? CapacidadNominalQ3 = null,
    string? TipoCaudal = null,
    string? UnidadCaudal = null,
    string? UnidadVolumen = null,
    string? TipoFuga = null);

public record ParticipanteVerificacionDto(
    int? Id,
    string Nombre,
    string? Cargo,
    string? Rol);

public record VerificacionDto(
    int Id,
    string TipoOrigen,
    string IdOrigen,
    int CodCon,
    int IdUsuarioMecanico,
    string? IdMedidor,
    DateTime FechaVerificacion,
    string Estado,
    string? Resultado,
    string? NombreCliente,
    string? NombreMecanico,
    EnsayoVerificacionDto? Ensayo,
    IReadOnlyList<ParticipanteVerificacionDto> Participantes);

public record SolicitudVerificacionDto(
    string Id,
    string TipoOrigen,
    int CodCon,
    string NombreCliente,
    string Direccion,
    string? Categoria,
    string? NumeroMedidor,
    string? MarcaMedidor,
    string? MotivoObservacion,
    DateTime FechaSolicitud,
    string Estado,
    bool Tomada);

public record TomarVerificacionRequestDto(
    string TipoOrigen,
    string IdOrigen,
    int CodCon,
    int IdUsuarioMecanico,
    string? IdMedidor);

public record TomarVerificacionResponseDto(
    int IdVerificacion,
    string Mensaje);

public record DatosSocioMedidorDto(
    int CodCon,
    string NombreCliente,
    string Direccion,
    string? Categoria,
    string? NumeroDocumento,
    string? TipDocumento,
    string? Ruc,
    string? NumeroMedidor,
    string? MarcaMedidor,
    DateTime? FechaConexion,
    string? CapacidadQ3 = null,
    string? TipoMedidor = null,
    string? ClaseMedidor = null,
    string? DiametroMedidor = null,
    int? RegSoc = null,
    int? CodConexion = null,
    string? LugarVerificacion = null,
    string? TipoEnsayo = null,
    string? MotivoObservacion = null);

public record GuardarEnsayoRequestDto(
    string? Condiciones,
    decimal? LecturaInicial,
    decimal? LecturaFinal,
    decimal? VolumenPatron,
    decimal? Caudal,
    bool? Fugas,
    string? Observaciones,
    IReadOnlyList<ParticipanteVerificacionDto> Participantes,
    string? TipoPrueba = null,
    string? InstrumentoBanco = null,
    string? IdentificacionBanco = null,
    string? TrazabilidadCalibracion = null,
    string? CapacidadNominalQ3 = null,
    string? TipoCaudal = null,
    string? UnidadCaudal = null,
    string? UnidadVolumen = null,
    string? TipoFuga = null,

    // M6:
    // snapshot provisional de la regla normativa realmente aplicada.
    // No lo envía Flutter; lo completa VerificacionService.
    string? ParametroNormativoCodigoAplicado = null,
    decimal? LimiteNormativoAplicado = null);

public record CalculoEnsayoDto(
    decimal? VolumenRegistrado,
    decimal? VolumenPatron,
    decimal? Diferencia,
    decimal? ErrorConSigno,
    decimal? ErrorAbsoluto,
    decimal? LimitePermitido,
    string? ParametroNormativo,
    string? Resultado);

public record EnsayoGuardadoResponseDto(
    int IdVerificacion,
    int? IdEnsayo,
    decimal? VolumenRegistrado,
    decimal? Error,
    string Mensaje,
    CalculoEnsayoDto? Calculo = null);

public record VerificacionDashboardDto(
    int Pendientes,
    int EnCurso,
    int Completadas,
    int Cumple,
    int NoCumple,
    int Indeterminados,
    int Total);

public record VerificacionHistorialFiltro(
    DateTime? Desde = null,
    DateTime? Hasta = null,
    string? Estado = null,
    string? Resultado = null,
    string? Buscar = null,
    int Page = 1,
    int PageSize = 50);

public record VerificacionHistorialItemDto(
    int IdVerificacion,
    DateTime Fecha,
    string Estado,
    string? Resultado,
    decimal? Error,
    bool? Fugas,
    int CodCon,
    string? NombreCliente,
    string? NumeroMedidor,
    string? MarcaMedidor,
    int? IdInforme,
    string? NroInforme,
    bool TieneInforme);

public record VerificacionHistorialResponseDto(
    int Total,
    int Page,
    int PageSize,
    IReadOnlyList<VerificacionHistorialItemDto> Items);

public record InformeVerificacionDto(
    int Id,
    int IdVerificacion,
    string NroInforme,
    DateTime FechaEmision,
    string? RutaPdf,
    bool Firmado,
    int VersionInforme,
    string? Observaciones);

public record GenerarInformeRequestDto(
    string? Observaciones,
    string? NombreResponsable);

public record GenerarInformeResponseDto(
    InformeVerificacionDto Informe,
    string Mensaje);