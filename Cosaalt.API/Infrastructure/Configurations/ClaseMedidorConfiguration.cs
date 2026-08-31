using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class ClaseMedidorConfiguration : IEntityTypeConfiguration<ClaseMedidor>
{
    public void Configure(EntityTypeBuilder<ClaseMedidor> builder)
    {
        builder.ToTable("ClasesMedidores", "dbo");
        builder.HasKey(c => c.CodClMe);
        builder.Property(c => c.CodClMe).HasColumnName("CodClMe");
        builder.Property(c => c.SigClMe).HasColumnName("SigClMe").HasMaxLength(50);
        builder.Property(c => c.DesClMe).HasColumnName("DesClMe").HasMaxLength(200);
        builder.Property(c => c.EstClMe).HasColumnName("EstClMe");
    }
}
