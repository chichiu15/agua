namespace Cosaalt.API.Domain.Entities;

public class Medidor
{
    public string NumeroMedidor { get; set; } = string.Empty;
    public string? Marca { get; set; }
    public int RegistroSocio { get; set; }
    public DateTime? FechaInstalacion { get; set; }
    public string? Estado { get; set; }

    // Ubicación física real del medidor (antes vivía, por error, en Socio)
    public double? Latitud { get; set; }
    public double? Longitud { get; set; }

    public Socio Socio { get; set; } = null!;
}
