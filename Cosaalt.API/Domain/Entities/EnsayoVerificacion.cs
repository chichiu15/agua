namespace Cosaalt.API.Domain.Entities;

public class EnsayoVerificacion
{
    public int Id { get; set; }
    public int IdVerificacion { get; set; }
    public string? Condiciones { get; set; }
    public decimal? LecturaInicial { get; set; }
    public decimal? LecturaFinal { get; set; }
    public decimal? VolumenPatron { get; set; }
    public decimal? Caudal { get; set; }
    public decimal? VolumenRegistrado { get; set; }
    public decimal? Error { get; set; }
    public bool? Fugas { get; set; }
    public string? Observaciones { get; set; }
    public DateTime FechaRegistro { get; set; }

    public Verificacion Verificacion { get; set; } = null!;
}
