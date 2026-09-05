namespace Cosaalt.API.Domain.Entities;

public class Usuario
{
    public int Id { get; set; }
    public long? CodPersonaCorporativa { get; set; }
    public string NombreUsuario { get; set; } = string.Empty;
    public string HashPassword { get; set; } = string.Empty;
    public int IdRol { get; set; }
    public bool Activo { get; set; } = true;
    public DateTime FechaCreacion { get; set; }
    public DateTime? FechaActualizacion { get; set; }

    public RolApp Rol { get; set; } = null!;
    public ICollection<EjecucionCambio> Ejecuciones { get; set; } = [];
    public ICollection<AsignacionRuta> RutasComoTecnico { get; set; } = [];
    public ICollection<AsignacionRuta> RutasComoAsignador { get; set; } = [];
    public ICollection<Verificacion> Verificaciones { get; set; } = [];
}
