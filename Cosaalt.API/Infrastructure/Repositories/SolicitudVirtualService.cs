using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public class SolicitudVirtualService
{
    private readonly CosaaltDbContext _context;

    public SolicitudVirtualService(CosaaltDbContext context) => _context = context;

    public async Task<SolicitudesResponseDto> ObtenerSolicitudesOdecoAsync(
        string? filtro = null, int top = 200)
    {
        top = Math.Clamp(top, 1, BandejaOdecoBuilder.MaxTop);

        var solicitudes = await BandejaOdecoBuilder.BuildAsync(_context, top);

        var filtradas = filtro?.ToLowerInvariant() switch
        {
            "pendientes" => solicitudes.Where(s => s.Estado == "Pendiente").ToList(),
            "urgentes" => solicitudes.Where(s => s.EsUrgente && s.Estado == "Pendiente").ToList(),
            _ => solicitudes
        };

        var resumen = new DashboardResumenDto(
            OdecoUrgentes: await ContarOdecoUrgentesPendientesAsync(),
            LecturasDelMes: await ContarLecturasDelMesAsync(),
            CompletadasHoy: 0);

        return new SolicitudesResponseDto(resumen, filtradas);
    }

    /// <summary>
    /// Reclamos vigentes de la gestión actual, urgentes y AÚN NO asignados en
    /// medidores.DetallesRuta. COUNT en el servidor sin traer filas; el anti-join
    /// es por Folio+origen (nunca Contains sobre CodRec: evitaría el bug OPENJSON).
    /// </summary>
    private async Task<int> ContarOdecoUrgentesPendientesAsync()
    {
        var inicioVentana = DateTime.Today.AddYears(-1);

        const string sql = """
            SELECT COUNT(*) AS Value
            FROM dbo.Reclamos r
            WHERE r.EstRec = CAST(1 AS bit)
              AND r.CodCon IS NOT NULL
              AND r.FecRec >= @inicioVentana
              AND (r.DesRec LIKE '%URGENTE%' OR r.PriRec = 'A')
              AND NOT EXISTS (
                    SELECT 1
                    FROM medidores.DetalleRuta dr
                    WHERE dr.TipoOrigen = 'ODECO'
                      AND dr.IdOrigen = CAST(r.CodRec AS nvarchar(20))
                  )
            """;

        return await _context.Database
            .SqlQueryRaw<int>(sql, new SqlParameter("@inicioVentana", inicioVentana))
            .SingleAsync();
    }

    private async Task<int> ContarLecturasDelMesAsync()
    {
        var inicioMes = new DateTime(DateTime.Today.Year, DateTime.Today.Month, 1);
        return await _context.DetallesSolicitudLectura
            .AsNoTracking()
            .CountAsync(d => d.Solicitud.FechaEmision >= inicioMes);
    }
}