using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace Cosaalt.API.Infrastructure.Configurations;

/// <summary>
/// Conversores numeric -> int para las tablas dbo de COSAALT.
/// La base real almacena los códigos como numeric(9,0)/numeric(5,0); sin estos
/// conversores SQL Server devuelve decimal y EF falla al materializar el entero
/// con InvalidCastException (recién se ve cuando hay filas reales que leer).
/// </summary>
public static class NumericConversions
{
    public static readonly ValueConverter<int, decimal> IntToDecimal =
        new(v => (decimal)v, v => (int)v);

    public static readonly ValueConverter<int?, decimal?> NullableIntToDecimal =
        new(v => v.HasValue ? (decimal?)v.Value : null,
            v => v.HasValue ? (int)v.Value : null);
}