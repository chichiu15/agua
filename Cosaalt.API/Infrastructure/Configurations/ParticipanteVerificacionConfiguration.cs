using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class ParticipanteVerificacionConfiguration : IEntityTypeConfiguration<ParticipanteVerificacion>
{
    public void Configure(EntityTypeBuilder<ParticipanteVerificacion> builder)
    {
        builder.ToTable("ParticipantesVerificacion", "medidores");
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasColumnName("IdParticipante");
        builder.Property(p => p.IdVerificacion).HasColumnName("IdVerificacion");
        builder.Property(p => p.Nombre).HasColumnName("Nombre").HasMaxLength(200);
        builder.Property(p => p.Cargo).HasColumnName("Cargo").HasMaxLength(100);
        builder.Property(p => p.Rol).HasColumnName("Rol").HasMaxLength(50);

        builder.HasOne(p => p.Verificacion)
            .WithMany(v => v.Participantes)
            .HasForeignKey(p => p.IdVerificacion);
    }
}
