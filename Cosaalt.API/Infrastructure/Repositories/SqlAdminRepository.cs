using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

/// <summary>
/// Consultas de supervisión y reportes del Administrador.
/// IMPORTANTE: dbo.* se usa exclusivamente en lectura. Todas las escrituras
/// del proyecto siguen ocurriendo en las tablas existentes del esquema medidores.
/// Esta clase NO crea ni modifica estructura de base de datos.
/// </summary>
public sealed class SqlAdminRepository : IAdminRepository
{
    private readonly CosaaltDbContext _context;

    public SqlAdminRepository(CosaaltDbContext context) => _context = context;

    public async Task<AdminDashboardDto> ObtenerDashboardAsync(DateTime? desde = null, DateTime? hasta = null)
    {
        var hoy = DateTime.Today;
        // El dashboard solo necesita estados/prioridades, no socio, direccion ni medidor.
        // Usar una consulta resumida evita cargar/enriquecer decenas de miles de ODECO
        // cada vez que se abre Inicio.
        var solicitudes = await ObtenerSolicitudesResumenDashboardAsync();

        if (desde.HasValue)
            solicitudes = solicitudes.Where(s => s.FechaSolicitud >= desde.Value.Date).ToList();
        if (hasta.HasValue)
            solicitudes = solicitudes.Where(s => s.FechaSolicitud < hasta.Value.Date.AddDays(1)).ToList();

        var rutasHoy = await _context.AsignacionesRuta
            .AsNoTracking()
            .Include(a => a.Detalles)
            .Where(a => a.FechaAsignacion.Date == hoy)
            .ToListAsync();

        var cambiosHoy = await _context.EjecucionesCambio
            .AsNoTracking()
            .Where(e => e.FechaHoraEjecucion >= hoy && e.FechaHoraEjecucion < hoy.AddDays(1))
            .CountAsync();

        var sincronizadosHoy = await _context.EjecucionesCambio
            .AsNoTracking()
            .Where(e => e.FechaHoraEjecucion >= hoy && e.FechaHoraEjecucion < hoy.AddDays(1) && e.Sincronizado)
            .CountAsync();

        // El modulo mecanico puede desplegarse de forma independiente. Si sus tablas aun no
        // estan disponibles o su estructura esta en proceso de integracion, Administracion no
        // debe dejar de funcionar: los indicadores mecanicos se muestran en cero hasta que el
        // modulo este disponible.
        var resumenVerificaciones = await ObtenerResumenVerificacionesSeguroAsync();
        var verificacionesPendientes = resumenVerificaciones.Pendientes;
        var verificacionesEnCurso = resumenVerificaciones.EnCurso;
        var verificacionesCompletadas = resumenVerificaciones.Completadas;
        var verificacionesCumple = resumenVerificaciones.Cumple;
        var verificacionesNoCumple = resumenVerificaciones.NoCumple;

        // Dashboard: motivos frecuentes de los ultimos 30 dias.
        // Se evita por completo agrupar o navegar Motivo dentro del IQueryable porque
        // EF Core no traduce de forma estable esa expresion contra este modelo SQL.
        // EjecucionCambio solo trae IdMotivo y el catalogo de motivos se lee aparte;
        // el cruce y GroupBy se realizan en memoria sobre un volumen acotado.
        var idsMotivoRecientes = await _context.EjecucionesCambio
            .AsNoTracking()
            .Where(e => e.FechaHoraEjecucion >= hoy.AddDays(-30))
            .Select(e => e.IdMotivo)
            .ToListAsync();

        var catalogoMotivos = await _context.MotivosCambioMedidorDbo
            .AsNoTracking()
            .Select(m => new { m.CodMoCaMe, m.NomMoCaMe })
            .ToListAsync();

        var nombreMotivoPorId = catalogoMotivos
            .GroupBy(m => m.CodMoCaMe)
            .ToDictionary(
                g => g.Key,
                g => string.IsNullOrWhiteSpace(g.First().NomMoCaMe)
                    ? $"Motivo #{g.Key}"
                    : g.First().NomMoCaMe.Trim());

        var motivos = idsMotivoRecientes
            .Select(id => nombreMotivoPorId.TryGetValue(id, out var nombre)
                ? nombre
                : $"Motivo #{id}")
            .GroupBy(nombre => nombre, StringComparer.OrdinalIgnoreCase)
            .Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count()))
            .OrderByDescending(x => x.Cantidad)
            .ThenBy(x => x.Categoria)
            .Take(6)
            .ToList();

        var sincronizacionHoy = await ObtenerSincronizacionAsync(hoy);
        var tecnicos = sincronizacionHoy
            .Select(s => new AdminTecnicoResumenDto(
                s.IdTecnico,
                s.NombreTecnico,
                s.Activo,
                s.RutasHoy,
                s.ParadasHoy,
                s.ParadasCompletadasHoy,
                s.ParadasHoy == 0 ? 0 : Math.Round((decimal)s.ParadasCompletadasHoy * 100m / s.ParadasHoy, 1),
                s.UltimaEjecucionRecibida,
                s.EstadoServidor))
            .OrderByDescending(t => t.RutasHoy)
            .ThenBy(t => t.Nombre)
            .Take(8)
            .ToList();

        var actividad = await ObtenerActividadRecienteAsync();

        var odecoVencidas = solicitudes.Count(s => s.TipoOrigen == "ODECO" && s.Vencida && s.Estado != "Completada");
        var odecoUrgentes = solicitudes.Count(s => s.TipoOrigen == "ODECO" && s.Prioridad == "Alta" && s.Estado != "Completada");
        var solicitudesPendientes = solicitudes.Count(s => s.Estado != "Completada");
        var alertas = new List<AdminAlertaDto>();

        if (odecoVencidas > 0)
            alertas.Add(new AdminAlertaDto("ODECO", "Critica", "ODECO vencidas", "Reclamos cuyo plazo de atención ya venció.", odecoVencidas));
        if (odecoUrgentes > 0)
            alertas.Add(new AdminAlertaDto("ODECO", "Alta", "ODECO urgentes", "Reclamos de prioridad alta aún no completados.", odecoUrgentes));

        var inconsistenciasSync = sincronizacionHoy
            .Sum(x => x.ParadasCompletadasSinEjecucion + x.EjecucionesSinParada + x.EjecucionesPendientesServidor + x.EjecucionesDuplicadas);
        if (inconsistenciasSync > 0)
            alertas.Add(new AdminAlertaDto("SYNC", "Alta", "Revisar sincronización", "El servidor detectó registros pendientes o inconsistencias entre rutas y ejecuciones.", inconsistenciasSync));

        var sinResultado = resumenVerificaciones.SinResultado;
        if (sinResultado > 0)
            alertas.Add(new AdminAlertaDto("VERIFICACION", "Media", "Verificaciones sin resultado", "Hay verificaciones completadas que todavia no tienen un resultado registrado.", sinResultado));

        return new AdminDashboardDto(
            SolicitudesPendientes: solicitudesPendientes,
            OdecoPendientes: solicitudes.Count(s => s.TipoOrigen == "ODECO" && s.Estado != "Completada"),
            OdecoUrgentes: odecoUrgentes,
            OdecoVencidas: odecoVencidas,
            LecturaPendientes: solicitudes.Count(s => s.TipoOrigen == "LECTURA" && s.Estado != "Completada"),
            RutasActivasHoy: rutasHoy.Count(r => r.Detalles.Any(d => d.Estado != "Completada")),
            TecnicosConRutaHoy: rutasHoy.Select(r => r.IdUsuarioApp).Distinct().Count(),
            CambiosEjecutadosHoy: cambiosHoy,
            CambiosSincronizadosHoy: sincronizadosHoy,
            VerificacionesPendientes: verificacionesPendientes,
            VerificacionesEnCurso: verificacionesEnCurso,
            VerificacionesCompletadas: verificacionesCompletadas,
            VerificacionesCumple: verificacionesCumple,
            VerificacionesNoCumple: verificacionesNoCumple,
            SolicitudesPorEstado: solicitudes
                .GroupBy(s => s.Estado)
                .Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count()))
                .OrderByDescending(x => x.Cantidad)
                .ToList(),
            MotivosCambioFrecuentes: motivos,
            Tecnicos: tecnicos,
            ActividadReciente: actividad,
            Alertas: alertas);
    }

    public async Task<PagedResultDto<AdminSolicitudDto>> ObtenerSolicitudesAsync(AdminSolicitudFiltro filtro)
    {
        // La fuente administrativa puede contener decenas de miles de ODECO activos.
        // Primero se filtra/pagina la bandeja y SOLO despues se resuelve el medidor
        // vigente de las filas visibles. Esto evita generar IN/OPENJSON gigantes por VPN.
        IEnumerable<AdminSolicitudDto> query = await ObtenerSolicitudesEnriquecidasAsync();

        if (filtro.Desde.HasValue)
            query = query.Where(s => s.FechaSolicitud >= filtro.Desde.Value.Date);
        if (filtro.Hasta.HasValue)
            query = query.Where(s => s.FechaSolicitud < filtro.Hasta.Value.Date.AddDays(1));
        if (!string.IsNullOrWhiteSpace(filtro.Origen) && !filtro.Origen.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            query = query.Where(s => s.TipoOrigen.Equals(filtro.Origen, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Estado) && !filtro.Estado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
        {
            if (filtro.Estado.Equals("Vencida", StringComparison.OrdinalIgnoreCase))
                query = query.Where(s => s.Vencida && s.Estado != "Completada");
            else
                query = query.Where(s => s.Estado.Equals(filtro.Estado, StringComparison.OrdinalIgnoreCase));
        }
        if (!string.IsNullOrWhiteSpace(filtro.Prioridad) && !filtro.Prioridad.Equals("Todas", StringComparison.OrdinalIgnoreCase))
            query = query.Where(s => s.Prioridad.Equals(filtro.Prioridad, StringComparison.OrdinalIgnoreCase));
        if (filtro.TecnicoId.HasValue)
            query = query.Where(s => s.IdTecnico == filtro.TecnicoId.Value);

        HashSet<int>? codConsPorMedidor = null;
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var q = filtro.Buscar.Trim();
            codConsPorMedidor = await BuscarCodConPorMedidorAsync(q);
            query = query.Where(s =>
                s.Id.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                s.CodCon.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                s.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                s.Direccion.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                (s.Motivo?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false) ||
                codConsPorMedidor.Contains(s.CodCon));
        }

        var ordenadas = query
            .OrderByDescending(s => s.Vencida)
            .ThenByDescending(s => s.FechaSolicitud)
            .ToList();

        var page = Math.Max(1, filtro.Page);
        var pageSize = Math.Clamp(filtro.PageSize, 5, 100);
        var total = ordenadas.Count;
        var pagina = ordenadas.Skip((page - 1) * pageSize).Take(pageSize).ToList();

        // Resolver el medidor vigente solo para la pagina visible (normalmente 25 filas).
        var medidores = await BandejaOdecoBuilder.MedidorVigentePorCodConAsync(
            _context,
            pagina.Select(x => x.CodCon));

        var items = pagina.Select(s =>
        {
            var medidor = medidores.GetValueOrDefault(s.CodCon);
            return s with
            {
                NumeroMedidor = medidor.SeriaMedidor,
                MarcaMedidor = medidor.MarcaMedidor
            };
        }).ToList();

        return new PagedResultDto<AdminSolicitudDto>(
            items,
            page,
            pageSize,
            total,
            CalcularPaginas(total, pageSize));
    }

    public async Task<PagedResultDto<AdminRutaDto>> ObtenerRutasAsync(AdminRutaFiltro filtro)
    {
        var query = _context.AsignacionesRuta
            .AsNoTracking()
            .Include(a => a.Detalles)
            .Include(a => a.Usuario).ThenInclude(u => u.Funcionario).ThenInclude(f => f!.Persona)
            .AsQueryable();

        if (filtro.Fecha.HasValue)
        {
            var fecha = filtro.Fecha.Value.Date;
            query = query.Where(a => a.FechaAsignacion >= fecha && a.FechaAsignacion < fecha.AddDays(1));
        }
        if (filtro.TecnicoId.HasValue)
            query = query.Where(a => a.IdUsuarioApp == filtro.TecnicoId.Value);

        var entidades = await query.OrderByDescending(a => a.FechaAsignacion).ToListAsync();
        var rutas = new List<AdminRutaDto>(entidades.Count);
        foreach (var entidad in entidades)
            rutas.Add(await MapRutaAsync(entidad));

        IEnumerable<AdminRutaDto> filtradas = rutas;
        if (!string.IsNullOrWhiteSpace(filtro.Estado) && !filtro.Estado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            filtradas = filtradas.Where(r => r.Estado.Equals(filtro.Estado, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var q = filtro.Buscar.Trim();
            filtradas = filtradas.Where(r =>
                r.IdAsignacion.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                r.NombreTecnico.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                r.Detalles.Any(d => d.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) || d.Direccion.Contains(q, StringComparison.OrdinalIgnoreCase)));
        }

        return Paginar(filtradas.ToList(), filtro.Page, filtro.PageSize);
    }

    public async Task<AdminRutaDto?> ObtenerRutaAsync(int idAsignacion)
    {
        var entidad = await _context.AsignacionesRuta
            .AsNoTracking()
            .Include(a => a.Detalles)
            .Include(a => a.Usuario).ThenInclude(u => u.Funcionario).ThenInclude(f => f!.Persona)
            .FirstOrDefaultAsync(a => a.Id == idAsignacion);
        return entidad is null ? null : await MapRutaAsync(entidad);
    }

    public async Task<IReadOnlyList<AdminSincronizacionTecnicoDto>> ObtenerSincronizacionAsync(DateTime? fecha = null)
    {
        var dia = (fecha ?? DateTime.Today).Date;
        var manana = dia.AddDays(1);

        var tecnicos = await _context.Usuarios
            .AsNoTracking()
            .Include(u => u.Rol)
            .Include(u => u.Funcionario).ThenInclude(f => f!.Persona)
            .Where(u => u.Rol.Nombre == "tecnico")
            .OrderBy(u => u.NombreUsuario)
            .ToListAsync();

        var rutas = await _context.AsignacionesRuta
            .AsNoTracking()
            .Include(a => a.Detalles)
            .Where(a => a.FechaAsignacion >= dia && a.FechaAsignacion < manana)
            .ToListAsync();

        var ejecuciones = await _context.EjecucionesCambio
            .AsNoTracking()
            .Where(e => e.FechaHoraEjecucion >= dia && e.FechaHoraEjecucion < manana)
            .ToListAsync();

        var resultado = new List<AdminSincronizacionTecnicoDto>();
        foreach (var tecnico in tecnicos)
        {
            var rutasTec = rutas.Where(r => r.IdUsuarioApp == tecnico.Id).ToList();
            var detalles = rutasTec.SelectMany(r => r.Detalles).ToList();
            var ejecTec = ejecuciones.Where(e => e.IdUsuarioApp == tecnico.Id).ToList();
            var clavesEjec = ejecTec.Select(e => $"{e.TipoOrigen}-{e.IdOrigen}").ToHashSet(StringComparer.OrdinalIgnoreCase);
            var clavesRuta = detalles.Select(d => $"{d.TipoOrigen}-{d.IdOrigen}").ToHashSet(StringComparer.OrdinalIgnoreCase);

            var completadasSinEjec = detalles.Count(d =>
                d.Estado.Equals("Completada", StringComparison.OrdinalIgnoreCase) &&
                !clavesEjec.Contains($"{d.TipoOrigen}-{d.IdOrigen}"));
            var ejecSinRuta = ejecTec.Count(e => !clavesRuta.Contains($"{e.TipoOrigen}-{e.IdOrigen}"));
            var duplicadas = ejecTec
                .GroupBy(e => $"{e.TipoOrigen}-{e.IdOrigen}", StringComparer.OrdinalIgnoreCase)
                .Sum(g => Math.Max(0, g.Count() - 1));
            var pendientesServidor = ejecTec.Count(e => !e.Sincronizado);

            var estado = pendientesServidor > 0 || completadasSinEjec > 0 || ejecSinRuta > 0 || duplicadas > 0
                ? "Revisar"
                : detalles.Count == 0
                    ? "Sin ruta"
                    : detalles.All(d => d.Estado.Equals("Completada", StringComparison.OrdinalIgnoreCase))
                        ? "Al dia"
                        : ejecTec.Count > 0
                            ? "En curso"
                            : "Sin actividad";

            resultado.Add(new AdminSincronizacionTecnicoDto(
                IdTecnico: tecnico.Id,
                NombreTecnico: tecnico.NombreCompleto,
                Activo: tecnico.Activo,
                RutasHoy: rutasTec.Count,
                ParadasHoy: detalles.Count,
                ParadasCompletadasHoy: detalles.Count(d => d.Estado.Equals("Completada", StringComparison.OrdinalIgnoreCase)),
                EjecucionesRecibidasHoy: ejecTec.Count,
                EjecucionesSincronizadasHoy: ejecTec.Count(e => e.Sincronizado),
                EjecucionesPendientesServidor: pendientesServidor,
                ParadasCompletadasSinEjecucion: completadasSinEjec,
                EjecucionesSinParada: ejecSinRuta,
                EjecucionesDuplicadas: duplicadas,
                UltimaEjecucionRecibida: ejecTec.Count == 0 ? null : ejecTec.Max(e => e.FechaHoraEjecucion),
                EstadoServidor: estado,
                Alcance: "Estado conocido por el servidor. La cola que permanezca solo en el celular no es visible hasta que el dispositivo intente sincronizar."));
        }

        return resultado;
    }

    public async Task<PagedResultDto<AdminVerificacionResumenDto>> ObtenerVerificacionesAsync(AdminVerificacionFiltro filtro)
    {
        try
        {

                    var query = _context.Verificaciones
                        .AsNoTracking()
                        .Include(v => v.Conexion)
                        .Include(v => v.Mecanico).ThenInclude(u => u.Funcionario).ThenInclude(f => f!.Persona)
                        .Include(v => v.Ensayo)
                        .Include(v => v.Informes)
                        .AsQueryable();

                    if (filtro.Desde.HasValue)
                        query = query.Where(v => v.FechaVerificacion >= filtro.Desde.Value.Date);
                    if (filtro.Hasta.HasValue)
                        query = query.Where(v => v.FechaVerificacion < filtro.Hasta.Value.Date.AddDays(1));
                    if (filtro.MecanicoId.HasValue)
                        query = query.Where(v => v.IdUsuarioMecanico == filtro.MecanicoId.Value);
                    if (!string.IsNullOrWhiteSpace(filtro.Estado) && !filtro.Estado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
                        query = query.Where(v => v.Estado == filtro.Estado);
                    if (!string.IsNullOrWhiteSpace(filtro.Resultado) && !filtro.Resultado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
                        query = query.Where(v => v.Resultado == filtro.Resultado);
                    if (filtro.SoloConInforme == true)
                        query = query.Where(v => v.Informes.Any());

                    var entidades = await query.OrderByDescending(v => v.FechaVerificacion).ToListAsync();
                    IEnumerable<AdminVerificacionResumenDto> items = entidades.Select(MapVerificacionResumen);
                    if (!string.IsNullOrWhiteSpace(filtro.Buscar))
                    {
                        var q = filtro.Buscar.Trim();
                        items = items.Where(v =>
                            v.IdVerificacion.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                            v.CodCon.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                            v.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                            (v.NumeroMedidor?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false) ||
                            v.NombreMecanico.Contains(q, StringComparison.OrdinalIgnoreCase));
                    }

                    return Paginar(items.ToList(), filtro.Page, filtro.PageSize);

        }
        catch (Exception ex) when (EsErrorModuloVerificacion(ex))
        {
            return new PagedResultDto<AdminVerificacionResumenDto>([], Math.Max(1, filtro.Page), Math.Clamp(filtro.PageSize, 5, 100), 0, 0);
        }
    }

    public async Task<IReadOnlyList<AdminVerificacionResumenDto>> ObtenerVerificacionesExportAsync(AdminVerificacionFiltro filtro, int maximo = 50000)
    {
        try
        {

                    var query = _context.Verificaciones
                        .AsNoTracking()
                        .Include(v => v.Conexion)
                        .Include(v => v.Mecanico).ThenInclude(u => u.Funcionario).ThenInclude(f => f!.Persona)
                        .Include(v => v.Ensayo)
                        .Include(v => v.Informes)
                        .AsQueryable();

                    if (filtro.Desde.HasValue)
                        query = query.Where(v => v.FechaVerificacion >= filtro.Desde.Value.Date);
                    if (filtro.Hasta.HasValue)
                        query = query.Where(v => v.FechaVerificacion < filtro.Hasta.Value.Date.AddDays(1));
                    if (filtro.MecanicoId.HasValue)
                        query = query.Where(v => v.IdUsuarioMecanico == filtro.MecanicoId.Value);
                    if (!string.IsNullOrWhiteSpace(filtro.Estado) && !filtro.Estado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
                        query = query.Where(v => v.Estado == filtro.Estado);
                    if (!string.IsNullOrWhiteSpace(filtro.Resultado) && !filtro.Resultado.Equals("Todos", StringComparison.OrdinalIgnoreCase))
                        query = query.Where(v => v.Resultado == filtro.Resultado);
                    if (filtro.SoloConInforme == true)
                        query = query.Where(v => v.Informes.Any());

                    var entidades = await query
                        .OrderByDescending(v => v.FechaVerificacion)
                        .Take(Math.Clamp(maximo, 1, 50000))
                        .ToListAsync();

                    IEnumerable<AdminVerificacionResumenDto> items = entidades.Select(MapVerificacionResumen);
                    if (!string.IsNullOrWhiteSpace(filtro.Buscar))
                    {
                        var q = filtro.Buscar.Trim();
                        items = items.Where(v =>
                            v.IdVerificacion.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                            v.CodCon.ToString().Contains(q, StringComparison.OrdinalIgnoreCase) ||
                            v.NombreCliente.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                            (v.NumeroMedidor?.Contains(q, StringComparison.OrdinalIgnoreCase) ?? false) ||
                            v.NombreMecanico.Contains(q, StringComparison.OrdinalIgnoreCase));
                    }

                    return items.Take(Math.Clamp(maximo, 1, 50000)).ToList();

        }
        catch (Exception ex) when (EsErrorModuloVerificacion(ex))
        {
            return [];
        }
    }

    public async Task<AdminVerificacionDetalleDto?> ObtenerVerificacionDetalleAsync(int idVerificacion)
    {
        try
        {

                    var entidad = await _context.Verificaciones
                        .AsNoTracking()
                        .Include(v => v.Conexion).ThenInclude(c => c.Predio)
                        .Include(v => v.Mecanico).ThenInclude(u => u.Funcionario).ThenInclude(f => f!.Persona)
                        .Include(v => v.Ensayo)
                        .Include(v => v.Participantes)
                        .Include(v => v.Informes)
                        .FirstOrDefaultAsync(v => v.Id == idVerificacion);

                    if (entidad is null) return null;

                    var vigente = await MedidorVigenteResolver.ResolverAsync(_context, [entidad.CodCon]);
                    vigente.TryGetValue(entidad.CodCon, out var medidor);

                    var socio = new DatosSocioMedidorDto(
                        CodCon: entidad.CodCon,
                        NombreCliente: entidad.Conexion?.NomSoc ?? "Sin nombre",
                        Direccion: BandejaOdecoBuilder.BuildDireccion(entidad.Conexion?.Predio),
                        Categoria: null,
                        NumeroDocumento: entidad.Conexion?.NumDoc,
                        TipDocumento: entidad.Conexion?.TipDoc,
                        Ruc: entidad.Conexion?.RucSoc,
                        NumeroMedidor: entidad.IdMedidor ?? medidor.Serial,
                        MarcaMedidor: medidor.Marca,
                        FechaConexion: entidad.Conexion?.FecCon);

                    var resumen = MapVerificacionResumen(entidad);
                    var ensayo = entidad.Ensayo is null ? null : new EnsayoVerificacionDto(
                        entidad.Ensayo.Id,
                        entidad.Ensayo.Condiciones,
                        entidad.Ensayo.LecturaInicial,
                        entidad.Ensayo.LecturaFinal,
                        entidad.Ensayo.VolumenPatron,
                        entidad.Ensayo.Caudal,
                        entidad.Ensayo.VolumenRegistrado,
                        entidad.Ensayo.Error,
                        entidad.Ensayo.Fugas,
                        entidad.Ensayo.Observaciones);

                    var participantes = entidad.Participantes
                        .OrderBy(p => p.Id)
                        .Select(p => new ParticipanteVerificacionDto(p.Id, p.Nombre, p.Cargo, p.Rol))
                        .ToList();
                    var informes = entidad.Informes
                        .OrderByDescending(i => i.FechaEmision)
                        .Select(i => new AdminInformeVerificacionDto(i.Id, i.NroInforme, i.FechaEmision, i.FechaFirma, i.RutaPdf, i.Firmado, i.Repeticiones))
                        .ToList();

                    return new AdminVerificacionDetalleDto(resumen, socio, ensayo, participantes, informes);

        }
        catch (Exception ex) when (EsErrorModuloVerificacion(ex))
        {
            return null;
        }
    }

    public async Task<PagedResultDto<AdminMovimientoDto>> ObtenerMovimientosAsync(AdminMovimientoFiltro filtro)
    {
        var query = AplicarFiltroMovimientos(ConsultaMovimientos(), filtro);
        var total = await query.CountAsync();
        var page = Math.Max(1, filtro.Page);
        var pageSize = Math.Clamp(filtro.PageSize, 5, 100);
        var entidades = await query
            .OrderByDescending(e => e.FechaHoraEjecucion)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
        var items = entidades.Select(MapMovimiento).ToList();
        return new PagedResultDto<AdminMovimientoDto>(items, page, pageSize, total, CalcularPaginas(total, pageSize));
    }

    public async Task<IReadOnlyList<AdminMovimientoDto>> ObtenerMovimientosExportAsync(AdminMovimientoFiltro filtro, int maximo = 50000)
    {
        var query = AplicarFiltroMovimientos(ConsultaMovimientos(), filtro);
        var entidades = await query.OrderByDescending(e => e.FechaHoraEjecucion).Take(maximo).ToListAsync();
        return entidades.Select(MapMovimiento).ToList();
    }

    public async Task<PagedResultDto<AdminMovimientoCorporativoDto>> ObtenerHistoricoCorporativoAsync(AdminMovimientoCorporativoFiltro filtro)
    {
        var query = AplicarFiltroHistoricoCorporativo(ConsultaHistoricoCorporativo(), filtro);
        var total = await query.CountAsync();
        var page = Math.Max(1, filtro.Page);
        var pageSize = Math.Clamp(filtro.PageSize, 5, 100);

        // dbo.CambioMedidores no tiene una fecha mapeada en el modelo actual.
        // Se prioriza el vigente y luego el código del movimiento SOLO como orden estable,
        // nunca como sustituto de una fecha cronológica.
        var rows = await query
            .OrderByDescending(x => x.Vigente)
            .ThenByDescending(x => x.CodCaMe)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<AdminMovimientoCorporativoDto>(
            rows.Select(MapHistoricoCorporativo).ToList(),
            page,
            pageSize,
            total,
            CalcularPaginas(total, pageSize));
    }

    public async Task<IReadOnlyList<AdminMovimientoCorporativoDto>> ObtenerHistoricoCorporativoExportAsync(
        AdminMovimientoCorporativoFiltro filtro,
        int maximo = 50000)
    {
        var rows = await AplicarFiltroHistoricoCorporativo(ConsultaHistoricoCorporativo(), filtro)
            .OrderByDescending(x => x.Vigente)
            .ThenByDescending(x => x.CodCaMe)
            .Take(Math.Clamp(maximo, 1, 50000))
            .ToListAsync();
        return rows.Select(MapHistoricoCorporativo).ToList();
    }

    public async Task<AdminEstadisticasDto> ObtenerEstadisticasAsync(AdminEstadisticasFiltro filtro)
    {
        var desde = filtro.Desde?.Date ?? DateTime.Today.AddDays(-30);
        var hasta = filtro.Hasta?.Date ?? DateTime.Today;
        var hastaExclusiva = hasta.AddDays(1);

        var movimientosFiltro = new AdminMovimientoFiltro(
            desde, hasta, filtro.TecnicoId, filtro.MotivoId, filtro.Origen, filtro.Marca, null, null, 1, 100);
        var movimientos = await AplicarFiltroMovimientos(ConsultaMovimientos(), movimientosFiltro)
            .OrderBy(e => e.FechaHoraEjecucion)
            .ToListAsync();

        var verificaciones = await ObtenerVerificacionesEstadisticasSeguroAsync(
            desde, hastaExclusiva, filtro.MecanicoId, filtro.Origen);

        var cumple = verificaciones.Count(v => v.Resultado == "CUMPLE");
        var noCumple = verificaciones.Count(v => v.Resultado == "NO CUMPLE");
        var conResultado = cumple + noCumple;
        var porcentaje = conResultado == 0 ? 0 : Math.Round((decimal)cumple * 100m / conResultado, 1);
        var errores = verificaciones.Where(v => v.Ensayo?.Error is not null).Select(v => v.Ensayo!.Error!.Value).ToList();

        var horasAtencion = await CalcularHorasAtencionAsync(movimientos);

        var tecnicos = movimientos
            .GroupBy(e => new { e.IdUsuarioApp, Nombre = e.Usuario?.NombreCompleto ?? $"Usuario #{e.IdUsuarioApp}" })
            .Select(g => new AdminPersonaMetricaDto(g.Key.IdUsuarioApp, g.Key.Nombre, "tecnico", g.Count(), null, 0, 0))
            .OrderByDescending(x => x.Atenciones)
            .Take(10)
            .ToList();

        var mecanicos = verificaciones
            .GroupBy(v => new { v.IdUsuarioMecanico, Nombre = v.Mecanico?.NombreCompleto ?? $"Mecanico #{v.IdUsuarioMecanico}" })
            .Select(g =>
            {
                var errs = g.Where(v => v.Ensayo?.Error is not null).Select(v => v.Ensayo!.Error!.Value).ToList();
                return new AdminPersonaMetricaDto(
                    g.Key.IdUsuarioMecanico,
                    g.Key.Nombre,
                    "mecanico",
                    g.Count(),
                    errs.Count == 0 ? null : Math.Round(errs.Average(), 3),
                    g.Count(v => v.Resultado == "CUMPLE"),
                    g.Count(v => v.Resultado == "NO CUMPLE"));
            })
            .OrderByDescending(x => x.Atenciones)
            .Take(10)
            .ToList();

        return new AdminEstadisticasDto(
            TotalCambios: movimientos.Count,
            TotalVerificaciones: verificaciones.Count,
            VerificacionesCumple: cumple,
            VerificacionesNoCumple: noCumple,
            PorcentajeCumple: porcentaje,
            CasosConFuga: verificaciones.Count(v => v.Ensayo?.Fugas == true),
            ErrorPromedio: errores.Count == 0 ? null : Math.Round(errores.Average(), 3),
            HorasPromedioAtencion: horasAtencion.Count == 0 ? null : Math.Round((decimal)horasAtencion.Average(), 2),
            MotivosCambio: movimientos
                .GroupBy(e => e.Motivo?.NomMoCaMe ?? "Sin motivo")
                .Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count()))
                .OrderByDescending(x => x.Cantidad)
                .Take(10)
                .ToList(),
            MarcasRetiradas: movimientos
                .GroupBy(e => string.IsNullOrWhiteSpace(e.MarcaRetirado) ? "Sin marca" : e.MarcaRetirado!)
                .Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count()))
                .OrderByDescending(x => x.Cantidad)
                .Take(10)
                .ToList(),
            OrigenesCambio: movimientos
                .GroupBy(e => e.TipoOrigen)
                .Select(g => new AdminCategoriaCantidadDto(g.Key, g.Count()))
                .OrderByDescending(x => x.Cantidad)
                .ToList(),
            CambiosPorDia: movimientos
                .GroupBy(e => e.FechaHoraEjecucion.Date)
                .OrderBy(g => g.Key)
                .Select(g => new AdminSerieTemporalDto(g.Key.ToString("yyyy-MM-dd"), g.Count()))
                .ToList(),
            Tecnicos: tecnicos,
            Mecanicos: mecanicos);
    }

    /// <summary>
    /// Fuente administrativa completa de solicitudes actuales. A diferencia de la bandeja
    /// móvil, no aplica el TOP 1000 de ODECO: recupera todos los reclamos activos con
    /// cuenta, incluso antiguos, y todos los detalles LECTURA
    /// propios. Sigue siendo SOLO LECTURA sobre dbo.
    /// </summary>
    private async Task<List<AdminSolicitudDashboardRow>> ObtenerSolicitudesResumenDashboardAsync()
    {
        var ahora = DateTime.Now;

        // Solo las columnas necesarias para KPIs. Sin joins a Conexion/Predio/Recurrente.
        var odeco = await _context.Reclamos
            .AsNoTracking()
            .Where(r => r.EstRec && r.CodCon != null)
            .Select(r => new
            {
                r.CodRec,
                r.FecRec,
                r.FecEstResRec,
                r.PriRec,
                r.DesRec
            })
            .ToListAsync();

        var lectura = await _context.DetallesSolicitudLectura
            .AsNoTracking()
            .Select(d => new
            {
                d.Id,
                Fecha = d.Solicitud.FechaEmision
            })
            .ToListAsync();

        // Las tablas propias son mucho menores que dbo.Reclamos. Solo necesitamos la
        // ultima situacion conocida de cada origen para derivar Pendiente/Asignada/
        // En proceso/Completada.
        var detalles = await _context.DetallesRuta
            .AsNoTracking()
            .Where(d => d.TipoOrigen == "ODECO" || d.TipoOrigen == "LECTURA")
            .Select(d => new { d.Id, d.TipoOrigen, d.IdOrigen, d.Estado })
            .ToListAsync();

        var ejecuciones = await _context.EjecucionesCambio
            .AsNoTracking()
            .Where(e => e.TipoOrigen == "ODECO" || e.TipoOrigen == "LECTURA")
            .Select(e => new { e.TipoOrigen, e.IdOrigen, e.FechaHoraEjecucion })
            .ToListAsync();

        var detallePorOrigen = detalles
            .GroupBy(d => $"{d.TipoOrigen}|{d.IdOrigen}", StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                g => g.Key,
                g => g.OrderByDescending(x => x.Id).First().Estado,
                StringComparer.OrdinalIgnoreCase);

        var ejecutados = ejecuciones
            .Select(e => $"{e.TipoOrigen}|{e.IdOrigen}")
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var resultado = new List<AdminSolicitudDashboardRow>(odeco.Count + lectura.Count);

        foreach (var r in odeco)
        {
            var key = $"ODECO|{r.CodRec}";
            var estado = ejecutados.Contains(key)
                ? "Completada"
                : detallePorOrigen.TryGetValue(key, out var estadoDetalle)
                    ? NormalizarEstadoDetalle(estadoDetalle)
                    : "Pendiente";

            var limite = r.FecEstResRec > r.FecRec
                ? r.FecEstResRec
                : r.FecRec.AddHours(24);
            var urgente = r.PriRec == 'A' || (r.DesRec?.Contains("URGENTE", StringComparison.OrdinalIgnoreCase) ?? false);
            var prioridad = urgente ? "Alta" : r.PriRec == 'B' ? "Media" : "Normal";

            resultado.Add(new AdminSolicitudDashboardRow(
                "ODECO",
                r.FecRec,
                ahora > limite && estado != "Completada",
                prioridad,
                estado));
        }

        foreach (var l in lectura)
        {
            var key = $"LECTURA|{l.Id}";
            var estado = ejecutados.Contains(key)
                ? "Completada"
                : detallePorOrigen.TryGetValue(key, out var estadoDetalle)
                    ? NormalizarEstadoDetalle(estadoDetalle)
                    : "Pendiente";
            var limite = new DateTime(l.Fecha.Year, l.Fecha.Month, 1).AddMonths(1);

            resultado.Add(new AdminSolicitudDashboardRow(
                "LECTURA",
                l.Fecha,
                ahora > limite && estado != "Completada",
                "Normal",
                estado));
        }

        return resultado;
    }

    private async Task<List<SolicitudBandejaDto>> ObtenerSolicitudesBaseAdminAsync()
    {
        // Administracion debe poder encontrar tambien solicitudes activas antiguas que
        // pudieron quedar rezagadas. Por eso NO se aplica una ventana temporal fija
        // aqui: el filtro por fecha pertenece a la consulta administrativa, no a la
        // fuente base. dbo.Reclamos sigue siendo estrictamente SOLO LECTURA.
        var odecoRows = await _context.Reclamos
            .AsNoTracking()
            .Where(r => r.EstRec && r.CodCon != null)
            .OrderByDescending(r => r.FecRec)
            .Select(r => new AdminOdecoRow
            {
                CodRec = r.CodRec,
                FecRec = r.FecRec,
                DesRec = r.DesRec,
                PriRec = r.PriRec,
                CodCon = r.CodCon ?? 0,
                NomRec = r.Recurrente != null ? r.Recurrente.NomRec : null,
                NomSoc = r.Conexion != null ? r.Conexion.NomSoc : null,
                Latitud = r.Conexion != null ? r.Conexion.CooX2Con : null,
                Longitud = r.Conexion != null ? r.Conexion.CooY2Con : null,
                CodUbiPre = r.Conexion != null && r.Conexion.Predio != null ? r.Conexion.Predio.CodUbiPre : null,
                NumPre = r.Conexion != null && r.Conexion.Predio != null ? r.Conexion.Predio.NumPre : null
            })
            .ToListAsync();

        var detallesLectura = await _context.DetallesSolicitudLectura
            .AsNoTracking()
            .Include(d => d.Solicitud)
            .Include(d => d.Conexion).ThenInclude(c => c!.Predio)
            .ToListAsync();

        // No se resuelven medidores aqui. Esta fuente puede contener muchos ODECO
        // activos y resolverlos todos convertiría una apertura del Dashboard en cientos
        // de consultas IN. El medidor se completa solo para la pagina visible en
        // ObtenerSolicitudesAsync. El Dashboard no necesita serial/marca para sus KPIs.
        var solicitudes = new List<SolicitudBandejaDto>(odecoRows.Count + detallesLectura.Count);
        foreach (var row in odecoRows)
        {
            solicitudes.Add(new SolicitudBandejaDto(
                Id: $"ODECO-{row.CodRec}",
                TipoOrigen: "ODECO",
                Estado: "Pendiente",
                EsUrgente: row.PriRec == 'A' || (row.DesRec?.Contains("URGENTE", StringComparison.OrdinalIgnoreCase) ?? false),
                CodCon: row.CodCon,
                NombreCliente: row.NomRec ?? row.NomSoc ?? "Sin nombre",
                Direccion: BandejaOdecoBuilder.BuildDireccion(row.CodUbiPre, row.NumPre),
                Categoria: null,
                Ruta: null,
                Recorrido: null,
                NumeroMedidor: null,
                MarcaMedidor: null,
                LecturaAnterior: null,
                LecturaActual: null,
                Consumo: null,
                MotivoObservacion: row.DesRec,
                FechaSolicitud: row.FecRec,
                FolioOdeco: row.CodRec,
                ConclusionOdeco: null,
                Latitud: row.Latitud,
                Longitud: row.Longitud));
        }

        foreach (var detalle in detallesLectura)
        {
            solicitudes.Add(new SolicitudBandejaDto(
                Id: $"LEC-{detalle.Id}",
                TipoOrigen: "LECTURA",
                Estado: "Pendiente",
                EsUrgente: false,
                CodCon: detalle.CodCon,
                NombreCliente: detalle.Conexion?.NomSoc ?? "Sin nombre",
                Direccion: BandejaOdecoBuilder.BuildDireccion(detalle.Conexion?.Predio),
                Categoria: null,
                Ruta: null,
                Recorrido: null,
                NumeroMedidor: null,
                MarcaMedidor: null,
                LecturaAnterior: detalle.LecturaAnterior,
                LecturaActual: detalle.LecturaActual,
                Consumo: detalle.Consumo,
                MotivoObservacion: detalle.Solicitud.DescripcionObservacion ?? $"Codigo {detalle.Solicitud.CodigoObservacion}",
                FechaSolicitud: detalle.Solicitud.FechaEmision,
                FolioOdeco: null,
                ConclusionOdeco: null,
                Latitud: detalle.Conexion?.CooX2Con,
                Longitud: detalle.Conexion?.CooY2Con));
        }

        return solicitudes;
    }

    private async Task<List<AdminSolicitudDto>> ObtenerSolicitudesEnriquecidasAsync()
    {
        var baseSolicitudes = await ObtenerSolicitudesBaseAdminAsync();
        var odecoIds = baseSolicitudes
            .Where(s => s.TipoOrigen == "ODECO")
            .Select(s => s.FolioOdeco ?? ParseIdOrigen(s.Id))
            .Where(x => x > 0)
            .Distinct()
            .ToList();
        var lecturaIds = baseSolicitudes
            .Where(s => s.TipoOrigen == "LECTURA")
            .Select(s => ParseIdOrigen(s.Id))
            .Where(x => x > 0)
            .Distinct()
            .ToList();

        // IMPORTANTE: no usar ids.Contains(...) con todos los ODECO activos. En la
        // base corporativa ese conjunto puede ser muy grande y SQL Server termina
        // evaluando una lista masiva que expira por VPN. Las tablas medidores son el
        // universo pequeno creado por esta aplicacion: se leen una sola vez y luego se
        // cruzan en memoria contra las solicitudes corporativas.
        var clavesBase = baseSolicitudes
            .Select(s =>
            {
                var id = s.TipoOrigen == "ODECO"
                    ? (s.FolioOdeco ?? ParseIdOrigen(s.Id)).ToString()
                    : ParseIdOrigen(s.Id).ToString();
                return $"{s.TipoOrigen}|{id}";
            })
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var detalles = (await _context.DetallesRuta
            .AsNoTracking()
            .Include(d => d.Asignacion)
                .ThenInclude(a => a.Usuario)
                .ThenInclude(u => u.Funcionario)
                .ThenInclude(f => f!.Persona)
            .Where(d => d.TipoOrigen == "ODECO" || d.TipoOrigen == "LECTURA")
            .ToListAsync())
            .Where(d => clavesBase.Contains($"{d.TipoOrigen}|{d.IdOrigen}"))
            .ToList();

        var ejecuciones = (await _context.EjecucionesCambio
            .AsNoTracking()
            .Include(e => e.Usuario)
                .ThenInclude(u => u.Funcionario)
                .ThenInclude(f => f!.Persona)
            .Where(e => e.TipoOrigen == "ODECO" || e.TipoOrigen == "LECTURA")
            .ToListAsync())
            .Where(e => clavesBase.Contains($"{e.TipoOrigen}|{e.IdOrigen}"))
            .ToList();

        // Una sola lectura de plazos/prioridades de ODECO activos. Evita decenas o
        // cientos de lotes IN de 500 IDs que hacian muy lenta la apertura del panel.
        var reclamos = new Dictionary<int, (DateTime? Limite, string Prioridad)>();
        if (odecoIds.Count > 0)
        {
            const string sqlPlazos = """
                SELECT CodRec,
                       FecEstResRec AS FechaLimite,
                       CAST(PriRec AS varchar(10)) AS Prioridad
                FROM dbo.Reclamos
                WHERE EstRec = CAST(1 AS bit)
                  AND CodCon IS NOT NULL
                """;

            var rows = await _context.Database
                .SqlQueryRaw<OdecoPlazoRow>(sqlPlazos)
                .ToListAsync();

            reclamos = rows.ToDictionary(
                x => (int)x.CodRec,
                x => (x.FechaLimite, x.Prioridad ?? string.Empty));
        }

        var detallePorOrigen = detalles
            .GroupBy(d => $"{d.TipoOrigen}|{d.IdOrigen}", StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.OrderByDescending(d => d.Id).First(), StringComparer.OrdinalIgnoreCase);
        var ejecucionPorOrigen = ejecuciones
            .GroupBy(e => $"{e.TipoOrigen}|{e.IdOrigen}", StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.OrderByDescending(e => e.FechaHoraEjecucion).First(), StringComparer.OrdinalIgnoreCase);

        var ahora = DateTime.Now;
        var resultado = new List<AdminSolicitudDto>(baseSolicitudes.Count);
        foreach (var s in baseSolicitudes)
        {
            var idOrigen = s.TipoOrigen == "ODECO" ? (s.FolioOdeco ?? ParseIdOrigen(s.Id)).ToString() : ParseIdOrigen(s.Id).ToString();
            var key = $"{s.TipoOrigen}|{idOrigen}";
            detallePorOrigen.TryGetValue(key, out var detalle);
            ejecucionPorOrigen.TryGetValue(key, out var ejecucion);

            var estado = ejecucion is not null
                ? "Completada"
                : detalle is not null
                    ? NormalizarEstadoDetalle(detalle.Estado)
                    : s.Estado;

            DateTime? limite;
            string prioridad;
            if (s.TipoOrigen == "ODECO")
            {
                var id = s.FolioOdeco ?? ParseIdOrigen(s.Id);
                reclamos.TryGetValue(id, out var rec);
                limite = rec.Limite.HasValue && rec.Limite.Value > s.FechaSolicitud
                    ? rec.Limite
                    : s.FechaSolicitud.AddHours(24);
                prioridad = rec.Prioridad == "A" || s.EsUrgente ? "Alta" : rec.Prioridad == "B" ? "Media" : "Normal";
            }
            else
            {
                limite = new DateTime(s.FechaSolicitud.Year, s.FechaSolicitud.Month, 1).AddMonths(1);
                prioridad = "Normal";
            }

            var vencida = estado != "Completada" && limite.HasValue && ahora > limite.Value;
            var dias = Math.Max(0, (int)Math.Floor((ahora - s.FechaSolicitud).TotalDays));
            resultado.Add(new AdminSolicitudDto(
                s.Id,
                s.TipoOrigen,
                s.FechaSolicitud,
                limite,
                vencida,
                dias,
                s.CodCon,
                s.NombreCliente,
                s.Direccion,
                s.MotivoObservacion,
                prioridad,
                estado,
                ejecucion?.IdUsuarioApp ?? detalle?.Asignacion.IdUsuarioApp,
                ejecucion?.Usuario?.NombreCompleto ?? detalle?.Asignacion.Usuario?.NombreCompleto,
                s.NumeroMedidor,
                s.MarcaMedidor,
                s.LecturaAnterior,
                s.LecturaActual,
                s.Consumo,
                ejecucion?.FechaHoraEjecucion,
                ejecucion is not null));
        }

        return resultado;
    }

    private async Task<AdminRutaDto> MapRutaAsync(Cosaalt.API.Domain.Entities.AsignacionRuta ruta)
    {
        var odecoIds = ruta.Detalles.Where(d => d.TipoOrigen == "ODECO").Select(d => d.IdOrigen).Distinct().ToList();
        var lecturaIds = ruta.Detalles.Where(d => d.TipoOrigen == "LECTURA").Select(d => d.IdOrigen).Distinct().ToList();
        var ejecuciones = new List<Cosaalt.API.Domain.Entities.EjecucionCambio>();
        if (odecoIds.Count > 0)
            ejecuciones.AddRange(await _context.EjecucionesCambio.AsNoTracking().Where(e => e.TipoOrigen == "ODECO" && odecoIds.Contains(e.IdOrigen)).ToListAsync());
        if (lecturaIds.Count > 0)
            ejecuciones.AddRange(await _context.EjecucionesCambio.AsNoTracking().Where(e => e.TipoOrigen == "LECTURA" && lecturaIds.Contains(e.IdOrigen)).ToListAsync());

        var detalles = ruta.Detalles.OrderBy(d => d.OrdenVisita).Select(d =>
        {
            var ejec = ejecuciones.Where(e => e.TipoOrigen == d.TipoOrigen && e.IdOrigen == d.IdOrigen).OrderByDescending(e => e.FechaHoraEjecucion).FirstOrDefault();
            var ejecutada = ejec is not null || d.Estado.Equals("Completada", StringComparison.OrdinalIgnoreCase);
            return new AdminRutaDetalleDto(d.Id, d.OrdenVisita, d.SolicitudId, d.TipoOrigen, d.NombreCliente, d.Direccion, d.Latitud, d.Longitud, ejecutada ? "Completada" : d.Estado, ejecutada, ejec?.FechaHoraEjecucion);
        }).ToList();

        var completadas = detalles.Count(d => d.Ejecutada);
        var total = detalles.Count;
        var estado = total > 0 && completadas == total ? "Completada" : completadas > 0 ? "EnCurso" : ruta.Estado;
        return new AdminRutaDto(
            ruta.Id,
            ruta.IdUsuarioApp,
            ruta.Usuario?.NombreCompleto ?? $"Tecnico #{ruta.IdUsuarioApp}",
            ruta.FechaAsignacion,
            estado,
            total,
            completadas,
            Math.Max(0, total - completadas),
            total == 0 ? 0 : Math.Round((decimal)completadas * 100m / total, 1),
            ejecuciones.Count == 0 ? null : ejecuciones.Max(e => e.FechaHoraEjecucion),
            detalles);
    }

    private IQueryable<HistoricoCorporativoRow> ConsultaHistoricoCorporativo() =>
        from cambio in _context.CambiosMedidoresDbo.AsNoTracking()
        join conexion in _context.Conexiones.AsNoTracking() on cambio.CodCon equals conexion.CodCon into conexiones
        from conexion in conexiones.DefaultIfEmpty()
        join predio in _context.Predios.AsNoTracking() on conexion.CodPre equals predio.CodPre into predios
        from predio in predios.DefaultIfEmpty()
        join medidor in _context.MedidoresDbo.AsNoTracking() on cambio.CodMed equals medidor.CodMed into medidores
        from medidor in medidores.DefaultIfEmpty()
        join marca in _context.MarcasDbo.AsNoTracking() on medidor.CodMar equals (int?)marca.CodMar into marcas
        from marca in marcas.DefaultIfEmpty()
        join motivo in _context.MotivosCambioMedidorDbo.AsNoTracking() on cambio.CodMoCaMe equals (int?)motivo.CodMoCaMe into motivos
        from motivo in motivos.DefaultIfEmpty()
        select new HistoricoCorporativoRow
        {
            CodCaMe = cambio.CodCaMe,
            CodCon = cambio.CodCon,
            NombreCliente = conexion != null ? conexion.NomSoc : null,
            CodUbiPre = predio != null ? predio.CodUbiPre : null,
            NumPre = predio != null ? predio.NumPre : null,
            NumeroMedidor = medidor != null ? medidor.SerMed : null,
            Marca = marca != null ? marca.NomMar : null,
            AliasMarca = marca != null ? marca.AliMar : null,
            Vigente = cambio.EstCaMe,
            IdMotivo = cambio.CodMoCaMe,
            Motivo = motivo != null ? motivo.NomMoCaMe : null,
            Descripcion = cambio.DesCaMe,
            CodOrdenTrabajo = cambio.CodOrTr
        };

    private static IQueryable<HistoricoCorporativoRow> AplicarFiltroHistoricoCorporativo(
        IQueryable<HistoricoCorporativoRow> query,
        AdminMovimientoCorporativoFiltro filtro)
    {
        if (filtro.CodCon.HasValue)
            query = query.Where(x => x.CodCon == filtro.CodCon.Value);
        if (filtro.Vigente.HasValue)
            query = query.Where(x => x.Vigente == filtro.Vigente.Value);
        if (filtro.MotivoId.HasValue)
            query = query.Where(x => x.IdMotivo == filtro.MotivoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Marca))
        {
            var marca = filtro.Marca.Trim();
            query = query.Where(x =>
                (x.Marca != null && x.Marca.Contains(marca)) ||
                (x.AliasMarca != null && x.AliasMarca.Contains(marca)));
        }
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var buscar = filtro.Buscar.Trim();
            if (int.TryParse(buscar, out var numero))
            {
                query = query.Where(x =>
                    x.CodCon == numero ||
                    x.CodCaMe == numero ||
                    (x.CodOrdenTrabajo.HasValue && x.CodOrdenTrabajo.Value == numero) ||
                    (x.NumeroMedidor != null && x.NumeroMedidor.Contains(buscar)));
            }
            else
            {
                query = query.Where(x =>
                    (x.NombreCliente != null && x.NombreCliente.Contains(buscar)) ||
                    (x.NumeroMedidor != null && x.NumeroMedidor.Contains(buscar)) ||
                    (x.Marca != null && x.Marca.Contains(buscar)) ||
                    (x.AliasMarca != null && x.AliasMarca.Contains(buscar)) ||
                    (x.Motivo != null && x.Motivo.Contains(buscar)) ||
                    (x.Descripcion != null && x.Descripcion.Contains(buscar)));
            }
        }
        return query;
    }

    private static AdminMovimientoCorporativoDto MapHistoricoCorporativo(HistoricoCorporativoRow x)
    {
        var marca = string.IsNullOrWhiteSpace(x.Marca) ? x.AliasMarca : x.Marca;
        return new AdminMovimientoCorporativoDto(
            x.CodCaMe,
            x.CodCon,
            string.IsNullOrWhiteSpace(x.NombreCliente) ? "Sin nombre" : x.NombreCliente.Trim(),
            BandejaOdecoBuilder.BuildDireccion(x.CodUbiPre, x.NumPre),
            string.IsNullOrWhiteSpace(x.NumeroMedidor) ? "Sin serial" : x.NumeroMedidor.Trim(),
            string.IsNullOrWhiteSpace(marca) ? null : marca.Trim(),
            x.Vigente,
            x.IdMotivo,
            string.IsNullOrWhiteSpace(x.Motivo) ? null : x.Motivo.Trim(),
            string.IsNullOrWhiteSpace(x.Descripcion) ? null : x.Descripcion.Trim(),
            x.CodOrdenTrabajo);
    }

    private IQueryable<Cosaalt.API.Domain.Entities.EjecucionCambio> ConsultaMovimientos() =>
        _context.EjecucionesCambio
            .AsNoTracking()
            .Include(e => e.Conexion).ThenInclude(c => c.Predio)
            .Include(e => e.Usuario).ThenInclude(u => u.Funcionario).ThenInclude(f => f!.Persona)
            .Include(e => e.Motivo)
            .Include(e => e.Evidencias);

    private static IQueryable<Cosaalt.API.Domain.Entities.EjecucionCambio> AplicarFiltroMovimientos(
        IQueryable<Cosaalt.API.Domain.Entities.EjecucionCambio> query,
        AdminMovimientoFiltro filtro)
    {
        if (filtro.Desde.HasValue)
            query = query.Where(e => e.FechaHoraEjecucion >= filtro.Desde.Value.Date);
        if (filtro.Hasta.HasValue)
            query = query.Where(e => e.FechaHoraEjecucion < filtro.Hasta.Value.Date.AddDays(1));
        if (filtro.TecnicoId.HasValue)
            query = query.Where(e => e.IdUsuarioApp == filtro.TecnicoId.Value);
        if (filtro.MotivoId.HasValue)
            query = query.Where(e => e.IdMotivo == filtro.MotivoId.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Origen) && !filtro.Origen.Equals("Todos", StringComparison.OrdinalIgnoreCase))
            query = query.Where(e => e.TipoOrigen == filtro.Origen);
        if (!string.IsNullOrWhiteSpace(filtro.Marca))
        {
            var marca = filtro.Marca.Trim();
            query = query.Where(e => (e.MarcaRetirado != null && e.MarcaRetirado.Contains(marca)) || (e.MarcaInstalado != null && e.MarcaInstalado.Contains(marca)));
        }
        if (filtro.Sincronizado.HasValue)
            query = query.Where(e => e.Sincronizado == filtro.Sincronizado.Value);
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var buscar = filtro.Buscar.Trim();
            if (int.TryParse(buscar, out var numero))
                query = query.Where(e => e.CodCon == numero || e.Id == numero || e.NumeroMedidorRetirado.Contains(buscar) || e.NumeroMedidorInstalado.Contains(buscar));
            else
                query = query.Where(e => e.NumeroMedidorRetirado.Contains(buscar) || e.NumeroMedidorInstalado.Contains(buscar) || (e.Conexion.NomSoc != null && e.Conexion.NomSoc.Contains(buscar)));
        }
        return query;
    }

    private static AdminMovimientoDto MapMovimiento(Cosaalt.API.Domain.Entities.EjecucionCambio e) => new(
        e.Id,
        e.FechaHoraEjecucion,
        e.TipoOrigen,
        e.IdOrigen,
        e.CodCon,
        e.Conexion?.NomSoc ?? "Sin nombre",
        BandejaOdecoBuilder.BuildDireccion(e.Conexion?.Predio),
        e.NumeroMedidorRetirado,
        e.MarcaRetirado,
        e.LecturaRetiro,
        e.IdMotivo,
        e.Motivo?.NomMoCaMe ?? $"Motivo #{e.IdMotivo}",
        e.NumeroMedidorInstalado,
        e.MarcaInstalado,
        e.ObservacionesInstalacion,
        e.LatLong,
        e.IdUsuarioApp,
        e.Usuario?.NombreCompleto ?? $"Usuario #{e.IdUsuarioApp}",
        e.Sincronizado,
        e.Evidencias.Count,
        e.Evidencias.Select(f => new EvidenciaHistorialDto(f.TipoFoto, f.RutaArchivo)).ToList());

    private static AdminVerificacionResumenDto MapVerificacionResumen(Cosaalt.API.Domain.Entities.Verificacion v)
    {
        var informe = v.Informes.OrderByDescending(i => i.FechaEmision).FirstOrDefault();
        return new AdminVerificacionResumenDto(
            v.Id,
            v.TipoOrigen,
            v.IdOrigen,
            v.CodCon,
            v.Conexion?.NomSoc ?? "Sin nombre",
            v.IdMedidor,
            v.FechaVerificacion,
            v.IdUsuarioMecanico,
            v.Mecanico?.NombreCompleto ?? $"Mecanico #{v.IdUsuarioMecanico}",
            v.Estado,
            v.Resultado,
            v.Ensayo?.Error,
            v.Ensayo?.Caudal,
            v.Ensayo?.Fugas,
            informe is not null,
            informe?.NroInforme,
            informe?.Firmado ?? false);
    }

    private async Task<IReadOnlyList<AdminActividadDto>> ObtenerActividadRecienteAsync()
    {
        var ejecuciones = await _context.EjecucionesCambio
            .AsNoTracking()
            .Include(e => e.Usuario).ThenInclude(u => u.Funcionario).ThenInclude(f => f!.Persona)
            .OrderByDescending(e => e.FechaHoraEjecucion)
            .Take(8)
            .Select(e => new AdminActividadDto(e.FechaHoraEjecucion, "CAMBIO", $"Cambio #{e.Id}", $"{e.TipoOrigen}-{e.IdOrigen} por {e.Usuario.NombreUsuario}", e.Sincronizado ? "Sincronizado" : "Pendiente"))
            .ToListAsync();

        List<AdminActividadDto> verificaciones;
        try
        {
            verificaciones = await _context.Verificaciones
                .AsNoTracking()
                .Include(v => v.Mecanico)
                .OrderByDescending(v => v.FechaVerificacion)
                .Take(8)
                .Select(v => new AdminActividadDto(
                    v.FechaVerificacion,
                    "VERIFICACION",
                    $"Verificacion #{v.Id}",
                    $"CodCon {v.CodCon} - {v.Mecanico.NombreUsuario}",
                    v.Resultado ?? v.Estado))
                .ToListAsync();
        }
        catch (Exception ex) when (EsErrorModuloVerificacion(ex))
        {
            verificaciones = [];
        }

        return ejecuciones.Concat(verificaciones).OrderByDescending(x => x.Fecha).Take(10).ToList();
    }

    private async Task<(int Pendientes, int EnCurso, int Completadas, int Cumple, int NoCumple, int SinResultado)> ObtenerResumenVerificacionesSeguroAsync()
    {
        try
        {
            var query = _context.Verificaciones.AsNoTracking();
            return (
                await query.CountAsync(v => v.Estado == "Pendiente"),
                await query.CountAsync(v => v.Estado == "EnCurso" || v.Estado == "En Curso"),
                await query.CountAsync(v => v.Estado == "Completada"),
                await query.CountAsync(v => v.Resultado == "CUMPLE"),
                await query.CountAsync(v => v.Resultado == "NO CUMPLE"),
                await query.CountAsync(v => v.Estado == "Completada" && v.Resultado == null));
        }
        catch (Exception ex) when (EsErrorModuloVerificacion(ex))
        {
            return (0, 0, 0, 0, 0, 0);
        }
    }

    private async Task<List<Cosaalt.API.Domain.Entities.Verificacion>> ObtenerVerificacionesEstadisticasSeguroAsync(
        DateTime desde,
        DateTime hastaExclusiva,
        int? mecanicoId,
        string? origen)
    {
        try
        {
            var query = _context.Verificaciones
                .AsNoTracking()
                .Include(v => v.Mecanico).ThenInclude(u => u.Funcionario).ThenInclude(f => f!.Persona)
                .Include(v => v.Ensayo)
                .Where(v => v.FechaVerificacion >= desde && v.FechaVerificacion < hastaExclusiva);

            if (mecanicoId.HasValue)
                query = query.Where(v => v.IdUsuarioMecanico == mecanicoId.Value);
            if (!string.IsNullOrWhiteSpace(origen))
                query = query.Where(v => v.TipoOrigen == origen);

            return await query.ToListAsync();
        }
        catch (Exception ex) when (EsErrorModuloVerificacion(ex))
        {
            return [];
        }
    }

    private static bool EsErrorModuloVerificacion(Exception ex)
    {
        // Las tablas del modulo mecanico se integran de manera independiente. Un esquema aun no
        // desplegado o temporalmente incompatible no debe derribar el panel administrativo.
        // Se limita el fallback a errores de acceso/modelado de datos; errores ajenos siguen
        // propagandose para no ocultar defectos de programacion.
        return ex is Microsoft.Data.SqlClient.SqlException
            || ex is Microsoft.EntityFrameworkCore.DbUpdateException
            || (ex is InvalidOperationException &&
                (ex.Message.Contains("Verificacion", StringComparison.OrdinalIgnoreCase)
                 || ex.Message.Contains("relationship", StringComparison.OrdinalIgnoreCase)
                 || ex.Message.Contains("column", StringComparison.OrdinalIgnoreCase)));
    }

    private async Task<HashSet<int>> BuscarCodConPorMedidorAsync(string buscar)
    {
        if (string.IsNullOrWhiteSpace(buscar)) return [];

        var patron = $"%{buscar.Trim()}%";
        var parametro = new SqlParameter("@buscar", patron);
        const string sql = """
            SELECT DISTINCT cm.CodCon
            FROM dbo.CambioMedidores cm
            INNER JOIN dbo.Medidores m ON m.CodMed = cm.CodMed
            LEFT JOIN dbo.Marcas ma ON ma.CodMar = m.CodMar
            WHERE cm.EstCaMe = CAST(1 AS bit)
              AND (LTRIM(RTRIM(m.SerMed)) LIKE @buscar
                   OR LTRIM(RTRIM(COALESCE(ma.NomMar, ''))) LIKE @buscar
                   OR LTRIM(RTRIM(COALESCE(ma.AliMar, ''))) LIKE @buscar)
            """;

        var rows = await _context.Database
            .SqlQueryRaw<ConexionPorMedidorRow>(sql, parametro)
            .ToListAsync();

        return rows
            .Select(x => (int)x.CodCon)
            .Where(x => x > 0)
            .ToHashSet();
    }

    private async Task<List<double>> CalcularHorasAtencionAsync(IReadOnlyList<Cosaalt.API.Domain.Entities.EjecucionCambio> movimientos)
    {
        var resultado = new List<double>();
        var odeco = movimientos.Where(e => e.TipoOrigen == "ODECO").Select(e => new { E = e, Id = ParseInt(e.IdOrigen) }).Where(x => x.Id > 0).ToList();
        var lectura = movimientos.Where(e => e.TipoOrigen == "LECTURA").Select(e => new { E = e, Id = ParseInt(e.IdOrigen) }).Where(x => x.Id > 0).ToList();

        if (odeco.Count > 0)
        {
            var fechas = await ObtenerFechasOdecoAsync(odeco.Select(x => x.Id).Distinct().ToList());
            foreach (var x in odeco)
                if (fechas.TryGetValue(x.Id, out var fecha) && x.E.FechaHoraEjecucion >= fecha)
                    resultado.Add((x.E.FechaHoraEjecucion - fecha).TotalHours);
        }

        if (lectura.Count > 0)
        {
            var ids = lectura.Select(x => x.Id).Distinct().ToList();
            var fechas = await _context.DetallesSolicitudLectura
                .AsNoTracking()
                .Where(d => ids.Contains(d.Id))
                .Select(d => new { d.Id, d.Solicitud.FechaEmision })
                .ToDictionaryAsync(x => x.Id, x => x.FechaEmision);
            foreach (var x in lectura)
                if (fechas.TryGetValue(x.Id, out var fecha) && x.E.FechaHoraEjecucion >= fecha)
                    resultado.Add((x.E.FechaHoraEjecucion - fecha).TotalHours);
        }
        return resultado;
    }

    private async Task<Dictionary<int, DateTime>> ObtenerFechasOdecoAsync(IReadOnlyList<int> ids)
    {
        var result = new Dictionary<int, DateTime>();
        foreach (var lote in ids.Chunk(500))
        {
            var parametros = lote.Select((id, i) => new SqlParameter($"@i{i}", (decimal)id)).ToArray();
            var inClause = string.Join(", ", parametros.Select(p => p.ParameterName));
            var sql = $"SELECT CodRec, FecRec FROM dbo.Reclamos WHERE CodRec IN ({inClause})";
            var rows = await _context.Database.SqlQueryRaw<OdecoFechaRow>(sql, parametros).ToListAsync();
            foreach (var row in rows) result[(int)row.CodRec] = row.FecRec;
        }
        return result;
    }

    private async Task<List<OdecoPlazoRow>> ObtenerPlazosOdecoAsync(IReadOnlyList<int> ids)
    {
        var result = new List<OdecoPlazoRow>();
        foreach (var lote in ids.Chunk(500))
        {
            var parametros = lote.Select((id, i) => new SqlParameter($"@i{i}", (decimal)id)).ToArray();
            var inClause = string.Join(", ", parametros.Select(p => p.ParameterName));
            var sql = $"SELECT CodRec, FecEstResRec AS FechaLimite, PriRec AS Prioridad FROM dbo.Reclamos WHERE CodRec IN ({inClause})";
            result.AddRange(await _context.Database.SqlQueryRaw<OdecoPlazoRow>(sql, parametros).ToListAsync());
        }
        return result;
    }

    private static PagedResultDto<T> Paginar<T>(IReadOnlyList<T> items, int page, int pageSize)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 5, 100);
        var total = items.Count;
        var data = items.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        return new PagedResultDto<T>(data, page, pageSize, total, CalcularPaginas(total, pageSize));
    }

    private static int CalcularPaginas(int total, int pageSize) => total == 0 ? 0 : (int)Math.Ceiling(total / (double)pageSize);
    private static int ParseIdOrigen(string id) => ParseInt(id.Contains('-') ? id[(id.LastIndexOf('-') + 1)..] : id);
    private static int ParseInt(string value) => int.TryParse(value, out var id) ? id : 0;

    private static string NormalizarEstadoDetalle(string estado) => estado.ToLowerInvariant() switch
    {
        "completada" or "completado" or "ejecutada" or "ejecutado" => "Completada",
        "encurso" or "en curso" or "proceso" or "en proceso" => "En proceso",
        _ => "Asignada"
    };

    private sealed record AdminSolicitudDashboardRow(
        string TipoOrigen,
        DateTime FechaSolicitud,
        bool Vencida,
        string Prioridad,
        string Estado);

    private sealed class AdminOdecoRow
    {
        public int CodRec { get; set; }
        public DateTime FecRec { get; set; }
        public string? DesRec { get; set; }
        public char PriRec { get; set; }
        public int CodCon { get; set; }
        public string? NomRec { get; set; }
        public string? NomSoc { get; set; }
        public double? Latitud { get; set; }
        public double? Longitud { get; set; }
        public string? CodUbiPre { get; set; }
        public string? NumPre { get; set; }
    }

    private sealed class HistoricoCorporativoRow
    {
        public int CodCaMe { get; set; }
        public int CodCon { get; set; }
        public string? NombreCliente { get; set; }
        public string? CodUbiPre { get; set; }
        public string? NumPre { get; set; }
        public string? NumeroMedidor { get; set; }
        public string? Marca { get; set; }
        public string? AliasMarca { get; set; }
        public bool Vigente { get; set; }
        public int? IdMotivo { get; set; }
        public string? Motivo { get; set; }
        public string? Descripcion { get; set; }
        public int? CodOrdenTrabajo { get; set; }
    }

    private sealed class ConexionPorMedidorRow
    {
        public decimal CodCon { get; set; }
    }

    private sealed class OdecoFechaRow
    {
        public decimal CodRec { get; set; }
        public DateTime FecRec { get; set; }
    }

    private sealed class OdecoPlazoRow
    {
        public decimal CodRec { get; set; }
        public DateTime? FechaLimite { get; set; }
        public string? Prioridad { get; set; }
    }
}
