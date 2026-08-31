using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class CategoriaConexionConfiguration : IEntityTypeConfiguration<CategoriaConexion>
{
    public void Configure(EntityTypeBuilder<CategoriaConexion> builder)
    {
        builder.ToTable("CategoriasConexiones", "dbo");
        builder.HasKey(c => c.CodCaCo);
        builder.Property(c => c.CodCaCo).HasColumnName("CodCaCo");
        builder.Property(c => c.NomCaCo).HasColumnName("NomCaCo").HasMaxLength(30);
        builder.Property(c => c.AliCaCo).HasColumnName("AliCaCo").HasMaxLength(5);
        builder.Property(c => c.FecIniCaCo).HasColumnName("FecIniCaCo");
        builder.Property(c => c.FecFinCaCo).HasColumnName("FecFinCaCo");
        builder.Property(c => c.EstCaCo).HasColumnName("EstCaCo");
    }
}
