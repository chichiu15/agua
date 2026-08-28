namespace Cosaalt.API.Domain.Entities;

public class Recurrente
{
    public int CodRec { get; set; }
    public string NomRec { get; set; } = string.Empty;
    public string? CeIdRec { get; set; }
    public string? TelRec { get; set; }
    public bool SexRec { get; set; }

    public ICollection<Reclamo> Reclamos { get; set; } = new List<Reclamo>();
}
