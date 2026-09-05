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
        builder.Property(d => d.TipoOrigen).HasColumnName("TipoOrigen").HasMaxLength(20).IsRequired();
        builder.Property(d => d.IdOrigen).HasColumnName("IdOrigen").HasMaxLength(50).IsRequired();
        builder.Property(d => d.OrdenVisita).HasColumnName("OrdenVisita");
        builder.Property(d => d.Estado).HasColumnName("Estado").HasMaxLength(20).IsRequired();
        builder.Property(d => d.SolicitudId).HasColumnName("SolicitudId").HasMaxLength(60).IsRequired();
        // SQL Server expone NUMERIC(6,0) como Decimal. El modelo de dominio usa
        // int?, por lo que la conversión debe ser explícita para que EF no trate
        // de leer esas columnas mediante SqlDataReader.GetInt32().
        builder.Property(d => d.RegSoc).HasColumnName("RegSoc").HasConversion<decimal?>().HasPrecision(6, 0);
        builder.Property(d => d.CodMedidorActual).HasColumnName("CodMedidorActual").HasConversion<decimal?>().HasPrecision(6, 0);
        builder.Property(d => d.NombreCliente).HasColumnName("NombreCliente").HasMaxLength(200).IsRequired();
        builder.Property(d => d.Direccion).HasColumnName("Direccion").HasMaxLength(300).IsRequired();
        builder.Property(d => d.Latitud).HasColumnName("Latitud").HasPrecision(18, 12);
        builder.Property(d => d.Longitud).HasColumnName("Longitud").HasPrecision(18, 12);
        builder.Property(d => d.FechaInicio).HasColumnName("FechaInicio");
        builder.Property(d => d.FechaFinalizacion).HasColumnName("FechaFinalizacion");

        builder.HasOne(d => d.Asignacion)
            .WithMany(a => a.Detalles)
            .HasForeignKey(d => d.IdAsignacion)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
