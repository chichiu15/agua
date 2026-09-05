using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class EvidenciaFotograficaConfiguration : IEntityTypeConfiguration<EvidenciaFotografica>
{
    public void Configure(EntityTypeBuilder<EvidenciaFotografica> builder)
    {
        builder.ToTable("EvidenciaFotografica", "medidores");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Id).HasColumnName("IdFoto");
        builder.Property(e => e.IdEjecucion).HasColumnName("IdEjecucion");
        builder.Property(e => e.TipoFoto).HasColumnName("TipoFoto").HasMaxLength(30).IsRequired();
        builder.Property(e => e.RutaArchivo).HasColumnName("RutaArchivo").HasMaxLength(500).IsRequired();
        builder.Property(e => e.FechaRegistro).HasColumnName("FechaRegistro");

        builder.HasOne(e => e.Ejecucion)
            .WithMany(ej => ej.Evidencias)
            .HasForeignKey(e => e.IdEjecucion)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
