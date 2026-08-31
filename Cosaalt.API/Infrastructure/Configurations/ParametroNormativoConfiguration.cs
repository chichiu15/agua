using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class ParametroNormativoConfiguration : IEntityTypeConfiguration<ParametroNormativo>
{
    public void Configure(EntityTypeBuilder<ParametroNormativo> builder)
    {
        builder.ToTable("ParametrosNormativos", "medidores");
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasColumnName("IdParametro");
        builder.Property(p => p.Codigo).HasColumnName("Codigo").HasMaxLength(30).IsRequired();
        builder.Property(p => p.Descripcion).HasColumnName("Descripcion").HasMaxLength(200);
        builder.Property(p => p.ErrorMaxPermitido).HasColumnName("ErrorMaxPermitido").HasPrecision(10, 4);
        builder.Property(p => p.CaudalMin).HasColumnName("CaudalMin").HasPrecision(10, 4);
        builder.Property(p => p.CaudalMax).HasColumnName("CaudalMax").HasPrecision(10, 4);
        builder.Property(p => p.VigenciaInicio).HasColumnName("VigenciaInicio");
        builder.Property(p => p.VigenciaFin).HasColumnName("VigenciaFin");
        builder.Property(p => p.Activo).HasColumnName("Activo");
    }
}
