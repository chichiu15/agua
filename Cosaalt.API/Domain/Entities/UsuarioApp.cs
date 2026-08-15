namespace Cosaalt.API.Domain.Entities;

public class UsuarioApp
{
    public int Id { get; set; }
    public string NombreUsuario { get; set; } = string.Empty;
    public string ContrasenaHash { get; set; } = string.Empty;
    public string NombreCompleto { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public bool Activo { get; set; } = true;

    public ICollection<EjecucionCambio> Ejecuciones { get; set; } = [];
    public ICollection<AsignacionRuta> Asignaciones { get; set; } = [];
}
