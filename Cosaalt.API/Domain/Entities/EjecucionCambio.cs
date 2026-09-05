namespace Cosaalt.API.Domain.Entities;

public class EjecucionCambio
{
    public int Id { get; set; }
    public string TipoOrigen { get; set; } = string.Empty;
    public string IdOrigen { get; set; } = string.Empty;
    public int RegSoc { get; set; }
    public int IdUsuarioApp { get; set; }
    public DateTime FechaHoraEjecucion { get; set; }

    public int? CodMedidorRetirado { get; set; }
    public string SerieMedidorRetirado { get; set; } = string.Empty;
    public string? MarcaRetirado { get; set; }
    public decimal LecturaRetiro { get; set; }

    public long? IdMotivoInstitucional { get; set; }
    public string? MotivoDescripcionSnapshot { get; set; }

    public int? CodMedidorInstalado { get; set; }
    public string SerieMedidorInstalado { get; set; } = string.Empty;
    public string? MarcaInstalado { get; set; }
    public string? ObservacionesInstalacion { get; set; }

    public decimal? Latitud { get; set; }
    public decimal? Longitud { get; set; }

    public bool Sincronizado { get; set; }
    public DateTime? FechaSincronizacion { get; set; }
    public string EstadoIntegracionInstitucional { get; set; } = "PENDIENTE";
    public DateTime? FechaIntegracionInstitucional { get; set; }
    public string? DetalleIntegracionInstitucional { get; set; }

    public Usuario Usuario { get; set; } = null!;
    public ICollection<EvidenciaFotografica> Evidencias { get; set; } = [];
}
