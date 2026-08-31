using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Domain.Entities;

namespace Cosaalt.API.Application.Mappers;

public static class CatalogoMapper
{
    public static MotivoCambioDto ToDto(MotivoCambioMedidorDbo motivo) =>
        new(
            motivo.CodMoCaMe,
            motivo.NomMoCaMe,
            motivo.DesMoCaMe,
            motivo.EstMoCaMe
        );
}

public static class SolicitudMapper
{
    public static SolicitudBandejaDto FromDetalleLectura(
        DetalleSolicitudLectura detalle,
        SolicitudLectura solicitud,
        Conexion? conexion,
        (string? NumeroMedidor, string? MarcaMedidor) medidor,
        string estado)
    {
        return new SolicitudBandejaDto(
            Id: $"LEC-{detalle.Id}",
            TipoOrigen: "LECTURA",
            Estado: estado,
            EsUrgente: false,
            CodCon: conexion?.CodCon ?? 0,
            NombreCliente: conexion?.NomSoc ?? "Sin nombre",
            Direccion: Cosaalt.API.Infrastructure.Repositories.BandejaOdecoBuilder.BuildDireccion(conexion?.Predio),
            Categoria: null,
            Ruta: null,
            Recorrido: null,
            NumeroMedidor: medidor.NumeroMedidor,
            MarcaMedidor: medidor.MarcaMedidor,
            LecturaAnterior: detalle.LecturaAnterior,
            LecturaActual: detalle.LecturaActual,
            Consumo: detalle.Consumo,
            MotivoObservacion: solicitud.DescripcionObservacion ?? $"Código {solicitud.CodigoObservacion}",
            FechaSolicitud: solicitud.FechaEmision,
            FolioOdeco: null,
            ConclusionOdeco: null,
            // La ubicación es la de la conexión (el medidor sale de dbo, sin coords).
            Latitud: conexion?.CooX2Con,
            Longitud: conexion?.CooY2Con);
    }
}

public static class EjecucionMapper
{
    public static EjecucionCambio ToEntity(EjecucionCambioRequestDto dto) =>
        new()
        {
            TipoOrigen = dto.TipoOrigen,
            IdOrigen = dto.IdOrigen,
            IdUsuarioApp = dto.IdUsuarioApp,
            FechaHoraEjecucion = dto.FechaHoraEjecucion,
            NumeroMedidorRetirado = dto.NumeroMedidorRetirado,
            MarcaRetirado = dto.MarcaRetirado,
            LecturaRetiro = dto.LecturaRetiro,
            IdMotivo = dto.IdMotivo,
            NumeroMedidorInstalado = dto.NumeroMedidorInstalado,
            MarcaInstalado = dto.MarcaInstalado,
            ObservacionesInstalacion = dto.ObservacionesInstalacion,
            LatLong = dto.LatLong,
            Sincronizado = true,
            Evidencias = dto.Evidencias?.Select(e => new EvidenciaFotografica
            {
                TipoFoto = e.TipoFoto,
                RutaArchivo = e.RutaArchivo
            }).ToList() ?? []
        };

    public static EjecucionCambioResponseDto ToResponse(EjecucionCambio entity) =>
        new(entity.Id, "Ejecución registrada correctamente.", entity.Sincronizado);
}

public static class RutaMapper
{    public static DetalleRuta ToEntity(DetalleRutaRequestDto dto) =>
        new()
        {
            TipoOrigen = dto.TipoOrigen,
            IdOrigen = dto.IdOrigen,
            OrdenVisita = dto.OrdenVisita,
            Estado = "Pendiente",
            SolicitudId = dto.SolicitudId,
            NombreCliente = dto.NombreCliente,
            Direccion = dto.Direccion,
            Latitud = dto.Latitud,
            Longitud = dto.Longitud
        };

    public static DetalleRutaResponseDto ToResponse(
        DetalleRuta entity,
        IReadOnlyDictionary<string, (int? CodCon, string? NumeroMedidor)>? resolucion = null)
    {
        int? codCon = null;
        string? medidor = null;

        if (resolucion?.TryGetValue($"{entity.TipoOrigen}-{entity.IdOrigen}", out var r) == true)
        {
            codCon = r.CodCon;
            medidor = r.NumeroMedidor;
        }

        return new DetalleRutaResponseDto(
            Id: entity.Id,
            SolicitudId: entity.SolicitudId,
            TipoOrigen: entity.TipoOrigen,
            OrdenVisita: entity.OrdenVisita,
            Estado: entity.Estado,
            NombreCliente: entity.NombreCliente,
            Direccion: entity.Direccion,
            Latitud: entity.Latitud,
            Longitud: entity.Longitud,
            EsUrgente: entity.TipoOrigen == "ODECO",
            CodCon: codCon,
            NumeroMedidor: medidor);
    }

    public static RutaAsignadaResponseDto ToResponse(
        AsignacionRuta entity,
        string nombreTecnico,
        IReadOnlyDictionary<string, (int? CodCon, string? NumeroMedidor)>? resolucion = null) =>
        new(
            IdAsignacion: entity.Id,
            IdUsuarioTecnico: entity.IdUsuarioApp,
            NombreTecnico: nombreTecnico,
            FechaAsignacion: entity.FechaAsignacion,
            Estado: entity.Estado,
            TotalParadas: entity.Detalles.Count,
            Detalles: entity.Detalles
                .OrderBy(d => d.OrdenVisita)
                .Select(d => ToResponse(d, resolucion))
                .ToList());
}

public static class VerificacionMapper
{
    public static Verificacion ToEntity(TomarVerificacionRequestDto request) =>
        new()
        {
            TipoOrigen = request.TipoOrigen,
            IdOrigen = request.IdOrigen,
            CodCon = request.CodCon,
            IdUsuarioMecanico = request.IdUsuarioMecanico,
            IdMedidor = request.IdMedidor,
            FechaVerificacion = DateTime.Now,
            Estado = "EnCurso",
            Resultado = null
        };

    public static VerificacionDto ToDto(
        Verificacion entity,
        string? nombreCliente = null,
        string? nombreMecanico = null) =>
        new(
            Id: entity.Id,
            TipoOrigen: entity.TipoOrigen,
            IdOrigen: entity.IdOrigen,
            CodCon: entity.CodCon,
            IdUsuarioMecanico: entity.IdUsuarioMecanico,
            IdMedidor: entity.IdMedidor,
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
                .Select(p => new ParticipanteVerificacionDto(
                    Id: p.Id,
                    Nombre: p.Nombre,
                    Cargo: p.Cargo,
                    Rol: p.Rol))
                .ToList());
}
