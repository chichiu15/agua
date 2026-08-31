using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlUsuarioRepository : IUsuarioRepository
{
    private readonly CosaaltDbContext _context;

    public SqlUsuarioRepository(CosaaltDbContext context) => _context = context;

    public async Task<IReadOnlyList<TecnicoDto>> ObtenerTecnicosActivosAsync()
    {
        var hoy = DateTime.Today;
        var tecnicos = await _context.Usuarios
            .AsNoTracking()
            .Include(u => u.Rol)
            .Include(u => u.Funcionario).ThenInclude(f => f!.Persona)
            .Where(u => u.Rol.Nombre == "tecnico")
            .OrderBy(u => u.Id)
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
            .OrderBy(t => t.NombreCompleto)
            .Select(t => new TecnicoDto(t.Id, t.NombreCompleto, t.Rol.Nombre, t.Activo, tieneRuta.Contains(t.Id)))
            .ToList();
    }

    public async Task<IReadOnlyList<UsuarioDto>> ObtenerUsuariosAsync()
    {
        var usuarios = await ConsultaUsuarios().OrderBy(u => u.Id).ToListAsync();
        return usuarios.Select(MapUsuario).ToList();
    }

    public async Task<IReadOnlyList<FuncionarioDto>> ObtenerFuncionariosActivosAsync()
    {
        var funcionarios = await _context.Funcionarios
            .AsNoTracking()
            .Include(f => f.Persona)
            .Where(f => f.EstFun && f.Persona!.EstPer)
            .OrderBy(f => f.CodFun)
            .ToListAsync();

        return funcionarios
            .Select(f => new FuncionarioDto(f.CodFun, f.Persona?.NombreCompleto ?? string.Empty, f.AliFun, f.EstFun))
            .ToList();
    }

    public async Task<IReadOnlyList<RolDto>> ObtenerRolesAsync()
    {
        return await _context.RolesApp
            .AsNoTracking()
            .OrderBy(r => r.IdRol)
            .Select(r => new RolDto(r.IdRol, r.Nombre, r.Descripcion, r.Activo))
            .ToListAsync();
    }

    public async Task<UsuarioDto> CrearAsync(CrearUsuarioRequestDto request)
    {
        var nombreUsuario = request.NombreUsuario.Trim();
        await ValidarDatosAsync(nombreUsuario, request.IdRol, request.CodFunCorporativo, null);

        var entity = new Usuario
        {
            CodFunCorporativo = request.CodFunCorporativo,
            NombreUsuario = nombreUsuario,
            HashPassword = request.Contrasena,
            IdRol = request.IdRol,
            Activo = request.Activo,
            FechaCreacion = DateTime.Now
        };

        _context.Usuarios.Add(entity);
        await _context.SaveChangesAsync();
        return (await ObtenerPorIdAsync(entity.Id))!;
    }

    public async Task<UsuarioDto?> ActualizarAsync(int id, ActualizarUsuarioRequestDto request)
    {
        var entity = await _context.Usuarios.FirstOrDefaultAsync(u => u.Id == id);
        if (entity is null) return null;

        var nombreUsuario = request.NombreUsuario.Trim();
        await ValidarDatosAsync(nombreUsuario, request.IdRol, request.CodFunCorporativo, id);

        entity.CodFunCorporativo = request.CodFunCorporativo;
        entity.NombreUsuario = nombreUsuario;
        entity.IdRol = request.IdRol;
        entity.Activo = request.Activo;
        if (!string.IsNullOrWhiteSpace(request.Contrasena))
            entity.HashPassword = request.Contrasena;

        await _context.SaveChangesAsync();
        return await ObtenerPorIdAsync(id);
    }

    private IQueryable<Usuario> ConsultaUsuarios() => _context.Usuarios
        .AsNoTracking()
        .Include(u => u.Rol)
        .Include(u => u.Funcionario).ThenInclude(f => f!.Persona);

    private async Task<UsuarioDto?> ObtenerPorIdAsync(int id)
    {
        var entity = await ConsultaUsuarios().FirstOrDefaultAsync(u => u.Id == id);
        return entity is null ? null : MapUsuario(entity);
    }

    private static UsuarioDto MapUsuario(Usuario u) => new(
        u.Id,
        u.NombreCompleto,
        u.NombreUsuario,
        u.Rol.Nombre,
        u.IdRol,
        u.Activo,
        u.CodFunCorporativo,
        u.FechaCreacion);

    private async Task ValidarDatosAsync(string nombreUsuario, int idRol, int? codFun, int? idActual)
    {
        if (string.IsNullOrWhiteSpace(nombreUsuario))
            throw new ArgumentException("El nombre de usuario es obligatorio.");

        var duplicado = await _context.Usuarios.AnyAsync(u =>
            u.NombreUsuario.ToLower() == nombreUsuario.ToLower() &&
            (!idActual.HasValue || u.Id != idActual.Value));
        if (duplicado)
            throw new InvalidOperationException("Ya existe un usuario con ese nombre de usuario.");

        var rolValido = await _context.RolesApp.AnyAsync(r => r.IdRol == idRol && r.Activo);
        if (!rolValido)
            throw new ArgumentException("El rol indicado no existe o esta inactivo.");

        if (codFun.HasValue)
        {
            var funcionarioExiste = await _context.Funcionarios.AsNoTracking().AnyAsync(f => f.CodFun == codFun.Value);
            if (!funcionarioExiste)
                throw new ArgumentException("El funcionario corporativo indicado no existe.");

            var funcionarioUsado = await _context.Usuarios.AnyAsync(u =>
                u.CodFunCorporativo == codFun.Value &&
                (!idActual.HasValue || u.Id != idActual.Value));
            if (funcionarioUsado)
                throw new InvalidOperationException("Ese funcionario ya esta vinculado a otra cuenta de la aplicacion.");
        }
    }
}

public class SqlRutaRepository : IRutaRepository
{
    private readonly CosaaltDbContext _context;

    public SqlRutaRepository(CosaaltDbContext context) => _context = context;

    public async Task<RutaAsignadaResponseDto> AsignarAsync(AsignarRutaRequestDto request)
    {
        var tecnico = await _context.Usuarios.AsNoTracking()
            .Include(u => u.Funcionario)
                .ThenInclude(f => f!.Persona)
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
                .ThenInclude(u => u.Funcionario)
                .ThenInclude(f => f!.Persona)
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
                .ThenInclude(u => u.Funcionario)
                .ThenInclude(f => f!.Persona)
            .FirstOrDefaultAsync(a => a.Id == idAsignacion);

        if (asignacion is null) return null;

        var resolucion = await ResolverSocioMedidorAsync(asignacion.Detalles);
        return RutaMapper.ToResponse(asignacion, asignacion.Usuario.NombreCompleto, resolucion);
    }

    /// <summary>
    /// Resuelve la conexión (CodCon = cuenta del socio en COSAALT) y su medidor
    /// VIGENTE (serial, desde dbo.CambioMedidores+Medidores) para cada parada.
    /// ODECO se resuelve directo desde dbo.Reclamos.CodCon, y LECTURA desde
    /// DetallesSolicitudLectura.CodCon. Solo lectura: no se modifican tablas de
    /// dbo. Si una parada no tiene conexión o medidor, devuelve null.
    /// </summary>
    private async Task<Dictionary<string, (int? CodCon, string? NumeroMedidor)>> ResolverSocioMedidorAsync(
        IEnumerable<DetalleRuta> detallesLista)
    {
        var detalles = detallesLista.ToList();
        var codConPorOrigen = new Dictionary<string, int>();

        var folios = detalles
            .Where(d => d.TipoOrigen == "ODECO")
            .Select(d => int.TryParse(d.IdOrigen, out var f) ? f : 0)
            .Where(f => f > 0)
            .Distinct()
            .Select(f => (decimal)f)
            .ToList();

        if (folios.Count > 0)
        {
            // FromSqlRaw: EF 10 reescribe Contains() sobre columnas numeric con
            // conversor a OPENJSON (SQL inválido, error 102). IN de parámetros directo.
            var filasReclamos = new List<ReclamoCodConRow>();

            foreach (var lote in folios.Chunk(1000))
            {
                var parametros = lote
                    .Select((f, i) => new SqlParameter($"@f{i}", f))
                    .ToArray();
                var inClause = string.Join(", ", parametros.Select(p => p.ParameterName));

                var sql = $"""
                    SELECT r.CodRec, r.CodCon
                    FROM dbo.Reclamos r
                    WHERE r.CodCon IS NOT NULL
                      AND r.CodRec IN ({inClause})
                    """;

                filasReclamos.AddRange(
                    await _context.Database.SqlQueryRaw<ReclamoCodConRow>(sql, parametros)
                        .ToListAsync());
            }

            foreach (var r in filasReclamos)
                codConPorOrigen[$"ODECO-{r.CodRec}"] = (int)r.CodCon;
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
                .Select(d => new { d.Id, d.CodCon })
                .ToListAsync();
            foreach (var d in detalle)
                codConPorOrigen[$"LECTURA-{d.Id}"] = d.CodCon;
        }

        var codCons = codConPorOrigen.Values.Distinct().ToList();
        var medidorPorCodCon = new Dictionary<int, string>();

        if (codCons.Count > 0)
        {
            var vigentes = await MedidorVigenteResolver.ResolverAsync(_context, codCons);
            foreach (var kv in vigentes)
                if (kv.Value.Serial is not null)
                    medidorPorCodCon[kv.Key] = kv.Value.Serial;
        }

        var resultado = new Dictionary<string, (int? CodCon, string? NumeroMedidor)>();
        foreach (var d in detalles)
        {
            var key = $"{d.TipoOrigen}-{d.IdOrigen}";
            if (resultado.ContainsKey(key)) continue;
            resultado[key] = codConPorOrigen.TryGetValue(key, out var codCon)
                ? ((int?)codCon, medidorPorCodCon.GetValueOrDefault(codCon))
                : ((int?)null, null);
        }

        return resultado;
    }

    private sealed class ReclamoCodConRow
    {
        public decimal CodRec { get; set; }
        public decimal CodCon { get; set; }
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
