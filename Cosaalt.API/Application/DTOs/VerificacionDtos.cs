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
    string? Observaciones);

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
    DateTime? FechaConexion);

public record GuardarEnsayoRequestDto(
    string? Condiciones,
    decimal? LecturaInicial,
    decimal? LecturaFinal,
    decimal? VolumenPatron,
    decimal? Caudal,
    bool? Fugas,
    string? Observaciones,
    IReadOnlyList<ParticipanteVerificacionDto> Participantes);

public record EnsayoGuardadoResponseDto(
    int IdVerificacion,
    int? IdEnsayo,
    decimal? VolumenRegistrado,
    decimal? Error,
    string Mensaje);
