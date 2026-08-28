namespace Cosaalt.API.Domain.Entities;

public class Funcionario
{
    public int CodFun { get; set; }
    public string? TipSanFun { get; set; }
    public string? AliFun { get; set; }
    public string? LugNacFun { get; set; }
    public bool EstFun { get; set; }
    public int CodPer { get; set; }
    public string? MatFun { get; set; }
    public bool? ModPagFun { get; set; }
    public decimal? NroCueFun { get; set; }
    public string? NacFun { get; set; }
    public DateTime? FecIngFun { get; set; }
    public char? NivEduFun { get; set; }
    public string? NuaFun { get; set; }
    public int? CodAfp { get; set; }
    public int? CodTiCo { get; set; }
    public decimal TipFun { get; set; }
    public int? CodDep { get; set; }

    public Persona? Persona { get; set; }
}
