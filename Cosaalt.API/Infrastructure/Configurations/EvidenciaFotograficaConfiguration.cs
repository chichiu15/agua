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
        builder.Property(e => e.TipoFoto).HasColumnName("TipoFoto").HasMaxLength(30);
        builder.Property(e => e.RutaArchivo).HasColumnName("RutaArchivoServidor").HasMaxLength(500);

        builder.HasOne(e => e.Ejecucion)
            .WithMany(ej => ej.Evidencias)
            .HasForeignKey(e => e.IdEjecucion);
    }
}
