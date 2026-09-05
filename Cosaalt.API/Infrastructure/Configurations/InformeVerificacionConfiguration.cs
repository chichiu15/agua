using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class InformeVerificacionConfiguration : IEntityTypeConfiguration<InformeVerificacion>
{
    public void Configure(EntityTypeBuilder<InformeVerificacion> builder)
    {
        builder.ToTable("InformesVerificacion", "medidores");
        builder.HasKey(i => i.Id);
        builder.Property(i => i.Id).HasColumnName("IdInforme");
        builder.Property(i => i.IdVerificacion).HasColumnName("IdVerificacion");
        builder.Property(i => i.NroInforme).HasColumnName("NroInforme").HasMaxLength(50).IsRequired();
        builder.Property(i => i.FechaEmision).HasColumnName("FechaEmision");
        builder.Property(i => i.FechaFirma).HasColumnName("FechaFirma");
        builder.Property(i => i.RutaPdf).HasColumnName("RutaPdf").HasMaxLength(500);
        builder.Property(i => i.Firmado).HasColumnName("Firmado");
        builder.Property(i => i.VersionInforme).HasColumnName("VersionInforme");
        builder.Property(i => i.Observaciones).HasColumnName("Observaciones").HasMaxLength(500);

        builder.HasOne(i => i.Verificacion)
            .WithMany(v => v.Informes)
            .HasForeignKey(i => i.IdVerificacion)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
