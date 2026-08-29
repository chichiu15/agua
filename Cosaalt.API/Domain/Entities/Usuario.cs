namespace Cosaalt.API.Domain.Entities;

public class Usuario
{
    public int Id { get; set; }
    public int? CodFunCorporativo { get; set; }
    public string NombreUsuario { get; set; } = string.Empty;
    public string HashPassword { get; set; } = string.Empty;
    public int IdRol { get; set; }
    public bool Activo { get; set; } = true;
    public DateTime FechaCreacion { get; set; }

    public RolApp Rol { get; set; } = null!;
    public Funcionario? Funcionario { get; set; }

    public ICollection<EjecucionCambio> Ejecuciones { get; set; } = [];
    public ICollection<AsignacionRuta> Asignaciones { get; set; } = [];

    // Nombre real resuelto desde dbo.Funcionarios→Persona (solo lectura);
    // si la cuenta no tiene funcionario vinculado, cae al nombre de usuario.
    public string NombreCompleto =>
        Funcionario?.Persona?.NombreCompleto ?? NombreUsuario;
}