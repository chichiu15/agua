using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class SocioConfiguration : IEntityTypeConfiguration<Socio>
{
    public void Configure(EntityTypeBuilder<Socio> builder)
    {
        builder.ToTable("Socio");
        builder.HasKey(s => s.RegistroSocio);
        builder.Property(s => s.RegistroSocio).HasColumnName("Reg_soc").ValueGeneratedNever();
        builder.Property(s => s.CodigoCatastral).HasColumnName("Catastral_soc");
        builder.Property(s => s.Nombre).HasColumnName("Nom_soc").HasMaxLength(200);
        builder.Property(s => s.Direccion).HasColumnName("Direc_soc").HasMaxLength(300);
        builder.Property(s => s.Categoria).HasColumnName("Cat_soc").HasMaxLength(50);
        builder.Property(s => s.Ruta).HasColumnName("Ruta_soc").HasMaxLength(20);
        builder.Property(s => s.Recorrido).HasColumnName("Recorrido_soc");
        builder.Property(s => s.Ci).HasColumnName("CI_soc").HasMaxLength(20);
        builder.Property(s => s.Telefono).HasColumnName("Telefono_soc").HasMaxLength(30);
        builder.Property(s => s.Sexo).HasColumnName("Sexo_soc").HasMaxLength(10);
        // Latitud_soc / Longitud_soc ya NO se mapean: la ubicación ahora
        // vive en Medidor (ver MedidorConfiguration).
    }
}