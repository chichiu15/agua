using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlVerificacionRepository : IVerificacionRepository
{
    private readonly CosaaltDbContext _context;
    private readonly CosaaltInstitutionalReader _institutional;
    private readonly IConfiguration _configuration;

    public SqlVerificacionRepository(CosaaltDbContext context, CosaaltInstitutionalReader institutional, IConfiguration configuration)
    {
        _context = context;
        _institutional = institutional;
        _configuration = configuration;
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
        var taken = tomadas.ToDictionary(x => $"{x.TipoOrigen}|{x.IdOrigen}", x => x.Estado, StringComparer.OrdinalIgnoreCase);

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
        var idOrigen = NormalizeOrigen(tipo, request.IdOrigen);
        if (await _context.Verificaciones.AnyAsync(v => v.TipoOrigen == tipo && v.IdOrigen == idOrigen && v.Estado != "Cancelada"))
            throw new InvalidOperationException("La solicitud ya tiene una verificacion activa.");

        var mecanico = await _context.Usuarios.AsNoTracking().Include(u => u.Rol)
            .FirstOrDefaultAsync(u => u.Id == request.IdUsuarioMecanico && u.Activo && u.Rol.Nombre.ToLower() == "mecanico")
            ?? throw new InvalidOperationException("El mecanico no existe o esta inactivo.");

        var regSoc = request.CodCon;
        if (regSoc <= 0 && tipo == "ODECO" && int.TryParse(idOrigen, out var codRec))
            regSoc = (await _institutional.ObtenerOdecoAsync(codRec))?.RegSoc ?? 0;
        if (regSoc <= 0) throw new InvalidOperationException("No fue posible identificar el socio de la verificacion.");

        MedidorInstitucional? medidor = null;
        if (int.TryParse(request.IdMedidor, out var codMedidor)) medidor = await _institutional.ObtenerMedidorPorCodigoAsync(codMedidor);
        if (medidor is null && !string.IsNullOrWhiteSpace(request.IdMedidor)) medidor = await _institutional.ObtenerMedidorPorSerieAsync(request.IdMedidor, regSoc);
        medidor ??= await _institutional.ObtenerMedidorActualAsync(regSoc);
        if (medidor is null) throw new InvalidOperationException("No se encontro el medidor asociado al socio.");

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
        return new TomarVerificacionResponseDto(entity.Id, "Verificacion iniciada correctamente.");
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
        var v = await _context.Verificaciones.AsNoTracking().FirstOrDefaultAsync(x => x.Id == idVerificacion);
        if (v is null) return null;
        var socio = await _institutional.ObtenerSocioAsync(v.RegSoc);
        var med = await _institutional.ObtenerMedidorPorCodigoAsync(v.CodMedidor);
        if (socio is null) return null;
        var direccion = await ResolveDireccionAsync(v.TipoOrigen, v.IdOrigen);
        return new DatosSocioMedidorDto(
            v.RegSoc, socio.Nombre, direccion ?? string.Empty, null,
            socio.Documento, null, socio.Ruc,
            med?.Serie, med?.Marca, med?.FechaRegistro);
    }

    public async Task<VerificacionDto?> GuardarEnsayoAsync(int idVerificacion, decimal? volumenRegistrado, decimal? error, GuardarEnsayoRequestDto request)
    {
        var v = await _context.Verificaciones
            .Include(x => x.Ensayo)
            .Include(x => x.Participantes)
            .Include(x => x.Mecanico).ThenInclude(u => u.Rol)
            .FirstOrDefaultAsync(x => x.Id == idVerificacion);
        if (v is null) return null;

        var ensayo = v.Ensayo ?? new EnsayoVerificacion { IdVerificacion = v.Id, FechaRegistro = DateTime.Now };
        ensayo.Condiciones = request.Condiciones;
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
        await _context.SaveChangesAsync();

        var actualizado = await ObtenerEntityAsync(v.Id);
        return actualizado is null ? null : await ToDtoAsync(actualizado);
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
        var d = await _context.DetallesRuta.AsNoTracking().FirstOrDefaultAsync(x => x.TipoOrigen == tipo && x.IdOrigen == idOrigen);
        if (d is not null) return d.Direccion;
        if (tipo == "ODECO" && int.TryParse(idOrigen, out var codRec)) return (await _institutional.ObtenerOdecoAsync(codRec))?.Direccion;
        return null;
    }

    private static string NormalizeOrigen(string tipo, string id)
    {
        var clean = (id ?? string.Empty).Trim();
        if (tipo == "ODECO" && clean.StartsWith("ODECO-", StringComparison.OrdinalIgnoreCase)) clean = clean[6..];
        if (tipo == "LECTURA" && clean.StartsWith("LEC-", StringComparison.OrdinalIgnoreCase)) clean = clean[4..];
        return clean;
    }
}
