namespace Cosaalt.API.Domain.Entities;

public class Verificacion
{
    public int Id { get; set; }
    public string TipoOrigen { get; set; } = string.Empty;
    public string IdOrigen { get; set; } = string.Empty;
    public int RegSoc { get; set; }
    public int IdUsuarioMecanico { get; set; }
    public int CodMedidor { get; set; }
    public int? IdParametroNormativoAplicado { get; set; }
    public DateTime FechaVerificacion { get; set; }
    public string Estado { get; set; } = "Pendiente";
    public string? Resultado { get; set; }

    public Usuario Mecanico { get; set; } = null!;
    public ParametroNormativo? ParametroNormativoAplicado { get; set; }
    public EnsayoVerificacion? Ensayo { get; set; }
    public ICollection<ParticipanteVerificacion> Participantes { get; set; } = [];
    public ICollection<InformeVerificacion> Informes { get; set; } = [];
}
