using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public sealed class SqlAdminRepository : IAdminRepository
{
    private readonly CosaaltDbContext _context;
    private readonly CosaaltInstitutionalReader _institutional;
    private readonly IConfiguration _configuration;

    public SqlAdminRepository(CosaaltDbContext context, CosaaltInstitutionalReader institutional, IConfiguration configuration)
    {
        _context = context;
        _institutional = institutional;
        _configuration = configuration;
    }

    public async Task<AdminDashboardDto> ObtenerDashboardAsync(DateTime? desde = null, DateTime? hasta = null)
    {
        var ini = (desde ?? DateTime.Today).Date;
        var finEx = (hasta ?? DateTime.Today).Date.AddDays(1);
        var solicitudes = (await BuildSolicitudesAsync()).Where(x => x.FechaSolicitud < finEx && x.FechaSolicitud >= (desde?.Date ?? DateTime.MinValue)).ToList();
        var rutas = await BuildRutasAsync();
        var movimientos = await BuildMovimientosAsync();
        var verificaciones = await BuildVerificacionesAsync();

        var pendientes = solicitudes.Count(x => x.Estado != "Completada" && x.Estado != "Cancelada");
        var odecoPend = solicitudes.Count(x => x.TipoOrigen == "ODECO" && x.Estado != "Completada" && x.Estado != "Cancelada");
        var odecoUrg = solicitudes.Count(x => x.TipoOrigen == "ODECO" && x.Prioridad.Equals("Alta", StringComparison.OrdinalIgnoreCase) && x.Estado != "Completada");
        var odecoVenc = solicitudes.Count(x => x.TipoOrigen == "ODECO" && x.Vencida && x.Estado != "Completada");
        var rutasHoy = rutas.Where(r => r.FechaAsignacion >= ini && r.FechaAsignacion < finEx && r.Estado != "Cancelado").ToList();
        var movHoy = movimientos.Where(m => m.FechaHora >= ini && m.FechaHora < finEx).ToList();

        var tecnicos = await BuildTecnicosResumenAsync(rutasHoy, movimientos);
        var actividad = movimientos.OrderByDescending(x => x.FechaHora).Take(8)
            .Select(x => new AdminActividadDto(x.FechaHora, "CAMBIO", $"Cambio de medidor - {x.NombreCliente}", $"{x.NumeroMedidorRetirado} -> {x.NumeroMedidorInstalado}", x.Sincronizado ? "Sincronizado" : "Pendiente"))
            .Concat(verificaciones.OrderByDescending(x => x.Fecha).Take(6)
                .Select(x => new AdminActividadDto(x.Fecha, "VERIFICACION", $"Verificacion #{x.IdVerificacion}", x.NombreCliente, x.Resultado ?? x.Estado)))
            .OrderByDescending(x => x.Fecha).Take(10).ToList();

        var alertas = new List<AdminAlertaDto>();
        if (odecoVenc > 0) alertas.Add(new AdminAlertaDto("ODECO", "Critica", "Solicitudes vencidas", "Existen solicitudes ODECO pendientes que superaron el plazo de atencion.", odecoVenc));
        var sinSync = movimientos.Count(x => !x.Sincronizado);
        if (sinSync > 0) alertas.Add(new AdminAlertaDto("SINCRONIZACION", "Alta", "Cambios pendientes de sincronizacion", "Existen cambios recibidos por el servidor que requieren revision de sincronizacion.", sinSync));
        if (string.IsNullOrWhiteSpace(_configuration["CosaaltRules:OdecoTipoReclamoIds"]))
            alertas.Add(new AdminAlertaDto("CONFIGURACION", "Informativa", "Tipos de reclamo por confirmar", "El cambio de medidor se incorpora como observacion del inspector y su seleccion se mantiene como proceso de validacion manual de la Unidad de Lecturas o Taller de Medidores.", 1));
        if (!bool.TryParse(_configuration["CosaaltRules:LecturaOrigenConfirmado"], out var lecturaOk) || !lecturaOk)
            alertas.Add(new AdminAlertaDto("CONFIGURACION", "Informativa", "Origen de Lecturas pendiente", "COSAALT confirmo observaciones de lectura 2, 4 y 11 como relevantes. La vinculacion tecnica exacta con el registro de Lectura queda pendiente de cerrar con el Taller de Medidores.", 1));

        var motivos = movimientos.GroupBy(x => string.IsNullOrWhiteSpace(x.Motivo) ? "Sin motivo" : x.Motivo)
            .Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).OrderByDescending(x => x.Cantidad).Take(6).ToList();
        var porEstado = solicitudes.GroupBy(x => x.Estado).Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).OrderByDescending(x => x.Cantidad).ToList();

        return new AdminDashboardDto(
            pendientes, odecoPend, odecoUrg, odecoVenc,
            solicitudes.Count(x => x.TipoOrigen == "LECTURA" && x.Estado != "Completada"),
            rutasHoy.Count, rutasHoy.Select(x => x.IdTecnico).Distinct().Count(),
            movHoy.Count, movHoy.Count(x => x.Sincronizado),
            verificaciones.Count(x => x.Estado == "Pendiente"),
            verificaciones.Count(x => x.Estado == "EnCurso"),
            verificaciones.Count(x => x.Estado == "Completada"),
            verificaciones.Count(x => x.Resultado == "CUMPLE"),
            verificaciones.Count(x => x.Resultado == "NO CUMPLE"),
            porEstado, motivos, tecnicos, actividad, alertas);
    }

    public async Task<PagedResultDto<AdminSolicitudDto>> ObtenerSolicitudesAsync(AdminSolicitudFiltro filtro)
    {
        IEnumerable<AdminSolicitudDto> q = await BuildSolicitudesAsync();
        if (filtro.Desde.HasValue) q = q.Where(x => x.FechaSolicitud >= filtro.Desde.Value.Date);
        if (filtro.Hasta.HasValue) q = q.Where(x => x.FechaSolicitud < filtro.Hasta.Value.Date.AddDays(1));
        if (!string.IsNullOrWhiteSpace(filtro.Origen)) q = q.Where(x => x.TipoOrigen.Equals(filtro.Origen, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Estado)) q = q.Where(x => x.Estado.Equals(filtro.Estado, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Prioridad)) q = q.Where(x => x.Prioridad.Equals(filtro.Prioridad, StringComparison.OrdinalIgnoreCase));
        if (filtro.TecnicoId.HasValue) q = q.Where(x => x.IdTecnico == filtro.TecnicoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var s = filtro.Buscar.Trim();
            q = q.Where(x => x.Id.Contains(s, StringComparison.OrdinalIgnoreCase) || x.CodCon.ToString().Contains(s) || x.NombreCliente.Contains(s, StringComparison.OrdinalIgnoreCase) || x.Direccion.Contains(s, StringComparison.OrdinalIgnoreCase) || (x.NumeroMedidor?.Contains(s, StringComparison.OrdinalIgnoreCase) ?? false) || (x.Motivo?.Contains(s, StringComparison.OrdinalIgnoreCase) ?? false));
        }
        return Page(q.OrderByDescending(x => x.Vencida).ThenByDescending(x => x.FechaSolicitud).ToList(), filtro.Page, filtro.PageSize);
    }

    public async Task<PagedResultDto<AdminRutaDto>> ObtenerRutasAsync(AdminRutaFiltro filtro)
    {
        IEnumerable<AdminRutaDto> q = await BuildRutasAsync();
        if (filtro.Fecha.HasValue) q = q.Where(x => x.FechaAsignacion.Date == filtro.Fecha.Value.Date);
        if (filtro.TecnicoId.HasValue) q = q.Where(x => x.IdTecnico == filtro.TecnicoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Estado)) q = q.Where(x => x.Estado.Equals(filtro.Estado, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var s = filtro.Buscar.Trim();
            q = q.Where(x => x.NombreTecnico.Contains(s, StringComparison.OrdinalIgnoreCase) || x.IdAsignacion.ToString().Contains(s) || x.Detalles.Any(d => d.NombreCliente.Contains(s, StringComparison.OrdinalIgnoreCase) || d.SolicitudId.Contains(s, StringComparison.OrdinalIgnoreCase)));
        }
        return Page(q.OrderByDescending(x => x.FechaAsignacion).ThenByDescending(x => x.IdAsignacion).ToList(), filtro.Page, filtro.PageSize);
    }

    public async Task<AdminRutaDto?> ObtenerRutaAsync(int idAsignacion) => (await BuildRutasAsync()).FirstOrDefault(x => x.IdAsignacion == idAsignacion);

    public async Task<IReadOnlyList<AdminSincronizacionTecnicoDto>> ObtenerSincronizacionAsync(DateTime? fecha = null)
    {
        var day = (fecha ?? DateTime.Today).Date;
        var rutas = (await BuildRutasAsync()).Where(x => x.FechaAsignacion >= day && x.FechaAsignacion < day.AddDays(1)).ToList();
        var movimientos = (await BuildMovimientosAsync()).Where(x => x.FechaHora >= day && x.FechaHora < day.AddDays(1)).ToList();
        var tecnicos = await _context.Usuarios.AsNoTracking().Include(u => u.Rol).Where(u => u.Rol.Nombre.ToLower() == "tecnico").ToListAsync();
        var result = new List<AdminSincronizacionTecnicoDto>();
        foreach (var t in tecnicos)
        {
            var name = await _institutional.ObtenerNombrePersonaAsync(t.CodPersonaCorporativa) ?? t.NombreUsuario;
            var tr = rutas.Where(r => r.IdTecnico == t.Id).ToList();
            var tm = movimientos.Where(m => m.IdTecnico == t.Id).ToList();
            var detalles = tr.SelectMany(x => x.Detalles).ToList();
            var completadasSinEjec = detalles.Count(d => d.Estado == "Completada" && !d.Ejecutada);
            var ejecSinParada = tm.Count(m => !detalles.Any(d => d.TipoOrigen == m.TipoOrigen && ExtractOrigen(d.SolicitudId) == m.IdOrigen));
            result.Add(new AdminSincronizacionTecnicoDto(
                t.Id, name, t.Activo, tr.Count, detalles.Count, detalles.Count(d => d.Estado == "Completada"), tm.Count,
                tm.Count(m => m.Sincronizado), tm.Count(m => !m.Sincronizado), completadasSinEjec, ejecSinParada, 0,
                tm.OrderByDescending(x => x.FechaHora).FirstOrDefault()?.FechaHora,
                tm.Any(m => !m.Sincronizado) || completadasSinEjec > 0 ? "Revisar" : "Correcto",
                "Datos recibidos y persistidos por la aplicacion"));
        }
        return result.OrderBy(x => x.NombreTecnico).ToList();
    }

    public async Task<PagedResultDto<AdminVerificacionResumenDto>> ObtenerVerificacionesAsync(AdminVerificacionFiltro filtro)
    {
        var items = ApplyVerificacionFilter(await BuildVerificacionesAsync(), filtro).OrderByDescending(x => x.Fecha).ToList();
        return Page(items, filtro.Page, filtro.PageSize);
    }

    public async Task<IReadOnlyList<AdminVerificacionResumenDto>> ObtenerVerificacionesExportAsync(AdminVerificacionFiltro filtro, int maximo = 50000) =>
        ApplyVerificacionFilter(await BuildVerificacionesAsync(), filtro).OrderByDescending(x => x.Fecha).Take(maximo).ToList();

    public async Task<AdminVerificacionDetalleDto?> ObtenerVerificacionDetalleAsync(int idVerificacion)
    {
        var v = await _context.Verificaciones.AsNoTracking()
            .Include(x => x.Mecanico).ThenInclude(u => u.Rol)
            .Include(x => x.Ensayo)
            .Include(x => x.Participantes)
            .Include(x => x.Informes)
            .FirstOrDefaultAsync(x => x.Id == idVerificacion);
        if (v is null) return null;
        var resumen = (await BuildVerificacionesAsync()).First(x => x.IdVerificacion == idVerificacion);
        var socio = await _institutional.ObtenerSocioAsync(v.RegSoc);
        var med = await _institutional.ObtenerMedidorPorCodigoAsync(v.CodMedidor);
        var ruta = await _context.DetallesRuta.AsNoTracking().FirstOrDefaultAsync(d => d.TipoOrigen == v.TipoOrigen && d.IdOrigen == v.IdOrigen);
        var datos = new DatosSocioMedidorDto(v.RegSoc, socio?.Nombre ?? $"Socio {v.RegSoc}", ruta?.Direccion ?? string.Empty, null, socio?.Documento, null, socio?.Ruc, med?.Serie, med?.Marca, med?.FechaRegistro);
        var ensayo = v.Ensayo is null ? null : new EnsayoVerificacionDto(v.Ensayo.Id, v.Ensayo.Condiciones, v.Ensayo.LecturaInicial, v.Ensayo.LecturaFinal, v.Ensayo.VolumenPatron, v.Ensayo.Caudal, v.Ensayo.VolumenRegistrado, v.Ensayo.Error, v.Ensayo.Fugas, v.Ensayo.Observaciones);
        var participantes = v.Participantes.OrderBy(x => x.Id).Select(x => new ParticipanteVerificacionDto(x.Id, x.Nombre, x.Cargo, x.Rol)).ToList();
        var informes = v.Informes.OrderByDescending(x => x.FechaEmision).Select(x => new AdminInformeVerificacionDto(x.Id, x.NroInforme, x.FechaEmision, x.FechaFirma, x.RutaPdf, x.Firmado, x.VersionInforme)).ToList();
        return new AdminVerificacionDetalleDto(resumen, datos, ensayo, participantes, informes);
    }

    public async Task<PagedResultDto<AdminMovimientoDto>> ObtenerMovimientosAsync(AdminMovimientoFiltro filtro)
    {
        var items = ApplyMovimientoFilter(await BuildMovimientosAsync(), filtro).OrderByDescending(x => x.FechaHora).ToList();
        return Page(items, filtro.Page, filtro.PageSize);
    }

    public async Task<IReadOnlyList<AdminMovimientoDto>> ObtenerMovimientosExportAsync(AdminMovimientoFiltro filtro, int maximo = 50000) =>
        ApplyMovimientoFilter(await BuildMovimientosAsync(), filtro).OrderByDescending(x => x.FechaHora).Take(maximo).ToList();

    public async Task<PagedResultDto<AdminMovimientoCorporativoDto>> ObtenerHistoricoCorporativoAsync(AdminMovimientoCorporativoFiltro filtro)
    {
        var items = ApplyHistoricoFilter(await BuildHistoricoAsync(filtro.CodCon), filtro).ToList();
        return Page(items, filtro.Page, filtro.PageSize);
    }

    public async Task<IReadOnlyList<AdminMovimientoCorporativoDto>> ObtenerHistoricoCorporativoExportAsync(AdminMovimientoCorporativoFiltro filtro, int maximo = 50000) =>
        ApplyHistoricoFilter(await BuildHistoricoAsync(filtro.CodCon), filtro).Take(maximo).ToList();

    public async Task<AdminEstadisticasDto> ObtenerEstadisticasAsync(AdminEstadisticasFiltro filtro)
    {
        IEnumerable<AdminMovimientoDto> mov = await BuildMovimientosAsync();
        IEnumerable<AdminVerificacionResumenDto> ver = await BuildVerificacionesAsync();
        if (filtro.Desde.HasValue) { mov = mov.Where(x => x.FechaHora >= filtro.Desde.Value.Date); ver = ver.Where(x => x.Fecha >= filtro.Desde.Value.Date); }
        if (filtro.Hasta.HasValue) { var e = filtro.Hasta.Value.Date.AddDays(1); mov = mov.Where(x => x.FechaHora < e); ver = ver.Where(x => x.Fecha < e); }
        if (filtro.TecnicoId.HasValue) mov = mov.Where(x => x.IdTecnico == filtro.TecnicoId.Value);
        if (filtro.MecanicoId.HasValue) ver = ver.Where(x => x.IdMecanico == filtro.MecanicoId.Value);
        if (filtro.MotivoId.HasValue) mov = mov.Where(x => x.IdMotivo == filtro.MotivoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Origen)) mov = mov.Where(x => x.TipoOrigen.Equals(filtro.Origen, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Marca)) mov = mov.Where(x => (x.MarcaRetirado?.Equals(filtro.Marca, StringComparison.OrdinalIgnoreCase) ?? false));
        var ml = mov.ToList(); var vl = ver.ToList();
        var cumple = vl.Count(x => x.Resultado == "CUMPLE"); var no = vl.Count(x => x.Resultado == "NO CUMPLE");
        var evaluadas = cumple + no;
        var motivos = ml.GroupBy(x => x.Motivo).Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).OrderByDescending(x => x.Cantidad).ToList();
        var marcas = ml.GroupBy(x => x.MarcaRetirado ?? "Sin marca").Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).OrderByDescending(x => x.Cantidad).ToList();
        var origen = ml.GroupBy(x => x.TipoOrigen).Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count())).OrderByDescending(x => x.Cantidad).ToList();
        var serie = ml.GroupBy(x => x.FechaHora.Date).OrderBy(g => g.Key).Select(g => new AdminSerieTemporalDto(g.Key.ToString("yyyy-MM-dd"), g.Count())).ToList();
        var tecnicos = ml.GroupBy(x => new { x.IdTecnico, x.NombreTecnico }).Select(g => new AdminPersonaMetricaDto(g.Key.IdTecnico, g.Key.NombreTecnico, "tecnico", g.Count(), null, 0, 0)).OrderByDescending(x => x.Atenciones).ToList();
        var mecanicos = vl.GroupBy(x => new { x.IdMecanico, x.NombreMecanico }).Select(g => new AdminPersonaMetricaDto(g.Key.IdMecanico, g.Key.NombreMecanico, "mecanico", g.Count(), g.Where(x => x.Error.HasValue).Select(x => x.Error!.Value).DefaultIfEmpty().Average(), g.Count(x => x.Resultado == "CUMPLE"), g.Count(x => x.Resultado == "NO CUMPLE"))).OrderByDescending(x => x.Atenciones).ToList();
        decimal? errorProm = vl.Any(x => x.Error.HasValue) ? vl.Where(x => x.Error.HasValue).Average(x => x.Error!.Value) : null;
        return new AdminEstadisticasDto(ml.Count, vl.Count, cumple, no, evaluadas == 0 ? 0 : Math.Round(cumple * 100m / evaluadas, 2), vl.Count(x => x.Fugas == true), errorProm, null, motivos, marcas, origen, serie, tecnicos, mecanicos);
    }

    private async Task<List<AdminSolicitudDto>> BuildSolicitudesAsync()
    {
        var tipos = SqlSolicitudRepository.ParseIds(_configuration["CosaaltRules:OdecoTipoReclamoIds"]);
        var odecos = await _institutional.ObtenerOdecosAsync(tipos, 1000);
        var rutas = await _context.DetallesRuta.AsNoTracking().Include(d => d.Asignacion).ThenInclude(a => a.Tecnico).ToListAsync();
        var ejec = await _context.EjecucionesCambio.AsNoTracking().ToListAsync();
        var nombres = await GetUserNamesAsync();
        var list = new List<AdminSolicitudDto>();
        foreach (var o in odecos)
        {
            var idOrigen = o.CodRec.ToString();
            var e = ejec.Where(x => x.TipoOrigen == "ODECO" && x.IdOrigen == idOrigen).OrderByDescending(x => x.FechaHoraEjecucion).FirstOrDefault();
            var d = rutas.Where(x => x.TipoOrigen == "ODECO" && x.IdOrigen == idOrigen && x.Estado != "Cancelada").OrderByDescending(x => x.Id).FirstOrDefault();
            var prioridad = NormalizePrioridad(o.Prioridad, o.CodPrioridad);
            var limite = prioridad == "Alta" ? o.Fecha.AddHours(24) : (DateTime?)null;
            var estado = e is not null ? "Completada" : d is not null ? (d.Estado == "Pendiente" ? "Asignada" : d.Estado) : "Pendiente";
            var motivo = string.Join(" - ", new[] { o.TipoReclamo, o.Observacion }.Where(x => !string.IsNullOrWhiteSpace(x)));
            list.Add(new AdminSolicitudDto($"ODECO-{o.CodRec}", "ODECO", o.Fecha, limite, limite.HasValue && limite.Value < DateTime.Now && e is null,
                Math.Max(0, (DateTime.Today - o.Fecha.Date).Days), o.RegSoc, o.NombreSocio, o.Direccion,
                string.IsNullOrWhiteSpace(motivo) ? null : motivo, prioridad, estado,
                d?.Asignacion.IdUsuarioApp, d is null ? null : nombres.GetValueOrDefault(d.Asignacion.IdUsuarioApp, d.Asignacion.Tecnico.NombreUsuario),
                o.SerieMedidor, o.MarcaMedidor, o.LecturaAnterior, o.LecturaActual, o.Consumo, e?.FechaHoraEjecucion, e is not null));
        }

        // La bateria QA vive en medidores.SolicitudPruebaE2E y es leida por la
        // bandeja del asignador. Administracion debe consumir exactamente la
        // misma fuente para que las busquedas QA-* y los totales sean coherentes.
        // Si la tabla temporal no existe, el lector devuelve una lista vacia.
        var qa = await _institutional.ObtenerSolicitudesPruebaAsync();
        foreach (var s in qa)
        {
            var e = ejec.Where(x => x.TipoOrigen.Equals(s.TipoOrigen, StringComparison.OrdinalIgnoreCase)
                                  && x.IdOrigen.Equals(s.Id, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(x => x.FechaHoraEjecucion)
                .FirstOrDefault();
            var d = rutas.Where(x => x.TipoOrigen.Equals(s.TipoOrigen, StringComparison.OrdinalIgnoreCase)
                                   && (x.IdOrigen.Equals(s.Id, StringComparison.OrdinalIgnoreCase)
                                       || x.SolicitudId.Equals(s.Id, StringComparison.OrdinalIgnoreCase))
                                   && x.Estado != "Cancelada")
                .OrderByDescending(x => x.Id)
                .FirstOrDefault();
            var prioridad = s.EsUrgente ? "Alta" : "Normal";
            var limite = s.EsUrgente ? s.FechaSolicitud.AddHours(24) : (DateTime?)null;
            var estado = e is not null ? "Completada"
                : d is not null ? (d.Estado == "Pendiente" ? "Asignada" : d.Estado)
                : s.Estado;

            list.Add(new AdminSolicitudDto(
                s.Id, s.TipoOrigen, s.FechaSolicitud, limite,
                limite.HasValue && limite.Value < DateTime.Now && e is null,
                Math.Max(0, (DateTime.Today - s.FechaSolicitud.Date).Days),
                s.CodCon, s.NombreCliente, s.Direccion, s.MotivoObservacion,
                prioridad, estado,
                d?.Asignacion.IdUsuarioApp,
                d is null ? null : nombres.GetValueOrDefault(d.Asignacion.IdUsuarioApp, d.Asignacion.Tecnico.NombreUsuario),
                s.NumeroMedidor, s.MarcaMedidor, s.LecturaAnterior, s.LecturaActual,
                s.Consumo, e?.FechaHoraEjecucion, e is not null));
        }
        return list;
    }

    private async Task<List<AdminRutaDto>> BuildRutasAsync()
    {
        var rows = await _context.AsignacionesRuta.AsNoTracking().Include(a => a.Tecnico).Include(a => a.Detalles).OrderByDescending(a => a.FechaAsignacion).ToListAsync();
        var ejec = await _context.EjecucionesCambio.AsNoTracking().ToListAsync();
        var nombres = await GetUserNamesAsync();
        return rows.Select(a =>
        {
            var det = a.Detalles.OrderBy(x => x.OrdenVisita).Select(d =>
            {
                var e = ejec.Where(x => x.TipoOrigen == d.TipoOrigen && x.IdOrigen == d.IdOrigen).OrderByDescending(x => x.FechaHoraEjecucion).FirstOrDefault();
                return new AdminRutaDetalleDto(d.Id, d.OrdenVisita, d.SolicitudId, d.TipoOrigen, d.NombreCliente, d.Direccion,
                    d.Latitud.HasValue ? (double?)d.Latitud.Value : null, d.Longitud.HasValue ? (double?)d.Longitud.Value : null,
                    d.Estado, e is not null, e?.FechaHoraEjecucion);
            }).ToList();
            var completed = det.Count(x => x.Estado == "Completada" || x.Ejecutada);
            return new AdminRutaDto(a.Id, a.IdUsuarioApp, nombres.GetValueOrDefault(a.IdUsuarioApp, a.Tecnico.NombreUsuario), a.FechaAsignacion, a.Estado,
                det.Count, completed, Math.Max(0, det.Count - completed), det.Count == 0 ? 0 : Math.Round(completed * 100m / det.Count, 2),
                det.Where(x => x.FechaEjecucion.HasValue).Max(x => x.FechaEjecucion), det);
        }).ToList();
    }

    private async Task<List<AdminMovimientoDto>> BuildMovimientosAsync()
    {
        var rows = await _context.EjecucionesCambio.AsNoTracking().Include(e => e.Usuario).Include(e => e.Evidencias).OrderByDescending(e => e.FechaHoraEjecucion).ToListAsync();
        var detalles = await _context.DetallesRuta.AsNoTracking().ToListAsync();
        var nombres = await GetUserNamesAsync();
        var socios = new Dictionary<int, SocioInstitucional?>();
        var list = new List<AdminMovimientoDto>();
        foreach (var e in rows)
        {
            if (!socios.TryGetValue(e.RegSoc, out var socio)) { socio = await _institutional.ObtenerSocioAsync(e.RegSoc); socios[e.RegSoc] = socio; }
            var d = detalles.FirstOrDefault(x => x.TipoOrigen == e.TipoOrigen && x.IdOrigen == e.IdOrigen);
            var latLong = e.Latitud.HasValue && e.Longitud.HasValue ? $"{e.Latitud.Value.ToString(System.Globalization.CultureInfo.InvariantCulture)},{e.Longitud.Value.ToString(System.Globalization.CultureInfo.InvariantCulture)}" : null;
            list.Add(new AdminMovimientoDto(e.Id, e.FechaHoraEjecucion, e.TipoOrigen, e.IdOrigen, e.RegSoc, socio?.Nombre ?? d?.NombreCliente ?? $"Socio {e.RegSoc}", d?.Direccion ?? string.Empty,
                e.SerieMedidorRetirado, e.MarcaRetirado, e.LecturaRetiro, e.IdMotivoInstitucional.HasValue ? (int)e.IdMotivoInstitucional.Value : 0, e.MotivoDescripcionSnapshot ?? "Sin descripcion",
                e.SerieMedidorInstalado, e.MarcaInstalado, e.ObservacionesInstalacion, latLong, e.IdUsuarioApp, nombres.GetValueOrDefault(e.IdUsuarioApp, e.Usuario.NombreUsuario),
                e.Sincronizado, e.Evidencias.Count, e.Evidencias.Select(x => new EvidenciaHistorialDto(x.TipoFoto, x.RutaArchivo)).ToList()));
        }
        return list;
    }

    private async Task<List<AdminVerificacionResumenDto>> BuildVerificacionesAsync()
    {
        var rows = await _context.Verificaciones.AsNoTracking().Include(v => v.Mecanico).Include(v => v.Ensayo).Include(v => v.Informes).OrderByDescending(v => v.FechaVerificacion).ToListAsync();
        var nombres = await GetUserNamesAsync();
        var result = new List<AdminVerificacionResumenDto>();
        foreach (var v in rows)
        {
            var socio = await _institutional.ObtenerSocioAsync(v.RegSoc);
            var med = await _institutional.ObtenerMedidorPorCodigoAsync(v.CodMedidor);
            var informe = v.Informes.OrderByDescending(x => x.FechaEmision).FirstOrDefault();
            result.Add(new AdminVerificacionResumenDto(v.Id, v.TipoOrigen, v.IdOrigen, v.RegSoc, socio?.Nombre ?? $"Socio {v.RegSoc}", med?.Serie, v.FechaVerificacion,
                v.IdUsuarioMecanico, nombres.GetValueOrDefault(v.IdUsuarioMecanico, v.Mecanico.NombreUsuario), v.Estado, v.Resultado, v.Ensayo?.Error, v.Ensayo?.Caudal, v.Ensayo?.Fugas,
                informe is not null, informe?.NroInforme, informe?.Firmado ?? false));
        }
        return result;
    }

    private async Task<List<AdminMovimientoCorporativoDto>> BuildHistoricoAsync(int? regSoc)
    {
        var rows = await _institutional.ObtenerHistoricoMedidoresAsync(regSoc, 10000);
        return rows.Select(h => new AdminMovimientoCorporativoDto(h.Id, h.RegSoc, h.NombreSocio ?? $"Socio {h.RegSoc}", string.Empty,
            h.Serie ?? "Sin serie", h.Marca, h.CoincideConMedidorActual, null,
            string.IsNullOrWhiteSpace(h.EstadoHistorico) ? "Estado historico sin codigo" : $"Estado historico {h.EstadoHistorico}",
            h.FechaInicio.HasValue || h.FechaRetiro.HasValue ? $"Registro historico: {h.FechaInicio:dd/MM/yyyy} - {h.FechaRetiro:dd/MM/yyyy}" : null, null)).ToList();
    }

    private async Task<Dictionary<int, string>> GetUserNamesAsync()
    {
        var users = await _context.Usuarios.AsNoTracking().ToListAsync();
        var dict = new Dictionary<int, string>();
        foreach (var u in users) dict[u.Id] = await _institutional.ObtenerNombrePersonaAsync(u.CodPersonaCorporativa) ?? u.NombreUsuario;
        return dict;
    }

    private async Task<IReadOnlyList<AdminTecnicoResumenDto>> BuildTecnicosResumenAsync(List<AdminRutaDto> rutasHoy, List<AdminMovimientoDto> movimientos)
    {
        var users = await _context.Usuarios.AsNoTracking().Include(u => u.Rol).Where(u => u.Rol.Nombre.ToLower() == "tecnico").ToListAsync();
        var names = await GetUserNamesAsync();
        return users.Select(u =>
        {
            var r = rutasHoy.Where(x => x.IdTecnico == u.Id).ToList();
            var det = r.SelectMany(x => x.Detalles).ToList();
            var total = det.Count; var comp = det.Count(x => x.Estado == "Completada" || x.Ejecutada);
            var last = movimientos.Where(x => x.IdTecnico == u.Id).OrderByDescending(x => x.FechaHora).FirstOrDefault()?.FechaHora;
            var estado = !u.Activo ? "Inactivo" : total == 0 ? "Sin ruta" : comp >= total ? "Completado" : "En ruta";
            return new AdminTecnicoResumenDto(u.Id, names.GetValueOrDefault(u.Id, u.NombreUsuario), u.Activo, r.Count, total, comp, total == 0 ? 0 : Math.Round(comp * 100m / total, 2), last, estado);
        }).OrderBy(x => x.Nombre).ToList();
    }

    private static IEnumerable<AdminVerificacionResumenDto> ApplyVerificacionFilter(IEnumerable<AdminVerificacionResumenDto> q, AdminVerificacionFiltro f)
    {
        if (f.Desde.HasValue) q = q.Where(x => x.Fecha >= f.Desde.Value.Date);
        if (f.Hasta.HasValue) q = q.Where(x => x.Fecha < f.Hasta.Value.Date.AddDays(1));
        if (f.MecanicoId.HasValue) q = q.Where(x => x.IdMecanico == f.MecanicoId.Value);
        if (!string.IsNullOrWhiteSpace(f.Estado)) q = q.Where(x => x.Estado.Equals(f.Estado, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(f.Resultado)) q = q.Where(x => string.Equals(x.Resultado, f.Resultado, StringComparison.OrdinalIgnoreCase));
        if (f.SoloConInforme == true) q = q.Where(x => x.TieneInforme);
        if (!string.IsNullOrWhiteSpace(f.Buscar)) { var s = f.Buscar.Trim(); q = q.Where(x => x.IdVerificacion.ToString().Contains(s) || x.CodCon.ToString().Contains(s) || x.NombreCliente.Contains(s, StringComparison.OrdinalIgnoreCase) || (x.NumeroMedidor?.Contains(s, StringComparison.OrdinalIgnoreCase) ?? false)); }
        return q;
    }

    private static IEnumerable<AdminMovimientoDto> ApplyMovimientoFilter(IEnumerable<AdminMovimientoDto> q, AdminMovimientoFiltro f)
    {
        if (f.Desde.HasValue) q = q.Where(x => x.FechaHora >= f.Desde.Value.Date);
        if (f.Hasta.HasValue) q = q.Where(x => x.FechaHora < f.Hasta.Value.Date.AddDays(1));
        if (f.TecnicoId.HasValue) q = q.Where(x => x.IdTecnico == f.TecnicoId.Value);
        if (f.MotivoId.HasValue) q = q.Where(x => x.IdMotivo == f.MotivoId.Value);
        if (!string.IsNullOrWhiteSpace(f.Origen)) q = q.Where(x => x.TipoOrigen.Equals(f.Origen, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(f.Marca)) q = q.Where(x => string.Equals(x.MarcaRetirado, f.Marca, StringComparison.OrdinalIgnoreCase) || string.Equals(x.MarcaInstalado, f.Marca, StringComparison.OrdinalIgnoreCase));
        if (f.Sincronizado.HasValue) q = q.Where(x => x.Sincronizado == f.Sincronizado.Value);
        if (!string.IsNullOrWhiteSpace(f.Buscar)) { var s = f.Buscar.Trim(); q = q.Where(x => x.CodCon.ToString().Contains(s) || x.NombreCliente.Contains(s, StringComparison.OrdinalIgnoreCase) || x.NumeroMedidorRetirado.Contains(s, StringComparison.OrdinalIgnoreCase) || x.NumeroMedidorInstalado.Contains(s, StringComparison.OrdinalIgnoreCase)); }
        return q;
    }

    private static IEnumerable<AdminMovimientoCorporativoDto> ApplyHistoricoFilter(IEnumerable<AdminMovimientoCorporativoDto> q, AdminMovimientoCorporativoFiltro f)
    {
        if (f.CodCon.HasValue) q = q.Where(x => x.CodCon == f.CodCon.Value);
        if (f.Vigente.HasValue) q = q.Where(x => x.Vigente == f.Vigente.Value);
        if (!string.IsNullOrWhiteSpace(f.Marca)) q = q.Where(x => string.Equals(x.Marca, f.Marca, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(f.Buscar)) { var s = f.Buscar.Trim(); q = q.Where(x => x.CodCon.ToString().Contains(s) || x.NombreCliente.Contains(s, StringComparison.OrdinalIgnoreCase) || x.NumeroMedidor.Contains(s, StringComparison.OrdinalIgnoreCase)); }
        return q.OrderByDescending(x => x.CodCaMe);
    }

    private static string NormalizePrioridad(string? nombre, int? codigo)
    {
        if (!string.IsNullOrWhiteSpace(nombre))
        {
            if (nombre.Contains("URG", StringComparison.OrdinalIgnoreCase) || nombre.Contains("ALT", StringComparison.OrdinalIgnoreCase)) return "Alta";
            if (nombre.Contains("BAJ", StringComparison.OrdinalIgnoreCase)) return "Baja";
            return nombre.Trim();
        }
        return codigo == 1 ? "Alta" : "Normal";
    }

    private static string ExtractOrigen(string solicitudId)
    {
        var i = solicitudId.IndexOf('-');
        return i >= 0 && i < solicitudId.Length - 1 ? solicitudId[(i + 1)..] : solicitudId;
    }

    private static PagedResultDto<T> Page<T>(IReadOnlyList<T> items, int page, int pageSize)
    {
        page = Math.Max(1, page); pageSize = Math.Clamp(pageSize, 1, 100);
        var total = items.Count; var pages = total == 0 ? 0 : (int)Math.Ceiling(total / (double)pageSize);
        var slice = items.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        return new PagedResultDto<T>(slice, page, pageSize, total, pages);
    }
}
