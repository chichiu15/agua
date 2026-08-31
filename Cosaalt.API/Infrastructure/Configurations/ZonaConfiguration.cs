using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class ZonaConfiguration : IEntityTypeConfiguration<Zona>
{
    public void Configure(EntityTypeBuilder<Zona> builder)
    {
        builder.ToTable("Zonas", "dbo");
        builder.HasKey(z => z.CodZon);
        builder.Property(z => z.CodZon).HasColumnName("CodZon");
        builder.Property(z => z.NomZon).HasColumnName("NomZon").HasMaxLength(50);
        builder.Property(z => z.EstZon).HasColumnName("EstZon");
    }
}
