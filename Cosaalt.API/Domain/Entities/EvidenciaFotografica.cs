namespace Cosaalt.API.Domain.Entities;

public class EvidenciaFotografica
{
    public int Id { get; set; }
    public int IdEjecucion { get; set; }
    public string TipoFoto { get; set; } = string.Empty;
    public string RutaArchivo { get; set; } = string.Empty;
    public DateTime FechaRegistro { get; set; }

    public EjecucionCambio Ejecucion { get; set; } = null!;
}
