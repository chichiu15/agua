using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class MotivoCambioMedidorConfiguration : IEntityTypeConfiguration<MotivoCambioMedidor>
{
    public void Configure(EntityTypeBuilder<MotivoCambioMedidor> builder)
    {
        builder.ToTable("MotivoCambioMedidor");
        builder.HasKey(m => m.Id);
        builder.Property(m => m.Id).HasColumnName("Id_motivo");
        builder.Property(m => m.Descripcion).HasColumnName("Descripcion").HasMaxLength(100);
        builder.Property(m => m.Activo).HasColumnName("Activo");
    }
}
