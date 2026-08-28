using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class RecurrenteConfiguration : IEntityTypeConfiguration<Recurrente>
{
    public void Configure(EntityTypeBuilder<Recurrente> builder)
    {
        builder.ToTable("Recurrentes", "dbo");
        builder.HasKey(r => r.CodRec);
        builder.Property(r => r.CodRec).HasColumnName("CodRec");
        builder.Property(r => r.NomRec).HasColumnName("NomRec").HasMaxLength(120);
        builder.Property(r => r.CeIdRec).HasColumnName("CeIdRec").HasMaxLength(15);
        builder.Property(r => r.TelRec).HasColumnName("TelRec").HasMaxLength(30);
        builder.Property(r => r.SexRec).HasColumnName("SexRec");
    }
}
