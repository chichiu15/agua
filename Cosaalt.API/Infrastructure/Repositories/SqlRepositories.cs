using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

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

        if (user is null) return null;

        var token = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{user.Id}:{user.NombreUsuario}:{DateTime.UtcNow.Ticks}"));
        return new LoginResponseDto(user.Id, user.NombreCompleto, user.Rol, token);
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

        // Obtener IDs de solicitudes que ya tienen ruta asignada
        var idsAsignados = await _context.DetallesRuta
            .AsNoTracking()
            .Select(d => d.TipoOrigen + "-" + d.IdOrigen)
            .Distinct()
            .ToListAsync();

        var detalles = await _context.DetallesSolicitudLectura
            .AsNoTracking()
            .Include(d => d.Solicitud)
            .Include(d => d.Socio)
            .ThenInclude(s => s.Medidor)
            .ToListAsync();

        foreach (var detalle in detalles)
        {
            var solicitudId = $"LEC-{detalle.Id}";
            var estado = idsAsignados.Contains($"LECTURA-{detalle.Id}")
                ? "Asignada" : "Pendiente";
            solicitudes.Add(SolicitudMapper.FromDetalleLectura(
                detalle, detalle.Solicitud, detalle.Socio, detalle.Socio.Medidor, estado));
        }

        var reclamos = await _context.ReclamosOdeco
            .AsNoTracking()
            .Include(r => r.Socio)
            .ThenInclude(s => s.Medidor)
            .ToListAsync();

        foreach (var reclamo in reclamos)
        {
            var estado = idsAsignados.Contains($"ODECO-{reclamo.Folio}")
                ? "Asignada" : "Pendiente";
            solicitudes.Add(SolicitudMapper.FromReclamoOdeco(
                reclamo, reclamo.Socio, reclamo.Socio.Medidor, estado));
        }

        var filtradas = filtro?.ToLowerInvariant() switch
        {
            "pendientes" => solicitudes.Where(s => s.Estado == "Pendiente").ToList(),
            "urgentes" => solicitudes.Where(s => s.EsUrgente && s.Estado == "Pendiente").ToList(),
            "odeco" => solicitudes.Where(s => s.TipoOrigen == "ODECO").ToList(),
            "lectura" => solicitudes.Where(s => s.TipoOrigen == "LECTURA").ToList(),
            _ => solicitudes
        };

        var resumen = new DashboardResumenDto(
            OdecoUrgentes: solicitudes.Count(s => s.TipoOrigen == "ODECO" && s.EsUrgente && s.Estado == "Pendiente"),
            LecturasDelMes: solicitudes.Count(s => s.TipoOrigen == "LECTURA" && s.Estado == "Pendiente"),
            CompletadasHoy: 0);

        return new SolicitudesResponseDto(resumen, filtradas);
    }

    public async Task<SolicitudBandejaDto?> ObtenerPorIdAsync(string id)
    {
        var result = await ObtenerSolicitudesAsync();
        return result.Solicitudes.FirstOrDefault(s => s.Id == id);
    }
}

public class SqlEjecucionRepository : IEjecucionRepository
{
    private readonly CosaaltDbContext _context;

    public SqlEjecucionRepository(CosaaltDbContext context) => _context = context;

    public async Task<EjecucionCambioResponseDto> RegistrarAsync(EjecucionCambioRequestDto request)
    {
        var entity = EjecucionMapper.ToEntity(request);
        _context.EjecucionesCambio.Add(entity);
        await _context.SaveChangesAsync();
        return EjecucionMapper.ToResponse(entity);
    }

    public async Task<IReadOnlyList<EjecucionHistorialDto>> ObtenerHistorialAsync(int? registroSocio = null)
    {
        var ejecuciones = await _context.EjecucionesCambio
            .AsNoTracking()
            .Include(e => e.Usuario)
            .Include(e => e.Motivo)
            .Include(e => e.Evidencias)
            .OrderByDescending(e => e.FechaHoraEjecucion)
            .Take(100)
            .ToListAsync();

        var foliosOdeco = ejecuciones
            .Where(e => e.TipoOrigen == "ODECO")
            .Select(e => int.TryParse(e.IdOrigen, out var folio) ? folio : 0)
            .Where(folio => folio > 0)
            .Distinct()
            .ToList();

        var idsLectura = ejecuciones
            .Where(e => e.TipoOrigen == "LECTURA")
            .Select(e => int.TryParse(e.IdOrigen, out var id) ? id : 0)
            .Where(id => id > 0)
            .Distinct()
            .ToList();

        var sociosOdeco = foliosOdeco.Count == 0
            ? new Dictionary<int, Socio>()
            : await ResolverSociosOdecoAsync(foliosOdeco);

        var sociosLectura = idsLectura.Count == 0
            ? new Dictionary<int, Socio>()
            : await _context.DetallesSolicitudLectura
                .AsNoTracking()
                .Where(d => idsLectura.Contains(d.Id))
                .Select(d => new { d.Id, d.Socio })
                .ToListAsync()
                .ContinueWith(t => t.Result.ToDictionary(x => x.Id, x => x.Socio));

        var historial = ejecuciones.Select(e =>
        {
            Socio? socio = e.TipoOrigen == "ODECO"
                ? (int.TryParse(e.IdOrigen, out var folio)
                    ? sociosOdeco.GetValueOrDefault(folio)
                    : null)
                : (int.TryParse(e.IdOrigen, out var id)
                    ? sociosLectura.GetValueOrDefault(id)
                    : null);

            return new EjecucionHistorialDto(
                IdEjecucion: e.Id,
                TipoOrigen: e.TipoOrigen,
                IdOrigen: e.IdOrigen,
                SolicitudId: $"{e.TipoOrigen}-{e.IdOrigen}",
                FechaHoraEjecucion: e.FechaHoraEjecucion,
                RegistroSocio: socio?.RegistroSocio,
                NombreCliente: socio?.Nombre,
                Direccion: socio?.Direccion,
                NumeroMedidorRetirado: e.NumeroMedidorRetirado,
                MarcaRetirado: e.MarcaRetirado,
                LecturaRetiro: e.LecturaRetiro,
                NumeroMedidorInstalado: e.NumeroMedidorInstalado,
                MarcaInstalado: e.MarcaInstalado,
                Observaciones: e.ObservacionesInstalacion,
                NombreTecnico: e.Usuario?.NombreCompleto,
                MotivoDescripcion: e.Motivo?.Descripcion,
                Evidencias: e.Evidencias
                    .Select(ev => new EvidenciaHistorialDto(ev.TipoFoto, ev.RutaArchivo))
                    .ToList());
        }).ToList();

        if (registroSocio is int registro)
        {
            historial = historial.Where(h => h.RegistroSocio == registro).ToList();
        }

        return historial;
    }

    /// <summary>
    /// Resuelve el Socio (de medidores.Socio) de cada reclamo ODECO, cruzando
    /// dbo.Reclamos por CodRec -> Conexi�n.NomSoc con medidores.Socio.Nombre.
    /// Es la misma fuente que genera las solicitudes (SolicitudVirtualService),
    /// no medidores.ReclamosODECO.
    /// </summary>
    private async Task<Dictionary<int, Socio>> ResolverSociosOdecoAsync(List<int> folios)
    {
        var reclamos = await _context.Reclamos
            .AsNoTracking()
            .Include(r => r.Conexion)
            .Where(r => folios.Contains(r.CodRec))
            .ToListAsync();

        var nombres = reclamos
            .Select(r => r.Conexion?.NomSoc?.Trim())
            .Where(n => !string.IsNullOrEmpty(n))
            .Distinct()
            .ToList();

        var socios = nombres.Count == 0
            ? new List<Socio>()
            : await _context.Socios
                .AsNoTracking()
                .Where(s => nombres.Contains(s.Nombre.Trim()))
                .ToListAsync();

        var socioPorNombre = socios
            .ToDictionary(s => s.Nombre.Trim(), StringComparer.OrdinalIgnoreCase);

        return reclamos
            .Where(r => r.Conexion?.NomSoc != null
                && socioPorNombre.ContainsKey(r.Conexion.NomSoc.Trim()))
            .ToDictionary(
                r => r.CodRec,
                r => socioPorNombre[r.Conexion!.NomSoc!.Trim()]);
    }
}
