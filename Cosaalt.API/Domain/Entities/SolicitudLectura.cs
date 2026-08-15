namespace Cosaalt.API.Domain.Entities;

public class SolicitudLectura
{
    public string NumeroHoja { get; set; } = string.Empty;
    public string AnioMes { get; set; } = string.Empty;
    public DateTime FechaEmision { get; set; }
    public TimeSpan? HoraEmision { get; set; }
    public string? ElaboradoPor { get; set; }
    public int CodigoObservacion { get; set; }
    public string? DescripcionObservacion { get; set; }

    public ICollection<DetalleSolicitudLectura> Detalles { get; set; } = [];
}
