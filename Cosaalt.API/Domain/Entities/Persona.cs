namespace Cosaalt.API.Domain.Entities;

public class Persona
{
    public int CodPer { get; set; }
    public string NomPer { get; set; } = string.Empty;
    public string PriApePer { get; set; } = string.Empty;
    public string? SegApePer { get; set; }
    public DateTime? FecNacPer { get; set; }
    public bool? SexPer { get; set; }
    public bool EstPer { get; set; }
    public bool? EstCivPer { get; set; }
    public string? FotPer { get; set; }
    public string? CorPer { get; set; }
    public string? ApeCasPer { get; set; }
    public int? CodPai { get; set; }

    public string NombreCompleto => $"{NomPer} {PriApePer} {SegApePer}".Trim();

    public ICollection<Funcionario> Funcionarios { get; set; } = new List<Funcionario>();
}
