namespace Cosaalt.API.Domain.Entities;

/// <summary>
/// Historial de cambios de medidor de COSAALT (dbo.CambioMedidores, solo lectura).
/// El medidor ACTUAL de cada conexión es la fila con EstCaMe = 1 (vigente);
/// sin columna de fecha, no se ordena por tiempo.
/// </summary>
public class CambioMedidorDbo
{
    public int CodCaMe { get; set; }
    public bool EstCaMe { get; set; }
    public string? DesCaMe { get; set; }
    public int CodCon { get; set; }
    public int CodMed { get; set; }
    public int? CodOrTr { get; set; }
    public int? CodCar { get; set; }
    public int? CodMoCaMe { get; set; }
}