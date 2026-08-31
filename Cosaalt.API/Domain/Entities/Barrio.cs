namespace Cosaalt.API.Domain.Entities;

public class Barrio
{
    public int CodBar { get; set; }
    public string NomBar { get; set; } = string.Empty;
    public bool EstBar { get; set; }

    public ICollection<Reclamo> Reclamos { get; set; } = new List<Reclamo>();
}
