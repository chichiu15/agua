using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class PredioConfiguration : IEntityTypeConfiguration<Predio>
{
    public void Configure(EntityTypeBuilder<Predio> builder)
    {
        builder.ToTable("Predios", "dbo");
        builder.HasKey(p => p.CodPre);
        builder.Property(p => p.CodPre).HasColumnName("CodPre");
        builder.Property(p => p.CodUbiPre).HasColumnName("CodUbiPre").HasMaxLength(15);
        builder.Property(p => p.NumPre).HasColumnName("NumPre").HasMaxLength(4);
        builder.Property(p => p.CodMaTr).HasColumnName("CodMaTr").HasMaxLength(25);
    }
}
