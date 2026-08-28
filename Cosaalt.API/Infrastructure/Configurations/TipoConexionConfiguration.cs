using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class TipoConexionConfiguration : IEntityTypeConfiguration<TipoConexion>
{
    public void Configure(EntityTypeBuilder<TipoConexion> builder)
    {
        builder.ToTable("TiposConexiones", "dbo");
        builder.HasKey(t => t.CodTiCo);
        builder.Property(t => t.CodTiCo).HasColumnName("CodTiCo");
        builder.Property(t => t.DesTiCo).HasColumnName("DesTiCo").HasMaxLength(50);
        builder.Property(t => t.EstTiCo).HasColumnName("EstTiCo");
        builder.Property(t => t.AliTiCo).HasColumnName("AliTiCo").HasMaxLength(5);
    }
}
