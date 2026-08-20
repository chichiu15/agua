using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlUsuarioRepository : IUsuarioRepository
{
    private readonly CosaaltDbContext _context;

    public SqlUsuarioRepository(CosaaltDbContext context) => _context = context;

    public async Task<IReadOnlyList<TecnicoDto>> ObtenerTecnicosActivosAsync()
    {
        var hoy = DateTime.Today;

        var tecnicos = await _context.UsuariosApp
            .AsNoTracking()
            .Where(u =>
                u.Rol == "tecnico" &&
                u.Activo)
            .OrderBy(u => u.NombreCompleto)
            .ToListAsync();

        var idsTecnicos = tecnicos
            .Select(t => t.Id)
            .ToList();

        var tecnicosConRuta = await _context.AsignacionesRuta
            .AsNoTracking()
            .Where(a =>
                idsTecnicos.Contains(a.IdUsuarioApp) &&
                a.FechaAsignacion.Date == hoy &&
                (a.Estado == "Planificado" || a.Estado == "EnCurso"))
            .Select(a => a.IdUsuarioApp)
            .Distinct()
            .ToListAsync();

        var tieneRuta = tecnicosConRuta.ToHashSet();

        return tecnicos
            .Select(t => new TecnicoDto(
                t.Id,
                t.NombreCompleto,
                t.Rol,
                t.Activo,
                tieneRuta.Contains(t.Id)))
            .ToList();
    }
}

public class SqlRutaRepository : IRutaRepository
{
    private readonly CosaaltDbContext _context;

    public SqlRutaRepository(CosaaltDbContext context) => _context = context;

    public async Task<RutaAsignadaResponseDto> AsignarAsync(
        AsignarRutaRequestDto request)
    {
        if (request.Detalles.Count == 0)
            throw new InvalidOperationException(
                "La ruta debe contener al menos una solicitud.");

        var tecnico = await _context.UsuariosApp
            .AsNoTracking()
            .FirstOrDefaultAsync(u =>
                u.Id == request.IdUsuarioTecnico &&
                (u.Rol == "tecnico" || u.Rol == "asignador") &&
                u.Activo);

        if (tecnico is null)
            throw new InvalidOperationException(
                "El usuario destino no existe, está inactivo o no puede recibir una ruta.");

        var fechaAsignacion = request.FechaAsignacion.Date;

        var tecnicoOcupado = await _context.AsignacionesRuta
            .AsNoTracking()
            .AnyAsync(a =>
                a.IdUsuarioApp == request.IdUsuarioTecnico &&
                a.FechaAsignacion.Date == fechaAsignacion &&
                (a.Estado == "Planificado" || a.Estado == "EnCurso"));

        if (tecnicoOcupado)
            throw new InvalidOperationException(
                "El usuario ya tiene una ruta activa para esa fecha.");

        var solicitudesIdsSolicitadas = request.Detalles
            .Select(d => d.SolicitudId.Trim())
            .ToList();

        var clavesOrigenSolicitadas = request.Detalles
            .Select(d =>
                $"{d.TipoOrigen.Trim().ToUpperInvariant()}|{d.IdOrigen.Trim()}")
            .ToList();

        if (solicitudesIdsSolicitadas
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Count() != solicitudesIdsSolicitadas.Count ||
            clavesOrigenSolicitadas
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Count() != clavesOrigenSolicitadas.Count)
        {
            throw new InvalidOperationException(
                "La ruta contiene solicitudes repetidas.");
        }

        foreach (var detalle in request.Detalles)
        {
            var tipo = detalle.TipoOrigen.Trim().ToUpperInvariant();
            if (tipo is not ("ODECO" or "LECTURA"))
            {
                throw new InvalidOperationException(
                    $"TipoOrigen no válido: {detalle.TipoOrigen}.");
            }

            if (string.IsNullOrWhiteSpace(detalle.IdOrigen))
            {
                throw new InvalidOperationException(
                    "Todas las solicitudes deben tener IdOrigen.");
            }

            if (string.IsNullOrWhiteSpace(detalle.SolicitudId))
            {
                throw new InvalidOperationException(
                    "Todas las solicitudes deben tener SolicitudId.");
            }

            if (detalle.OrdenVisita <= 0)
            {
                throw new InvalidOperationException(
                    "OrdenVisita debe ser mayor que cero.");
            }
        }

        var detallesActivos = await _context.DetallesRuta
            .AsNoTracking()
            .Where(d =>
                d.Asignacion.FechaAsignacion.Date == fechaAsignacion &&
                (d.Asignacion.Estado == "Planificado" ||
                 d.Asignacion.Estado == "EnCurso"))
            .Select(d => new
            {
                d.SolicitudId,
                d.TipoOrigen,
                d.IdOrigen
            })
            .ToListAsync();

        var solicitudesIdsActivas = detallesActivos
            .Where(d => !string.IsNullOrWhiteSpace(d.SolicitudId))
            .Select(d => d.SolicitudId.Trim())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var clavesOrigenActivas = detallesActivos
            .Select(d =>
                $"{d.TipoOrigen.Trim().ToUpperInvariant()}|{d.IdOrigen.Trim()}")
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        if (solicitudesIdsSolicitadas.Any(solicitudesIdsActivas.Contains) ||
            clavesOrigenSolicitadas.Any(clavesOrigenActivas.Contains))
        {
            throw new InvalidOperationException(
                "Una o más solicitudes ya pertenecen a otra ruta activa.");
        }

        var asignacion = new AsignacionRuta
        {
            IdUsuarioApp = request.IdUsuarioTecnico,
            FechaAsignacion = request.FechaAsignacion,
            Estado = "Planificado",
            Detalles = request.Detalles
                .OrderBy(d => d.OrdenVisita)
                .Select(RutaMapper.ToEntity)
                .ToList()
        };

        _context.AsignacionesRuta.Add(asignacion);
        await _context.SaveChangesAsync();

        return RutaMapper.ToResponse(
            asignacion,
            tecnico.NombreCompleto);
    }

    public async Task<RutasTecnicoResponseDto> ObtenerPorTecnicoAsync(
        int idTecnico,
        DateTime? fecha = null)
    {
        var fechaFiltro = (fecha ?? DateTime.Today).Date;

        var asignaciones = await _context.AsignacionesRuta
            .AsNoTracking()
            .Include(a => a.Detalles)
            .Include(a => a.Usuario)
            .Where(a =>
                a.IdUsuarioApp == idTecnico &&
                a.FechaAsignacion.Date == fechaFiltro)
            .OrderBy(a => a.FechaAsignacion)
            .ToListAsync();

        var resultado = asignaciones
            .Select(a =>
                RutaMapper.ToResponse(
                    a,
                    a.Usuario.NombreCompleto))
            .ToList();

        return new RutasTecnicoResponseDto(resultado);
    }

    public async Task<RutaAsignadaResponseDto?> ObtenerPorIdAsync(
        int idAsignacion)
    {
        var asignacion = await _context.AsignacionesRuta
            .AsNoTracking()
            .Include(a => a.Detalles)
            .Include(a => a.Usuario)
            .FirstOrDefaultAsync(a => a.Id == idAsignacion);

        return asignacion is null
            ? null
            : RutaMapper.ToResponse(
                asignacion,
                asignacion.Usuario.NombreCompleto);
    }
}

public class SqlSincronizacionRepository : ISincronizacionRepository
{
    private readonly CosaaltDbContext _context;

    public SqlSincronizacionRepository(CosaaltDbContext context) =>
        _context = context;

    public async Task<SincronizacionResponseDto> ProcesarCambiosAsync(
        SincronizacionRequestDto request)
    {
        var idsGuardados = new List<int>();
        var errores = 0;

        foreach (var ejecucionDto in request.Ejecuciones)
        {
            if (ejecucionDto.IdUsuarioApp != request.IdUsuario)
            {
                errores++;
                continue;
            }

            await using var transaction =
                await _context.Database.BeginTransactionAsync();

            try
            {
                var entity = await CambioMedidorPersistence.GuardarAsync(
                    _context,
                    ejecucionDto,
                    exigirRutaActiva: true);

                await transaction.CommitAsync();
                idsGuardados.Add(entity.Id);
            }
            catch
            {
                await transaction.RollbackAsync();
                _context.ChangeTracker.Clear();
                errores++;
            }
        }

        return new SincronizacionResponseDto(
            TotalRecibidos: request.Ejecuciones.Count,
            ProcesadosOk: idsGuardados.Count,
            Errores: errores,
            IdsEjecucion: idsGuardados,
            Mensaje:
                $"{idsGuardados.Count} de {request.Ejecuciones.Count} ejecuciones sincronizadas correctamente.");
    }
}
