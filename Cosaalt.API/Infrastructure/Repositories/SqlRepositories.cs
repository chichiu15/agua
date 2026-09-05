using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Cosaalt.API.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlAuthRepository : IAuthRepository
{
    private readonly CosaaltDbContext _context;
    private readonly CosaaltInstitutionalReader _institutional;

    public SqlAuthRepository(CosaaltDbContext context, CosaaltInstitutionalReader institutional)
    {
        _context = context;
        _institutional = institutional;
    }

    public async Task<LoginResponseDto?> LoginAsync(string usuario, string contrasena)
    {
        var user = await _context.Usuarios
            .Include(u => u.Rol)
            .FirstOrDefaultAsync(u => u.NombreUsuario == usuario && u.Activo && u.Rol.Activo);

        if (user is null || !PasswordHasher.Verify(contrasena, user.HashPassword, out var needsUpgrade))
            return null;

        if (needsUpgrade)
        {
            user.HashPassword = PasswordHasher.Hash(contrasena);
            user.FechaActualizacion = DateTime.Now;
            await _context.SaveChangesAsync();
        }

        var nombre = await _institutional.ObtenerNombrePersonaAsync(user.CodPersonaCorporativa)
                     ?? user.NombreUsuario;
        var token = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{user.Id}:{user.NombreUsuario}:{DateTime.UtcNow.Ticks}"));
        return new LoginResponseDto(user.Id, nombre, user.Rol.Nombre.Trim(), token);
    }
}

public class SqlCatalogoRepository : ICatalogoRepository
{
    private readonly CosaaltInstitutionalReader _institutional;

    public SqlCatalogoRepository(CosaaltInstitutionalReader institutional) => _institutional = institutional;

    public Task<IReadOnlyList<MotivoCambioDto>> ObtenerMotivosAsync(bool incluirInactivos = false) =>
        _institutional.ObtenerMotivosAsync(incluirInactivos);

    public Task<MotivoCambioDto> CrearMotivoAsync(GuardarMotivoCambioRequestDto request) =>
        _institutional.CrearMotivoAsync(request);

    public Task<MotivoCambioDto?> ActualizarMotivoAsync(int id, GuardarMotivoCambioRequestDto request) =>
        _institutional.ActualizarMotivoAsync(id, request);

    public Task<MotivoCambioDto?> CambiarEstadoMotivoAsync(int id, bool activo) =>
        _institutional.CambiarEstadoMotivoAsync(id, activo);

    public Task<IReadOnlyList<MarcaMedidorDto>> ObtenerMarcasAsync(bool incluirInactivos = true) =>
        _institutional.ObtenerMarcasAsync(incluirInactivos);

    public Task<MarcaMedidorDto> CrearMarcaAsync(GuardarMarcaMedidorRequestDto request) =>
        _institutional.CrearMarcaAsync(request);

    public Task<MarcaMedidorDto?> ActualizarMarcaAsync(int id, GuardarMarcaMedidorRequestDto request) =>
        _institutional.ActualizarMarcaAsync(id, request);

    public Task<MarcaMedidorDto?> CambiarEstadoMarcaAsync(int id, bool activo) =>
        _institutional.CambiarEstadoMarcaAsync(id, activo);

    public Task<IReadOnlyList<MedidorDisponibleDto>> ObtenerMedidoresDisponiblesAsync(string? buscar = null, int limite = 100) =>
        _institutional.ObtenerMedidoresDisponiblesAsync(buscar, limite);
}

public class SqlSolicitudRepository : ISolicitudRepository
{
    private readonly CosaaltDbContext _context;
    private readonly CosaaltInstitutionalReader _institutional;
    private readonly IConfiguration _configuration;

    public SqlSolicitudRepository(CosaaltDbContext context, CosaaltInstitutionalReader institutional, IConfiguration configuration)
    {
        _context = context;
        _institutional = institutional;
        _configuration = configuration;
    }

    public async Task<SolicitudesResponseDto> ObtenerSolicitudesAsync(string? filtro = null)
    {
        var tipos = ParseIds(_configuration["CosaaltRules:OdecoTipoReclamoIds"]);
        var odecos = await _institutional.ObtenerOdecosAsync(tipos, 2000);

        var asignadas = await _context.DetallesRuta.AsNoTracking()
            .Where(d => d.TipoOrigen == "ODECO" && d.Estado != "Cancelada")
            .Select(d => d.IdOrigen)
            .ToListAsync();
        var completadas = await _context.EjecucionesCambio.AsNoTracking()
            .Where(e => e.TipoOrigen == "ODECO")
            .Select(e => e.IdOrigen)
            .ToListAsync();
        var asignadasSet = asignadas.ToHashSet(StringComparer.OrdinalIgnoreCase);
        var completadasSet = completadas.ToHashSet(StringComparer.OrdinalIgnoreCase);

        var items = odecos.Select(o => ToSolicitud(o, asignadasSet, completadasSet)).ToList();

        // Bateria E2E opcional: vive solo en medidores.SolicitudPruebaE2E y nunca toca dbo.
        var qa = (await _institutional.ObtenerSolicitudesPruebaAsync()).ToList();
        if (qa.Count > 0)
        {
            var qaIds = qa.Select(x => x.Id).ToArray();
            var estadosQaRows = await _context.DetallesRuta.AsNoTracking()
                .Where(d => qaIds.Contains(d.SolicitudId) && d.Estado != "Cancelada")
                .GroupBy(d => d.SolicitudId)
                .Select(g => new { SolicitudId = g.Key, Completada = g.Any(x => x.Estado == "Completada") })
                .ToListAsync();
            var estadosQa = estadosQaRows.ToDictionary(x => x.SolicitudId, x => x.Completada, StringComparer.OrdinalIgnoreCase);
            foreach (var item in qa)
            {
                if (estadosQa.TryGetValue(item.Id, out var completadaQa))
                    items.Add(item with { Estado = completadaQa ? "Completada" : "Asignada" });
                else
                    items.Add(item);
            }
        }

        if (!string.IsNullOrWhiteSpace(filtro))
        {
            var q = filtro.Trim();
            items = items.Where(s =>
                s.Id.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                s.CodCon.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                s.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                s.Direccion.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                (s.NumeroMedidor?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false) ||
                (s.MotivoObservacion?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false))
                .ToList();
        }

        items = items.OrderByDescending(x => x.EsUrgente).ThenBy(x => x.Estado == "Completada").ThenByDescending(x => x.FechaSolicitud).ToList();
        var hoy = DateTime.Today;
        var completadasHoy = await _context.EjecucionesCambio.AsNoTracking().CountAsync(e => e.FechaHoraEjecucion >= hoy && e.FechaHoraEjecucion < hoy.AddDays(1));
        var resumen = new DashboardResumenDto(
            items.Count(x => x.TipoOrigen == "ODECO" && x.EsUrgente && x.Estado != "Completada"),
            0,
            completadasHoy);
        return new SolicitudesResponseDto(resumen, items);
    }

    public async Task<SolicitudBandejaDto?> ObtenerPorIdAsync(string id)
    {
        if (id.StartsWith("QA-", StringComparison.OrdinalIgnoreCase))
        {
            var qa = await _institutional.ObtenerSolicitudPruebaAsync(id);
            if (qa is null) return null;
            var detalleQa = await _context.DetallesRuta.AsNoTracking()
                .Where(d => d.SolicitudId == id && d.Estado != "Cancelada")
                .OrderByDescending(d => d.Id)
                .FirstOrDefaultAsync();
            return detalleQa is null ? qa : qa with { Estado = detalleQa.Estado == "Completada" ? "Completada" : "Asignada" };
        }

        var codRec = ParseOdecoId(id);
        if (!codRec.HasValue) return null;
        var o = await _institutional.ObtenerOdecoAsync(codRec.Value);
        if (o is null) return null;

        var origen = codRec.Value.ToString();
        var asignada = await _context.DetallesRuta.AsNoTracking().AnyAsync(d => d.TipoOrigen == "ODECO" && d.IdOrigen == origen && d.Estado != "Cancelada");
        var completada = await _context.EjecucionesCambio.AsNoTracking().AnyAsync(e => e.TipoOrigen == "ODECO" && e.IdOrigen == origen);
        return ToSolicitud(o,
            asignada ? new HashSet<string>(StringComparer.OrdinalIgnoreCase) { origen } : new HashSet<string>(StringComparer.OrdinalIgnoreCase),
            completada ? new HashSet<string>(StringComparer.OrdinalIgnoreCase) { origen } : new HashSet<string>(StringComparer.OrdinalIgnoreCase));
    }

    private static SolicitudBandejaDto ToSolicitud(OdecoInstitucional o, HashSet<string> asignadas, HashSet<string> completadas)
    {
        var origen = o.CodRec.ToString();
        var estado = completadas.Contains(origen) ? "Completada" : asignadas.Contains(origen) ? "Asignada" : "Pendiente";
        var prioridad = o.Prioridad?.Trim();
        var urgente = (prioridad?.Contains("URG", StringComparison.OrdinalIgnoreCase) ?? false)
                      || (prioridad?.Contains("ALT", StringComparison.OrdinalIgnoreCase) ?? false)
                      || o.CodPrioridad == 1;
        var motivo = string.Join(" - ", new[] { o.TipoReclamo, o.Observacion }.Where(x => !string.IsNullOrWhiteSpace(x)));
        return new SolicitudBandejaDto(
            Id: $"ODECO-{o.CodRec}",
            TipoOrigen: "ODECO",
            Estado: estado,
            EsUrgente: urgente,
            CodCon: o.RegSoc,
            NombreCliente: o.NombreSocio,
            Direccion: o.Direccion,
            Categoria: prioridad,
            Ruta: null,
            Recorrido: null,
            NumeroMedidor: o.SerieMedidor,
            MarcaMedidor: o.MarcaMedidor,
            LecturaAnterior: o.LecturaAnterior,
            LecturaActual: o.LecturaActual,
            Consumo: o.Consumo,
            MotivoObservacion: string.IsNullOrWhiteSpace(motivo) ? null : motivo,
            FechaSolicitud: o.Fecha,
            FolioOdeco: o.CodRec,
            ConclusionOdeco: null,
            Latitud: o.Latitud.HasValue ? (double?)o.Latitud.Value : null,
            Longitud: o.Longitud.HasValue ? (double?)o.Longitud.Value : null);
    }

    internal static int? ParseOdecoId(string? id)
    {
        if (string.IsNullOrWhiteSpace(id)) return null;
        var clean = id.Trim();
        if (clean.StartsWith("ODECO-", StringComparison.OrdinalIgnoreCase)) clean = clean[6..];
        return int.TryParse(clean, out var value) ? value : null;
    }

    internal static IReadOnlyCollection<int>? ParseIds(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        var values = raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(x => int.TryParse(x, out var v) ? (int?)v : null)
            .Where(x => x.HasValue)
            .Select(x => x!.Value)
            .Distinct()
            .ToArray();
        return values.Length == 0 ? null : values;
    }
}

public class SqlEjecucionRepository : IEjecucionRepository
{
    private readonly CosaaltDbContext _context;
    private readonly CosaaltInstitutionalReader _institutional;

    public SqlEjecucionRepository(CosaaltDbContext context, CosaaltInstitutionalReader institutional)
    {
        _context = context;
        _institutional = institutional;
    }

    public async Task<EjecucionCambioResponseDto> RegistrarAsync(EjecucionCambioRequestDto request)
    {
        var tipoOrigen = (request.TipoOrigen ?? string.Empty).Trim().ToUpperInvariant();
        if (tipoOrigen is not ("ODECO" or "LECTURA" or "REVISION"))
            throw new ArgumentException("TipoOrigen debe ser ODECO, LECTURA o REVISION.");
        if (string.IsNullOrWhiteSpace(request.IdOrigen))
            throw new ArgumentException("IdOrigen es obligatorio.");
        if (string.IsNullOrWhiteSpace(request.NumeroMedidorInstalado) && !request.CodMedidorInstalado.HasValue)
            throw new ArgumentException("Debe indicar el medidor instalado.");

        var idOrigen = NormalizeOrigenId(tipoOrigen, request.IdOrigen);
        var existente = await _context.EjecucionesCambio
            .AsNoTracking()
            .FirstOrDefaultAsync(e => e.TipoOrigen == tipoOrigen && e.IdOrigen == idOrigen);
        if (existente is not null)
        {
            await MarcarDetalleCompletadoAsync(tipoOrigen, idOrigen, existente.FechaHoraEjecucion);
            return new EjecucionCambioResponseDto(existente.Id, "La ejecucion ya habia sido registrada; no se duplico.", existente.Sincronizado, true);
        }

        var usuario = await _context.Usuarios.AsNoTracking().Include(u => u.Rol)
            .FirstOrDefaultAsync(u => u.Id == request.IdUsuarioApp && u.Activo && u.Rol.Activo
                && (u.Rol.Nombre.ToLower() == "tecnico" || u.Rol.Nombre.ToLower() == "asignador"));
        if (usuario is null) throw new InvalidOperationException("El ejecutor no existe, esta inactivo o no tiene rol tecnico/asignador.");

        var regSoc = request.RegSoc
                     ?? await ResolveRegSocAsync(tipoOrigen, idOrigen)
                     ?? throw new InvalidOperationException("No fue posible determinar el socio de la solicitud.");

        MedidorInstitucional? retirado = null;
        if (request.CodMedidorRetirado.HasValue)
            retirado = await _institutional.ObtenerMedidorPorCodigoAsync(request.CodMedidorRetirado.Value);
        if (retirado is null && !string.IsNullOrWhiteSpace(request.NumeroMedidorRetirado))
            retirado = await _institutional.ObtenerMedidorPorSerieAsync(request.NumeroMedidorRetirado, regSoc);
        retirado ??= await _institutional.ObtenerMedidorActualAsync(regSoc);

        MedidorInstitucional? instalado = null;
        if (request.CodMedidorInstalado.HasValue)
            instalado = await _institutional.ObtenerMedidorPorCodigoAsync(request.CodMedidorInstalado.Value);
        if (instalado is null && !string.IsNullOrWhiteSpace(request.NumeroMedidorInstalado))
            instalado = await _institutional.ObtenerMedidorDisponiblePorSerieAsync(request.NumeroMedidorInstalado);
        if (instalado is null)
            throw new InvalidOperationException("El medidor instalado no existe o no cumple la regla provisional de disponibilidad: PERFECTO + L + sin socio.");
        if (instalado.CodigoEstado != 5 || !string.Equals(instalado.Disponibilidad?.Trim(), "L", StringComparison.OrdinalIgnoreCase) || instalado.RegSoc != 0)
            throw new InvalidOperationException("El medidor seleccionado ya no se encuentra disponible para instalacion.");

        var yaUsado = await _context.EjecucionesCambio.AsNoTracking().AnyAsync(e => e.CodMedidorInstalado == instalado.CodMedidor);
        if (yaUsado) throw new InvalidOperationException("El medidor seleccionado ya fue utilizado en otra ejecucion registrada por la aplicacion.");

        string? motivo = null;
        try { motivo = (await _institutional.ObtenerMotivoAsync(request.IdMotivo))?.Descripcion; }
        catch (IntegrationPendingException) { motivo = $"Motivo institucional #{request.IdMotivo}"; }

        var (lat, lon) = ParseCoordinates(request);
        var now = request.FechaHoraEjecucion == default ? DateTime.Now : request.FechaHoraEjecucion;
        var entity = new EjecucionCambio
        {
            TipoOrigen = tipoOrigen,
            IdOrigen = idOrigen,
            RegSoc = regSoc,
            IdUsuarioApp = request.IdUsuarioApp,
            FechaHoraEjecucion = now,
            CodMedidorRetirado = retirado?.CodMedidor,
            SerieMedidorRetirado = !string.IsNullOrWhiteSpace(request.NumeroMedidorRetirado) ? request.NumeroMedidorRetirado.Trim() : retirado?.Serie ?? "SIN-DATO",
            MarcaRetirado = request.MarcaRetirado ?? retirado?.Marca,
            LecturaRetiro = request.LecturaRetiro,
            IdMotivoInstitucional = request.IdMotivo,
            MotivoDescripcionSnapshot = motivo,
            CodMedidorInstalado = instalado.CodMedidor,
            SerieMedidorInstalado = instalado.Serie,
            MarcaInstalado = request.MarcaInstalado ?? instalado.Marca,
            ObservacionesInstalacion = string.IsNullOrWhiteSpace(request.ObservacionesInstalacion) ? null : request.ObservacionesInstalacion.Trim(),
            Latitud = lat,
            Longitud = lon,
            Sincronizado = true,
            FechaSincronizacion = DateTime.Now,
            EstadoIntegracionInstitucional = "PENDIENTE",
            Evidencias = request.Evidencias?.Where(e => !string.IsNullOrWhiteSpace(e.RutaArchivo)).Select(e => new EvidenciaFotografica
            {
                TipoFoto = e.TipoFoto.Trim(),
                RutaArchivo = e.RutaArchivo.Trim(),
                FechaRegistro = DateTime.Now
            }).ToList() ?? []
        };

        _context.EjecucionesCambio.Add(entity);
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            // Un intento concurrente puede haber insertado la misma ejecución.
            // Limpiamos el estado Added antes de reparar la ruta y responder.
            _context.ChangeTracker.Clear();
            var dup = await _context.EjecucionesCambio.AsNoTracking().FirstOrDefaultAsync(e => e.TipoOrigen == tipoOrigen && e.IdOrigen == idOrigen);
            if (dup is not null)
            {
                await MarcarDetalleCompletadoAsync(tipoOrigen, idOrigen, dup.FechaHoraEjecucion);
                return new EjecucionCambioResponseDto(dup.Id, "La ejecucion ya habia sido registrada; no se duplico.", dup.Sincronizado, true);
            }

            var medidorDuplicado = await _context.EjecucionesCambio.AsNoTracking()
                .AnyAsync(e => e.CodMedidorInstalado == instalado.CodMedidor);
            if (medidorDuplicado)
                throw new InvalidOperationException("El medidor seleccionado ya fue utilizado en otra ejecucion registrada por la aplicacion.");

            throw;
        }

        await MarcarDetalleCompletadoAsync(tipoOrigen, idOrigen, now);

        return EjecucionMapper.ToResponse(entity);
    }

    private async Task MarcarDetalleCompletadoAsync(string tipoOrigen, string idOrigen, DateTime fecha)
    {
        var detalle = await _context.DetallesRuta.FirstOrDefaultAsync(d => d.TipoOrigen == tipoOrigen && d.IdOrigen == idOrigen && d.Estado != "Cancelada");
        if (detalle is not null)
        {
            detalle.Estado = "Completada";
            detalle.FechaFinalizacion ??= fecha;

            var ruta = await _context.AsignacionesRuta
                .Include(r => r.Detalles)
                .FirstOrDefaultAsync(r => r.Id == detalle.IdAsignacion);
            if (ruta is not null)
            {
                var activos = ruta.Detalles.Where(d => d.Estado != "Cancelada").ToList();
                ruta.Estado = activos.Count > 0 && activos.All(d => d.Estado == "Completada")
                    ? "Finalizado"
                    : "EnCurso";
            }

            await _context.SaveChangesAsync();
        }
    }

    public async Task<IReadOnlyList<EjecucionHistorialDto>> ObtenerHistorialAsync(int? codCon = null, int? idUsuarioApp = null)
    {
        var query = _context.EjecucionesCambio.AsNoTracking()
            .Include(e => e.Usuario).ThenInclude(u => u.Rol)
            .Include(e => e.Evidencias)
            .AsQueryable();
        if (codCon.HasValue) query = query.Where(e => e.RegSoc == codCon.Value);
        if (idUsuarioApp.HasValue) query = query.Where(e => e.IdUsuarioApp == idUsuarioApp.Value);
        var rows = await query.OrderByDescending(e => e.FechaHoraEjecucion).Take(2000).ToListAsync();

        var result = new List<EjecucionHistorialDto>(rows.Count);
        var nombres = new Dictionary<int, string>();
        var socios = new Dictionary<int, SocioInstitucional?>();
        foreach (var e in rows)
        {
            if (!nombres.TryGetValue(e.IdUsuarioApp, out var nombreTecnico))
            {
                nombreTecnico = await _institutional.ObtenerNombrePersonaAsync(e.Usuario.CodPersonaCorporativa) ?? e.Usuario.NombreUsuario;
                nombres[e.IdUsuarioApp] = nombreTecnico;
            }
            if (!socios.TryGetValue(e.RegSoc, out var socio))
            {
                socio = await _institutional.ObtenerSocioAsync(e.RegSoc);
                socios[e.RegSoc] = socio;
            }
            var detalle = await _context.DetallesRuta.AsNoTracking().FirstOrDefaultAsync(d => d.TipoOrigen == e.TipoOrigen && d.IdOrigen == e.IdOrigen);
            result.Add(new EjecucionHistorialDto(
                e.Id, e.TipoOrigen, e.IdOrigen, detalle?.SolicitudId ?? $"{e.TipoOrigen}-{e.IdOrigen}", e.FechaHoraEjecucion,
                e.RegSoc, socio?.Nombre, detalle?.Direccion,
                e.SerieMedidorRetirado, e.MarcaRetirado, e.LecturaRetiro,
                e.SerieMedidorInstalado, e.MarcaInstalado, e.ObservacionesInstalacion,
                nombreTecnico, e.MotivoDescripcionSnapshot,
                e.Evidencias.Select(x => new EvidenciaHistorialDto(x.TipoFoto, x.RutaArchivo)).ToList()));
        }
        return result;
    }

    private async Task<int?> ResolveRegSocAsync(string tipoOrigen, string idOrigen)
    {
        var detalle = await _context.DetallesRuta.AsNoTracking().FirstOrDefaultAsync(d => d.TipoOrigen == tipoOrigen && d.IdOrigen == idOrigen);
        if (detalle?.RegSoc is not null) return detalle.RegSoc;
        if (tipoOrigen == "ODECO" && int.TryParse(idOrigen, out var codRec))
            return (await _institutional.ObtenerOdecoAsync(codRec))?.RegSoc;
        return null;
    }

    private static string NormalizeOrigenId(string tipo, string id)
    {
        var clean = id.Trim();
        if (tipo == "ODECO" && clean.StartsWith("ODECO-", StringComparison.OrdinalIgnoreCase)) clean = clean[6..];
        if (tipo == "LECTURA" && clean.StartsWith("LEC-", StringComparison.OrdinalIgnoreCase)) clean = clean[4..];
        return clean;
    }

    private static (decimal? Lat, decimal? Lon) ParseCoordinates(EjecucionCambioRequestDto request)
    {
        if (request.Latitud.HasValue || request.Longitud.HasValue) return (request.Latitud, request.Longitud);
        if (string.IsNullOrWhiteSpace(request.LatLong)) return (null, null);
        var p = request.LatLong.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        if (p.Length >= 2 && decimal.TryParse(p[0], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var lat)
                          && decimal.TryParse(p[1], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var lon))
            return (lat, lon);
        return (null, null);
    }
}
