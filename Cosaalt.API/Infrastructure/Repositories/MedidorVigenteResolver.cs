using Cosaalt.API.Infrastructure.Context;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Repositories;

public readonly record struct MedidorVigente(string? Serial, string? Marca);

/// <summary>
/// Resuelve el medidor ACTIVO (vigente) de cada conexión leyendo SOLO dbo:
///   dbo.CambioMedidores (EstCaMe = 1) JOIN dbo.Medidores (SerMed) LEFT JOIN dbo.Marcas (NomMar).
/// Reemplaza al snapshot medidores.Medidor como única fuente de verdad del
/// "N° de medidor" y su marca que ve la app. Nunca escribe en dbo.
/// </summary>
public static class MedidorVigenteResolver
{
    public static async Task<Dictionary<int, MedidorVigente>> ResolverAsync(
        CosaaltDbContext context,
        IEnumerable<int> codCons)
    {
        var keys = codCons.Where(c => c > 0).Distinct().ToList();
        if (keys.Count == 0) return new Dictionary<int, MedidorVigente>();

        // FromSqlRaw: EF 10 reescribe los Contains() sobre columnas numeric con
        // value converter a OPENJSON(@keys ... '$'), y ese SQL da error 102.
        // Con IN de parámetros normales el SQL es determinista y válido.
        var filas = new List<ResolverRow>();

        foreach (var lote in keys.Chunk(1000))
        {
            var parametros = lote
                .Select((cod, i) => new SqlParameter($"@c{i}", cod))
                .ToArray();
            var inClause = string.Join(", ", parametros.Select(p => p.ParameterName));

            var sql = $"""
                SELECT cm.CodCon,
                       cm.CodCaMe,
                       LTRIM(RTRIM(m.SerMed)) AS SerMed,
                       LTRIM(RTRIM(ma.NomMar)) AS Marca
                FROM dbo.CambioMedidores cm
                INNER JOIN dbo.Medidores m ON m.CodMed = cm.CodMed
                LEFT JOIN dbo.Marcas ma ON ma.CodMar = m.CodMar
                WHERE cm.EstCaMe = CAST(1 AS bit)
                  AND cm.CodCon IN ({inClause})
                """;

            filas.AddRange(
                await context.Database.SqlQueryRaw<ResolverRow>(sql, parametros)
                    .ToListAsync());
        }

        // Defensa por si una conexión tiene más de una fila vigente (no ocurre en
        // la base real: EstCaMe=1 es único por CodCon): quedarse con max(CodCaMe).
        return filas
            .GroupBy(r => r.CodCon)
            .ToDictionary(
                g => (int)g.Key,
                g => g
                    .OrderByDescending(r => r.CodCaMe)
                    .Select(r => new MedidorVigente(r.SerMed, r.Marca))
                    .First());
    }

    private sealed class ResolverRow
    {
        public decimal CodCon { get; set; }
        public decimal CodCaMe { get; set; }
        public string? SerMed { get; set; }
        public string? Marca { get; set; }
    }
}