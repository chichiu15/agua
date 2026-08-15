using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class EjecucionCambioConfiguration : IEntityTypeConfiguration<EjecucionCambio>
{
    public void Configure(EntityTypeBuilder<EjecucionCambio> builder)
    {
        builder.ToTable("EjecucionCambio");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Id).HasColumnName("IdEjecucion");
        builder.Property(e => e.TipoOrigen).HasColumnName("TipoOrigen").HasMaxLength(20);
        builder.Property(e => e.IdOrigen).HasColumnName("IdOrigen").HasMaxLength(50);
        builder.Property(e => e.IdUsuarioApp).HasColumnName("IdUsuarioApp");
        builder.Property(e => e.FechaHoraEjecucion).HasColumnName("FechaHoraEjecucion");
        builder.Property(e => e.NumeroMedidorRetirado).HasColumnName("NroMedidorRetirado").HasMaxLength(30);
        builder.Property(e => e.MarcaRetirado).HasColumnName("MarcaRetirado").HasMaxLength(50);
        builder.Property(e => e.LecturaRetiro).HasColumnName("LecturaRetiro");
        builder.Property(e => e.IdMotivo).HasColumnName("IdMotivo");
        builder.Property(e => e.NumeroMedidorInstalado).HasColumnName("NroMedidorInstalado").HasMaxLength(30);
        builder.Property(e => e.MarcaInstalado).HasColumnName("MarcaInstalado").HasMaxLength(50);
        builder.Property(e => e.ObservacionesInstalacion).HasColumnName("Observaciones").HasMaxLength(500);
        builder.Property(e => e.LatLong).HasColumnName("LatLong").HasMaxLength(50);
        builder.Property(e => e.Sincronizado).HasColumnName("Sincronizado");

        builder.HasOne(e => e.Usuario)
            .WithMany(u => u.Ejecuciones)
            .HasForeignKey(e => e.IdUsuarioApp);

        builder.HasOne(e => e.Motivo)
            .WithMany(m => m.Ejecuciones)
            .HasForeignKey(e => e.IdMotivo);
    }
}
