namespace Cosaalt.API.Domain.Entities;

public class CategoriaConexion
{
    public int CodCaCo { get; set; }
    public string NomCaCo { get; set; } = string.Empty;
    public string? AliCaCo { get; set; }
    public DateTime? FecIniCaCo { get; set; }
    public DateTime? FecFinCaCo { get; set; }
    public bool EstCaCo { get; set; }
}
