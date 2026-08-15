using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
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

        var detalles = await _context.DetallesSolicitudLectura
            .AsNoTracking()
            .Include(d => d.Solicitud)
            .Include(d => d.Socio)
            .ThenInclude(s => s.Medidor)
            .ToListAsync();

        foreach (var detalle in detalles)
        {
            solicitudes.Add(SolicitudMapper.FromDetalleLectura(
                detalle, detalle.Solicitud, detalle.Socio, detalle.Socio.Medidor, "Pendiente"));
        }

        var reclamos = await _context.ReclamosOdeco
            .AsNoTracking()
            .Include(r => r.Socio)
            .ThenInclude(s => s.Medidor)
            .ToListAsync();

        foreach (var reclamo in reclamos)
        {
            solicitudes.Add(SolicitudMapper.FromReclamoOdeco(
                reclamo, reclamo.Socio, reclamo.Socio.Medidor, "Pendiente"));
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
}
