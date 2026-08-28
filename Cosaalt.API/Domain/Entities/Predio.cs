namespace Cosaalt.API.Domain.Entities;

public class Predio
{
    public int CodPre { get; set; }
    public string CodUbiPre { get; set; } = string.Empty;
    public string? NumPre { get; set; }
    public string? CodMaTr { get; set; }

    public ICollection<Conexion> Conexiones { get; set; } = new List<Conexion>();
}
