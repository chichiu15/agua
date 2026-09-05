using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Domain.Entities;

namespace Cosaalt.API.Application.Mappers;

public static class EjecucionMapper
{
    public static EjecucionCambioResponseDto ToResponse(EjecucionCambio entity, bool yaExistia = false) =>
        new(entity.Id,
            yaExistia ? "La ejecucion ya habia sido registrada; no se duplico." : "Ejecucion registrada correctamente.",
            entity.Sincronizado,
            yaExistia);
}

public static class RutaMapper
{
    public static DetalleRutaResponseDto ToResponse(DetalleRuta entity, string? numeroMedidor = null) =>
        new(
            Id: entity.Id,
            SolicitudId: entity.SolicitudId,
            TipoOrigen: entity.TipoOrigen,
            OrdenVisita: entity.OrdenVisita,
            Estado: entity.Estado,
            NombreCliente: entity.NombreCliente,
            Direccion: entity.Direccion,
            Latitud: entity.Latitud.HasValue ? (double?)entity.Latitud.Value : null,
            Longitud: entity.Longitud.HasValue ? (double?)entity.Longitud.Value : null,
            EsUrgente: entity.TipoOrigen.Equals("ODECO", StringComparison.OrdinalIgnoreCase),
            CodCon: entity.RegSoc,
            NumeroMedidor: numeroMedidor);
}

public static class VerificacionMapper
{
    public static VerificacionDto ToDto(
        Verificacion entity,
        string? nombreCliente = null,
        string? nombreMecanico = null) =>
        new(
            Id: entity.Id,
            TipoOrigen: entity.TipoOrigen,
            IdOrigen: entity.IdOrigen,
            CodCon: entity.RegSoc,
            IdUsuarioMecanico: entity.IdUsuarioMecanico,
            IdMedidor: entity.CodMedidor.ToString(),
            FechaVerificacion: entity.FechaVerificacion,
            Estado: entity.Estado,
            Resultado: entity.Resultado,
            NombreCliente: nombreCliente,
            NombreMecanico: nombreMecanico,
            Ensayo: entity.Ensayo is null
                ? null
                : new EnsayoVerificacionDto(
                    Id: entity.Ensayo.Id,
                    Condiciones: entity.Ensayo.Condiciones,
                    LecturaInicial: entity.Ensayo.LecturaInicial,
                    LecturaFinal: entity.Ensayo.LecturaFinal,
                    VolumenPatron: entity.Ensayo.VolumenPatron,
                    Caudal: entity.Ensayo.Caudal,
                    VolumenRegistrado: entity.Ensayo.VolumenRegistrado,
                    Error: entity.Ensayo.Error,
                    Fugas: entity.Ensayo.Fugas,
                    Observaciones: entity.Ensayo.Observaciones),
            Participantes: entity.Participantes
                .OrderBy(p => p.Id)
                .Select(p => new ParticipanteVerificacionDto(p.Id, p.Nombre, p.Cargo, p.Rol))
                .ToList());
}
