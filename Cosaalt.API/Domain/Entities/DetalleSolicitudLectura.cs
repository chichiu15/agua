namespace Cosaalt.API.Domain.Entities;

public class DetalleSolicitudLectura
{
    public int Id { get; set; }
    public string NumeroHoja { get; set; } = string.Empty;
    public int RegistroSocio { get; set; }
    public decimal LecturaAnterior { get; set; }
    public decimal LecturaActual { get; set; }
    public decimal Consumo { get; set; }

    public SolicitudLectura Solicitud { get; set; } = null!;
    public Socio Socio { get; set; } = null!;
}
