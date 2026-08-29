using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

/// <summary>
/// Única lógica de persistencia para un cambio físico de medidor.
/// La utilizan tanto POST /api/ejecuciones como la sincronización masiva,
/// evitando que ambos flujos actualicen la BD de maneras diferentes.
/// </summary>
internal static class CambioMedidorPersistence
{
    public static async Task<EjecucionCambio> GuardarAsync(
        CosaaltDbContext context,
        EjecucionCambioRequestDto request,
        bool exigirRutaActiva = true)
    {
        var tipoOrigen = request.TipoOrigen.Trim().ToUpperInvariant();
        var idOrigen = request.IdOrigen.Trim();

        if (tipoOrigen is not ("ODECO" or "LECTURA"))
            throw new InvalidOperationException("TipoOrigen debe ser ODECO o LECTURA.");

        if (string.IsNullOrWhiteSpace(idOrigen))
            throw new InvalidOperationException("IdOrigen es obligatorio.");

        if (string.IsNullOrWhiteSpace(request.NumeroMedidorInstalado))
            throw new InvalidOperationException("El número del medidor instalado es obligatorio.");

        if (request.LecturaRetiro < 0)
            throw new InvalidOperationException("La lectura de retiro no puede ser negativa.");

        var existente = await context.EjecucionesCambio
            .FirstOrDefaultAsync(e =>
                e.TipoOrigen == tipoOrigen &&
                e.IdOrigen == idOrigen);

        // Idempotencia para sincronización: si ya llegó esta ejecución,
        // devolvemos la existente y no volvemos a cambiar el medidor.
        if (existente is not null)
            return existente;

        var usuarioValido = await context.Usuarios
            .AsNoTracking()
            .AnyAsync(u => u.Id == request.IdUsuarioApp && u.Activo);

        if (!usuarioValido)
            throw new InvalidOperationException("El usuario que ejecuta el cambio no existe o está inactivo.");

        var codCon = await ResolverCodConAsync(context, tipoOrigen, idOrigen);

        // El medidor ACTUAL (vigente) sale de dbo: CambioMedidores(EstCaMe=1)+Medidores.
        // Solo lectura; nunca escribimos el espejo medidores.Medidor.
        var vigente = (await MedidorVigenteResolver.ResolverAsync(context, [codCon]))
            .GetValueOrDefault(codCon);

        if (vigente == default || vigente.Serial is null)
            throw new InvalidOperationException(
                "La conexión no tiene un medidor activo registrado en COSAALT (CambioMedidores).");

        if (!vigente.Serial.Equals(
                request.NumeroMedidorRetirado.Trim(),
                StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"El medidor retirado no coincide con el medidor activo de la conexión. Activo: {vigente.Serial}.");
        }

        var numeroNuevo = request.NumeroMedidorInstalado.Trim();

        if (numeroNuevo.Equals(vigente.Serial, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("El medidor instalado debe ser distinto al medidor retirado.");

        var nuevoYaExiste = await context.MedidoresDbo
            .AsNoTracking()
            .AnyAsync(m => m.SerMed == numeroNuevo);

        if (nuevoYaExiste)
            throw new InvalidOperationException("El número del medidor instalado ya existe en COSAALT (dbo.Medidores).");

        DetalleRuta? detalleRuta = null;

        if (exigirRutaActiva)
        {
            detalleRuta = await context.DetallesRuta
                .Include(d => d.Asignacion)
                .FirstOrDefaultAsync(d =>
                    d.TipoOrigen == tipoOrigen &&
                    d.IdOrigen == idOrigen &&
                    d.Asignacion.IdUsuarioApp == request.IdUsuarioApp &&
                    (d.Asignacion.Estado == "Planificado" ||
                     d.Asignacion.Estado == "EnCurso"));

            if (detalleRuta is null)
                throw new InvalidOperationException(
                    "No existe una parada activa asignada a este usuario para la solicitud indicada.");
        }

        var fechaEjecucion = request.FechaHoraEjecucion == default
            ? DateTime.Now
            : request.FechaHoraEjecucion;

        // No se escribe ningún espejo en medidores.Medidor: el registro del cambio
        // (retirado/instalado) queda solo en EjecucionCambio (nuestra tabla) y en
        // dbo.CambioMedidores (que actualiza el sistema de COSAALT, no la app).
        var normalizado = request with
        {
            TipoOrigen = tipoOrigen,
            IdOrigen = idOrigen,
            FechaHoraEjecucion = fechaEjecucion,
            NumeroMedidorRetirado = vigente.Serial,
            MarcaRetirado = vigente.Marca,
            NumeroMedidorInstalado = numeroNuevo,
            MarcaInstalado = request.MarcaInstalado?.Trim()
        };

        var ejecucion = EjecucionMapper.ToEntity(normalizado);
        ejecucion.CodCon = codCon;
        context.EjecucionesCambio.Add(ejecucion);

        if (detalleRuta is not null)
        {
            detalleRuta.Estado = "Completada";

            var quedanOtrosPendientes = await context.DetallesRuta
                .AsNoTracking()
                .AnyAsync(d =>
                    d.IdAsignacion == detalleRuta.IdAsignacion &&
                    d.Id != detalleRuta.Id &&
                    d.Estado != "Completada");

            detalleRuta.Asignacion.Estado = quedanOtrosPendientes
                ? "EnCurso"
                : "Finalizado";
        }

        await context.SaveChangesAsync();
        return ejecucion;
    }

    private static async Task<int> ResolverCodConAsync(
        CosaaltDbContext context,
        string tipoOrigen,
        string idOrigen)
    {
        if (!int.TryParse(idOrigen, out var idNumerico))
            throw new InvalidOperationException("IdOrigen debe ser numérico para ODECO/LECTURA.");

        if (tipoOrigen == "LECTURA")
        {
            // La conexión que originó la lectura vive en DetalleSolicitudLectura.
            var codCon = await context.DetallesSolicitudLectura
                .AsNoTracking()
                .Where(d => d.Id == idNumerico)
                .Select(d => (int?)d.CodCon)
                .FirstOrDefaultAsync();

            return codCon
                ?? throw new InvalidOperationException("No se encontró la solicitud de LECTURA indicada.");
        }

        // ODECO: la conexión del socio sale directa de dbo.Reclamos.CodCon,
        // sin tablas intermedias inventadas.
        var codConOdeco = await context.Reclamos
            .AsNoTracking()
            .Where(r => r.CodRec == idNumerico)
            .Select(r => (int?)r.CodCon)
            .FirstOrDefaultAsync();

        return codConOdeco
            ?? throw new InvalidOperationException("No se encontró el reclamo ODECO indicado.");
    }
}
