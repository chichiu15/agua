using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class CalleConfiguration : IEntityTypeConfiguration<Calle>
{
    public void Configure(EntityTypeBuilder<Calle> builder)
    {
        builder.ToTable("Calles", "dbo");
        builder.HasKey(c => c.CodCal);
        builder.Property(c => c.CodCal).HasColumnName("CodCal");
        builder.Property(c => c.NomCal).HasColumnName("NomCal").HasMaxLength(50);
        builder.Property(c => c.EstCal).HasColumnName("EstCal");
        builder.Property(c => c.TipCal).HasColumnName("TipCal");
    }
}
