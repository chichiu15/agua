using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class MarcaDboConfiguration : IEntityTypeConfiguration<MarcaDbo>
{
    public void Configure(EntityTypeBuilder<MarcaDbo> builder)
    {
        builder.ToTable("Marcas", "dbo");
        builder.HasKey(m => m.CodMar);
        builder.Property(m => m.CodMar).HasColumnName("CodMar").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(m => m.NomMar).HasColumnName("NomMar").HasMaxLength(50);
        builder.Property(m => m.AliMar).HasColumnName("AliMar").HasMaxLength(50);
    }
}