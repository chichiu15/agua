namespace Cosaalt.API.Domain.Entities;

public class DetalleRuta
{
    public int Id { get; set; }
    public int IdAsignacion { get; set; }
    public string TipoOrigen { get; set; } = string.Empty;
    public string IdOrigen { get; set; } = string.Empty;
    public int OrdenVisita { get; set; }
    public string Estado { get; set; } = "Pendiente";
    public string SolicitudId { get; set; } = string.Empty;
    public int? RegSoc { get; set; }
    public int? CodMedidorActual { get; set; }
    public string NombreCliente { get; set; } = string.Empty;
    public string Direccion { get; set; } = string.Empty;
    public decimal? Latitud { get; set; }
    public decimal? Longitud { get; set; }
    public DateTime? FechaInicio { get; set; }
    public DateTime? FechaFinalizacion { get; set; }

    public AsignacionRuta Asignacion { get; set; } = null!;
}
