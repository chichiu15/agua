using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class DetalleSolicitudLecturaConfiguration : IEntityTypeConfiguration<DetalleSolicitudLectura>
{
    public void Configure(EntityTypeBuilder<DetalleSolicitudLectura> builder)
    {
        builder.ToTable("DetalleSolicitudLectura");
        builder.HasKey(d => d.Id);
        builder.Property(d => d.Id).HasColumnName("Id_detalle").ValueGeneratedNever();
        builder.Property(d => d.NumeroHoja).HasColumnName("Nro_hoja_detalle").HasMaxLength(30);
        builder.Property(d => d.RegistroSocio).HasColumnName("Reg_soc");
        builder.Property(d => d.LecturaAnterior).HasColumnName("Lec_ant_detalle");
        builder.Property(d => d.LecturaActual).HasColumnName("Lec_act_detalle");
        builder.Property(d => d.Consumo).HasColumnName("Consumo_detalle");

        builder.HasOne(d => d.Solicitud)
            .WithMany(s => s.Detalles)
            .HasForeignKey(d => d.NumeroHoja);

        builder.HasOne(d => d.Socio)
            .WithMany(s => s.DetallesLectura)
            .HasForeignKey(d => d.RegistroSocio);
    }
}