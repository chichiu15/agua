using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class SolicitudLecturaConfiguration : IEntityTypeConfiguration<SolicitudLectura>
{
    public void Configure(EntityTypeBuilder<SolicitudLectura> builder)
    {
        builder.ToTable("SolicitudLectura");
        builder.HasKey(s => s.NumeroHoja);
        builder.Property(s => s.NumeroHoja).HasColumnName("Nro_hoja_solicitudLec").HasMaxLength(30);
        builder.Property(s => s.AnioMes).HasColumnName("Año_mes_solicitudLec").HasMaxLength(10);
        builder.Property(s => s.FechaEmision).HasColumnName("Fecha_emision_solicitudLec");
        builder.Property(s => s.HoraEmision).HasColumnName("Hora_emision_solicitudLec");
        builder.Property(s => s.ElaboradoPor).HasColumnName("Elaborad_por_solicitudLec").HasMaxLength(100);
        builder.Property(s => s.CodigoObservacion).HasColumnName("Cod_obs_solicitudLec");
        builder.Property(s => s.DescripcionObservacion).HasColumnName("Desc_obs_solicitudLec").HasMaxLength(200);
    }
}
