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

        var resolucion = await ResolverSocioMedidorAsync(asignacion.Detalles);
        return RutaMapper.ToResponse(asignacion, nombreTecnico, resolucion);
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

        var resolucion = await ResolverSocioMedidorAsync(
            asignaciones.SelectMany(a => a.Detalles).ToList());

        var resultado = asignaciones
            .Select(a => RutaMapper.ToResponse(a, a.Usuario.NombreCompleto, resolucion))
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

        if (asignacion is null) return null;

        var resolucion = await ResolverSocioMedidorAsync(asignacion.Detalles);
        return RutaMapper.ToResponse(asignacion, asignacion.Usuario.NombreCompleto, resolucion);
    }

    /// <summary>
    /// Resuelve el socio (RegistroSocio) y su medidor ACTIVO (NumeroMedidor)
    /// para cada parada. ODECO se resuelve desde dbo.Reclamos + Conexi�n +
    /// medidores.Socio (la misma fuente que genera las solicitudes), y LECTURA
    /// desde DetallesSolicitudLectura. Solo lectura: no se modifican tablas de
    /// dbo. Si una parada no tiene socio o medidor, devuelve null.
    /// </summary>
    private async Task<Dictionary<string, (int? RegistroSocio, string? NumeroMedidor)>> ResolverSocioMedidorAsync(
        IEnumerable<DetalleRuta> detallesLista)
    {
        var detalles = detallesLista.ToList();
        var registrosPorOrigen = new Dictionary<string, int>();

        var folios = detalles
            .Where(d => d.TipoOrigen == "ODECO")
            .Select(d => int.TryParse(d.IdOrigen, out var f) ? f : 0)
            .Where(f => f > 0)
            .Distinct()
            .ToList();

        if (folios.Count > 0)
        {
            // Las solicitudes ODECO salen de dbo.Reclamos (SolicitudVirtualService),
            // no de medidores.ReclamosODECO. El socio se resuelve desde la Conexi�n
            // del reclamo por su nombre, y de ah� se toma el medidor ACTIVO.
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
                    .Include(s => s.Medidor)
                    .Where(s => nombres.Contains(s.Nombre.Trim()))
                    .ToListAsync();

            var socioPorNombre = socios
                .ToDictionary(s => s.Nombre.Trim(), StringComparer.OrdinalIgnoreCase);

            foreach (var r in reclamos)
            {
                var nombre = r.Conexion?.NomSoc?.Trim();
                if (string.IsNullOrEmpty(nombre) || !socioPorNombre.TryGetValue(nombre, out var socio))
                    continue;

                registrosPorOrigen[$"ODECO-{r.CodRec}"] = socio.RegistroSocio;
            }
        }

        var lecturas = detalles
            .Where(d => d.TipoOrigen == "LECTURA")
            .Select(d => int.TryParse(d.IdOrigen, out var f) ? f : 0)
            .Where(f => f > 0)
            .Distinct()
            .ToList();

        if (lecturas.Count > 0)
        {
            var detalle = await _context.DetallesSolicitudLectura
                .AsNoTracking()
                .Where(d => lecturas.Contains(d.Id))
                .Select(d => new { d.Id, d.RegistroSocio })
                .ToListAsync();
            foreach (var d in detalle)
                registrosPorOrigen[$"LECTURA-{d.Id}"] = d.RegistroSocio;
        }

        var registros = registrosPorOrigen.Values.Distinct().ToList();
        var medidorPorRegistro = new Dictionary<int, string>();

        if (registros.Count > 0)
        {
            var medidores = await _context.Medidores
                .AsNoTracking()
                .Where(m => registros.Contains(m.RegistroSocio)
                    && m.Estado != null
                    && m.Estado.ToUpper() == "ACTIVO")
                .Select(m => new { m.RegistroSocio, m.NumeroMedidor })
                .ToListAsync();
            foreach (var m in medidores)
                medidorPorRegistro[m.RegistroSocio] = m.NumeroMedidor;
        }

        var resultado = new Dictionary<string, (int? RegistroSocio, string? NumeroMedidor)>();
        foreach (var d in detalles)
        {
            var key = $"{d.TipoOrigen}-{d.IdOrigen}";
            if (resultado.ContainsKey(key)) continue;
            resultado[key] = registrosPorOrigen.TryGetValue(key, out var reg)
                ? ((int?)reg, medidorPorRegistro.GetValueOrDefault(reg))
                : ((int?)null, null);
        }

        return resultado;
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

                // Marca la parada correspondiente del recorrido del d�a del
                // t�cnico como Completada, as� el asignador ve el avance real.
                var asignacionHoy = await _context.AsignacionesRuta
                    .AsNoTracking()
                    .Where(a => a.IdUsuarioApp == request.IdUsuario
                        && a.FechaAsignacion.Date == DateTime.Today)
                    .OrderByDescending(a => a.FechaAsignacion)
                    .Select(a => a.Id)
                    .FirstOrDefaultAsync();

                DetalleRuta? detalle = null;
                if (asignacionHoy != 0)
                {
                    detalle = await _context.DetallesRuta.FirstOrDefaultAsync(d =>
                        d.IdAsignacion == asignacionHoy
                        && d.TipoOrigen == ejecucionDto.TipoOrigen
                        && d.IdOrigen == ejecucionDto.IdOrigen);
                }

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
