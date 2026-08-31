using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class ReclamoConfiguration : IEntityTypeConfiguration<Reclamo>
{
    public void Configure(EntityTypeBuilder<Reclamo> builder)
    {
        builder.ToTable("Reclamos", "dbo");
        builder.HasKey(r => r.CodRec);
        builder.Property(r => r.CodRec).HasColumnName("CodRec").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(r => r.ModRec).HasColumnName("ModRec");
        builder.Property(r => r.FecRec).HasColumnName("FecRec");
        builder.Property(r => r.NumRec).HasColumnName("NumRec").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(r => r.FecEstResRec).HasColumnName("FecEstResRec");
        builder.Property(r => r.CodAsFu).HasColumnName("CodAsFu").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(r => r.CodRec2).HasColumnName("CodRec2").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(r => r.CodMoRe).HasColumnName("CodMoRe").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(r => r.CodCon).HasColumnName("CodCon").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(r => r.PriRec).HasColumnName("PriRec");
        builder.Property(r => r.EstRec).HasColumnName("EstRec");
        builder.Property(r => r.DesRec).HasColumnName("DesRec").HasMaxLength(300);
        builder.Property(r => r.CodIns).HasColumnName("CodIns").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(r => r.CodBar).HasColumnName("CodBar").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(r => r.CodCal).HasColumnName("CodCal").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(r => r.CodCal1).HasColumnName("CodCal1").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(r => r.CodCal2).HasColumnName("CodCal2").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(r => r.NroDirRec).HasColumnName("NroDirRec");
        builder.Property(r => r.RefRec).HasColumnName("RefRec").HasMaxLength(300);

        builder.HasOne(r => r.Conexion)
            .WithMany(c => c.Reclamos)
            .HasForeignKey(r => r.CodCon);

        builder.HasOne(r => r.Recurrente)
            .WithMany(rec => rec.Reclamos)
            .HasForeignKey(r => r.CodRec2);

        builder.HasOne(r => r.Barrio)
            .WithMany(b => b.Reclamos)
            .HasForeignKey(r => r.CodBar);
    }
}
