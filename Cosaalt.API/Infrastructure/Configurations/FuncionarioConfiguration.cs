using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class FuncionarioConfiguration : IEntityTypeConfiguration<Funcionario>
{
    public void Configure(EntityTypeBuilder<Funcionario> builder)
    {
        builder.ToTable("Funcionarios", "dbo");
        builder.HasKey(f => f.CodFun);
        builder.Property(f => f.CodFun).HasColumnName("CodFun");
        builder.Property(f => f.TipSanFun).HasColumnName("TipSanFun").HasMaxLength(3);
        builder.Property(f => f.AliFun).HasColumnName("AliFun").HasMaxLength(7);
        builder.Property(f => f.LugNacFun).HasColumnName("LugNacFun").HasMaxLength(50);
        builder.Property(f => f.EstFun).HasColumnName("EstFun");
        builder.Property(f => f.CodPer).HasColumnName("CodPer");
        builder.Property(f => f.MatFun).HasColumnName("MatFun").HasMaxLength(12);
        builder.Property(f => f.ModPagFun).HasColumnName("ModPagFun");
        builder.Property(f => f.NroCueFun).HasColumnName("NroCueFun");
        builder.Property(f => f.NacFun).HasColumnName("NacFun").HasMaxLength(20);
        builder.Property(f => f.FecIngFun).HasColumnName("FecIngFun");
        builder.Property(f => f.NivEduFun).HasColumnName("NivEduFun");
        builder.Property(f => f.NuaFun).HasColumnName("NuaFun").HasMaxLength(12);
        builder.Property(f => f.CodAfp).HasColumnName("CodAfp");
        builder.Property(f => f.CodTiCo).HasColumnName("CodTiCo");
        builder.Property(f => f.TipFun).HasColumnName("TipFun");
        builder.Property(f => f.CodDep).HasColumnName("CodDep");

        builder.HasOne(f => f.Persona)
            .WithMany(p => p.Funcionarios)
            .HasForeignKey(f => f.CodPer);
    }
}
