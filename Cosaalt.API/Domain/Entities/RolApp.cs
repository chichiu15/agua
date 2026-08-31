namespace Cosaalt.API.Domain.Entities;

public class RolApp
{
    public int IdRol { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public bool Activo { get; set; } = true;

    public ICollection<Usuario> Usuarios { get; set; } = [];
}