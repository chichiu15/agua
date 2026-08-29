using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class MotivoCambioMedidorDboConfiguration : IEntityTypeConfiguration<MotivoCambioMedidorDbo>
{
    public void Configure(EntityTypeBuilder<MotivoCambioMedidorDbo> builder)
    {
        builder.ToTable("MotivosCambioMedidor", "dbo");
        builder.HasKey(m => m.CodMoCaMe);
        builder.Property(m => m.CodMoCaMe).HasColumnName("CodMoCaMe").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(m => m.NomMoCaMe).HasColumnName("NomMoCaMe").HasMaxLength(50);
        builder.Property(m => m.DesMoCaMe).HasColumnName("DesMoCaMe").HasMaxLength(200);
        builder.Property(m => m.EstMoCaMe).HasColumnName("EstMoCaMe");
    }
}