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

    public async Task<IReadOnlyList<SolicitudVerificacionDto>>
        ObtenerSolicitudesAsync()
    {
        // Hasta que COSAALT confirme exactamente que tipos/observaciones
        // originan REVISION, se exponen ODECO filtrables por configuracion
        // y las rutas REVISION propias de la app.
        var tipos =
            SqlSolicitudRepository.ParseIds(
                _configuration["CosaaltRules:OdecoTipoReclamoIds"]);

        var odecos =
            await _institutional.ObtenerOdecosAsync(
                tipos,
                1000);

        var tomadas =
            await _context.Verificaciones
                .AsNoTracking()
                .Select(v => new
                {
                    v.TipoOrigen,
                    v.IdOrigen,
                    v.Estado
                })
                .ToListAsync();

        var taken =
            tomadas
                .GroupBy(
                    x => $"{x.TipoOrigen}|{x.IdOrigen}",
                    StringComparer.OrdinalIgnoreCase)
                .ToDictionary(
                    g => g.Key,
                    g => g.FirstOrDefault(x =>
                            !string.Equals(
                                x.Estado,
                                "Cancelada",
                                StringComparison.OrdinalIgnoreCase))
                        ?.Estado ?? "Cancelada",
                    StringComparer.OrdinalIgnoreCase);

        var list =
            odecos
                .Select(o =>
                {
                    var key =
                        $"ODECO|{o.CodRec}";

                    var tomada =
                        taken.TryGetValue(
                            key,
                            out var est)
                        && !string.Equals(
                            est,
                            "Cancelada",
                            StringComparison.OrdinalIgnoreCase);

                    var motivo =
                        string.Join(
                            " - ",
                            new[]
                            {
                                o.TipoReclamo,
                                o.Observacion
                            }
                            .Where(x =>
                                !string.IsNullOrWhiteSpace(x)));

                    return new SolicitudVerificacionDto(
                        $"ODECO-{o.CodRec}",
                        "ODECO",
                        o.RegSoc,
                        o.NombreSocio,
                        o.Direccion,
                        o.Prioridad,
                        o.SerieMedidor,
                        o.MarcaMedidor,
                        string.IsNullOrWhiteSpace(motivo)
                            ? null
                            : motivo,
                        o.Fecha,
                        tomada
                            ? "Tomada"
                            : "Pendiente",
                        tomada);
                })
                .ToList();

        // Mantiene disponible la bateria temporal QA sin convertir
        // esos datos en registros institucionales dbo.*.
        var qa =
            await _institutional.ObtenerSolicitudesPruebaAsync();

        foreach (var s in qa)
        {
            var key =
                $"{s.TipoOrigen}|{s.Id}";

            var tomada =
                taken.TryGetValue(
                    key,
                    out var est)
                && !string.Equals(
                    est,
                    "Cancelada",
                    StringComparison.OrdinalIgnoreCase);

            list.Add(
                new SolicitudVerificacionDto(
                    s.Id,
                    s.TipoOrigen,
                    s.CodCon,
                    s.NombreCliente,
                    s.Direccion,
                    s.Categoria,
                    s.NumeroMedidor,
                    s.MarcaMedidor,
                    s.MotivoObservacion,
                    s.FechaSolicitud,
                    tomada
                        ? "Tomada"
                        : s.Estado,
                    tomada));
        }

        var revisiones =
            await _context.DetallesRuta
                .AsNoTracking()
                .Where(d =>
                    d.TipoOrigen == "REVISION"
                    && d.RegSoc != null)
                .OrderByDescending(d => d.Id)
                .Take(500)
                .ToListAsync();

        foreach (var d in revisiones)
        {
            var key =
                $"REVISION|{d.IdOrigen}";

            var tomada =
                taken.TryGetValue(
                    key,
                    out var est)
                && !string.Equals(
                    est,
                    "Cancelada",
                    StringComparison.OrdinalIgnoreCase);

            var med =
                d.CodMedidorActual.HasValue
                    ? await _institutional
                        .ObtenerMedidorPorCodigoAsync(
                            d.CodMedidorActual.Value)
                    : null;

            list.Add(
                new SolicitudVerificacionDto(
                    d.SolicitudId,
                    "REVISION",
                    d.RegSoc!.Value,
                    d.NombreCliente,
                    d.Direccion,
                    null,
                    med?.Serie,
                    med?.Marca,
                    "Revision de medidor",
                    d.FechaInicio ?? DateTime.Now,
                    tomada
                        ? "Tomada"
                        : d.Estado,
                    tomada));
        }

        return list
            .OrderBy(x => x.Tomada)
            .ThenByDescending(x => x.FechaSolicitud)
            .ToList();
    }

    public async Task<TomarVerificacionResponseDto>
        TomarAsync(
            TomarVerificacionRequestDto request)
    {
        var tipo =
            (request.TipoOrigen ?? string.Empty)
                .Trim()
                .ToUpperInvariant();

        if (tipo is not ("ODECO" or "LECTURA" or "REVISION"))
        {
            throw new InvalidOperationException(
                "El origen de la solicitud no es valido.");
        }

        var idOrigen =
            NormalizeOrigen(
                tipo,
                request.IdOrigen);

        if (string.IsNullOrWhiteSpace(idOrigen))
        {
            throw new InvalidOperationException(
                "No fue posible identificar la solicitud.");
        }

        DetalleRuta? detalleRevision = null;

        if (tipo == "REVISION")
        {
            detalleRevision =
                await _context.DetallesRuta
                    .AsNoTracking()
                    .Where(d =>
                        d.TipoOrigen == "REVISION"
                        && (
                            d.IdOrigen == idOrigen
                            || d.SolicitudId == idOrigen
                        ))
                    .OrderByDescending(d => d.Id)
                    .FirstOrDefaultAsync();

            if (detalleRevision is null)
            {
                throw new InvalidOperationException(
                    "No se encontro la solicitud de revision seleccionada.");
            }

            idOrigen =
                detalleRevision.IdOrigen;
        }

        var mecanico =
            await _context.Usuarios
                .AsNoTracking()
                .Include(u => u.Rol)
                .FirstOrDefaultAsync(u =>
                    u.Id == request.IdUsuarioMecanico
                    && u.Activo
                    && u.Rol.Nombre.ToLower() == "mecanico")
            ?? throw new InvalidOperationException(
                "El mecanico no existe o esta inactivo.");

        var regSoc =
            request.CodCon;

        if (regSoc <= 0
            && detalleRevision?.RegSoc
                is int regSocRevision)
        {
            regSoc =
                regSocRevision;
        }

        if (regSoc <= 0
            && tipo == "ODECO"
            && int.TryParse(
                idOrigen,
                out var codRec))
        {
            regSoc =
                (await _institutional
                    .ObtenerOdecoAsync(codRec))
                ?.RegSoc ?? 0;
        }

        if (regSoc <= 0)
        {
            throw new InvalidOperationException(
                "No fue posible identificar el socio de la verificacion.");
        }

        MedidorInstitucional? medidor =
            null;

        if (int.TryParse(
            request.IdMedidor,
            out var codMedidor))
        {
            medidor =
                await _institutional
                    .ObtenerMedidorPorCodigoAsync(
                        codMedidor);
        }

        if (medidor is null
            && !string.IsNullOrWhiteSpace(
                request.IdMedidor))
        {
            medidor =
                await _institutional
                    .ObtenerMedidorPorSerieAsync(
                        request.IdMedidor,
                        regSoc);
        }

        if (medidor is null
            && detalleRevision?.CodMedidorActual
                is int codMedidorRevision)
        {
            medidor =
                await _institutional
                    .ObtenerMedidorPorCodigoAsync(
                        codMedidorRevision);
        }

        medidor ??=
            await _institutional
                .ObtenerMedidorActualAsync(
                    regSoc);

        if (medidor is null)
        {
            throw new InvalidOperationException(
                "No se encontro el medidor asociado al socio.");
        }

        /*
         * El DbContext utiliza EnableRetryOnFailure().
         * La transaccion manual debe ejecutarse dentro de
         * la estrategia de ejecucion de EF Core.
         */
        var strategy =
            _context.Database
                .CreateExecutionStrategy();

        return await strategy.ExecuteAsync(
            async () =>
            {
                _context.ChangeTracker.Clear();

                await using var transaction =
                    await _context.Database
                        .BeginTransactionAsync();

                try
                {
                    await BloquearSolicitudAsync(
                        tipo,
                        idOrigen);

                    var yaTomada =
                        await _context.Verificaciones
                            .AnyAsync(v =>
                                v.TipoOrigen == tipo
                                && v.IdOrigen == idOrigen
                                && v.Estado != "Cancelada");

                    if (yaTomada)
                    {
                        throw new InvalidOperationException(
                            "La solicitud ya fue tomada por otro mecanico.");
                    }

                    var entity =
                        new Verificacion
                        {
                            TipoOrigen = tipo,
                            IdOrigen = idOrigen,
                            RegSoc = regSoc,
                            IdUsuarioMecanico =
                                request.IdUsuarioMecanico,
                            CodMedidor =
                                medidor.CodMedidor,
                            FechaVerificacion =
                                DateTime.Now,
                            Estado =
                                "EnCurso"
                        };

                    _context.Verificaciones.Add(
                        entity);

                    await _context
                        .SaveChangesAsync();

                    await transaction
                        .CommitAsync();

                    return new TomarVerificacionResponseDto(
                        entity.Id,
                        "Verificacion iniciada correctamente.");
                }
                catch
                {
                    await transaction
                        .RollbackAsync();

                    throw;
                }
            });
    }

    public async Task<IReadOnlyList<VerificacionDto>>
        ObtenerVerificacionesAsync(
            int idMecanico)
    {
        var rows =
            await _context.Verificaciones
                .AsNoTracking()
                .Include(v => v.Mecanico)
                    .ThenInclude(u => u.Rol)
                .Include(v => v.Ensayo)
                .Include(v => v.Participantes)
                .Include(v => v.ParametroNormativoAplicado)
                .Where(v =>
                    v.IdUsuarioMecanico == idMecanico)
                .OrderByDescending(v =>
                    v.FechaVerificacion)
                .ToListAsync();

        var result =
            new List<VerificacionDto>();

        foreach (var v in rows)
        {
            result.Add(
                await ToDtoAsync(v));
        }

        return result;
    }

    public async Task<VerificacionDto?>
        ObtenerVerificacionAsync(
            int id)
    {
        var row =
            await _context.Verificaciones
                .AsNoTracking()
                .Include(v => v.Mecanico)
                    .ThenInclude(u => u.Rol)
                .Include(v => v.Ensayo)
                .Include(v => v.Participantes)
                .Include(v => v.ParametroNormativoAplicado)
                .FirstOrDefaultAsync(v =>
                    v.Id == id);

        return row is null
            ? null
            : await ToDtoAsync(row);
    }

    public async Task<DatosSocioMedidorDto?>
        ObtenerDatosSocioMedidorAsync(
            int idVerificacion)
    {
        var v =
            await _context.Verificaciones
                .AsNoTracking()
                .Include(x => x.Ensayo)
                .FirstOrDefaultAsync(x =>
                    x.Id == idVerificacion);

        if (v is null)
        {
            return null;
        }

        var socio =
            await _institutional
                .ObtenerSocioAsync(
                    v.RegSoc);

        var med =
            await _institutional
                .ObtenerMedidorPorCodigoAsync(
                    v.CodMedidor);

        if (socio is null)
        {
            return null;
        }

        var direccion =
            await ResolveDireccionAsync(
                v.TipoOrigen,
                v.IdOrigen);

        var codConexion =
            await ResolveCodConexionAsync(
                v.TipoOrigen,
                v.IdOrigen);

        var motivoObservacion =
            await ResolveMotivoObservacionAsync(
                v.TipoOrigen,
                v.IdOrigen);

        string? tipoEnsayo =
            null;

        if (v.Ensayo is not null)
        {
            var (
                _,
                tipoPrueba,
                _,
                _,
                _,
                _,
                _,
                _,
                _,
                _,
                _,
                _) =
                EnsayoCamposProvisionales.Decode(
                    v.Ensayo.Condiciones);

            tipoEnsayo =
                V(tipoPrueba);
        }

        var lugarVerificacion =
            V(
                _configuration[
                    "CosaaltRules:LugarVerificacionMecanica"]);

        return new DatosSocioMedidorDto(
            CodCon:
                v.RegSoc,
            NombreCliente:
                socio.Nombre,
            Direccion:
                direccion ?? string.Empty,
            Categoria:
                null,
            NumeroDocumento:
                socio.Documento,
            TipDocumento:
                null,
            Ruc:
                socio.Ruc,
            NumeroMedidor:
                med?.Serie,
            MarcaMedidor:
                med?.Marca,
            FechaConexion:
                med?.FechaRegistro,
            CapacidadQ3:
                med?.Capacidad,
            TipoMedidor:
                med?.Tipo,
            ClaseMedidor:
                med?.Clase,
            DiametroMedidor:
                med?.Diametro,
            RegSoc:
                v.RegSoc,
            CodConexion:
                codConexion,
            LugarVerificacion:
                lugarVerificacion,
            TipoEnsayo:
                tipoEnsayo,
            MotivoObservacion:
                motivoObservacion);
    }

    public async Task<VerificacionDto?>
        GuardarEnsayoAsync(
            int idVerificacion,
            decimal? volumenRegistrado,
            decimal? error,
            int? idParametroNormativo,
            string? resultado,
            GuardarEnsayoRequestDto request)
    {
        /*
         * GuardarEnsayoAsync administra solamente el ensayo.
         * Los participantes se guardan por GuardarParticipantesAsync().
         */
        var v =
            await _context.Verificaciones
                .Include(x => x.Ensayo)
                .Include(x => x.Mecanico)
                    .ThenInclude(u => u.Rol)
                .FirstOrDefaultAsync(x =>
                    x.Id == idVerificacion);

        if (v is null)
        {
            return null;
        }

        if (v.Estado == "Completada")
        {
            throw new InvalidOperationException(
                "La verificacion ya fue finalizada y no admite modificaciones.");
        }

        var ensayo =
            v.Ensayo
            ?? new EnsayoVerificacion
            {
                IdVerificacion =
                    v.Id,
                FechaRegistro =
                    DateTime.Now
            };

        ensayo.Condiciones =
            EnsayoCamposProvisionales.Encode(
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

        ensayo.LecturaInicial =
            request.LecturaInicial;

        ensayo.LecturaFinal =
            request.LecturaFinal;

        ensayo.VolumenPatron =
            request.VolumenPatron;

        ensayo.Caudal =
            request.Caudal;

        ensayo.VolumenRegistrado =
            volumenRegistrado;

        ensayo.Error =
            error;

        ensayo.Fugas =
            request.Fugas;

        ensayo.Observaciones =
            request.Observaciones;

        ensayo.FechaRegistro =
            DateTime.Now;

        if (v.Ensayo is null)
        {
            _context.EnsayosVerificacion.Add(
                ensayo);

            v.Ensayo =
                ensayo;
        }

        v.IdParametroNormativoAplicado =
            idParametroNormativo;

        v.Resultado =
            resultado;

        await _context
            .SaveChangesAsync();

        var actualizado =
            await ObtenerEntityAsync(
                v.Id);

        return actualizado is null
            ? null
            : await ToDtoAsync(
                actualizado);
    }

    public async Task<VerificacionDto?>
        GuardarParticipantesAsync(
            int idVerificacion,
            IReadOnlyList<ParticipanteVerificacionDto>
                participantes)
    {
        var v =
            await _context.Verificaciones
                .Include(x => x.Mecanico)
                    .ThenInclude(u => u.Rol)
                .Include(x => x.Participantes)
                .FirstOrDefaultAsync(x =>
                    x.Id == idVerificacion);

        if (v is null)
        {
            return null;
        }

        if (v.Estado == "Completada")
        {
            throw new InvalidOperationException(
                "La verificacion ya fue finalizada y no admite modificaciones.");
        }

        _context.ParticipantesVerificacion
            .RemoveRange(
                v.Participantes);

        v.Participantes =
            participantes?
                .Where(p =>
                    !string.IsNullOrWhiteSpace(
                        p.Nombre))
                .Select(p =>
                    new ParticipanteVerificacion
                    {
                        IdVerificacion =
                            v.Id,
                        Nombre =
                            p.Nombre.Trim(),
                        Cargo =
                            string.IsNullOrWhiteSpace(
                                p.Cargo)
                                ? null
                                : p.Cargo.Trim(),
                        Rol =
                            string.IsNullOrWhiteSpace(
                                p.Rol)
                                ? null
                                : p.Rol.Trim()
                    })
                .ToList()
            ?? [];

        await _context
            .SaveChangesAsync();

        var actualizado =
            await ObtenerEntityAsync(
                v.Id);

        return actualizado is null
            ? null
            : await ToDtoAsync(
                actualizado);
    }

    public async Task<VerificacionDashboardDto>
        ObtenerDashboardAsync(
            int idMecanico)
    {
        var solicitudes =
            await ObtenerSolicitudesAsync();

        var rows =
            await _context.Verificaciones
                .AsNoTracking()
                .Where(v =>
                    v.IdUsuarioMecanico == idMecanico)
                .Select(v => new
                {
                    v.Estado,
                    v.Resultado
                })
                .ToListAsync();

        return new VerificacionDashboardDto(
            Pendientes:
                solicitudes.Count(s =>
                    !s.Tomada),
            EnCurso:
                rows.Count(v =>
                    v.Estado == "EnCurso"),
            Completadas:
                rows.Count(v =>
                    v.Estado == "Completada"),
            Cumple:
                rows.Count(v =>
                    v.Resultado == "CUMPLE"),
            NoCumple:
                rows.Count(v =>
                    v.Resultado == "NO CUMPLE"),
            Indeterminados:
                rows.Count(v =>
                    v.Resultado == "INDETERMINADO"),
            Total:
                rows.Count);
    }

    public async Task<VerificacionHistorialResponseDto>
        ObtenerHistorialAsync(
            int idMecanico,
            VerificacionHistorialFiltro filtro)
    {
        /*
         * M9 - Historial del mecánico.
         *
         * Se muestran las verificaciones que forman parte del trabajo
         * operativo del mecánico: EnCurso y Completada.
         *
         * La búsqueda contempla:
         * - nombre / RegSoc del socio
         * - código de conexión ODECO cuando existe
         * - serie / código institucional del medidor
         * - número de informe
         * - identificador de origen
         */
        var q =
            _context.Verificaciones
                .AsNoTracking()
                .Include(v => v.Ensayo)
                .Include(v => v.Informes)
                .Where(v =>
                    v.IdUsuarioMecanico == idMecanico
                    && (
                        v.Estado == "EnCurso"
                        || v.Estado == "Completada"
                    ));

        if (filtro.Desde.HasValue)
        {
            var desde =
                filtro.Desde.Value.Date;

            q =
                q.Where(v =>
                    v.FechaVerificacion >= desde);
        }

        if (filtro.Hasta.HasValue)
        {
            // Límite exclusivo para incluir todo el día seleccionado.
            var hastaExclusivo =
                filtro.Hasta.Value.Date.AddDays(1);

            q =
                q.Where(v =>
                    v.FechaVerificacion < hastaExclusivo);
        }

        var estado =
            V(filtro.Estado);

        if (estado is not null)
        {
            q =
                q.Where(v =>
                    v.Estado == estado);
        }

        var resultado =
            V(filtro.Resultado);

        if (resultado is not null)
        {
            q =
                q.Where(v =>
                    v.Resultado == resultado);
        }

        var buscar =
            V(filtro.Buscar);

        if (buscar is not null)
        {
            if (buscar.Length > 120)
            {
                buscar =
                    buscar[..120];
            }

            /*
             * Resolver primero candidatos en dbo.* evita traer todas las
             * verificaciones a memoria sólo para buscar por nombre o serie.
             */
            var sociosTask =
                _institutional.BuscarRegSocAsync(
                    buscar,
                    500);

            var medidoresTask =
                _institutional.BuscarCodMedidoresAsync(
                    buscar,
                    500);

            var reclamosTask =
                _institutional.BuscarCodReclamosPorConexionAsync(
                    buscar,
                    500);

            await Task.WhenAll(
                sociosTask,
                medidoresTask,
                reclamosTask);

            var regSocCoincidentes =
                (await sociosTask)
                    .Distinct()
                    .ToArray();

            var codMedidoresCoincidentes =
                (await medidoresTask)
                    .Distinct()
                    .ToArray();

            var codReclamosCoincidentes =
                (await reclamosTask)
                    .Distinct()
                    .ToArray();

            var origenesOdeco =
                codReclamosCoincidentes
                    .Select(x => x.ToString())
                    .ToArray();

            string[] origenesRevision = [];

            if (codReclamosCoincidentes.Length > 0)
            {
                var solicitudesOdeco =
                    codReclamosCoincidentes
                        .Select(x => $"ODECO-{x}")
                        .ToArray();

                origenesRevision =
                    await _context.DetallesRuta
                        .AsNoTracking()
                        .Where(d =>
                            d.TipoOrigen == "REVISION"
                            && solicitudesOdeco.Contains(
                                d.SolicitudId))
                        .Select(d => d.IdOrigen)
                        .Distinct()
                        .Take(500)
                        .ToArrayAsync();
            }

            q =
                q.Where(v =>
                    v.RegSoc.ToString().Contains(buscar)
                    || v.CodMedidor.ToString().Contains(buscar)
                    || v.IdOrigen.Contains(buscar)
                    || regSocCoincidentes.Contains(v.RegSoc)
                    || codMedidoresCoincidentes.Contains(v.CodMedidor)
                    || (
                        v.TipoOrigen == "ODECO"
                        && origenesOdeco.Contains(v.IdOrigen)
                    )
                    || (
                        v.TipoOrigen == "REVISION"
                        && origenesRevision.Contains(v.IdOrigen)
                    )
                    || v.Informes.Any(i =>
                        i.NroInforme.Contains(buscar))
                );
        }

        var page =
            Math.Max(
                1,
                filtro.Page);

        var pageSize =
            Math.Clamp(
                filtro.PageSize,
                5,
                100);

        var total =
            await q.CountAsync();

        var rows =
            await q
                .OrderByDescending(v =>
                    v.FechaVerificacion)
                .ThenByDescending(v =>
                    v.Id)
                .Skip(
                    (page - 1)
                    * pageSize)
                .Take(pageSize)
                .ToListAsync();

        var items =
            new List<VerificacionHistorialItemDto>(
                rows.Count);

        foreach (var v in rows)
        {
            var socio =
                await _institutional
                    .ObtenerSocioAsync(
                        v.RegSoc);

            var med =
                await _institutional
                    .ObtenerMedidorPorCodigoAsync(
                        v.CodMedidor);

            var codConexion =
                await ResolveCodConexionAsync(
                    v.TipoOrigen,
                    v.IdOrigen);

            var informe =
                v.Informes
                    .OrderByDescending(i =>
                        i.VersionInforme)
                    .ThenByDescending(i =>
                        i.Id)
                    .FirstOrDefault();

            var estadoInforme =
                informe is null
                    ? "No emitido"
                    : informe.Firmado
                        ? "Firmado"
                        : "Pendiente firma";

            items.Add(
                new VerificacionHistorialItemDto(
                    IdVerificacion:
                        v.Id,
                    Fecha:
                        v.FechaVerificacion,
                    Estado:
                        v.Estado,
                    Resultado:
                        v.Resultado,
                    Error:
                        v.Ensayo?.Error,
                    Fugas:
                        v.Ensayo?.Fugas,

                    // Compatibilidad con la respuesta histórica.
                    CodCon:
                        v.RegSoc,
                    RegSoc:
                        v.RegSoc,
                    CodConexion:
                        codConexion,

                    NombreCliente:
                        socio?.Nombre,
                    NumeroMedidor:
                        med?.Serie,
                    MarcaMedidor:
                        med?.Marca,

                    // Siempre se expone la última versión emitida.
                    IdInforme:
                        informe?.Id,
                    NroInforme:
                        informe?.NroInforme,
                    VersionInforme:
                        informe?.VersionInforme,
                    FechaEmisionInforme:
                        informe?.FechaEmision,
                    InformeFirmado:
                        informe?.Firmado,
                    EstadoInforme:
                        estadoInforme,
                    TieneInforme:
                        informe is not null));
        }

        return new VerificacionHistorialResponseDto(
            total,
            page,
            pageSize,
            items);
    }

    public async Task<VerificacionDto?>
        FinalizarAsync(
            int idVerificacion)
    {
        var v =
            await _context.Verificaciones
                .Include(x => x.Ensayo)
                .Include(x => x.Participantes)
                .Include(x => x.Mecanico)
                    .ThenInclude(u => u.Rol)
                .FirstOrDefaultAsync(x =>
                    x.Id == idVerificacion);

        if (v is null)
        {
            return null;
        }

        if (v.Estado == "Completada")
        {
            throw new InvalidOperationException(
                "La verificacion ya esta finalizada.");
        }

        if (v.Ensayo is null
            || v.Ensayo.LecturaInicial is null
            || v.Ensayo.LecturaFinal is null
            || v.Ensayo.VolumenPatron is null
            || v.Ensayo.VolumenPatron <= 0
            || v.Ensayo.Caudal is null
            || v.Ensayo.Caudal <= 0)
        {
            throw new InvalidOperationException(
                "Complete los campos obligatorios del ensayo antes de finalizar.");
        }

        v.Estado =
            "Completada";

        // Provisional:
        // no existe todavía una columna FechaFinalizacion propia.
        v.FechaVerificacion =
            DateTime.Now;

        await _context
            .SaveChangesAsync();

        var actualizado =
            await ObtenerEntityAsync(
                v.Id);

        return actualizado is null
            ? null
            : await ToDtoAsync(
                actualizado);
    }

    public async Task<IReadOnlyList<InformeVerificacionDto>>
        ObtenerInformesAsync(
            int idVerificacion)
    {
        return await _context
            .InformesVerificacion
            .AsNoTracking()
            .Where(i =>
                i.IdVerificacion == idVerificacion)
            .OrderByDescending(i =>
                i.VersionInforme)
            .Select(i =>
                new InformeVerificacionDto(
                    i.Id,
                    i.IdVerificacion,
                    i.NroInforme,
                    i.FechaEmision,
                    i.RutaPdf,
                    i.Firmado,
                    i.VersionInforme,
                    i.Observaciones))
            .ToListAsync();
    }

    public async Task<GenerarInformeResponseDto>
        GenerarInformeAsync(
            int idVerificacion,
            GenerarInformeRequestDto request)
    {
        var v =
            await _context.Verificaciones
                .AsNoTracking()
                .Include(x => x.Ensayo)
                .Include(x => x.Participantes)
                .Include(x =>
                    x.ParametroNormativoAplicado)
                .Include(x => x.Mecanico)
                    .ThenInclude(u => u.Rol)
                .FirstOrDefaultAsync(x =>
                    x.Id == idVerificacion);

        if (v is null)
        {
            throw new InvalidOperationException(
                "No se encontro la verificacion.");
        }

        if (v.Estado != "Completada")
        {
            throw new InvalidOperationException(
                "Finalice la verificacion antes de generar el informe.");
        }

        if (v.Ensayo is null)
        {
            throw new InvalidOperationException(
                "No se pudo generar el informe: falta el ensayo.");
        }

        /*
         * M8:
         * Cada nueva emision obtiene la siguiente version.
         *
         * Las versiones anteriores NO se eliminan.
         */
        var version =
            (
                await _context
                    .InformesVerificacion
                    .AsNoTracking()
                    .Where(i =>
                        i.IdVerificacion == v.Id)
                    .Select(i =>
                        (int?)i.VersionInforme)
                    .ToListAsync()
            )
            .Max()
            .GetValueOrDefault(0)
            + 1;

        /*
         * Una sola fecha de emisión para toda la operación.
         */
        var fechaEmision =
            DateTime.Now;

        /*
         * M8 - compatibilidad con:
         *
         * UQ_Informe_Numero UNIQUE (NroInforme)
         *
         * La base no permite repetir NroInforme.
         * Por ello:
         *
         * v1 -> INF-VER-2026-000002
         * v2 -> INF-VER-2026-000002-V2
         * v3 -> INF-VER-2026-000002-V3
         *
         * No es necesario modificar el índice de la BD.
         */
        var nroInformeBase =
            $"INF-VER-{fechaEmision.Year}-{v.Id:D6}";

        var nroInforme =
            version <= 1
                ? nroInformeBase
                : $"{nroInformeBase}-V{version}";

        /*
         * nroInforme es el identificador real y único de esta emisión.
         */
        var datos =
            await BuildDatosInformeAsync(
                v,
                request.NombreResponsable,
                version,
                nroInforme,
                fechaEmision);

        var bytes =
            InformePdfBuilder.Build(
                datos);

        var carpeta =
            Path.Combine(
                _environment.WebRootPath
                    ?? Path.Combine(
                        _environment.ContentRootPath,
                        "wwwroot"),
                "informes");

        Directory.CreateDirectory(
            carpeta);

        /*
         * Conservamos además VersionInforme en el nombre físico.
         *
         * Ejemplo v2:
         * INF-VER-2026-000002-V2_v2.pdf
         *
         * Aunque NroInforme ya es único, esto deja explícita
         * también la versión técnica del archivo.
         */
        var archivo =
            $"{nroInforme}_v{version}.pdf";

        var rutaFisica =
            Path.Combine(
                carpeta,
                archivo);

        await System.IO.File
            .WriteAllBytesAsync(
                rutaFisica,
                bytes);

        var entidad =
            new InformeVerificacion
            {
                IdVerificacion =
                    v.Id,

                NroInforme =
                    nroInforme,

                FechaEmision =
                    fechaEmision,

                RutaPdf =
                    $"wwwroot/informes/{archivo}",

                Firmado =
                    false,

                VersionInforme =
                    version,

                Observaciones =
                    V(request.Observaciones)
            };

        _context
            .InformesVerificacion
            .Add(entidad);

        await _context
            .SaveChangesAsync();

        return new GenerarInformeResponseDto(
            new InformeVerificacionDto(
                entidad.Id,
                entidad.IdVerificacion,
                entidad.NroInforme,
                entidad.FechaEmision,
                entidad.RutaPdf,
                entidad.Firmado,
                entidad.VersionInforme,
                entidad.Observaciones),
            "Informe generado correctamente.");
    }

    private async Task<InformePdfData>
        BuildDatosInformeAsync(
            Verificacion v,
            string? responsable,
            int version,
            string nroInforme,
            DateTime fechaEmision)
    {
        var socio =
            await _institutional
                .ObtenerSocioAsync(
                    v.RegSoc);

        var med =
            await _institutional
                .ObtenerMedidorPorCodigoAsync(
                    v.CodMedidor);

        var nombreMecanico =
            await _institutional
                .ObtenerNombrePersonaAsync(
                    v.Mecanico.CodPersonaCorporativa)
            ?? v.Mecanico.NombreUsuario;

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
            EnsayoCamposProvisionales.Decode(
                v.Ensayo!.Condiciones);

        var (
            errorConSigno,
            errorAbsoluto) =
            CalcularErrores(
                v.Ensayo);

        /*
         * M6:
         * snapshot historico primero.
         * Catalogo actual solamente como fallback.
         */
        var limite =
            limiteNormativoSnapshot
            ?? v.ParametroNormativoAplicado
                ?.ErrorMaxPermitido;

        var direccion =
            await ResolveDireccionAsync(
                v.TipoOrigen,
                v.IdOrigen)
            ?? "No registrado";

        /*
         * RegSoc y Codigo/Conexion son conceptos diferentes.
         */
        var codConexion =
            await ResolveCodConexionAsync(
                v.TipoOrigen,
                v.IdOrigen);

        var documentoRuc =
            string.Join(
                " / ",
                new[]
                {
                    socio?.Documento,
                    socio?.Ruc
                }
                .Where(x =>
                    !string.IsNullOrWhiteSpace(x)));

        if (string.IsNullOrWhiteSpace(
            documentoRuc))
        {
            documentoRuc =
                "No registrado";
        }

        var parametroCodigo =
            V(parametroNormativoSnapshot)
            ?? v.ParametroNormativoAplicado
                ?.Codigo
            ?? "Sin parametro aplicable";

        var resultado =
            v.Resultado
            ?? "INDETERMINADO";

        return new InformePdfData(
            NroInforme:
                nroInforme,

            Version:
                version,

            FechaEmision:
                fechaEmision,

            Mecanico:
                nombreMecanico,

            SocioNombre:
                socio?.Nombre
                ?? "No registrado",

            RegSoc:
                v.RegSoc.ToString(),

            CodConexion:
                codConexion?.ToString()
                ?? "No registrado",

            Direccion:
                direccion,

            DocumentoRuc:
                documentoRuc,

            MotivoOrigen:
                $"{v.TipoOrigen} - {v.IdOrigen}",

            MedidorMarca:
                med?.Marca
                ?? "No registrado",

            MedidorSerie:
                med?.Serie
                ?? "No registrado",

            MedidorCapacidad:
                V(capacidadQ3)
                ?? med?.Capacidad
                ?? "No registrado",

            MedidorTipo:
                V(med?.Tipo)
                ?? "No registrado",

            MedidorClase:
                V(med?.Clase)
                ?? "No registrado",

            MedidorDiametro:
                V(med?.Diametro)
                ?? "No registrado",

            MedidorFechaRegistro:
                med?.FechaRegistro
                    ?.ToString("dd/MM/yyyy")
                ?? "No registrado",

            FechaVerificacion:
                v.FechaVerificacion
                    .ToString("dd/MM/yyyy HH:mm"),

            TipoPrueba:
                V(tipoPrueba)
                ?? "No registrado",

            InstrumentoBanco:
                V(instrumentoBanco)
                ?? "No registrado",

            TipoCaudal:
                V(tipoCaudal)
                ?? "No registrado",

            Caudal:
                v.Ensayo.Caudal
                    ?.ToString("0.####")
                ?? "No registrado",

            UnidadCaudal:
                V(unidadCaudal)
                ?? string.Empty,

            PrimeraLectura:
                v.Ensayo.LecturaInicial
                    ?.ToString("0.00")
                ?? "No registrado",

            SegundaLectura:
                v.Ensayo.LecturaFinal
                    ?.ToString("0.00")
                ?? "No registrado",

            VolumenRegistrado:
                v.Ensayo.VolumenRegistrado
                    ?.ToString("0.0000")
                ?? "No registrado",

            VolumenPatron:
                v.Ensayo.VolumenPatron
                    ?.ToString("0.0000")
                ?? "No registrado",

            Diferencia:
                (
                    v.Ensayo.VolumenRegistrado
                    - v.Ensayo.VolumenPatron
                )
                ?.ToString("0.0000")
                ?? "No registrado",

            ErrorConSigno:
                errorConSigno
                    ?.ToString("0.00")
                ?? "No registrado",

            ErrorAbsoluto:
                errorAbsoluto
                    ?.ToString("0.00")
                ?? "No registrado",

            ParametroNormativo:
                parametroCodigo,

            LimitePermitido:
                limite
                    ?.ToString("0.00")
                ?? "N/A",

            Resultado:
                resultado,

            Fugas:
                v.Ensayo.Fugas == true
                    ? "Sí"
                    : "No",

            TipoFuga:
                v.Ensayo.Fugas == true
                    ? V(tipoFuga)
                        ?? "No reportado"
                    : "No aplica",

            Condiciones:
                V(condicionesDecoded)
                ?? "-",

            Observaciones:
                V(v.Ensayo.Observaciones)
                ?? "-",

            Responsable:
                V(responsable)
                ?? V(nombreMecanico)
                ?? "-",

            Participantes:
                v.Participantes
                    .OrderBy(p => p.Id)
                    .Select(p => (
                        p.Nombre,
                        p.Cargo ?? "-",
                        p.Rol ?? "-"
                    ))
                    .ToList());
    }

    private static (
        decimal? ConSigno,
        decimal? Absoluto)
        CalcularErrores(
            EnsayoVerificacion ensayo)
    {
        if (ensayo.VolumenRegistrado is null
            || ensayo.VolumenPatron is null
            || ensayo.VolumenPatron <= 0)
        {
            return (
                null,
                null);
        }

        var conSigno =
            (
                ensayo.VolumenRegistrado.Value
                - ensayo.VolumenPatron.Value
            )
            / ensayo.VolumenPatron.Value
            * 100m;

        return (
            conSigno,
            Math.Abs(conSigno));
    }

    private async Task<Verificacion?>
        ObtenerEntityAsync(
            int id)
    {
        return await _context.Verificaciones
            .AsNoTracking()
            .Include(v => v.Mecanico)
                .ThenInclude(u => u.Rol)
            .Include(v => v.Ensayo)
            .Include(v => v.Participantes)
            .Include(v => v.ParametroNormativoAplicado)
            .FirstOrDefaultAsync(v =>
                v.Id == id);
    }

    private async Task<VerificacionDto>
        ToDtoAsync(
            Verificacion v)
    {
        var socio =
            await _institutional
                .ObtenerSocioAsync(
                    v.RegSoc);

        var nombreMecanico =
            await _institutional
                .ObtenerNombrePersonaAsync(
                    v.Mecanico.CodPersonaCorporativa)
            ?? v.Mecanico.NombreUsuario;

        return VerificacionMapper.ToDto(
            v,
            socio?.Nombre,
            nombreMecanico);
    }

    private async Task<string?>
        ResolveDireccionAsync(
            string tipo,
            string idOrigen)
    {
        var qa =
            await _institutional
                .ObtenerSolicitudPruebaAsync(
                    idOrigen);

        if (qa is not null
            && !string.IsNullOrWhiteSpace(
                qa.Direccion))
        {
            return qa.Direccion.Trim();
        }

        var d =
            await _context.DetallesRuta
                .AsNoTracking()
                .FirstOrDefaultAsync(x =>
                    x.TipoOrigen == tipo
                    && x.IdOrigen == idOrigen);

        if (d is not null
            && !string.IsNullOrWhiteSpace(
                d.Direccion))
        {
            return d.Direccion.Trim();
        }

        if (tipo == "ODECO"
            && int.TryParse(
                idOrigen,
                out var codRec))
        {
            return V(
                (await _institutional
                    .ObtenerOdecoAsync(
                        codRec))
                ?.Direccion);
        }

        return null;
    }

    private async Task<int?>
        ResolveCodConexionAsync(
            string tipo,
            string idOrigen)
    {
        /*
         * Los QA guardan RegSoc en el campo historicamente llamado CodCon.
         * Ese dato NO se reutiliza como CodConexion real.
         */
        if (await _institutional
                .ObtenerSolicitudPruebaAsync(
                    idOrigen)
            is not null)
        {
            return null;
        }

        if (tipo == "ODECO"
            && int.TryParse(
                idOrigen,
                out var codRec))
        {
            return await _institutional
                .ObtenerCodConexionPorReclamoAsync(
                    codRec);
        }

        if (tipo == "REVISION")
        {
            var d =
                await _context.DetallesRuta
                    .AsNoTracking()
                    .FirstOrDefaultAsync(x =>
                        x.TipoOrigen == "REVISION"
                        && x.IdOrigen == idOrigen);

            if (d is not null
                && !string.IsNullOrWhiteSpace(
                    d.SolicitudId))
            {
                var solicitudId =
                    d.SolicitudId.Trim();

                if (solicitudId.StartsWith(
                        "ODECO-",
                        StringComparison.OrdinalIgnoreCase)
                    && int.TryParse(
                        solicitudId[6..],
                        out var codRecRevision))
                {
                    return await _institutional
                        .ObtenerCodConexionPorReclamoAsync(
                            codRecRevision);
                }
            }
        }

        return null;
    }

    private async Task<string?>
        ResolveMotivoObservacionAsync(
            string tipo,
            string idOrigen)
    {
        var qa =
            await _institutional
                .ObtenerSolicitudPruebaAsync(
                    idOrigen);

        if (qa is not null)
        {
            return V(
                qa.MotivoObservacion);
        }

        if (tipo == "ODECO"
            && int.TryParse(
                idOrigen,
                out var codRec))
        {
            var odeco =
                await _institutional
                    .ObtenerOdecoAsync(
                        codRec);

            if (odeco is null)
            {
                return null;
            }

            var partes =
                new[]
                {
                    V(odeco.TipoReclamo),
                    V(odeco.Observacion)
                }
                .Where(x =>
                    !string.IsNullOrWhiteSpace(x));

            var motivo =
                string.Join(
                    " - ",
                    partes!);

            return V(
                motivo);
        }

        if (tipo == "REVISION")
        {
            var d =
                await _context.DetallesRuta
                    .AsNoTracking()
                    .FirstOrDefaultAsync(x =>
                        x.TipoOrigen == "REVISION"
                        && x.IdOrigen == idOrigen);

            if (d is not null
                && !string.IsNullOrWhiteSpace(
                    d.SolicitudId))
            {
                var solicitudQa =
                    await _institutional
                        .ObtenerSolicitudPruebaAsync(
                            d.SolicitudId);

                if (solicitudQa is not null
                    && !string.IsNullOrWhiteSpace(
                        solicitudQa.MotivoObservacion))
                {
                    return solicitudQa
                        .MotivoObservacion
                        .Trim();
                }
            }

            return "Revision de medidor";
        }

        return null;
    }

    private async Task BloquearSolicitudAsync(
        string tipo,
        string idOrigen)
    {
        var resource =
            $"medidores.Verificaciones:{tipo}:{idOrigen}";

        var resultado =
            new SqlParameter(
                "@resultado",
                SqlDbType.Int)
            {
                Direction =
                    ParameterDirection.Output
            };

        var recurso =
            new SqlParameter(
                "@recurso",
                SqlDbType.NVarChar,
                255)
            {
                Value =
                    resource
            };

        await _context.Database
            .ExecuteSqlRawAsync(
                """
                EXEC @resultado = sys.sp_getapplock
                    @Resource = @recurso,
                    @LockMode = 'Exclusive',
                    @LockOwner = 'Transaction',
                    @LockTimeout = 10000;
                """,
                resultado,
                recurso);

        var codigo =
            resultado.Value is int value
                ? value
                : Convert.ToInt32(
                    resultado.Value);

        if (codigo < 0)
        {
            throw new InvalidOperationException(
                "No se pudo reservar la solicitud. Actualice la bandeja e intente nuevamente.");
        }
    }

    private static string NormalizeOrigen(
        string tipo,
        string id)
    {
        var clean =
            (id ?? string.Empty)
                .Trim();

        if (tipo == "ODECO"
            && clean.StartsWith(
                "ODECO-",
                StringComparison.OrdinalIgnoreCase))
        {
            clean =
                clean[6..];
        }

        if (tipo == "LECTURA"
            && clean.StartsWith(
                "LEC-",
                StringComparison.OrdinalIgnoreCase))
        {
            clean =
                clean[4..];
        }

        return clean;
    }

    private static string? V(
        string? value)
    {
        return string.IsNullOrWhiteSpace(
            value)
            ? null
            : value.Trim();
    }
}