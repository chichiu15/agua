using System.Data;
using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Cosaalt.API.Infrastructure.Exporting;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlVerificacionRepository : IVerificacionRepository
{
    private readonly CosaaltDbContext _context;
    private readonly CosaaltInstitutionalReader _institutional;
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;

    public SqlVerificacionRepository(
        CosaaltDbContext context,
        CosaaltInstitutionalReader institutional,
        IConfiguration configuration,
        IWebHostEnvironment environment)
    {
        _context = context;
        _institutional = institutional;
        _configuration = configuration;
        _environment = environment;
    }

    public async Task<IReadOnlyList<SolicitudVerificacionDto>> ObtenerSolicitudesAsync()
    {
        // Hasta que COSAALT confirme exactamente que tipos/observaciones originan REVISION,
        // se exponen ODECO filtrables por configuracion y las rutas REVISION propias de la app.
        var tipos = SqlSolicitudRepository.ParseIds(_configuration["CosaaltRules:OdecoTipoReclamoIds"]);
        var odecos = await _institutional.ObtenerOdecosAsync(tipos, 1000);
        var tomadas = await _context.Verificaciones.AsNoTracking()
            .Select(v => new { v.TipoOrigen, v.IdOrigen, v.Estado })
            .ToListAsync();
        var taken = tomadas
            .GroupBy(x => $"{x.TipoOrigen}|{x.IdOrigen}", StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key,
                g => g.FirstOrDefault(x => !string.Equals(x.Estado, "Cancelada", StringComparison.OrdinalIgnoreCase))?.Estado ?? "Cancelada",
                StringComparer.OrdinalIgnoreCase);

        var list = odecos.Select(o =>
        {
            var key = $"ODECO|{o.CodRec}";
            var tomada = taken.TryGetValue(key, out var est) && !string.Equals(est, "Cancelada", StringComparison.OrdinalIgnoreCase);
            var motivo = string.Join(" - ", new[] { o.TipoReclamo, o.Observacion }.Where(x => !string.IsNullOrWhiteSpace(x)));
            return new SolicitudVerificacionDto(
                $"ODECO-{o.CodRec}", "ODECO", o.RegSoc, o.NombreSocio, o.Direccion, o.Prioridad,
                o.SerieMedidor, o.MarcaMedidor, string.IsNullOrWhiteSpace(motivo) ? null : motivo,
                o.Fecha, tomada ? "Tomada" : "Pendiente", tomada);
        }).ToList();

        // Mantiene disponible la misma bateria temporal QA que usan
        // Asignador/Tecnico/Admin. Esto permite probar los endpoints M1-M5 sin
        // convertir las filas temporales en registros institucionales dbo.*.
        var qa = await _institutional.ObtenerSolicitudesPruebaAsync();
        foreach (var s in qa)
        {
            var key = $"{s.TipoOrigen}|{s.Id}";
            var tomada = taken.TryGetValue(key, out var est)
                && !string.Equals(est, "Cancelada", StringComparison.OrdinalIgnoreCase);
            list.Add(new SolicitudVerificacionDto(
                s.Id, s.TipoOrigen, s.CodCon, s.NombreCliente, s.Direccion,
                s.Categoria, s.NumeroMedidor, s.MarcaMedidor, s.MotivoObservacion,
                s.FechaSolicitud, tomada ? "Tomada" : s.Estado, tomada));
        }

        var revisiones = await _context.DetallesRuta.AsNoTracking()
            .Where(d => d.TipoOrigen == "REVISION" && d.RegSoc != null)
            .OrderByDescending(d => d.Id)
            .Take(500)
            .ToListAsync();
        foreach (var d in revisiones)
        {
            var key = $"REVISION|{d.IdOrigen}";
            var tomada = taken.TryGetValue(key, out var est) && !string.Equals(est, "Cancelada", StringComparison.OrdinalIgnoreCase);
            var med = d.CodMedidorActual.HasValue ? await _institutional.ObtenerMedidorPorCodigoAsync(d.CodMedidorActual.Value) : null;
            list.Add(new SolicitudVerificacionDto(
                d.SolicitudId, "REVISION", d.RegSoc!.Value, d.NombreCliente, d.Direccion, null,
                med?.Serie, med?.Marca, "Revision de medidor", d.FechaInicio ?? DateTime.Now,
                tomada ? "Tomada" : d.Estado, tomada));
        }
        return list.OrderBy(x => x.Tomada).ThenByDescending(x => x.FechaSolicitud).ToList();
    }

    public async Task<TomarVerificacionResponseDto> TomarAsync(TomarVerificacionRequestDto request)
    {
        var tipo = (request.TipoOrigen ?? string.Empty).Trim().ToUpperInvariant();
        if (tipo is not ("ODECO" or "LECTURA" or "REVISION"))
            throw new InvalidOperationException("El origen de la solicitud no es valido.");

        var idOrigen = NormalizeOrigen(tipo, request.IdOrigen);
        if (string.IsNullOrWhiteSpace(idOrigen))
            throw new InvalidOperationException("No fue posible identificar la solicitud.");

        // REVISION se muestra en la bandeja con SolicitudId, pero la clave canonica
        // del proceso es DetalleRuta.IdOrigen. Se resuelve aqui antes de persistir
        // para que la solicitud tomada, el historial y la direccion utilicen la
        // misma clave en todo el modulo.
        DetalleRuta? detalleRevision = null;
        if (tipo == "REVISION")
        {
            detalleRevision = await _context.DetallesRuta.AsNoTracking()
                .Where(d => d.TipoOrigen == "REVISION"
                    && (d.IdOrigen == idOrigen || d.SolicitudId == idOrigen))
                .OrderByDescending(d => d.Id)
                .FirstOrDefaultAsync();

            if (detalleRevision is null)
                throw new InvalidOperationException("No se encontro la solicitud de revision seleccionada.");

            idOrigen = detalleRevision.IdOrigen;
        }

        var mecanico = await _context.Usuarios.AsNoTracking()
            .Include(u => u.Rol)
            .FirstOrDefaultAsync(u =>
                u.Id == request.IdUsuarioMecanico
                && u.Activo
                && u.Rol.Nombre.ToLower() == "mecanico")
            ?? throw new InvalidOperationException("El mecanico no existe o esta inactivo.");

        var regSoc = request.CodCon;
        if (regSoc <= 0 && detalleRevision?.RegSoc is int regSocRevision)
            regSoc = regSocRevision;

        if (regSoc <= 0 && tipo == "ODECO" && int.TryParse(idOrigen, out var codRec))
            regSoc = (await _institutional.ObtenerOdecoAsync(codRec))?.RegSoc ?? 0;

        if (regSoc <= 0)
            throw new InvalidOperationException("No fue posible identificar el socio de la verificacion.");

        MedidorInstitucional? medidor = null;
        if (int.TryParse(request.IdMedidor, out var codMedidor))
            medidor = await _institutional.ObtenerMedidorPorCodigoAsync(codMedidor);

        if (medidor is null && !string.IsNullOrWhiteSpace(request.IdMedidor))
            medidor = await _institutional.ObtenerMedidorPorSerieAsync(request.IdMedidor, regSoc);

        if (medidor is null && detalleRevision?.CodMedidorActual is int codMedidorRevision)
            medidor = await _institutional.ObtenerMedidorPorCodigoAsync(codMedidorRevision);

        medidor ??= await _institutional.ObtenerMedidorActualAsync(regSoc);
        if (medidor is null)
            throw new InvalidOperationException("No se encontro el medidor asociado al socio.");

        // La comprobacion y el INSERT se protegen con un bloqueo logico de SQL Server
        // asociado al origen de la solicitud. No cambia el esquema de la base y evita
        // que dos mecanicos puedan tomar la misma solicitud de forma simultanea.
        await using var transaction = await _context.Database.BeginTransactionAsync();
        await BloquearSolicitudAsync(tipo, idOrigen);

        var yaTomada = await _context.Verificaciones.AnyAsync(v =>
            v.TipoOrigen == tipo
            && v.IdOrigen == idOrigen
            && v.Estado != "Cancelada");

        if (yaTomada)
            throw new InvalidOperationException("La solicitud ya fue tomada por otro mecanico.");

        var entity = new Verificacion
        {
            TipoOrigen = tipo,
            IdOrigen = idOrigen,
            RegSoc = regSoc,
            IdUsuarioMecanico = request.IdUsuarioMecanico,
            CodMedidor = medidor.CodMedidor,
            FechaVerificacion = DateTime.Now,
            Estado = "EnCurso"
        };

        _context.Verificaciones.Add(entity);
        await _context.SaveChangesAsync();
        await transaction.CommitAsync();

        return new TomarVerificacionResponseDto(
            entity.Id,
            "Verificacion iniciada correctamente.");
    }

    public async Task<IReadOnlyList<VerificacionDto>> ObtenerVerificacionesAsync(int idMecanico)
    {
        var rows = await _context.Verificaciones.AsNoTracking()
            .Include(v => v.Mecanico).ThenInclude(u => u.Rol)
            .Include(v => v.Ensayo)
            .Include(v => v.Participantes)
            .Where(v => v.IdUsuarioMecanico == idMecanico)
            .OrderByDescending(v => v.FechaVerificacion)
            .ToListAsync();
        var result = new List<VerificacionDto>();
        foreach (var v in rows) result.Add(await ToDtoAsync(v));
        return result;
    }

    public async Task<VerificacionDto?> ObtenerVerificacionAsync(int id)
    {
        var row = await _context.Verificaciones.AsNoTracking()
            .Include(v => v.Mecanico).ThenInclude(u => u.Rol)
            .Include(v => v.Ensayo)
            .Include(v => v.Participantes)
            .FirstOrDefaultAsync(v => v.Id == id);
        return row is null ? null : await ToDtoAsync(row);
    }

    public async Task<DatosSocioMedidorDto?> ObtenerDatosSocioMedidorAsync(int idVerificacion)
    {
        var v = await _context.Verificaciones.AsNoTracking()
            .Include(x => x.Ensayo)
            .FirstOrDefaultAsync(x => x.Id == idVerificacion);
        if (v is null) return null;

        var socio = await _institutional.ObtenerSocioAsync(v.RegSoc);
        var med = await _institutional.ObtenerMedidorPorCodigoAsync(v.CodMedidor);
        if (socio is null) return null;

        var direccion = await ResolveDireccionAsync(v.TipoOrigen, v.IdOrigen);
        var codConexion = await ResolveCodConexionAsync(v.TipoOrigen, v.IdOrigen);
        var motivoObservacion = await ResolveMotivoObservacionAsync(v.TipoOrigen, v.IdOrigen);

        string? tipoEnsayo = null;
        if (v.Ensayo is not null)
        {
            var (_, tipoPrueba, _, _, _, _, _, _, _, _, _, _) =
                EnsayoCamposProvisionales.Decode(v.Ensayo.Condiciones);
            tipoEnsayo = V(tipoPrueba);
        }

        var lugarVerificacion = V(_configuration["CosaaltRules:LugarVerificacionMecanica"]);

        return new DatosSocioMedidorDto(
            CodCon: v.RegSoc, // compatibilidad con DTOs existentes; no se usa como CodConexion en M3
            NombreCliente: socio.Nombre,
            Direccion: direccion ?? string.Empty,
            Categoria: null,
            NumeroDocumento: socio.Documento,
            TipDocumento: null,
            Ruc: socio.Ruc,
            NumeroMedidor: med?.Serie,
            MarcaMedidor: med?.Marca,
            FechaConexion: med?.FechaRegistro,
            CapacidadQ3: med?.Capacidad,
            TipoMedidor: med?.Tipo,
            ClaseMedidor: med?.Clase,
            DiametroMedidor: med?.Diametro,
            RegSoc: v.RegSoc,
            CodConexion: codConexion,
            LugarVerificacion: lugarVerificacion,
            TipoEnsayo: tipoEnsayo,
            MotivoObservacion: motivoObservacion);
    }

    public async Task<VerificacionDto?> GuardarEnsayoAsync(
        int idVerificacion,
        decimal? volumenRegistrado,
        decimal? error,
        int? idParametroNormativo,
        string? resultado,
        GuardarEnsayoRequestDto request)
    {
        var v = await _context.Verificaciones
            .Include(x => x.Ensayo)
            .Include(x => x.Participantes)
            .Include(x => x.Mecanico).ThenInclude(u => u.Rol)
            .FirstOrDefaultAsync(x => x.Id == idVerificacion);
        if (v is null) return null;
        if (v.Estado == "Completada")
            throw new InvalidOperationException("La verificacion ya fue finalizada y no admite modificaciones.");

        var ensayo = v.Ensayo ?? new EnsayoVerificacion { IdVerificacion = v.Id, FechaRegistro = DateTime.Now };
        ensayo.Condiciones = EnsayoCamposProvisionales.Encode(
            request.Condiciones,
            request.TipoPrueba,
            request.InstrumentoBanco,
            request.IdentificacionBanco,
            request.TrazabilidadCalibracion,
            request.CapacidadNominalQ3,
            request.TipoCaudal,
            request.UnidadCaudal,
            request.UnidadVolumen,
            request.TipoFuga,
            request.ParametroNormativoCodigoAplicado,
            request.LimiteNormativoAplicado);
        ensayo.LecturaInicial = request.LecturaInicial;
        ensayo.LecturaFinal = request.LecturaFinal;
        ensayo.VolumenPatron = request.VolumenPatron;
        ensayo.Caudal = request.Caudal;
        ensayo.VolumenRegistrado = volumenRegistrado;
        ensayo.Error = error;
        ensayo.Fugas = request.Fugas;
        ensayo.Observaciones = request.Observaciones;
        ensayo.FechaRegistro = DateTime.Now;
        if (v.Ensayo is null) { _context.EnsayosVerificacion.Add(ensayo); v.Ensayo = ensayo; }

        _context.ParticipantesVerificacion.RemoveRange(v.Participantes);
        v.Participantes = request.Participantes?.Where(p => !string.IsNullOrWhiteSpace(p.Nombre)).Select(p => new ParticipanteVerificacion
        {
            IdVerificacion = v.Id,
            Nombre = p.Nombre.Trim(),
            Cargo = string.IsNullOrWhiteSpace(p.Cargo) ? null : p.Cargo.Trim(),
            Rol = string.IsNullOrWhiteSpace(p.Rol) ? null : p.Rol.Trim()
        }).ToList() ?? [];

        v.IdParametroNormativoAplicado = idParametroNormativo;
        v.Resultado = resultado;
        await _context.SaveChangesAsync();

        var actualizado = await ObtenerEntityAsync(v.Id);
        return actualizado is null ? null : await ToDtoAsync(actualizado);
    }

    public async Task<VerificacionDto?> GuardarParticipantesAsync(int idVerificacion, IReadOnlyList<ParticipanteVerificacionDto> participantes)
    {
        var v = await _context.Verificaciones
            .Include(x => x.Mecanico).ThenInclude(u => u.Rol)
            .Include(x => x.Participantes)
            .FirstOrDefaultAsync(x => x.Id == idVerificacion);
        if (v is null) return null;
        if (v.Estado == "Completada")
            throw new InvalidOperationException("La verificacion ya fue finalizada y no admite modificaciones.");

        _context.ParticipantesVerificacion.RemoveRange(v.Participantes);
        v.Participantes = participantes?.Where(p => !string.IsNullOrWhiteSpace(p.Nombre)).Select(p => new ParticipanteVerificacion
        {
            IdVerificacion = v.Id,
            Nombre = p.Nombre.Trim(),
            Cargo = string.IsNullOrWhiteSpace(p.Cargo) ? null : p.Cargo.Trim(),
            Rol = string.IsNullOrWhiteSpace(p.Rol) ? null : p.Rol.Trim()
        }).ToList() ?? [];

        await _context.SaveChangesAsync();
        var actualizado = await ObtenerEntityAsync(v.Id);
        return actualizado is null ? null : await ToDtoAsync(actualizado);
    }

    public async Task<VerificacionDashboardDto> ObtenerDashboardAsync(int idMecanico)
    {
        // Misma fuente y regla de disponibilidad que la bandeja del Mecanico.
        var solicitudes = await ObtenerSolicitudesAsync();
        var rows = await _context.Verificaciones.AsNoTracking()
            .Where(v => v.IdUsuarioMecanico == idMecanico)
            .Select(v => new { v.Estado, v.Resultado })
            .ToListAsync();
        return new VerificacionDashboardDto(
            Pendientes: solicitudes.Count(s => !s.Tomada),
            EnCurso: rows.Count(v => v.Estado == "EnCurso"),
            Completadas: rows.Count(v => v.Estado == "Completada"),
            Cumple: rows.Count(v => v.Resultado == "CUMPLE"),
            NoCumple: rows.Count(v => v.Resultado == "NO CUMPLE"),
            Indeterminados: rows.Count(v => v.Resultado == "INDETERMINADO"),
            Total: rows.Count);
    }

    public async Task<VerificacionHistorialResponseDto> ObtenerHistorialAsync(int idMecanico, VerificacionHistorialFiltro filtro)
    {
        var q = _context.Verificaciones.AsNoTracking()
            .Include(v => v.Ensayo)
            .Include(v => v.Informes.OrderByDescending(i => i.VersionInforme))
            .Include(v => v.Mecanico).ThenInclude(u => u.Rol)
            .Where(v => v.IdUsuarioMecanico == idMecanico);

        if (filtro.Desde.HasValue) q = q.Where(v => v.FechaVerificacion >= filtro.Desde.Value);
        if (filtro.Hasta.HasValue) q = q.Where(v => v.FechaVerificacion <= filtro.Hasta.Value.AddDays(1));
        if (!string.IsNullOrWhiteSpace(filtro.Estado)) q = q.Where(v => v.Estado == filtro.Estado.Trim());
        if (!string.IsNullOrWhiteSpace(filtro.Resultado)) q = q.Where(v => v.Resultado == filtro.Resultado.Trim());
        if (!string.IsNullOrWhiteSpace(filtro.Buscar))
        {
            var buscar = filtro.Buscar.Trim();
            var medPorSerie = await _institutional.ObtenerMedidorPorSerieAsync(buscar);
            var codMedidorPorSerie = medPorSerie?.CodMedidor;
            q = q.Where(v =>
                v.RegSoc.ToString().Contains(buscar) ||
                v.CodMedidor.ToString().Contains(buscar) ||
                (codMedidorPorSerie.HasValue && v.CodMedidor == codMedidorPorSerie.Value) ||
                (v.Ensayo != null && (v.Ensayo.Error ?? -1).ToString().Contains(buscar)));
        }

        var page = Math.Max(1, filtro.Page);
        var pageSize = Math.Clamp(filtro.PageSize, 5, 100);
        var total = await q.CountAsync();
        var rows = await q.OrderByDescending(v => v.FechaVerificacion)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var items = new List<VerificacionHistorialItemDto>();
        foreach (var v in rows)
        {
            var socio = await _institutional.ObtenerSocioAsync(v.RegSoc);
            var med = await _institutional.ObtenerMedidorPorCodigoAsync(v.CodMedidor);
            var informe = v.Informes.FirstOrDefault();
            items.Add(new VerificacionHistorialItemDto(
                IdVerificacion: v.Id,
                Fecha: v.FechaVerificacion,
                Estado: v.Estado,
                Resultado: v.Resultado,
                Error: v.Ensayo?.Error,
                Fugas: v.Ensayo?.Fugas,
                CodCon: v.RegSoc,
                NombreCliente: socio?.Nombre,
                NumeroMedidor: med?.Serie,
                MarcaMedidor: med?.Marca,
                IdInforme: informe?.Id,
                NroInforme: informe?.NroInforme,
                TieneInforme: informe != null));
        }

        return new VerificacionHistorialResponseDto(total, page, pageSize, items);
    }

    public async Task<VerificacionDto?> FinalizarAsync(int idVerificacion)
    {
        var v = await _context.Verificaciones
            .Include(x => x.Ensayo)
            .Include(x => x.Participantes)
            .Include(x => x.Mecanico).ThenInclude(u => u.Rol)
            .FirstOrDefaultAsync(x => x.Id == idVerificacion);
        if (v is null) return null;
        if (v.Estado == "Completada")
            throw new InvalidOperationException("La verificacion ya esta finalizada.");

        if (v.Ensayo is null
            || v.Ensayo.LecturaInicial is null
            || v.Ensayo.LecturaFinal is null
            || v.Ensayo.VolumenPatron is null || v.Ensayo.VolumenPatron == 0
            || v.Ensayo.Caudal is null || v.Ensayo.Caudal <= 0)
            throw new InvalidOperationException("Complete los campos obligatorios del ensayo antes de finalizar.");

        v.Estado = "Completada";
        // Sin columna propia de fecha de finalizacion, FechaVerificacion se usa
        // como fecha de cierre (provisional hasta que COSAALT autorice el esquema).
        v.FechaVerificacion = DateTime.Now;
        await _context.SaveChangesAsync();

        var actualizado = await ObtenerEntityAsync(v.Id);
        return actualizado is null ? null : await ToDtoAsync(actualizado);
    }

    public async Task<IReadOnlyList<InformeVerificacionDto>> ObtenerInformesAsync(int idVerificacion)
    {
        return await _context.InformesVerificacion.AsNoTracking()
            .Where(i => i.IdVerificacion == idVerificacion)
            .OrderByDescending(i => i.VersionInforme)
            .Select(i => new InformeVerificacionDto(
                i.Id, i.IdVerificacion, i.NroInforme, i.FechaEmision,
                i.RutaPdf, i.Firmado, i.VersionInforme, i.Observaciones))
            .ToListAsync();
    }

    public async Task<GenerarInformeResponseDto> GenerarInformeAsync(int idVerificacion, GenerarInformeRequestDto request)
    {
        var v = await _context.Verificaciones.AsNoTracking()
            .Include(x => x.Ensayo)
            .Include(x => x.Participantes)
            .Include(x => x.ParametroNormativoAplicado)
            .Include(x => x.Mecanico).ThenInclude(u => u.Rol)
            .FirstOrDefaultAsync(x => x.Id == idVerificacion);
        if (v is null) throw new InvalidOperationException("No se encontro la verificacion.");
        if (v.Estado != "Completada")
            throw new InvalidOperationException("Finalice la verificacion antes de generar el informe.");
        if (v.Ensayo is null)
            throw new InvalidOperationException("No se pudo generar el informe: falta el ensayo.");

        var version = (await _context.InformesVerificacion.AsNoTracking()
            .Where(i => i.IdVerificacion == v.Id)
            .Select(i => (int?)i.VersionInforme)
            .ToListAsync()).Max().GetValueOrDefault(0) + 1;

        var nroInforme = $"INF-VER-{DateTime.Now.Year}-{v.Id:D6}";
        var datos = await BuildDatosInformeAsync(v, request.NombreResponsable, version);

        var bytes = InformePdfBuilder.Build(datos);
        var carpeta = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), "informes");
        Directory.CreateDirectory(carpeta);
        var archivo = $"{nroInforme}_v{version}.pdf";
        var rutaFisica = Path.Combine(carpeta, archivo);
        await System.IO.File.WriteAllBytesAsync(rutaFisica, bytes);

        var entidad = new InformeVerificacion
        {
            IdVerificacion = v.Id,
            NroInforme = nroInforme,
            FechaEmision = DateTime.Now,
            RutaPdf = $"wwwroot/informes/{archivo}",
            Firmado = false,
            VersionInforme = version,
            Observaciones = request.Observaciones
        };
        _context.InformesVerificacion.Add(entidad);
        await _context.SaveChangesAsync();

        return new GenerarInformeResponseDto(
            new InformeVerificacionDto(
                entidad.Id, entidad.IdVerificacion, entidad.NroInforme, entidad.FechaEmision,
                entidad.RutaPdf, entidad.Firmado, entidad.VersionInforme, entidad.Observaciones),
            "Informe generado correctamente.");
    }

    private async Task<InformePdfData> BuildDatosInformeAsync(Verificacion v, string? responsable, int version)
    {
        var socio = await _institutional.ObtenerSocioAsync(v.RegSoc);
        var med = await _institutional.ObtenerMedidorPorCodigoAsync(v.CodMedidor);
        var nombreMecanico = await _institutional.ObtenerNombrePersonaAsync(v.Mecanico.CodPersonaCorporativa) ?? v.Mecanico.NombreUsuario;
        var (
            condicionesDecoded,
            tipoPrueba,
            instrumentoBanco,
            _,
            _,
            capacidadQ3,
            tipoCaudal,
            unidadCaudal,
            unidadVolumen,
            tipoFuga,
            parametroNormativoSnapshot,
            limiteNormativoSnapshot) =
            EnsayoCamposProvisionales.Decode(v.Ensayo!.Condiciones);

        var (errorConSigno, errorAbsoluto) = CalcularErrores(v.Ensayo);

        // Primero usamos la norma EXACTA guardada al realizar el ensayo.
        // El valor actual del catalogo solamente sirve como compatibilidad
        // para registros viejos sin snapshot.
        var limite = limiteNormativoSnapshot
            ?? v.ParametroNormativoAplicado?.ErrorMaxPermitido;

        var direccion = await ResolveDireccionAsync(v.TipoOrigen, v.IdOrigen) ?? "No registrado";
        var documentoRuc = string.Join(" / ", new[] { socio?.Documento, socio?.Ruc }.Where(x => !string.IsNullOrWhiteSpace(x)));
        if (string.IsNullOrWhiteSpace(documentoRuc)) documentoRuc = "No registrado";

        var parametroCodigo = V(parametroNormativoSnapshot)
            ?? v.ParametroNormativoAplicado?.Codigo
            ?? "Sin parametro aplicable";
        var resultado = v.Resultado ?? "INDETERMINADO";

        return new InformePdfData(
            NroInforme: $"INF-VER-{v.FechaVerificacion.Year}-{v.Id:D6}",
            Version: version,
            FechaEmision: DateTime.Now,
            Mecanico: nombreMecanico,
            SocioNombre: socio?.Nombre ?? "No registrado",
            CodCon: v.RegSoc.ToString(),
            Direccion: direccion,
            DocumentoRuc: documentoRuc,
            MotivoOrigen: $"{v.TipoOrigen} - {v.IdOrigen}",
            MedidorMarca: med?.Marca ?? "No registrado",
            MedidorSerie: med?.Serie ?? "No registrado",
            MedidorCapacidad: V(capacidadQ3) ?? med?.Capacidad ?? "No registrado",
            MedidorTipo: V(med?.Tipo) ?? "No registrado",
            MedidorClase: V(med?.Clase) ?? "No registrado",
            MedidorDiametro: V(med?.Diametro) ?? "No registrado",
            MedidorFechaRegistro: med?.FechaRegistro?.ToString("dd/MM/yyyy") ?? "No registrado",
            FechaVerificacion: v.FechaVerificacion.ToString("dd/MM/yyyy HH:mm"),
            TipoPrueba: V(tipoPrueba) ?? "No registrado",
            InstrumentoBanco: V(instrumentoBanco) ?? "No registrado",
            TipoCaudal: V(tipoCaudal) ?? "No registrado",
            Caudal: v.Ensayo.Caudal?.ToString("0.####") ?? "No registrado",
            UnidadCaudal: V(unidadCaudal) ?? string.Empty,
            PrimeraLectura: v.Ensayo.LecturaInicial?.ToString("0.00") ?? "No registrado",
            SegundaLectura: v.Ensayo.LecturaFinal?.ToString("0.00") ?? "No registrado",
            VolumenRegistrado: v.Ensayo.VolumenRegistrado?.ToString("0.0000") ?? "No registrado",
            VolumenPatron: v.Ensayo.VolumenPatron?.ToString("0.0000") ?? "No registrado",
            Diferencia: (v.Ensayo.VolumenRegistrado - v.Ensayo.VolumenPatron)?.ToString("0.0000") ?? "No registrado",
            ErrorConSigno: errorConSigno?.ToString("0.00") ?? "No registrado",
            ErrorAbsoluto: errorAbsoluto?.ToString("0.00") ?? "No registrado",
            ParametroNormativo: parametroCodigo,
            LimitePermitido: limite?.ToString("0.00") ?? "N/A",
            Resultado: resultado,
            Fugas: v.Ensayo.Fugas?.Equals(true) == true ? "Sí" : "No",
            TipoFuga: V(tipoFuga) ?? "No reportado",
            Condiciones: V(condicionesDecoded) ?? "-",
            Observaciones: V(v.Ensayo.Observaciones) ?? "-",
            Responsable: V(responsable) ?? V(nombreMecanico) ?? "-",
            Participantes: v.Participantes
                .OrderBy(p => p.Id)
                .Select(p => (p.Nombre, p.Cargo ?? "-", p.Rol ?? "-"))
                .ToList());
    }

    private static (decimal? ConSigno, decimal? Absoluto) CalcularErrores(EnsayoVerificacion ensayo)
    {
        if (ensayo.VolumenRegistrado is null || ensayo.VolumenPatron is null || ensayo.VolumenPatron == 0)
            return (null, null);
        var conSigno = (ensayo.VolumenRegistrado.Value - ensayo.VolumenPatron.Value) / ensayo.VolumenPatron.Value * 100m;
        return (conSigno, Math.Abs(conSigno));
    }

    private async Task<Verificacion?> ObtenerEntityAsync(int id) => await _context.Verificaciones.AsNoTracking()
        .Include(v => v.Mecanico).ThenInclude(u => u.Rol)
        .Include(v => v.Ensayo)
        .Include(v => v.Participantes)
        .FirstOrDefaultAsync(v => v.Id == id);

    private async Task<VerificacionDto> ToDtoAsync(Verificacion v)
    {
        var socio = await _institutional.ObtenerSocioAsync(v.RegSoc);
        var nombreMecanico = await _institutional.ObtenerNombrePersonaAsync(v.Mecanico.CodPersonaCorporativa) ?? v.Mecanico.NombreUsuario;
        return VerificacionMapper.ToDto(v, socio?.Nombre, nombreMecanico);
    }

    private async Task<string?> ResolveDireccionAsync(string tipo, string idOrigen)
    {
        var qa = await _institutional.ObtenerSolicitudPruebaAsync(idOrigen);
        if (qa is not null && !string.IsNullOrWhiteSpace(qa.Direccion))
            return qa.Direccion.Trim();

        var d = await _context.DetallesRuta.AsNoTracking()
            .FirstOrDefaultAsync(x => x.TipoOrigen == tipo && x.IdOrigen == idOrigen);
        if (d is not null && !string.IsNullOrWhiteSpace(d.Direccion))
            return d.Direccion.Trim();

        if (tipo == "ODECO" && int.TryParse(idOrigen, out var codRec))
            return V((await _institutional.ObtenerOdecoAsync(codRec))?.Direccion);

        return null;
    }

    private async Task<int?> ResolveCodConexionAsync(string tipo, string idOrigen)
    {
        // Los QA guardan RegSoc en el campo historicamente llamado CodCon, por lo
        // que no se reutiliza ese valor como conexion real. Si no hay fuente
        // institucional segura, M3 muestra "No registrado".
        if (await _institutional.ObtenerSolicitudPruebaAsync(idOrigen) is not null)
            return null;

        if (tipo == "ODECO" && int.TryParse(idOrigen, out var codRec))
            return await _institutional.ObtenerCodConexionPorReclamoAsync(codRec);

        if (tipo == "REVISION")
        {
            var d = await _context.DetallesRuta.AsNoTracking()
                .FirstOrDefaultAsync(x => x.TipoOrigen == "REVISION" && x.IdOrigen == idOrigen);
            if (d is not null && !string.IsNullOrWhiteSpace(d.SolicitudId))
            {
                var solicitudId = d.SolicitudId.Trim();
                if (solicitudId.StartsWith("ODECO-", StringComparison.OrdinalIgnoreCase)
                    && int.TryParse(solicitudId[6..], out var codRecRevision))
                    return await _institutional.ObtenerCodConexionPorReclamoAsync(codRecRevision);
            }
        }

        return null;
    }

    private async Task<string?> ResolveMotivoObservacionAsync(string tipo, string idOrigen)
    {
        var qa = await _institutional.ObtenerSolicitudPruebaAsync(idOrigen);
        if (qa is not null)
            return V(qa.MotivoObservacion);

        if (tipo == "ODECO" && int.TryParse(idOrigen, out var codRec))
        {
            var odeco = await _institutional.ObtenerOdecoAsync(codRec);
            if (odeco is null) return null;

            var partes = new[] { V(odeco.TipoReclamo), V(odeco.Observacion) }
                .Where(x => !string.IsNullOrWhiteSpace(x));
            var motivo = string.Join(" - ", partes!);
            return V(motivo);
        }

        if (tipo == "REVISION")
        {
            var d = await _context.DetallesRuta.AsNoTracking()
                .FirstOrDefaultAsync(x => x.TipoOrigen == "REVISION" && x.IdOrigen == idOrigen);
            if (d is not null && !string.IsNullOrWhiteSpace(d.SolicitudId))
            {
                var solicitudQa = await _institutional.ObtenerSolicitudPruebaAsync(d.SolicitudId);
                if (solicitudQa is not null && !string.IsNullOrWhiteSpace(solicitudQa.MotivoObservacion))
                    return solicitudQa.MotivoObservacion.Trim();
            }
            return "Revision de medidor";
        }

        return null;
    }

    private async Task BloquearSolicitudAsync(string tipo, string idOrigen)
    {
        var resource = $"medidores.Verificaciones:{tipo}:{idOrigen}";
        var resultado = new SqlParameter("@resultado", SqlDbType.Int)
        {
            Direction = ParameterDirection.Output
        };
        var recurso = new SqlParameter("@recurso", SqlDbType.NVarChar, 255)
        {
            Value = resource
        };

        await _context.Database.ExecuteSqlRawAsync(
            """
            EXEC @resultado = sys.sp_getapplock
                @Resource = @recurso,
                @LockMode = 'Exclusive',
                @LockOwner = 'Transaction',
                @LockTimeout = 10000;
            """,
            resultado,
            recurso);

        var codigo = resultado.Value is int value
            ? value
            : Convert.ToInt32(resultado.Value);

        if (codigo < 0)
            throw new InvalidOperationException(
                "No se pudo reservar la solicitud. Actualice la bandeja e intente nuevamente.");
    }

    private static string NormalizeOrigen(string tipo, string id)
    {
        var clean = (id ?? string.Empty).Trim();
        if (tipo == "ODECO" && clean.StartsWith("ODECO-", StringComparison.OrdinalIgnoreCase)) clean = clean[6..];
        if (tipo == "LECTURA" && clean.StartsWith("LEC-", StringComparison.OrdinalIgnoreCase)) clean = clean[4..];
        return clean;
    }

    private static string? V(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
