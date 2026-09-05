using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class EjecucionCambioConfiguration : IEntityTypeConfiguration<EjecucionCambio>
{
    public void Configure(EntityTypeBuilder<EjecucionCambio> builder)
    {
        builder.ToTable("EjecucionCambio", "medidores");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Id).HasColumnName("IdEjecucion");
        builder.Property(e => e.TipoOrigen).HasColumnName("TipoOrigen").HasMaxLength(20).IsRequired();
        builder.Property(e => e.IdOrigen).HasColumnName("IdOrigen").HasMaxLength(50).IsRequired();
        builder.Property(e => e.RegSoc).HasColumnName("RegSoc").HasConversion<decimal>().HasPrecision(6, 0);
        builder.Property(e => e.IdUsuarioApp).HasColumnName("IdUsuarioApp");
        builder.Property(e => e.FechaHoraEjecucion).HasColumnName("FechaHoraEjecucion");
        builder.Property(e => e.CodMedidorRetirado).HasColumnName("CodMedidorRetirado").HasConversion<decimal?>().HasPrecision(6, 0);
        builder.Property(e => e.SerieMedidorRetirado).HasColumnName("SerieMedidorRetirado").HasMaxLength(30).IsRequired();
        builder.Property(e => e.MarcaRetirado).HasColumnName("MarcaRetirado").HasMaxLength(50);
        builder.Property(e => e.LecturaRetiro).HasColumnName("LecturaRetiro").HasPrecision(18, 2);
        builder.Property(e => e.IdMotivoInstitucional).HasColumnName("IdMotivoInstitucional").HasConversion<decimal?>().HasPrecision(10, 0);
        builder.Property(e => e.MotivoDescripcionSnapshot).HasColumnName("MotivoDescripcionSnapshot").HasMaxLength(200);
        builder.Property(e => e.CodMedidorInstalado).HasColumnName("CodMedidorInstalado").HasConversion<decimal?>().HasPrecision(6, 0);
        builder.Property(e => e.SerieMedidorInstalado).HasColumnName("SerieMedidorInstalado").HasMaxLength(30).IsRequired();
        builder.Property(e => e.MarcaInstalado).HasColumnName("MarcaInstalado").HasMaxLength(50);
        builder.Property(e => e.ObservacionesInstalacion).HasColumnName("ObservacionesInstalacion").HasMaxLength(500);
        builder.Property(e => e.Latitud).HasColumnName("Latitud").HasPrecision(18, 12);
        builder.Property(e => e.Longitud).HasColumnName("Longitud").HasPrecision(18, 12);
        builder.Property(e => e.Sincronizado).HasColumnName("Sincronizado");
        builder.Property(e => e.FechaSincronizacion).HasColumnName("FechaSincronizacion");
        builder.Property(e => e.EstadoIntegracionInstitucional).HasColumnName("EstadoIntegracionInstitucional").HasMaxLength(30).IsRequired();
        builder.Property(e => e.FechaIntegracionInstitucional).HasColumnName("FechaIntegracionInstitucional");
        builder.Property(e => e.DetalleIntegracionInstitucional).HasColumnName("DetalleIntegracionInstitucional").HasMaxLength(500);

        builder.HasOne(e => e.Usuario)
            .WithMany(u => u.Ejecuciones)
            .HasForeignKey(e => e.IdUsuarioApp)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
