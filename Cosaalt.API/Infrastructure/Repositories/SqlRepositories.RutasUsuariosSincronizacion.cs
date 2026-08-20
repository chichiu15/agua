using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

/// <summary>
/// Implementaciones SQL que faltaban. Antes, aunque RepositoryMode="Sql",
/// Rutas/Usuarios/Sincronización seguían usando el Mock en memoria (se
/// perdía todo al reiniciar la API). Con esto ya quedan sobre SQL Server.
/// </summary>
public class SqlUsuarioRepository : IUsuarioRepository
{
    private readonly CosaaltDbContext _context;

    public SqlUsuarioRepository(CosaaltDbContext context) => _context = context;

    public async Task<IReadOnlyList<TecnicoDto>> ObtenerTecnicosActivosAsync()
    {
        var hoy = DateTime.Today;

        var tecnicos = await _context.UsuariosApp
            .AsNoTracking()
            .Where(u => u.Rol == "tecnico")
            .OrderBy(u => u.NombreCompleto)
            .ToListAsync();

        var idsTecnicos = tecnicos.Select(t => t.Id).ToList();

        var tecnicosConRuta = await _context.AsignacionesRuta
            .AsNoTracking()
            .Where(a => idsTecnicos.Contains(a.IdUsuarioApp)
                && a.FechaAsignacion.Date == hoy
                && (a.Estado == "Planificado" || a.Estado == "EnCurso"))
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

    public async Task<RutaAsignadaResponseDto> AsignarAsync(AsignarRutaRequestDto request)
    {
        var tecnico = await _context.UsuariosApp.AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == request.IdUsuarioTecnico);

        var nombreTecnico = tecnico?.NombreCompleto ?? $"Técnico #{request.IdUsuarioTecnico}";

        var asignacion = new AsignacionRuta
        {
            IdUsuarioApp = request.IdUsuarioTecnico,
            FechaAsignacion = request.FechaAsignacion,
            Estado = "Planificado",
            Detalles = request.Detalles.Select(RutaMapper.ToEntity).ToList()
        };

        _context.AsignacionesRuta.Add(asignacion);
        await _context.SaveChangesAsync();

        return RutaMapper.ToResponse(asignacion, nombreTecnico);
    }

    public async Task<RutasTecnicoResponseDto> ObtenerPorTecnicoAsync(int idTecnico, DateTime? fecha = null)
    {
        var fechaFiltro = (fecha ?? DateTime.Today).Date;

        var asignaciones = await _context.AsignacionesRuta
            .AsNoTracking()
            .Include(a => a.Detalles)
            .Include(a => a.Usuario)
            .Where(a => a.IdUsuarioApp == idTecnico && a.FechaAsignacion.Date == fechaFiltro)
            .ToListAsync();

        var resultado = asignaciones
            .Select(a => RutaMapper.ToResponse(a, a.Usuario.NombreCompleto))
            .ToList();

        return new RutasTecnicoResponseDto(resultado);
    }

    public async Task<RutaAsignadaResponseDto?> ObtenerPorIdAsync(int idAsignacion)
    {
        var asignacion = await _context.AsignacionesRuta
            .AsNoTracking()
            .Include(a => a.Detalles)
            .Include(a => a.Usuario)
            .FirstOrDefaultAsync(a => a.Id == idAsignacion);

        return asignacion is null ? null : RutaMapper.ToResponse(asignacion, asignacion.Usuario.NombreCompleto);
    }
}

public class SqlSincronizacionRepository : ISincronizacionRepository
{
    private readonly CosaaltDbContext _context;

    public SqlSincronizacionRepository(CosaaltDbContext context) => _context = context;

    public async Task<SincronizacionResponseDto> ProcesarCambiosAsync(SincronizacionRequestDto request)
    {
        var idsGuardados = new List<int>();
        var errores = 0;

        foreach (var ejecucionDto in request.Ejecuciones)
        {
            try
            {
                var entity = EjecucionMapper.ToEntity(ejecucionDto);
                _context.EjecucionesCambio.Add(entity);
                await _context.SaveChangesAsync();
                idsGuardados.Add(entity.Id);

                // Marca la parada correspondiente del recorrido como Completada,
                // así el asignador ve el avance real al recargar su seguimiento.
                var detalle = await _context.DetallesRuta.FirstOrDefaultAsync(d =>
                    d.TipoOrigen == ejecucionDto.TipoOrigen && d.IdOrigen == ejecucionDto.IdOrigen);

                if (detalle is not null)
                {
                    detalle.Estado = "Completada";
                    await _context.SaveChangesAsync();
                }
            }
            catch
            {
                errores++;
            }
        }

        return new SincronizacionResponseDto(
            TotalRecibidos: request.Ejecuciones.Count,
            ProcesadosOk: idsGuardados.Count,
            Errores: errores,
            IdsEjecucion: idsGuardados,
            Mensaje: $"{idsGuardados.Count} de {request.Ejecuciones.Count} ejecuciones sincronizadas correctamente.");
    }
}
