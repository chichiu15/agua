namespace Cosaalt.API.Domain.Entities;

/// <summary>
/// Catálogo real de medidores de COSAALT (dbo.Medidores, solo lectura).
/// La fuente de verdad del "N° de medidor" es el serial (SerMed).
/// </summary>
public class MedidorDbo
{
    public int CodMed { get; set; }
    public string SerMed { get; set; } = string.Empty;
    public DateTime? FecFabMed { get; set; }
    public bool EstMed { get; set; }
    public string ObsMed { get; set; } = string.Empty;
    public int? CodMar { get; set; }
    public string? CodPeEmTiPe { get; set; }
    public int? CodCaTu { get; set; }
    public int? CodTiTr { get; set; }
    public int? CodElMe { get; set; }
    public int? DigMed { get; set; }
}