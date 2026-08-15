namespace Cosaalt.API.Domain.Entities;

public class EjecucionCambio
{
    public int Id { get; set; }
    public string TipoOrigen { get; set; } = string.Empty;
    public string IdOrigen { get; set; } = string.Empty;
    public int IdUsuarioApp { get; set; }
    public DateTime FechaHoraEjecucion { get; set; }
    public string NumeroMedidorRetirado { get; set; } = string.Empty;
    public string? MarcaRetirado { get; set; }
    public decimal LecturaRetiro { get; set; }
    public int IdMotivo { get; set; }
    public string NumeroMedidorInstalado { get; set; } = string.Empty;
    public string? MarcaInstalado { get; set; }
    public string? ObservacionesInstalacion { get; set; }
    public string? LatLong { get; set; }
    public bool Sincronizado { get; set; }

    public UsuarioApp Usuario { get; set; } = null!;
    public MotivoCambioMedidor Motivo { get; set; } = null!;
    public ICollection<EvidenciaFotografica> Evidencias { get; set; } = [];
}
