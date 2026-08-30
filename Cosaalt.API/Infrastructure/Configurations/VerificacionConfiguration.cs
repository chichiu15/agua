using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class VerificacionConfiguration : IEntityTypeConfiguration<Verificacion>
{
    public void Configure(EntityTypeBuilder<Verificacion> builder)
    {
        builder.ToTable("Verificaciones", "medidores");
        builder.HasKey(v => v.Id);
        builder.Property(v => v.Id).HasColumnName("IdVerificacion");
        builder.Property(v => v.TipoOrigen).HasColumnName("TipoOrigen").HasMaxLength(20);
        builder.Property(v => v.IdOrigen).HasColumnName("IdOrigen").HasMaxLength(50);
        builder.Property(v => v.CodCon).HasColumnName("Cod_con").HasConversion(NumericConversions.IntToDecimal);
        builder.Property(v => v.IdUsuarioMecanico).HasColumnName("IdUsuarioMecanico");
        builder.Property(v => v.IdMedidor).HasColumnName("IdMedidor").HasMaxLength(30);
        builder.Property(v => v.FechaVerificacion).HasColumnName("FechaVerificacion");
        builder.Property(v => v.Estado).HasColumnName("Estado").HasMaxLength(20);
        builder.Property(v => v.Resultado).HasColumnName("Resultado").HasMaxLength(20);

        builder.HasOne(v => v.Conexion)
            .WithMany()
            .HasForeignKey(v => v.CodCon);

        builder.HasOne(v => v.Mecanico)
            .WithMany()
            .HasForeignKey(v => v.IdUsuarioMecanico);

        builder.HasOne(v => v.Ensayo)
            .WithOne(e => e.Verificacion)
            .HasForeignKey<EnsayoVerificacion>(e => e.IdVerificacion);
    }
}
