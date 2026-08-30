namespace Cosaalt.API.Domain.Entities;

public class Verificacion
{
    public int Id { get; set; }
    public string TipoOrigen { get; set; } = string.Empty;
    public string IdOrigen { get; set; } = string.Empty;
    public int CodCon { get; set; }
    public int IdUsuarioMecanico { get; set; }
    public string? IdMedidor { get; set; }
    public DateTime FechaVerificacion { get; set; }
    public string Estado { get; set; } = "Pendiente";
    public string? Resultado { get; set; }

    public Conexion Conexion { get; set; } = null!;
    public Usuario Mecanico { get; set; } = null!;
    public EnsayoVerificacion? Ensayo { get; set; }
    public ICollection<ParticipanteVerificacion> Participantes { get; set; } = [];
    public ICollection<InformeVerificacion> Informes { get; set; } = [];
}
