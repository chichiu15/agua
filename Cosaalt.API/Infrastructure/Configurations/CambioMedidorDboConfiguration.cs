using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class CambioMedidorDboConfiguration : IEntityTypeConfiguration<CambioMedidorDbo>
{
    public void Configure(EntityTypeBuilder<CambioMedidorDbo> builder)
    {
        builder.ToTable("CambioMedidores", "dbo");
        builder.HasKey(c => c.CodCaMe);
        builder.Property(c => c.CodCaMe).HasColumnName("CodCaMe").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(c => c.EstCaMe).HasColumnName("EstCaMe");
        builder.Property(c => c.DesCaMe).HasColumnName("DesCaMe").HasMaxLength(100);
        builder.Property(c => c.CodCon).HasColumnName("CodCon").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(c => c.CodMed).HasColumnName("CodMed").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(c => c.CodOrTr).HasColumnName("CodOrTr").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(c => c.CodCar).HasColumnName("CodCar").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(c => c.CodMoCaMe).HasColumnName("CodMoCaMe").HasConversion(NumericConversions.NullableIntToDecimal);
    }
}