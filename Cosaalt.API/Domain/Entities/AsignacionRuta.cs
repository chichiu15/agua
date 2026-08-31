namespace Cosaalt.API.Domain.Entities;

public class AsignacionRuta
{
    public int Id { get; set; }
    public int IdUsuarioApp { get; set; }
    public DateTime FechaAsignacion { get; set; }
    public string Estado { get; set; } = "Planificado";

    public Usuario Usuario { get; set; } = null!;
    public ICollection<DetalleRuta> Detalles { get; set; } = [];
}
