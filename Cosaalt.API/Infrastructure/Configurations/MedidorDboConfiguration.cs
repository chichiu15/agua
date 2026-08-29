using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class MedidorDboConfiguration : IEntityTypeConfiguration<MedidorDbo>
{
    public void Configure(EntityTypeBuilder<MedidorDbo> builder)
    {
        builder.ToTable("Medidores", "dbo");
        builder.HasKey(m => m.CodMed);
        builder.Property(m => m.CodMed).HasColumnName("CodMed").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(m => m.SerMed).HasColumnName("SerMed").HasMaxLength(15);
        builder.Property(m => m.FecFabMed).HasColumnName("FecFabMed");
        builder.Property(m => m.EstMed).HasColumnName("EstMed");
        builder.Property(m => m.ObsMed).HasColumnName("ObsMed").HasMaxLength(300);
        builder.Property(m => m.CodMar).HasColumnName("CodMar").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(m => m.CodPeEmTiPe).HasColumnName("CodPeEmTiPe").HasMaxLength(12);
        builder.Property(m => m.CodCaTu).HasColumnName("CodCaTu").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(m => m.CodTiTr).HasColumnName("CodTiTr").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(m => m.CodElMe).HasColumnName("CodElMe").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(m => m.DigMed).HasColumnName("DigMed");
    }
}