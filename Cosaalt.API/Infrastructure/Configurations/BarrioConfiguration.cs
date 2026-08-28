using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class BarrioConfiguration : IEntityTypeConfiguration<Barrio>
{
    public void Configure(EntityTypeBuilder<Barrio> builder)
    {
        builder.ToTable("Barrios", "dbo");
        builder.HasKey(b => b.CodBar);
        builder.Property(b => b.CodBar).HasColumnName("CodBar");
        builder.Property(b => b.NomBar).HasColumnName("NomBar").HasMaxLength(50);
        builder.Property(b => b.EstBar).HasColumnName("EstBar");
    }
}
