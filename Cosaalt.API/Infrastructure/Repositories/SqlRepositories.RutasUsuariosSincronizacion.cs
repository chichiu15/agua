using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Cosaalt.API.Infrastructure.Security;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlUsuarioRepository : IUsuarioRepository
{
    private readonly CosaaltDbContext _context;
    private readonly CosaaltInstitutionalReader _institutional;

    public SqlUsuarioRepository(CosaaltDbContext context, CosaaltInstitutionalReader institutional)
    {
        _context = context;
        _institutional = institutional;
    }

    public async Task<IReadOnlyList<TecnicoDto>> ObtenerTecnicosActivosAsync()
    {
        var usuarios = await _context.Usuarios.AsNoTracking()
            .Include(u => u.Rol)
            .Where(u => u.Activo && u.Rol.Activo && u.Rol.Nombre.ToLower() == "tecnico")
            .OrderBy(u => u.NombreUsuario)
            .ToListAsync();
        var conRuta = await _context.AsignacionesRuta.AsNoTracking()
            .Where(a => a.Estado != "Finalizado" && a.Estado != "Cancelado")
            .Select(a => a.IdUsuarioApp).Distinct().ToListAsync();
        var set = conRuta.ToHashSet();
        var result = new List<TecnicoDto>();
        foreach (var u in usuarios)
        {
            var nombre = await _institutional.ObtenerNombrePersonaAsync(u.CodPersonaCorporativa) ?? u.NombreUsuario;
            result.Add(new TecnicoDto(u.Id, nombre, u.Rol.Nombre, u.Activo, set.Contains(u.Id)));
        }
        return result;
    }

    public async Task<IReadOnlyList<UsuarioDto>> ObtenerUsuariosAsync()
    {
        var usuarios = await _context.Usuarios.AsNoTracking().Include(u => u.Rol).OrderBy(u => u.NombreUsuario).ToListAsync();
        var result = new List<UsuarioDto>(usuarios.Count);
        foreach (var u in usuarios)
        {
            var nombre = await _institutional.ObtenerNombrePersonaAsync(u.CodPersonaCorporativa) ?? u.NombreUsuario;
            result.Add(ToDto(u, nombre));
        }
        return result;
    }

    public Task<IReadOnlyList<FuncionarioDto>> ObtenerFuncionariosActivosAsync() =>
        _institutional.ObtenerPersonasAsync(null, 500);

    public async Task<IReadOnlyList<RolDto>> ObtenerRolesAsync() =>
        await _context.RolesApp.AsNoTracking().OrderBy(r => r.IdRol)
            .Select(r => new RolDto(r.IdRol, r.Nombre, r.Descripcion, r.Activo)).ToListAsync();

    public async Task<UsuarioDto> CrearAsync(CrearUsuarioRequestDto request)
    {
        var username = request.NombreUsuario.Trim();
        if (await _context.Usuarios.AnyAsync(u => u.NombreUsuario == username))
            throw new InvalidOperationException("Ya existe un usuario con ese nombre.");
        var rol = await _context.RolesApp.AsNoTracking().FirstOrDefaultAsync(r => r.IdRol == request.IdRol && r.Activo)
                  ?? throw new InvalidOperationException("El rol indicado no existe o esta inactivo.");
        if (request.CodFunCorporativo.HasValue && !await _institutional.PersonaExisteAsync(request.CodFunCorporativo.Value))
            throw new InvalidOperationException("La persona corporativa seleccionada no existe en dbo.PERSONAS.");

        var entity = new Usuario
        {
            CodPersonaCorporativa = request.CodFunCorporativo,
            NombreUsuario = username,
            HashPassword = PasswordHasher.Hash(request.Contrasena),
            IdRol = rol.IdRol,
            Activo = request.Activo,
            FechaCreacion = DateTime.Now
        };
        _context.Usuarios.Add(entity);
        await _context.SaveChangesAsync();
        entity.Rol = rol;
        var nombre = await _institutional.ObtenerNombrePersonaAsync(entity.CodPersonaCorporativa) ?? entity.NombreUsuario;
        return ToDto(entity, nombre);
    }

    public async Task<UsuarioDto?> ActualizarAsync(int id, ActualizarUsuarioRequestDto request)
    {
        var entity = await _context.Usuarios.Include(u => u.Rol).FirstOrDefaultAsync(u => u.Id == id);
        if (entity is null) return null;
        var username = request.NombreUsuario.Trim();
        if (await _context.Usuarios.AnyAsync(u => u.Id != id && u.NombreUsuario == username))
            throw new InvalidOperationException("Ya existe otro usuario con ese nombre.");
        var rol = await _context.RolesApp.AsNoTracking().FirstOrDefaultAsync(r => r.IdRol == request.IdRol)
                  ?? throw new InvalidOperationException("El rol indicado no existe.");
        if (request.CodFunCorporativo.HasValue && !await _institutional.PersonaExisteAsync(request.CodFunCorporativo.Value))
            throw new InvalidOperationException("La persona corporativa seleccionada no existe en dbo.PERSONAS.");

        entity.CodPersonaCorporativa = request.CodFunCorporativo;
        entity.NombreUsuario = username;
        if (!string.IsNullOrWhiteSpace(request.Contrasena)) entity.HashPassword = PasswordHasher.Hash(request.Contrasena);
        entity.IdRol = request.IdRol;
        entity.Activo = request.Activo;
        entity.FechaActualizacion = DateTime.Now;
        await _context.SaveChangesAsync();
        entity.Rol = rol;
        var nombre = await _institutional.ObtenerNombrePersonaAsync(entity.CodPersonaCorporativa) ?? entity.NombreUsuario;
        return ToDto(entity, nombre);
    }

    private static UsuarioDto ToDto(Usuario u, string nombre) => new(
        u.Id, nombre, u.NombreUsuario, u.Rol.Nombre, u.IdRol, u.Activo,
        u.CodPersonaCorporativa.HasValue && u.CodPersonaCorporativa <= int.MaxValue ? (int?)u.CodPersonaCorporativa.Value : null,
        u.FechaCreacion);
}

public class SqlRutaRepository : IRutaRepository
{
    private readonly CosaaltDbContext _context;
    private readonly CosaaltInstitutionalReader _institutional;

    public SqlRutaRepository(CosaaltDbContext context, CosaaltInstitutionalReader institutional)
    {
        _context = context;
        _institutional = institutional;
    }

    public async Task<RutaAsignadaResponseDto> AsignarAsync(AsignarRutaRequestDto request)
    {
        if (request.Detalles is null || request.Detalles.Count == 0)
            throw new ArgumentException("Debe seleccionar al menos una solicitud.");

        var tecnico = await _context.Usuarios.AsNoTracking().Include(u => u.Rol)
            .FirstOrDefaultAsync(u => u.Id == request.IdUsuarioTecnico && u.Activo && u.Rol.Activo
                && (u.Rol.Nombre.ToLower() == "tecnico" || u.Rol.Nombre.ToLower() == "asignador"))
            ?? throw new InvalidOperationException("El responsable seleccionado no existe, esta inactivo o no tiene rol tecnico/asignador.");
        var asignador = await _context.Usuarios.AsNoTracking().Include(u => u.Rol)
            .FirstOrDefaultAsync(u => u.Id == request.IdUsuarioAsignador && u.Activo && u.Rol.Activo && u.Rol.Nombre.ToLower() == "asignador")
            ?? throw new InvalidOperationException("El usuario asignador no existe, esta inactivo o no tiene el rol asignador.");

        var tieneRutaPendiente = await _context.AsignacionesRuta.AsNoTracking()
            .AnyAsync(a => a.IdUsuarioApp == tecnico.Id
                           && a.Estado != "Finalizado"
                           && a.Estado != "Cancelado");
        if (tieneRutaPendiente)
            throw new InvalidOperationException("El técnico ya tiene una ruta activa. Debe completar o cancelar esa ruta antes de recibir otra.");

        var fecha = request.FechaAsignacion == default ? DateTime.Today : request.FechaAsignacion.Date;
        var entity = new AsignacionRuta
        {
            IdUsuarioApp = tecnico.Id,
            IdUsuarioAsignador = asignador.Id,
            FechaAsignacion = fecha,
            Estado = "Planificado",
            FechaCreacion = DateTime.Now
        };

        var ordenes = new HashSet<int>();
        foreach (var d in request.Detalles.OrderBy(x => x.OrdenVisita))
        {
            if (!ordenes.Add(d.OrdenVisita)) throw new ArgumentException("No puede repetir el orden de visita dentro de una ruta.");
            var tipo = (d.TipoOrigen ?? string.Empty).Trim().ToUpperInvariant();
            if (tipo is not ("ODECO" or "LECTURA" or "REVISION"))
                throw new ArgumentException($"Tipo de origen no valido en {d.SolicitudId}: {tipo}.");
            var idOrigen = NormalizeOrigen(tipo, d.IdOrigen);
            if (string.IsNullOrWhiteSpace(idOrigen))
                throw new ArgumentException($"La solicitud {d.SolicitudId} no tiene un IdOrigen valido.");
            var duplicada = await _context.DetallesRuta.AsNoTracking()
                .AnyAsync(x => x.TipoOrigen == tipo && x.IdOrigen == idOrigen && x.Estado != "Cancelada" && x.Estado != "Completada");
            if (duplicada) throw new InvalidOperationException($"La solicitud {d.SolicitudId} ya se encuentra asignada en otra ruta activa.");

            int? regSoc = null;
            int? codMedidor = null;
            string nombre = d.NombreCliente;
            string direccion = d.Direccion;
            decimal? lat = d.Latitud.HasValue ? Convert.ToDecimal(d.Latitud.Value) : null;
            decimal? lon = d.Longitud.HasValue ? Convert.ToDecimal(d.Longitud.Value) : null;

            if (idOrigen.StartsWith("QA-", StringComparison.OrdinalIgnoreCase) ||
                (d.SolicitudId?.StartsWith("QA-", StringComparison.OrdinalIgnoreCase) ?? false))
            {
                var qa = await _institutional.ObtenerSolicitudPruebaAsync(d.SolicitudId ?? idOrigen);
                if (qa is not null)
                {
                    regSoc = qa.CodCon;
                    var actual = await _institutional.ObtenerMedidorActualAsync(qa.CodCon);
                    codMedidor = actual?.CodMedidor;
                    if (string.IsNullOrWhiteSpace(nombre)) nombre = qa.NombreCliente;
                    if (string.IsNullOrWhiteSpace(direccion)) direccion = qa.Direccion;
                    lat ??= qa.Latitud.HasValue ? Convert.ToDecimal(qa.Latitud.Value) : null;
                    lon ??= qa.Longitud.HasValue ? Convert.ToDecimal(qa.Longitud.Value) : null;
                }
            }
            else if (tipo == "ODECO" && int.TryParse(idOrigen, out var codRec))
            {
                var o = await _institutional.ObtenerOdecoAsync(codRec);
                if (o is not null)
                {
                    regSoc = o.RegSoc;
                    codMedidor = o.CodMedidor;
                    if (string.IsNullOrWhiteSpace(nombre)) nombre = o.NombreSocio;
                    if (string.IsNullOrWhiteSpace(direccion)) direccion = o.Direccion;
                    lat ??= o.Latitud;
                    lon ??= o.Longitud;
                }
            }

            entity.Detalles.Add(new DetalleRuta
            {
                TipoOrigen = tipo,
                IdOrigen = idOrigen,
                OrdenVisita = d.OrdenVisita,
                Estado = "Pendiente",
                SolicitudId = string.IsNullOrWhiteSpace(d.SolicitudId) ? $"{tipo}-{idOrigen}" : d.SolicitudId.Trim(),
                RegSoc = regSoc,
                CodMedidorActual = codMedidor,
                NombreCliente = string.IsNullOrWhiteSpace(nombre) ? "Sin nombre" : nombre.Trim(),
                Direccion = direccion?.Trim() ?? string.Empty,
                Latitud = lat,
                Longitud = lon
            });
        }

        _context.AsignacionesRuta.Add(entity);
        await _context.SaveChangesAsync();

        // Volvemos a leer desde SQL para garantizar que la respuesta representa
        // exactamente la ruta persistida (incluidos IdDetalle y relaciones).
        var persistida = await _context.AsignacionesRuta.AsNoTracking()
            .Include(a => a.Tecnico).ThenInclude(u => u.Rol)
            .Include(a => a.Detalles)
            .FirstAsync(a => a.Id == entity.Id);
        return await BuildResponseAsync(persistida, persistida.Tecnico);
    }

    public async Task<RutasTecnicoResponseDto> ObtenerPorTecnicoAsync(int idTecnico, DateTime? fecha = null)
    {
        var query = _context.AsignacionesRuta.AsNoTracking()
            .Include(a => a.Tecnico).ThenInclude(u => u.Rol)
            .Include(a => a.Detalles)
            .Where(a => a.IdUsuarioApp == idTecnico);
        if (fecha.HasValue)
        {
            var day = fecha.Value.Date;
            query = query.Where(a => a.FechaAsignacion >= day && a.FechaAsignacion < day.AddDays(1));
        }
        var rows = await query.OrderByDescending(a => a.FechaAsignacion).ThenByDescending(a => a.Id).ToListAsync();
        var list = new List<RutaAsignadaResponseDto>();
        foreach (var row in rows) list.Add(await BuildResponseAsync(row, row.Tecnico));
        return new RutasTecnicoResponseDto(list);
    }

    public async Task<RutaAsignadaResponseDto?> ObtenerActualPorTecnicoAsync(int idTecnico)
    {
        var hoy = DateTime.Today;
        var manana = hoy.AddDays(1);

        // La ruta de hoy sigue siendo visible cuando ya fue finalizada; de lo
        // contrario el dashboard quedaba vacio justo despues de sincronizar
        // la ultima parada.
        var row = await _context.AsignacionesRuta.AsNoTracking()
            .Include(a => a.Tecnico).ThenInclude(u => u.Rol)
            .Include(a => a.Detalles)
            .Where(a => a.IdUsuarioApp == idTecnico
                        && a.Estado != "Cancelado"
                        && a.FechaAsignacion >= hoy && a.FechaAsignacion < manana)
            .OrderByDescending(a => a.Id)
            .FirstOrDefaultAsync();

        row ??= await _context.AsignacionesRuta.AsNoTracking()
            .Include(a => a.Tecnico).ThenInclude(u => u.Rol)
            .Include(a => a.Detalles)
            .Where(a => a.IdUsuarioApp == idTecnico
                        && a.Estado != "Finalizado"
                        && a.Estado != "Cancelado")
            .OrderByDescending(a => a.FechaAsignacion)
            .ThenByDescending(a => a.Id)
            .FirstOrDefaultAsync();

        return row is null ? null : await BuildResponseAsync(row, row.Tecnico);
    }

    public async Task<RutasTecnicoResponseDto> ObtenerActivasAsync(DateTime? fecha = null)
    {
        var day = (fecha ?? DateTime.Today).Date;
        var next = day.AddDays(1);
        var query = _context.AsignacionesRuta.AsNoTracking()
            .Include(a => a.Tecnico).ThenInclude(u => u.Rol)
            .Include(a => a.Detalles)
            .Where(a => a.Estado != "Cancelado");

        // Sin fecha: monitoreo operativo. Incluye toda ruta pendiente aunque
        // provenga de días anteriores y las finalizadas hoy. Con fecha: vista
        // histórica exacta de ese día.
        query = fecha.HasValue
            ? query.Where(a => a.FechaAsignacion >= day && a.FechaAsignacion < next)
            : query.Where(a => a.Estado != "Finalizado"
                               || (a.FechaAsignacion >= day && a.FechaAsignacion < next));

        var rows = await query
            .OrderByDescending(a => a.Id)
            .ToListAsync();

        var list = new List<RutaAsignadaResponseDto>(rows.Count);
        foreach (var row in rows) list.Add(await BuildResponseAsync(row, row.Tecnico));
        return new RutasTecnicoResponseDto(list);
    }

    public async Task<RutaAsignadaResponseDto?> ObtenerPorIdAsync(int idAsignacion)
    {
        var row = await _context.AsignacionesRuta.AsNoTracking()
            .Include(a => a.Tecnico).ThenInclude(u => u.Rol)
            .Include(a => a.Detalles)
            .FirstOrDefaultAsync(a => a.Id == idAsignacion);
        return row is null ? null : await BuildResponseAsync(row, row.Tecnico);
    }

    private async Task<RutaAsignadaResponseDto> BuildResponseAsync(AsignacionRuta entity, Usuario tecnico)
    {
        var nombre = await _institutional.ObtenerNombrePersonaAsync(tecnico.CodPersonaCorporativa) ?? tecnico.NombreUsuario;
        var detalles = new List<DetalleRutaResponseDto>();
        foreach (var d in entity.Detalles.OrderBy(x => x.OrdenVisita))
        {
            string? serie = null;
            if (d.CodMedidorActual.HasValue)
                serie = (await _institutional.ObtenerMedidorPorCodigoAsync(d.CodMedidorActual.Value))?.Serie;
            detalles.Add(RutaMapper.ToResponse(d, serie));
        }
        return new RutaAsignadaResponseDto(entity.Id, entity.IdUsuarioApp, nombre, entity.FechaAsignacion, entity.Estado, detalles.Count, detalles);
    }

    private static string NormalizeOrigen(string tipo, string id)
    {
        var clean = (id ?? string.Empty).Trim();
        if (tipo == "ODECO" && clean.StartsWith("ODECO-", StringComparison.OrdinalIgnoreCase)) clean = clean[6..];
        if (tipo == "LECTURA" && clean.StartsWith("LEC-", StringComparison.OrdinalIgnoreCase)) clean = clean[4..];
        return clean;
    }
}

public class SqlSincronizacionRepository : ISincronizacionRepository
{
    private readonly IEjecucionRepository _ejecuciones;

    public SqlSincronizacionRepository(IEjecucionRepository ejecuciones) => _ejecuciones = ejecuciones;

    public async Task<SincronizacionResponseDto> ProcesarCambiosAsync(SincronizacionRequestDto request)
    {
        var ids = new List<int>();
        var resultados = new List<SincronizacionItemResultadoDto>();

        foreach (var item in request.Ejecuciones ?? [])
        {
            try
            {
                var normalizado = item.IdUsuarioApp == 0
                    ? item with { IdUsuarioApp = request.IdUsuario }
                    : item;
                var result = await _ejecuciones.RegistrarAsync(normalizado);
                ids.Add(result.Id);
                resultados.Add(new SincronizacionItemResultadoDto(
                    normalizado.TipoOrigen, normalizado.IdOrigen, true, result.Id, result.YaExistia, null));
            }
            catch (Exception ex)
            {
                resultados.Add(new SincronizacionItemResultadoDto(
                    item.TipoOrigen, item.IdOrigen, false, null, false,
                    EsFallaConexionSql(ex)
                        ? "No hay conexión con la base de datos institucional. Verifique la VPN; el trabajo continúa guardado en el dispositivo."
                        : ex.Message));
            }
        }

        var total = request.Ejecuciones?.Count ?? 0;
        var ok = resultados.Count(x => x.Ok);
        var errores = total - ok;
        return new SincronizacionResponseDto(
            total, ok, errores, ids,
            errores == 0
                ? "Sincronizacion completada correctamente."
                : "Sincronizacion completada con registros pendientes de revision.",
            resultados);
    }

    private static bool EsFallaConexionSql(Exception ex)
    {
        for (Exception? actual = ex; actual is not null; actual = actual.InnerException)
        {
            if (actual is SqlException sql &&
                (sql.Class >= 20 || sql.Number is -2 or 20 or 40 or 53 or 64 or 121 or 233 or 258 or 10053 or 10054 or 10060))
                return true;
        }
        return false;
    }
}
