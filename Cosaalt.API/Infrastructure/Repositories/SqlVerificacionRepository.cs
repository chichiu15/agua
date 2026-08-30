using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Mappers;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SqlVerificacionRepository : IVerificacionRepository
{
    private readonly CosaaltDbContext _context;

    public SqlVerificacionRepository(CosaaltDbContext context) => _context = context;

    public async Task<IReadOnlyList<SolicitudVerificacionDto>> ObtenerSolicitudesAsync()
    {
        var tomadas = await _context.Verificaciones
            .AsNoTracking()
            .Where(v => v.Estado != "Completada")
            .Select(v => v.TipoOrigen + "-" + v.IdOrigen)
            .Distinct()
            .ToListAsync();

        var tomadasSet = tomadas.ToHashSet();

        var solicitudes = new List<SolicitudVerificacionDto>();

        var odecos = await BandejaOdecoBuilder.BuildAsync(_context, BandejaOdecoBuilder.MaxTop);
        foreach (var o in odecos)
        {
            if (tomadasSet.Contains(o.Id)) continue;
            solicitudes.Add(new SolicitudVerificacionDto(
                Id: o.Id,
                TipoOrigen: o.TipoOrigen,
                CodCon: o.CodCon,
                NombreCliente: o.NombreCliente,
                Direccion: o.Direccion,
                Categoria: o.Categoria,
                NumeroMedidor: o.NumeroMedidor,
                MarcaMedidor: o.MarcaMedidor,
                MotivoObservacion: o.MotivoObservacion,
                FechaSolicitud: o.FechaSolicitud,
                Estado: "Pendiente",
                Tomada: false));
        }

        var detalles = await _context.DetallesSolicitudLectura
            .AsNoTracking()
            .Include(d => d.Solicitud)
            .Include(d => d.Conexion)
                .ThenInclude(c => c!.Predio)
            .ToListAsync();

        var codConsLectura = detalles.Select(d => d.CodCon).Distinct().ToList();
        var medidorPorCodCon = await BandejaOdecoBuilder.MedidorVigentePorCodConAsync(_context, codConsLectura);

        foreach (var detalle in detalles)
        {
            var id = $"LEC-{detalle.Id}";
            if (tomadasSet.Contains(id)) continue;

            var medidor = medidorPorCodCon.GetValueOrDefault(detalle.CodCon);
            solicitudes.Add(new SolicitudVerificacionDto(
                Id: id,
                TipoOrigen: "LECTURA",
                CodCon: detalle.CodCon,
                NombreCliente: detalle.Conexion?.NomSoc ?? "Sin nombre",
                Direccion: BandejaOdecoBuilder.BuildDireccion(detalle.Conexion?.Predio),
                Categoria: null,
                NumeroMedidor: medidor.SeriaMedidor,
                MarcaMedidor: medidor.MarcaMedidor,
                MotivoObservacion: detalle.Solicitud?.DescripcionObservacion,
                FechaSolicitud: detalle.Solicitud?.FechaEmision ?? DateTime.Today,
                Estado: "Pendiente",
                Tomada: false));
        }

        return solicitudes;
    }

    public async Task<TomarVerificacionResponseDto> TomarAsync(TomarVerificacionRequestDto request)
    {
        var yaTomada = await _context.Verificaciones
            .AsNoTracking()
            .AnyAsync(v => v.TipoOrigen == request.TipoOrigen
                        && v.IdOrigen == request.IdOrigen
                        && v.Estado != "Completada");

        if (yaTomada)
        {
            throw new InvalidOperationException(
                $"La solicitud {request.TipoOrigen}-{request.IdOrigen} ya está tomada por otro mecánico.");
        }

        var entity = VerificacionMapper.ToEntity(request);
        _context.Verificaciones.Add(entity);
        await _context.SaveChangesAsync();

        return new TomarVerificacionResponseDto(entity.Id, "Verificación tomada correctamente.");
    }

    public async Task<IReadOnlyList<VerificacionDto>> ObtenerVerificacionesAsync(int idMecanico)
    {
        var verificaciones = await _context.Verificaciones
            .AsNoTracking()
            .Where(v => v.IdUsuarioMecanico == idMecanico)
            .Include(v => v.Conexion)
            .Include(v => v.Mecanico)
                .ThenInclude(m => m.Funcionario)
                .ThenInclude(f => f!.Persona)
            .Include(v => v.Ensayo)
            .Include(v => v.Participantes)
            .OrderByDescending(v => v.FechaVerificacion)
            .Take(200)
            .ToListAsync();

        return verificaciones
            .Select(v => VerificacionMapper.ToDto(
                v,
                nombreCliente: v.Conexion?.NomSoc,
                nombreMecanico: v.Mecanico?.NombreCompleto))
            .ToList();
    }

    public async Task<VerificacionDto?> ObtenerVerificacionAsync(int id)
    {
        var verificacion = await _context.Verificaciones
            .AsNoTracking()
            .Include(v => v.Conexion)
            .Include(v => v.Mecanico)
                .ThenInclude(m => m.Funcionario)
                .ThenInclude(f => f!.Persona)
            .Include(v => v.Ensayo)
            .Include(v => v.Participantes)
            .FirstOrDefaultAsync(v => v.Id == id);

        return verificacion is null
            ? null
            : VerificacionMapper.ToDto(
                verificacion,
                nombreCliente: verificacion.Conexion?.NomSoc,
                nombreMecanico: verificacion.Mecanico?.NombreCompleto);
    }

    public async Task<DatosSocioMedidorDto?> ObtenerDatosSocioMedidorAsync(int idVerificacion)
    {
        var verificacion = await _context.Verificaciones
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.Id == idVerificacion);

        if (verificacion is null) return null;

        var conexion = await _context.Conexiones
            .AsNoTracking()
            .Include(c => c.Predio)
            .FirstOrDefaultAsync(c => c.CodCon == verificacion.CodCon);

        if (conexion is null)
        {
            return new DatosSocioMedidorDto(
                CodCon: verificacion.CodCon,
                NombreCliente: "Sin datos de conexión",
                Direccion: "Sin dirección",
                Categoria: null,
                NumeroDocumento: null,
                TipDocumento: null,
                Ruc: null,
                NumeroMedidor: verificacion.IdMedidor,
                MarcaMedidor: null,
                FechaConexion: null);
        }

        var medidores = await BandejaOdecoBuilder.MedidorVigentePorCodConAsync(
            _context, new[] { conexion.CodCon });

        var medidor = medidores.GetValueOrDefault(conexion.CodCon);

        return new DatosSocioMedidorDto(
            CodCon: conexion.CodCon,
            NombreCliente: conexion.NomSoc ?? "Sin nombre",
            Direccion: BandejaOdecoBuilder.BuildDireccion(conexion.Predio),
            Categoria: null,
            NumeroDocumento: conexion.NumDoc,
            TipDocumento: conexion.TipDoc,
            Ruc: conexion.RucSoc,
            NumeroMedidor: verificacion.IdMedidor ?? medidor.SeriaMedidor,
            MarcaMedidor: medidor.MarcaMedidor,
            FechaConexion: conexion.FecCon);
    }

    public async Task<VerificacionDto?> GuardarEnsayoAsync(
        int idVerificacion,
        decimal? volumenRegistrado,
        decimal? error,
        GuardarEnsayoRequestDto request)
    {
        var verificacion = await _context.Verificaciones
            .Include(v => v.Ensayo)
            .Include(v => v.Participantes)
            .FirstOrDefaultAsync(v => v.Id == idVerificacion);

        if (verificacion is null) return null;

        if (verificacion.Ensayo is null)
        {
            verificacion.Ensayo = new Domain.Entities.EnsayoVerificacion
            {
                IdVerificacion = verificacion.Id
            };
            _context.EnsayosVerificacion.Add(verificacion.Ensayo);
        }

        var ensayo = verificacion.Ensayo;
        ensayo.Condiciones = request.Condiciones;
        ensayo.LecturaInicial = request.LecturaInicial;
        ensayo.LecturaFinal = request.LecturaFinal;
        ensayo.VolumenPatron = request.VolumenPatron;
        ensayo.Caudal = request.Caudal;
        ensayo.Fugas = request.Fugas;
        ensayo.Observaciones = request.Observaciones;
        ensayo.VolumenRegistrado = volumenRegistrado;
        ensayo.Error = error;

        if (verificacion.Estado == "Pendiente" || verificacion.Estado == "EnCurso")
        {
            verificacion.Estado = "EnCurso";
        }

        if (request.Participantes is not null)
        {
            _context.ParticipantesVerificacion.RemoveRange(verificacion.Participantes);
            foreach (var p in request.Participantes)
            {
                verificacion.Participantes.Add(new Domain.Entities.ParticipanteVerificacion
                {
                    IdVerificacion = verificacion.Id,
                    Nombre = p.Nombre,
                    Cargo = p.Cargo,
                    Rol = p.Rol
                });
            }
        }

        await _context.SaveChangesAsync();
        return await ObtenerVerificacionAsync(verificacion.Id);
    }
}
