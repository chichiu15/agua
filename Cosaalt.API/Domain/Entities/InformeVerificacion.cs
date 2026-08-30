namespace Cosaalt.API.Domain.Entities;

public class InformeVerificacion
{
    public int Id { get; set; }
    public int IdVerificacion { get; set; }
    public string NroInforme { get; set; } = string.Empty;
    public DateTime FechaEmision { get; set; }
    public DateTime? FechaFirma { get; set; }
    public string? RutaPdf { get; set; }
    public bool Firmado { get; set; }
    public int Repeticiones { get; set; }

    public Verificacion Verificacion { get; set; } = null!;
}
