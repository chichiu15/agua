namespace Cosaalt.API.Domain.Entities;

public class ReclamoOdeco
{
    public int Folio { get; set; }
    public DateTime FechaReclamo { get; set; }
    public int RegistroSocio { get; set; }
    public string? NombreSolicitante { get; set; }
    public string? CiSolicitante { get; set; }
    public string? TelefonoSolicitante { get; set; }
    public string? TipoVisita { get; set; }
    public string? MotivoReclamo { get; set; }
    public DateTime? FechaEstimadaRespuesta { get; set; }
    public string? RespuestaAtencion { get; set; }
    public decimal? LecturaAnteriorAnalisis { get; set; }
    public decimal? LecturaActualAnalisis { get; set; }
    public decimal? ConsumoAnalisis { get; set; }
    public string? Grifos { get; set; }
    public string? LlavePaso { get; set; }
    public bool MedidorParado { get; set; }
    public string? Inspeccion { get; set; }
    public string? Diagnostico { get; set; }
    public string? Comentarios { get; set; }
    public string? TipoReclamo { get; set; }
    public DateTime? FechaInspeccion { get; set; }
    public string? Conclusion { get; set; }
    public string? PrioridadNota { get; set; }

    public Socio Socio { get; set; } = null!;
}
