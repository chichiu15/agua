namespace Cosaalt.API.Domain.Entities;

public class Calle
{
    public int CodCal { get; set; }
    public string NomCal { get; set; } = string.Empty;
    public bool EstCal { get; set; }
    public char? TipCal { get; set; }
}
