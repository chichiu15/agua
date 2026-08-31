using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class PersonaConfiguration : IEntityTypeConfiguration<Persona>
{
    public void Configure(EntityTypeBuilder<Persona> builder)
    {
        builder.ToTable("Personas", "dbo");
        builder.HasKey(p => p.CodPer);
        builder.Property(p => p.CodPer).HasColumnName("CodPer").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(p => p.NomPer).HasColumnName("NomPer").HasMaxLength(50);
        builder.Property(p => p.PriApePer).HasColumnName("PriApePer").HasMaxLength(30);
        builder.Property(p => p.SegApePer).HasColumnName("SegApePer").HasMaxLength(30);
        builder.Property(p => p.FecNacPer).HasColumnName("FecNacPer");
        builder.Property(p => p.SexPer).HasColumnName("SexPer");
        builder.Property(p => p.EstPer).HasColumnName("EstPer");
        builder.Property(p => p.EstCivPer).HasColumnName("EstCivPer");
        builder.Property(p => p.FotPer).HasColumnName("FotPer").HasMaxLength(50);
        builder.Property(p => p.CorPer).HasColumnName("CorPer").HasMaxLength(60);
        builder.Property(p => p.ApeCasPer).HasColumnName("ApeCasPer").HasMaxLength(30);
        builder.Property(p => p.CodPai).HasColumnName("CodPai").HasConversion(NumericConversions.NullableIntToDecimal);
    }
}
