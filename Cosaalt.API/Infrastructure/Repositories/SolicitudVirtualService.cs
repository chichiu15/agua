using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SolicitudVirtualService
{
    private readonly CosaaltDbContext _context;

    public SolicitudVirtualService(CosaaltDbContext context) => _context = context;

    public async Task<SolicitudesResponseDto> ObtenerSolicitudesOdecoAsync(string? filtro = null)
    {
        var solicitudes = new List<SolicitudBandejaDto>();

        var idsAsignados = await _context.DetallesRuta
            .AsNoTracking()
            .Select(d => d.TipoOrigen + "-" + d.IdOrigen)
            .Distinct()
            .ToListAsync();

        var reclamos = await _context.Reclamos
            .AsNoTracking()
            .Include(r => r.Conexion)
                .ThenInclude(c => c!.Predio)
            .Include(r => r.Recurrente)
            .ToListAsync();

        var nombres = reclamos
            .Select(r => r.Conexion?.NomSoc?.Trim())
            .Where(n => !string.IsNullOrEmpty(n))
            .Distinct()
            .ToList();

        var socios = nombres.Count == 0
            ? new List<Domain.Entities.Socio>()
            : await _context.Socios
                .AsNoTracking()
                .Include(s => s.Medidor)
                .Where(s => nombres.Contains(s.Nombre.Trim()))
                .ToListAsync();

        var socioPorNombre = socios
            .ToDictionary(s => s.Nombre.Trim(), StringComparer.OrdinalIgnoreCase);

        foreach (var r in reclamos)
        {
            var estado = idsAsignados.Contains($"ODECO-{r.CodRec}")
                ? "Asignada" : "Pendiente";

            var esUrgente = r.DesRec?.Contains("URGENTE", StringComparison.OrdinalIgnoreCase) == true
                || r.PriRec == 'A';

            var nombre = r.Conexion?.NomSoc?.Trim();
            Domain.Entities.Socio? socio = null;
            if (!string.IsNullOrEmpty(nombre))
                socioPorNombre.TryGetValue(nombre, out socio);

            var medidorActivo = socio?.Medidor?.Estado?.ToUpper() == "ACTIVO"
                ? socio.Medidor
                : null;

            solicitudes.Add(new SolicitudBandejaDto(
                Id: $"ODECO-{r.CodRec}",
                TipoOrigen: "ODECO",
                Estado: estado,
                EsUrgente: esUrgente,
                RegistroSocio: socio?.RegistroSocio ?? 0,
                NombreCliente: r.Recurrente?.NomRec ?? r.Conexion?.NomSoc ?? "Sin nombre",
                Direccion: BuildDireccion(r.Conexion?.Predio),
                Categoria: socio?.Categoria,
                Ruta: socio?.Ruta,
                Recorrido: socio?.Recorrido,
                NumeroMedidor: medidorActivo?.NumeroMedidor,
                MarcaMedidor: medidorActivo?.Marca,
                LecturaAnterior: null,
                LecturaActual: null,
                Consumo: null,
                MotivoObservacion: r.DesRec,
                FechaSolicitud: r.FecRec,
                FolioOdeco: r.CodRec,
                ConclusionOdeco: null,
                Latitud: r.Conexion?.CooX2Con,
                Longitud: r.Conexion?.CooY2Con));
        }

        var filtradas = filtro?.ToLowerInvariant() switch
        {
            "pendientes" => solicitudes.Where(s => s.Estado == "Pendiente").ToList(),
            "urgentes" => solicitudes.Where(s => s.EsUrgente && s.Estado == "Pendiente").ToList(),
            _ => solicitudes
        };

        var resumen = new DashboardResumenDto(
            OdecoUrgentes: solicitudes.Count(s => s.EsUrgente && s.Estado == "Pendiente"),
            LecturasDelMes: 0,
            CompletadasHoy: 0);

        return new SolicitudesResponseDto(resumen, filtradas);
    }

    private static string BuildDireccion(Domain.Entities.Predio? predio)
    {
        if (predio is null) return "Sin dirección";
        return $"{predio.CodUbiPre} {predio.NumPre}".Trim();
    }
}
