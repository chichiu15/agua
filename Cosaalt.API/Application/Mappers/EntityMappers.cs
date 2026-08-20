using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Domain.Entities;

namespace Cosaalt.API.Application.Mappers;

public static class CatalogoMapper
{
    public static MotivoCambioDto ToDto(MotivoCambioMedidor motivo) =>
        new(motivo.Id, motivo.Descripcion);
}

public static class SolicitudMapper
{
    public static SolicitudBandejaDto FromDetalleLectura(
        DetalleSolicitudLectura detalle,
        SolicitudLectura solicitud,
        Socio socio,
        Medidor? medidor,
        string estado)
    {
        var esVencida = EsSolicitudVencida(
            tipoOrigen: "LECTURA",
            fechaSolicitud: solicitud.FechaEmision,
            estado: estado);

        return new SolicitudBandejaDto(
            Id: $"LEC-{detalle.Id}",
            TipoOrigen: "LECTURA",
            Estado: estado,
            EsUrgente: false,
            EsVencida: esVencida,
            RegistroSocio: socio.RegistroSocio,
            NombreCliente: socio.Nombre,
            Direccion: socio.Direccion,
            Categoria: socio.Categoria,
            Ruta: socio.Ruta,
            Recorrido: socio.Recorrido,
            NumeroMedidor: medidor?.NumeroMedidor,
            MarcaMedidor: medidor?.Marca,
            LecturaAnterior: detalle.LecturaAnterior,
            LecturaActual: detalle.LecturaActual,
            Consumo: detalle.Consumo,
            MotivoObservacion: solicitud.DescripcionObservacion ?? $"Código {solicitud.CodigoObservacion}",
            FechaSolicitud: solicitud.FechaEmision,
            FolioOdeco: null,
            ConclusionOdeco: null,
            Latitud: medidor?.Latitud,
            Longitud: medidor?.Longitud);
    }

    public static SolicitudBandejaDto FromReclamoOdeco(
        ReclamoOdeco reclamo,
        Socio socio,
        Medidor? medidor,
        string estado)
    {
        var esUrgente = reclamo.Conclusion?.Contains("CAMBIAR", StringComparison.OrdinalIgnoreCase) == true
            || reclamo.PrioridadNota?.Contains("URGENTE", StringComparison.OrdinalIgnoreCase) == true
            || reclamo.PrioridadNota?.Contains("24", StringComparison.OrdinalIgnoreCase) == true;

        var esVencida = EsSolicitudVencida(
            tipoOrigen: "ODECO",
            fechaSolicitud: reclamo.FechaReclamo,
            estado: estado);

        return new SolicitudBandejaDto(
            Id: $"ODECO-{reclamo.Folio}",
            TipoOrigen: "ODECO",
            Estado: estado,
            EsUrgente: esUrgente,
            EsVencida: esVencida,
            RegistroSocio: socio.RegistroSocio,
            NombreCliente: socio.Nombre,
            Direccion: socio.Direccion,
            Categoria: socio.Categoria,
            Ruta: socio.Ruta,
            Recorrido: socio.Recorrido,
            NumeroMedidor: medidor?.NumeroMedidor,
            MarcaMedidor: medidor?.Marca,
            LecturaAnterior: reclamo.LecturaAnteriorAnalisis,
            LecturaActual: reclamo.LecturaActualAnalisis,
            Consumo: reclamo.ConsumoAnalisis,
            MotivoObservacion: reclamo.MotivoReclamo ?? reclamo.Comentarios,
            FechaSolicitud: reclamo.FechaReclamo,
            FolioOdeco: reclamo.Folio,
            ConclusionOdeco: reclamo.Conclusion,
            Latitud: medidor?.Latitud,
            Longitud: medidor?.Longitud);
    }

    private static bool EsSolicitudVencida(string tipoOrigen, DateTime fechaSolicitud, string estado)
    {
        if (!estado.Equals("Pendiente", StringComparison.OrdinalIgnoreCase))
            return false;

        var ahora = DateTime.Now;

        return tipoOrigen.ToUpperInvariant() switch
        {
            "ODECO" => fechaSolicitud.AddHours(24) < ahora,
            "LECTURA" => fechaSolicitud.AddMonths(1) < ahora,
            _ => false
        };
    }
}

public static class EjecucionMapper
{
    public static EjecucionCambio ToEntity(EjecucionCambioRequestDto dto) =>
        new()
        {
            TipoOrigen = dto.TipoOrigen.Trim().ToUpperInvariant(),
            IdOrigen = dto.IdOrigen.Trim(),
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
{
    public static DetalleRuta ToEntity(DetalleRutaRequestDto dto) =>
        new()
        {
            TipoOrigen = dto.TipoOrigen.Trim().ToUpperInvariant(),
            IdOrigen = dto.IdOrigen.Trim(),
            OrdenVisita = dto.OrdenVisita,
            Estado = "Pendiente",
            SolicitudId = dto.SolicitudId.Trim(),
            NombreCliente = dto.NombreCliente.Trim(),
            Direccion = dto.Direccion.Trim(),
            Latitud = dto.Latitud,
            Longitud = dto.Longitud
        };

    public static DetalleRutaResponseDto ToResponse(DetalleRuta entity) =>
        new(
            Id: entity.Id,
            SolicitudId: entity.SolicitudId,
            TipoOrigen: entity.TipoOrigen,
            OrdenVisita: entity.OrdenVisita,
            Estado: entity.Estado,
            NombreCliente: entity.NombreCliente,
            Direccion: entity.Direccion,
            Latitud: entity.Latitud,
            Longitud: entity.Longitud,
            EsUrgente: entity.TipoOrigen == "ODECO");

    public static RutaAsignadaResponseDto ToResponse(AsignacionRuta entity, string nombreTecnico) =>
        new(
            IdAsignacion: entity.Id,
            IdUsuarioTecnico: entity.IdUsuarioApp,
            NombreTecnico: nombreTecnico,
            FechaAsignacion: entity.FechaAsignacion,
            Estado: entity.Estado,
            TotalParadas: entity.Detalles.Count,
            Detalles: entity.Detalles.OrderBy(d => d.OrdenVisita).Select(ToResponse).ToList());
}
