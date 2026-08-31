using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class DetalleSolicitudLecturaConfiguration : IEntityTypeConfiguration<DetalleSolicitudLectura>
{
    public void Configure(EntityTypeBuilder<DetalleSolicitudLectura> builder)
    {
        builder.ToTable("DetalleSolicitudLectura", "medidores");
        builder.HasKey(d => d.Id);
        builder.Property(d => d.Id).HasColumnName("Id_detalle").ValueGeneratedNever();
        builder.Property(d => d.NumeroHoja).HasColumnName("Nro_hoja_detalle").HasMaxLength(30);
        builder.Property(d => d.CodCon).HasColumnName("Cod_con").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(d => d.LecturaAnterior).HasColumnName("Lec_ant_detalle");
        builder.Property(d => d.LecturaActual).HasColumnName("Lec_act_detalle");
        builder.Property(d => d.Consumo).HasColumnName("Consumo_detalle");

        builder.HasOne(d => d.Solicitud)
            .WithMany(s => s.Detalles)
            .HasForeignKey(d => d.NumeroHoja);

        // La conexión (dbo.Conexiones) es la cuenta del socio en COSAALT; solo lectura.
        builder.HasOne(d => d.Conexion)
            .WithMany()
            .HasForeignKey(d => d.CodCon);
    }
}