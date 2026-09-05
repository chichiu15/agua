using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class EnsayoVerificacionConfiguration : IEntityTypeConfiguration<EnsayoVerificacion>
{
    public void Configure(EntityTypeBuilder<EnsayoVerificacion> builder)
    {
        builder.ToTable("EnsayoVerificacion", "medidores");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Id).HasColumnName("IdEnsayo");
        builder.Property(e => e.IdVerificacion).HasColumnName("IdVerificacion");
        builder.Property(e => e.Condiciones).HasColumnName("Condiciones").HasMaxLength(500);
        builder.Property(e => e.LecturaInicial).HasColumnName("LecturaInicial").HasPrecision(18, 2);
        builder.Property(e => e.LecturaFinal).HasColumnName("LecturaFinal").HasPrecision(18, 2);
        builder.Property(e => e.VolumenPatron).HasColumnName("VolumenPatron").HasPrecision(18, 4);
        builder.Property(e => e.Caudal).HasColumnName("Caudal").HasPrecision(18, 4);
        builder.Property(e => e.VolumenRegistrado).HasColumnName("VolumenRegistrado").HasPrecision(18, 4);
        builder.Property(e => e.Error).HasColumnName("Error").HasPrecision(10, 4);
        builder.Property(e => e.Fugas).HasColumnName("Fugas");
        builder.Property(e => e.Observaciones).HasColumnName("Observaciones").HasMaxLength(500);
        builder.Property(e => e.FechaRegistro).HasColumnName("FechaRegistro");
    }
}
