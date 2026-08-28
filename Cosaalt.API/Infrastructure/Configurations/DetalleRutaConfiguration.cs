using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class DetalleRutaConfiguration : IEntityTypeConfiguration<DetalleRuta>
{
    public void Configure(EntityTypeBuilder<DetalleRuta> builder)
    {
        builder.ToTable("DetalleRuta", "medidores");
        builder.HasKey(d => d.Id);
        builder.Property(d => d.Id).HasColumnName("IdDetalle");
        builder.Property(d => d.IdAsignacion).HasColumnName("IdAsignacion");
        builder.Property(d => d.TipoOrigen).HasColumnName("TipoOrigen").HasMaxLength(20);
        builder.Property(d => d.IdOrigen).HasColumnName("IdOrigen").HasMaxLength(50);
        builder.Property(d => d.OrdenVisita).HasColumnName("OrdenVisita");
        builder.Property(d => d.Estado).HasColumnName("Estado").HasMaxLength(20);
        builder.Property(d => d.SolicitudId).HasColumnName("SolicitudId").HasMaxLength(50);
        builder.Property(d => d.NombreCliente).HasColumnName("NombreCliente").HasMaxLength(200);
        builder.Property(d => d.Direccion).HasColumnName("Direccion").HasMaxLength(300);
        builder.Property(d => d.Latitud).HasColumnName("Latitud");
        builder.Property(d => d.Longitud).HasColumnName("Longitud");

        builder.HasOne(d => d.Asignacion)
            .WithMany(a => a.Detalles)
            .HasForeignKey(d => d.IdAsignacion);
    }
}
