using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

/// <summary>
/// Construye la bandeja de solicitudes ODECO leyendo DIRECTAMENTE de dbo
/// (Reclamos + Conexion + Predio + Recurrente) sin inventar una tabla de socios.
/// La cuenta del socio en COSAALT es la CONEXIÓN (Conexiones.CodCon);
/// el medidor ACTIVO de cada cuenta sale de dbo.CambioMedidores + dbo.Medidores.
/// Solo lectura: nunca escribe en dbo.
/// </summary>
internal static class BandejaOdecoBuilder
{
    public const int MaxTop = 1000;

    public static async Task<List<SolicitudBandejaDto>> BuildAsync(CosaaltDbContext context, int top)
    {
        var inicioVentana = DateTime.Today.AddYears(-1);

        var asignadosSet = (await context.DetallesRuta
                .AsNoTracking()
                .Select(d => d.TipoOrigen + "-" + d.IdOrigen)
                .Distinct()
                .ToListAsync())
            .ToHashSet();

        // Reclamos vigentes de los últimos 12 meses con cuenta, proyectados solo a
        // las columnas que la bandeja muestra (el SQL transmite únicamente esto, no
        // las 4 tablas completas). OrderBy + Take se traducen al servidor (TOP).
        var filas = await context.Reclamos
            .AsNoTracking()
            .Where(r => r.EstRec && r.CodCon != null && r.FecRec >= inicioVentana)
            .OrderByDescending(r => r.FecRec)
            .Take(top)
            .Select(r => new ReclamoFila(
                r.CodRec,
                r.FecRec,
                r.DesRec,
                r.PriRec,
                r.CodCon,
                r.Recurrente == null ? null : r.Recurrente.NomRec,
                r.Conexion == null ? null : r.Conexion.NomSoc,
                r.Conexion == null ? null : r.Conexion.CooX2Con,
                r.Conexion == null ? null : r.Conexion.CooY2Con,
                r.Conexion != null && r.Conexion.Predio != null ? r.Conexion.Predio.CodUbiPre : null,
                r.Conexion != null && r.Conexion.Predio != null ? r.Conexion.Predio.NumPre : null))
            .ToListAsync();

        var codCons = filas.Select(f => f.CodCon ?? 0).Distinct().ToList();
        var medidorPorCodCon = await MedidorVigentePorCodConAsync(context, codCons);

        var solicitudes = new List<SolicitudBandejaDto>(filas.Count);
        foreach (var f in filas)
        {
            var medidor = medidorPorCodCon.GetValueOrDefault(f.CodCon ?? 0);
            solicitudes.Add(new SolicitudBandejaDto(
                Id: $"ODECO-{f.CodRec}",
                TipoOrigen: "ODECO",
                Estado: asignadosSet.Contains($"ODECO-{f.CodRec}") ? "Asignada" : "Pendiente",
                EsUrgente: f.DesRec?.Contains("URGENTE", StringComparison.OrdinalIgnoreCase) == true
                    || f.PriRec == 'A',
                CodCon: f.CodCon ?? 0,
                NombreCliente: f.NomRec ?? f.NomSoc ?? "Sin nombre",
                Direccion: BuildDireccion(f.CodUbiPre, f.NumPre),
                Categoria: null,
                Ruta: null,
                Recorrido: null,
                NumeroMedidor: medidor.SeriaMedidor,
                MarcaMedidor: medidor.MarcaMedidor,
                LecturaAnterior: null,
                LecturaActual: null,
                Consumo: null,
                MotivoObservacion: f.DesRec,
                FechaSolicitud: f.FecRec,
                FolioOdeco: f.CodRec,
                ConclusionOdeco: null,
                Latitud: f.Latitud,
                Longitud: f.Longitud));
        }

        return solicitudes;
    }

    internal static string BuildDireccion(string? codUbiPre, string? numPre)
    {
        if (string.IsNullOrWhiteSpace(codUbiPre)) return "Sin dirección";
        return $"{codUbiPre} {numPre}".Trim();
    }

    internal static string BuildDireccion(Cosaalt.API.Domain.Entities.Predio? predio)
    {
        if (predio is null) return "Sin dirección";
        return BuildDireccion(predio.CodUbiPre, predio.NumPre);
    }

    /// <summary>
    /// Medidor vigente por conexión desde dbo (CambioMedidores EstCaMe=1 → Medidores
    /// → Marcas.NomMar). Solo lectura.
    /// </summary>
    public static async Task<Dictionary<int, (string? SeriaMedidor, string? MarcaMedidor)>>
        MedidorVigentePorCodConAsync(CosaaltDbContext context, IEnumerable<int> codCons)
    {
        var vigentes = await MedidorVigenteResolver.ResolverAsync(context, codCons);
        return vigentes.ToDictionary(
            kv => kv.Key,
            kv => (kv.Value.Serial, kv.Value.Marca));
    }

    private sealed record ReclamoFila(
        int CodRec,
        DateTime FecRec,
        string DesRec,
        char PriRec,
        int? CodCon,
        string? NomRec,
        string? NomSoc,
        double? Latitud,
        double? Longitud,
        string? CodUbiPre,
        string? NumPre);
}