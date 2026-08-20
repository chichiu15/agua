using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class MedidorConfiguration : IEntityTypeConfiguration<Medidor>
{
    public void Configure(EntityTypeBuilder<Medidor> builder)
    {
        builder.ToTable("Medidor");
        builder.HasKey(m => m.NumeroMedidor);

        builder.Property(m => m.NumeroMedidor)
            .HasColumnName("Nro_medidor")
            .HasMaxLength(30);

        builder.Property(m => m.Marca)
            .HasColumnName("Marca_medidor")
            .HasMaxLength(50);

        builder.Property(m => m.RegistroSocio)
            .HasColumnName("Reg_soc");

        builder.Property(m => m.FechaInstalacion)
            .HasColumnName("Fecha_instalacion_medidor");

        builder.Property(m => m.Estado)
            .HasColumnName("Estado_medidor")
            .HasMaxLength(30);

        builder.Property(m => m.Latitud)
            .HasColumnName("Latitud_medidor");

        builder.Property(m => m.Longitud)
            .HasColumnName("Longitud_medidor");

        // HISTORIAL: un socio puede conservar todos sus medidores anteriores.
        builder.HasOne(m => m.Socio)
            .WithMany(s => s.Medidores)
            .HasForeignKey(m => m.RegistroSocio)
            .OnDelete(DeleteBehavior.Restrict);

        // Integridad: permite muchos medidores retirados, pero solo un Activo por socio.
        builder.HasIndex(m => m.RegistroSocio)
            .HasDatabaseName("UX_Medidor_RegSoc_Activo")
            .IsUnique()
            .HasFilter("[Estado_medidor] = N'Activo'");
    }
}
