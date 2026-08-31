namespace Cosaalt.API.Domain.Entities;

public class ParametroNormativo
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public decimal ErrorMaxPermitido { get; set; }
    public decimal? CaudalMin { get; set; }
    public decimal? CaudalMax { get; set; }
    public DateTime? VigenciaInicio { get; set; }
    public DateTime? VigenciaFin { get; set; }
    public bool Activo { get; set; } = true;
}
