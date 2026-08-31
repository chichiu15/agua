namespace Cosaalt.API.Domain.Entities;

public class Reclamo
{
    public int CodRec { get; set; }
    public char ModRec { get; set; }
    public DateTime FecRec { get; set; }
    public int NumRec { get; set; }
    public DateTime FecEstResRec { get; set; }
    public int CodAsFu { get; set; }
    public int? CodRec2 { get; set; }
    public int CodMoRe { get; set; }
    public int? CodCon { get; set; }
    public char PriRec { get; set; }
    public bool EstRec { get; set; }
    public string DesRec { get; set; } = string.Empty;
    public int? CodIns { get; set; }
    public int? CodBar { get; set; }
    public int? CodCal { get; set; }
    public int? CodCal1 { get; set; }
    public int? CodCal2 { get; set; }
    public int? NroDirRec { get; set; }
    public string? RefRec { get; set; }

    public Conexion? Conexion { get; set; }
    public Recurrente? Recurrente { get; set; }
    public Barrio? Barrio { get; set; }
}
