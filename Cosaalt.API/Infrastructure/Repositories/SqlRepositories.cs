using System.Data;
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
        var user = await _context.Usuarios
            .AsNoTracking()
            .Include(u => u.Rol)
            .Include(u => u.Funcionario)
                .ThenInclude(f => f!.Persona)
            .FirstOrDefaultAsync(u =>
                u.NombreUsuario == usuario &&
                u.HashPassword == contrasena &&
                u.Activo);

        if (user is null) return null;

        var token = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{user.Id}:{user.NombreUsuario}:{DateTime.UtcNow.Ticks}"));
        return new LoginResponseDto(user.Id, user.NombreCompleto, user.Rol.Nombre, token);
    }
}

public class SqlCatalogoRepository : ICatalogoRepository
{
    private readonly CosaaltDbContext _context;

    public SqlCatalogoRepository(CosaaltDbContext context) => _context = context;

    public async Task<IReadOnlyList<MotivoCambioDto>> ObtenerMotivosAsync(bool incluirInactivos = false)
    {
        var query = _context.MotivosCambioMedidorDbo.AsNoTracking().AsQueryable();
        if (!incluirInactivos)
            query = query.Where(m => m.EstMoCaMe);

        return await query
            .OrderBy(m => m.CodMoCaMe)
            .Select(m => new MotivoCambioDto(
                m.CodMoCaMe,
                m.NomMoCaMe.Trim(),
                m.DesMoCaMe == null ? null : m.DesMoCaMe.Trim(),
                m.EstMoCaMe))
            .ToListAsync();
    }

    public async Task<MotivoCambioDto> CrearMotivoAsync(GuardarMotivoCambioRequestDto request)
    {
        var nombre = request.Nombre.Trim();
        var descripcion = string.IsNullOrWhiteSpace(request.Descripcion) ? null : request.Descripcion.Trim();

        if (await _context.MotivosCambioMedidorDbo.AnyAsync(m => m.NomMoCaMe == nombre))
            throw new InvalidOperationException("Ya existe un motivo con ese nombre.");

        await using var tx = await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var max = await _context.MotivosCambioMedidorDbo
            .Select(m => (int?)m.CodMoCaMe)
            .MaxAsync() ?? 0;
        var next = max + 1;
        if (next > 99)
            throw new InvalidOperationException("No hay codigos disponibles para registrar un nuevo motivo.");

        var entity = new MotivoCambioMedidorDbo
        {
            CodMoCaMe = next,
            NomMoCaMe = nombre,
            DesMoCaMe = descripcion,
            EstMoCaMe = request.Activo
        };
        _context.MotivosCambioMedidorDbo.Add(entity);
        await _context.SaveChangesAsync();
        await tx.CommitAsync();
        return new MotivoCambioDto(entity.CodMoCaMe, entity.NomMoCaMe, entity.DesMoCaMe, entity.EstMoCaMe);
    }

    public async Task<MotivoCambioDto?> ActualizarMotivoAsync(int id, GuardarMotivoCambioRequestDto request)
    {
        var entity = await _context.MotivosCambioMedidorDbo.FirstOrDefaultAsync(m => m.CodMoCaMe == id);
        if (entity is null) return null;

        var nombre = request.Nombre.Trim();
        if (await _context.MotivosCambioMedidorDbo.AnyAsync(m => m.CodMoCaMe != id && m.NomMoCaMe == nombre))
            throw new InvalidOperationException("Ya existe otro motivo con ese nombre.");

        entity.NomMoCaMe = nombre;
        entity.DesMoCaMe = string.IsNullOrWhiteSpace(request.Descripcion) ? null : request.Descripcion.Trim();
        entity.EstMoCaMe = request.Activo;
        await _context.SaveChangesAsync();
        return new MotivoCambioDto(entity.CodMoCaMe, entity.NomMoCaMe, entity.DesMoCaMe, entity.EstMoCaMe);
    }

    public async Task<MotivoCambioDto?> CambiarEstadoMotivoAsync(int id, bool activo)
    {
        var entity = await _context.MotivosCambioMedidorDbo.FirstOrDefaultAsync(m => m.CodMoCaMe == id);
        if (entity is null) return null;
        entity.EstMoCaMe = activo;
        await _context.SaveChangesAsync();
        return new MotivoCambioDto(entity.CodMoCaMe, entity.NomMoCaMe.Trim(), entity.DesMoCaMe?.Trim(), entity.EstMoCaMe);
    }

    public async Task<IReadOnlyList<MarcaMedidorDto>> ObtenerMarcasAsync()
    {
        return await _context.MarcasDbo
            .AsNoTracking()
            .OrderBy(m => m.CodMar)
            .Select(m => new MarcaMedidorDto(m.CodMar, m.NomMar.Trim(), m.AliMar))
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

        var idsAsignados = await _context.DetallesRuta
            .AsNoTracking()
            .Select(d => d.TipoOrigen + "-" + d.IdOrigen)
            .Distinct()
            .ToListAsync();

        // LECTURA: detalles propios, socio resuelto desde dbo.Conexiones por CodCon.
        var detalles = await _context.DetallesSolicitudLectura
            .AsNoTracking()
            .Include(d => d.Solicitud)
            .Include(d => d.Conexion)
                .ThenInclude(c => c!.Predio)
            .ToListAsync();

        var codConsLectura = detalles.Select(d => d.CodCon).Distinct().ToList();
        var medidorPorCodCon = await BandejaOdecoBuilder.MedidorVigentePorCodConAsync(_context, codConsLectura);

        foreach (var detalle in detalles)
        {
            var estado = idsAsignados.Contains($"LECTURA-{detalle.Id}")
                ? "Asignada" : "Pendiente";
            solicitudes.Add(SolicitudMapper.FromDetalleLectura(
                detalle,
                detalle.Solicitud,
                detalle.Conexion,
                medidorPorCodCon.GetValueOrDefault(detalle.CodCon),
                estado));
        }

        // ODECO: lectura directa de dbo.Reclamos + Conexion + Recurrente.
        solicitudes.AddRange(await BandejaOdecoBuilder.BuildAsync(_context, BandejaOdecoBuilder.MaxTop));

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

    public async Task<IReadOnlyList<EjecucionHistorialDto>> ObtenerHistorialAsync(int? codCon = null)
    {
        var ejecuciones = await _context.EjecucionesCambio
            .AsNoTracking()
            .Include(e => e.Conexion)
                .ThenInclude(c => c!.Predio)
            .Include(e => e.Usuario)
                .ThenInclude(u => u.Funcionario)
                .ThenInclude(f => f!.Persona)
            .Include(e => e.Motivo)
            .Include(e => e.Evidencias)
            .OrderByDescending(e => e.FechaHoraEjecucion)
            .Take(100)
            .ToListAsync();

        var historial = ejecuciones
            .Where(e => codCon is null || e.CodCon == codCon)
            .Select(e => new EjecucionHistorialDto(
                IdEjecucion: e.Id,
                TipoOrigen: e.TipoOrigen,
                IdOrigen: e.IdOrigen,
                SolicitudId: $"{e.TipoOrigen}-{e.IdOrigen}",
                FechaHoraEjecucion: e.FechaHoraEjecucion,
                CodCon: e.CodCon,
                NombreCliente: e.Conexion?.NomSoc,
                Direccion: BandejaOdecoBuilder.BuildDireccion(e.Conexion?.Predio),
                NumeroMedidorRetirado: e.NumeroMedidorRetirado,
                MarcaRetirado: e.MarcaRetirado,
                LecturaRetiro: e.LecturaRetiro,
                NumeroMedidorInstalado: e.NumeroMedidorInstalado,
                MarcaInstalado: e.MarcaInstalado,
                Observaciones: e.ObservacionesInstalacion,
                NombreTecnico: e.Usuario?.NombreCompleto,
                MotivoDescripcion: e.Motivo?.NomMoCaMe,
                Evidencias: e.Evidencias
                    .Select(ev => new EvidenciaHistorialDto(ev.TipoFoto, ev.RutaArchivo))
                    .ToList()))
            .ToList();

        return historial;
    }
}