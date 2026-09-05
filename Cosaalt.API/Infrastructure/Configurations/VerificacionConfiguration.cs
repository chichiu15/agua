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
        builder.Property(v => v.TipoOrigen).HasColumnName("TipoOrigen").HasMaxLength(20).IsRequired();
        builder.Property(v => v.IdOrigen).HasColumnName("IdOrigen").HasMaxLength(50).IsRequired();
        builder.Property(v => v.RegSoc).HasColumnName("RegSoc").HasConversion<decimal>().HasPrecision(6, 0);
        builder.Property(v => v.IdUsuarioMecanico).HasColumnName("IdUsuarioMecanico");
        builder.Property(v => v.CodMedidor).HasColumnName("CodMedidor").HasConversion<decimal>().HasPrecision(6, 0);
        builder.Property(v => v.IdParametroNormativoAplicado).HasColumnName("IdParametroNormativoAplicado");
        builder.Property(v => v.FechaVerificacion).HasColumnName("FechaVerificacion");
        builder.Property(v => v.Estado).HasColumnName("Estado").HasMaxLength(20).IsRequired();
        builder.Property(v => v.Resultado).HasColumnName("Resultado").HasMaxLength(20);

        builder.HasOne(v => v.Mecanico)
            .WithMany(u => u.Verificaciones)
            .HasForeignKey(v => v.IdUsuarioMecanico)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(v => v.ParametroNormativoAplicado)
            .WithMany()
            .HasForeignKey(v => v.IdParametroNormativoAplicado)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(v => v.Ensayo)
            .WithOne(e => e.Verificacion)
            .HasForeignKey<EnsayoVerificacion>(e => e.IdVerificacion)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
