namespace Cosaalt.API.Domain.Entities;

public class Conexion
{
    public int CodCon { get; set; }
    public DateTime FecCon { get; set; }
    public string? ObsCon { get; set; }
    public double? CooX2Con { get; set; }
    public double? CooY2Con { get; set; }
    public double? CooZ2Con { get; set; }
    public bool? TipCon { get; set; }
    public int CanPerCon { get; set; }
    public int? CanFamCon { get; set; }
    public string? NomSoc { get; set; }
    public string? CodUbiSoc { get; set; }
    public string? DnuSoc { get; set; }
    public string? NumDoc { get; set; }
    public string? TipDoc { get; set; }
    public string? RucSoc { get; set; }
    public int CodPre { get; set; }

    public Predio? Predio { get; set; }
    public ICollection<Reclamo> Reclamos { get; set; } = new List<Reclamo>();
}
