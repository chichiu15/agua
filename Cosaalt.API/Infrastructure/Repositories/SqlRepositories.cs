using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;
using Cosaalt.API.Domain.Entities;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlAuthRepository : IAuthRepository
{
    private readonly CosaaltDbContext _context;

    public SqlAuthRepository(CosaaltDbContext context) => _context = context;

    public async Task<LoginResponseDto?> LoginAsync(string usuario, string contrasena)
    {
        var user = await _context.UsuariosApp
            .AsNoTracking()
            .FirstOrDefaultAsync(u =>
                u.NombreUsuario == usuario &&
                u.ContrasenaHash == contrasena &&
                u.Activo);

        if (user is null)
            return null;

        // NOTA:
        // Sigue siendo un token provisional en Base64.
        // No se cambia a JWT real en este archivo para no introducir dependencias
        // de autenticación sin revisar el .csproj y la configuración final de seguridad.
        var token = Convert.ToBase64String(
            System.Text.Encoding.UTF8.GetBytes(
                $"{user.Id}:{user.NombreUsuario}:{DateTime.UtcNow.Ticks}"));

        return new LoginResponseDto(
            user.Id,
            user.NombreCompleto,
            user.Rol,
            token);
    }
}

public class SqlCatalogoRepository : ICatalogoRepository
{
    private readonly CosaaltDbContext _context;

    public SqlCatalogoRepository(CosaaltDbContext context) => _context = context;

    public async Task<IReadOnlyList<MotivoCambioDto>> ObtenerMotivosAsync()
    {
        return await _context.MotivosCambio
            .AsNoTracking()
            .Where(m => m.Activo)
            .OrderBy(m => m.Id)
            .Select(m => new MotivoCambioDto(m.Id, m.Descripcion))
            .ToListAsync();
    }
}

public class SqlSolicitudRepository : ISolicitudRepository
{
    private readonly CosaaltDbContext _context;

    public SqlSolicitudRepository(CosaaltDbContext context) => _context = context;

    public async Task<SolicitudesResponseDto> ObtenerSolicitudesAsync(string? filtro = null)
    {
        var solicitudes = new List<SolicitudBandejaDto>();

        // Cargamos también SolicitudId porque es el identificador canónico que
        // Flutter envía (LEC-xxx / ODECO-xxx). Para datos antiguos conservamos
        // además la comparación por TipoOrigen + IdOrigen.
        var estadosRuta = await _context.DetallesRuta
            .AsNoTracking()
            .Select(d => new
            {
                d.SolicitudId,
                d.TipoOrigen,
                d.IdOrigen,
                EstadoDetalle = d.Estado,
                EstadoRuta = d.Asignacion.Estado
            })
            .ToListAsync();

        var detalles = await _context.DetallesSolicitudLectura
            .AsNoTracking()
            .Include(d => d.Solicitud)
            .Include(d => d.Socio)
            .ThenInclude(s => s.Medidores)
            .ToListAsync();

        foreach (var detalle in detalles)
        {
            var solicitudId = $"LEC-{detalle.Id}";
            var idOrigen = detalle.Id.ToString();

            var coincidencias = estadosRuta
                .Where(r =>
                    CoincideSolicitud(
                        r.SolicitudId,
                        r.TipoOrigen,
                        r.IdOrigen,
                        solicitudId,
                        "LECTURA",
                        idOrigen))
                .ToList();

            var estado = ResolverEstadoSolicitud(coincidencias
                .Select(r => (r.EstadoDetalle, r.EstadoRuta)));

            solicitudes.Add(
                SolicitudMapper.FromDetalleLectura(
                    detalle,
                    detalle.Solicitud,
                    detalle.Socio,
                    ObtenerMedidorActivo(detalle.Socio),
                    estado));
        }

        var reclamos = await _context.ReclamosOdeco
            .AsNoTracking()
            .Include(r => r.Socio)
            .ThenInclude(s => s.Medidores)
            .ToListAsync();

        foreach (var reclamo in reclamos)
        {
            var solicitudId = $"ODECO-{reclamo.Folio}";
            var idOrigen = reclamo.Folio.ToString();

            var coincidencias = estadosRuta
                .Where(r =>
                    CoincideSolicitud(
                        r.SolicitudId,
                        r.TipoOrigen,
                        r.IdOrigen,
                        solicitudId,
                        "ODECO",
                        idOrigen))
                .ToList();

            var estado = ResolverEstadoSolicitud(coincidencias
                .Select(r => (r.EstadoDetalle, r.EstadoRuta)));

            solicitudes.Add(
                SolicitudMapper.FromReclamoOdeco(
                    reclamo,
                    reclamo.Socio,
                    ObtenerMedidorActivo(reclamo.Socio),
                    estado));
        }

        var filtradas = filtro?.Trim().ToLowerInvariant() switch
        {
            "pendientes" => solicitudes
                .Where(s => s.Estado.Equals("Pendiente", StringComparison.OrdinalIgnoreCase))
                .ToList(),

            "urgentes" => solicitudes
                .Where(s => s.EsUrgente && s.Estado.Equals("Pendiente", StringComparison.OrdinalIgnoreCase))
                .ToList(),

            "vencidas" => solicitudes
                .Where(s => s.EsVencida && s.Estado.Equals("Pendiente", StringComparison.OrdinalIgnoreCase))
                .ToList(),

            "asignadas" => solicitudes
                .Where(s => s.Estado.Equals("Asignada", StringComparison.OrdinalIgnoreCase))
                .ToList(),

            "odeco" => solicitudes
                .Where(s => s.TipoOrigen.Equals("ODECO", StringComparison.OrdinalIgnoreCase))
                .ToList(),

            "lectura" => solicitudes
                .Where(s => s.TipoOrigen.Equals("LECTURA", StringComparison.OrdinalIgnoreCase))
                .ToList(),

            _ => solicitudes
        };

        // Fuente principal: ejecuciones efectivamente registradas hoy.
        // Como durante desarrollo también se marcan DetalleRuta manualmente desde SQL,
        // se agrega un fallback para rutas de hoy sin duplicar solicitudes.
        var hoy = DateTime.Today;

        var completadasPorEjecucion = await _context.EjecucionesCambio
            .AsNoTracking()
            .Where(e => e.FechaHoraEjecucion.Date == hoy)
            .Select(e => e.TipoOrigen + "|" + e.IdOrigen)
            .Distinct()
            .ToListAsync();

        var completadasPorRuta = await _context.DetallesRuta
            .AsNoTracking()
            .Where(d =>
                d.Asignacion.FechaAsignacion.Date == hoy &&
                d.Estado == "Completada")
            .Select(d => d.TipoOrigen + "|" + d.IdOrigen)
            .Distinct()
            .ToListAsync();

        var completadasHoy = completadasPorEjecucion
            .Concat(completadasPorRuta)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Count();

        var resumen = new DashboardResumenDto(
            OdecoUrgentes: solicitudes.Count(s =>
                s.TipoOrigen.Equals("ODECO", StringComparison.OrdinalIgnoreCase) &&
                s.EsUrgente &&
                s.Estado.Equals("Pendiente", StringComparison.OrdinalIgnoreCase)),
            LecturasDelMes: solicitudes.Count(s =>
                s.TipoOrigen.Equals("LECTURA", StringComparison.OrdinalIgnoreCase) &&
                s.Estado.Equals("Pendiente", StringComparison.OrdinalIgnoreCase)),
            CompletadasHoy: completadasHoy);

        return new SolicitudesResponseDto(
            resumen,
            filtradas);
    }

    public async Task<SolicitudBandejaDto?> ObtenerPorIdAsync(string id)
    {
        var result = await ObtenerSolicitudesAsync();

        return result.Solicitudes.FirstOrDefault(s =>
            s.Id.Equals(id, StringComparison.OrdinalIgnoreCase));
    }

    private static bool CoincideSolicitud(
        string? solicitudIdGuardado,
        string? tipoOrigenGuardado,
        string? idOrigenGuardado,
        string solicitudIdEsperado,
        string tipoOrigenEsperado,
        string idOrigenEsperado)
    {
        // Primera opción: identificador canónico guardado en DetalleRuta.
        if (!string.IsNullOrWhiteSpace(solicitudIdGuardado) &&
            solicitudIdGuardado.Trim().Equals(
                solicitudIdEsperado,
                StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        // Compatibilidad con registros creados antes de utilizar SolicitudId
        // consistentemente: normalizamos espacios y mayúsculas.
        return (tipoOrigenGuardado ?? string.Empty)
                   .Trim()
                   .Equals(tipoOrigenEsperado, StringComparison.OrdinalIgnoreCase)
            && (idOrigenGuardado ?? string.Empty)
                   .Trim()
                   .Equals(idOrigenEsperado, StringComparison.OrdinalIgnoreCase);
    }

    private static Medidor? ObtenerMedidorActivo(Socio socio) =>
        socio.Medidores
            .Where(m => string.Equals(m.Estado, "Activo", StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(m => m.FechaInstalacion)
            .FirstOrDefault();

    private static string ResolverEstadoSolicitud(
        IEnumerable<(string EstadoDetalle, string EstadoRuta)> coincidencias)
    {
        var lista = coincidencias.ToList();

        if (lista.Any(x =>
            x.EstadoDetalle.Equals("Completada", StringComparison.OrdinalIgnoreCase)))
        {
            return "Completada";
        }

        if (lista.Any(x =>
            x.EstadoRuta.Equals("Planificado", StringComparison.OrdinalIgnoreCase) ||
            x.EstadoRuta.Equals("EnCurso", StringComparison.OrdinalIgnoreCase)))
        {
            return "Asignada";
        }

        return "Pendiente";
    }
}

public class SqlEjecucionRepository : IEjecucionRepository
{
    private readonly CosaaltDbContext _context;

    public SqlEjecucionRepository(CosaaltDbContext context) => _context = context;

    public async Task<EjecucionCambioResponseDto> RegistrarAsync(
        EjecucionCambioRequestDto request)
    {
        await using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            var entity = await CambioMedidorPersistence.GuardarAsync(
                _context,
                request,
                exigirRutaActiva: true);

            await transaction.CommitAsync();
            return EjecucionMapper.ToResponse(entity);
        }
        catch
        {
            await transaction.RollbackAsync();
            _context.ChangeTracker.Clear();
            throw;
        }
    }
}