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

        var usuarioValido = await context.UsuariosApp
            .AsNoTracking()
            .AnyAsync(u => u.Id == request.IdUsuarioApp && u.Activo);

        if (!usuarioValido)
            throw new InvalidOperationException("El usuario que ejecuta el cambio no existe o está inactivo.");

        var registroSocio = await ResolverRegistroSocioAsync(context, tipoOrigen, idOrigen);

        var medidorActual = await context.Medidores
            .Where(m =>
                m.RegistroSocio == registroSocio &&
                m.Estado != null &&
                m.Estado.ToUpper() == "ACTIVO")
            .OrderByDescending(m => m.FechaInstalacion)
            .FirstOrDefaultAsync();

        if (medidorActual is null)
            throw new InvalidOperationException("El socio no tiene un medidor activo registrado.");

        if (!medidorActual.NumeroMedidor.Equals(
                request.NumeroMedidorRetirado.Trim(),
                StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"El medidor retirado no coincide con el medidor activo del socio. Activo: {medidorActual.NumeroMedidor}.");
        }

        var numeroNuevo = request.NumeroMedidorInstalado.Trim();

        if (numeroNuevo.Equals(medidorActual.NumeroMedidor, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("El medidor instalado debe ser distinto al medidor retirado.");

        var nuevoYaExiste = await context.Medidores
            .AsNoTracking()
            .AnyAsync(m => m.NumeroMedidor == numeroNuevo);

        if (nuevoYaExiste)
            throw new InvalidOperationException("El número del medidor instalado ya existe en la base de datos.");

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

        // El historial permanece en Medidor: el viejo se conserva como Retirado
        // y el nuevo queda ligado al MISMO socio como Activo.
        medidorActual.Estado = "Retirado";

        // Persistimos el retiro antes de insertar el nuevo para que el índice
        // filtrado único (un solo Activo por socio) no pueda chocar por orden
        // de operaciones. El caller mantiene una transacción, así que si algo
        // falla después, este cambio también se revierte.
        await context.SaveChangesAsync();

        var medidorNuevo = new Medidor
        {
            NumeroMedidor = numeroNuevo,
            Marca = request.MarcaInstalado?.Trim(),
            RegistroSocio = registroSocio,
            FechaInstalacion = fechaEjecucion,
            Estado = "Activo",
            // Conservamos la ubicación física del suministro. En Sprint futuro
            // puede sustituirse por GPS capturado en campo.
            Latitud = medidorActual.Latitud,
            Longitud = medidorActual.Longitud
        };

        context.Medidores.Add(medidorNuevo);

        // Fuerza los datos históricos del retirado desde la BD y no desde texto editable.
        var normalizado = request with
        {
            TipoOrigen = tipoOrigen,
            IdOrigen = idOrigen,
            FechaHoraEjecucion = fechaEjecucion,
            NumeroMedidorRetirado = medidorActual.NumeroMedidor,
            MarcaRetirado = medidorActual.Marca,
            NumeroMedidorInstalado = numeroNuevo,
            MarcaInstalado = request.MarcaInstalado?.Trim()
        };

        var ejecucion = EjecucionMapper.ToEntity(normalizado);
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

    private static async Task<int> ResolverRegistroSocioAsync(
        CosaaltDbContext context,
        string tipoOrigen,
        string idOrigen)
    {
        if (!int.TryParse(idOrigen, out var idNumerico))
            throw new InvalidOperationException("IdOrigen debe ser numérico para ODECO/LECTURA.");

        if (tipoOrigen == "LECTURA")
        {
            var registro = await context.DetallesSolicitudLectura
                .AsNoTracking()
                .Where(d => d.Id == idNumerico)
                .Select(d => (int?)d.RegistroSocio)
                .FirstOrDefaultAsync();

            return registro
                ?? throw new InvalidOperationException("No se encontró la solicitud de LECTURA indicada.");
        }

        var registroOdeco = await context.ReclamosOdeco
            .AsNoTracking()
            .Where(r => r.Folio == idNumerico)
            .Select(r => (int?)r.RegistroSocio)
            .FirstOrDefaultAsync();

        return registroOdeco
            ?? throw new InvalidOperationException("No se encontró el reclamo ODECO indicado.");
    }
}
