namespace Cosaalt.API.Domain.Entities;

public class AsignacionRuta
{
    public int Id { get; set; }
    public int IdUsuarioApp { get; set; }
    public int IdUsuarioAsignador { get; set; }
    public DateTime FechaAsignacion { get; set; }
    public string Estado { get; set; } = "Planificado";
    public string? Observaciones { get; set; }
    public DateTime FechaCreacion { get; set; }

    public Usuario Tecnico { get; set; } = null!;
    public Usuario Asignador { get; set; } = null!;
    public ICollection<DetalleRuta> Detalles { get; set; } = [];
}
