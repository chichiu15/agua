namespace Cosaalt.API.Domain.Entities;

/// <summary>
/// Catálogo de marcas de medidores de COSAALT (dbo.Marcas, solo lectura).
/// El nombre visible (ej. "SAG", "Elster") es NomMar.
/// </summary>
public class MarcaDbo
{
    public int CodMar { get; set; }
    public string NomMar { get; set; } = string.Empty;
    public string? AliMar { get; set; }
}