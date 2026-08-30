namespace Cosaalt.API.Domain.Entities;

public class ParticipanteVerificacion
{
    public int Id { get; set; }
    public int IdVerificacion { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? Cargo { get; set; }
    public string? Rol { get; set; }

    public Verificacion Verificacion { get; set; } = null!;
}
