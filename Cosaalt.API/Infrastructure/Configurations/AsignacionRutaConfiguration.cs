using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class AsignacionRutaConfiguration : IEntityTypeConfiguration<AsignacionRuta>
{
    public void Configure(EntityTypeBuilder<AsignacionRuta> builder)
    {
        builder.ToTable("AsignacionRuta", "medidores");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.Id).HasColumnName("IdAsignacion");
        builder.Property(a => a.IdUsuarioApp).HasColumnName("IdUsuarioApp");
        builder.Property(a => a.IdUsuarioAsignador).HasColumnName("IdUsuarioAsignador");
        builder.Property(a => a.FechaAsignacion).HasColumnName("FechaAsignacion");
        builder.Property(a => a.Estado).HasColumnName("Estado").HasMaxLength(20).IsRequired();
        builder.Property(a => a.Observaciones).HasColumnName("Observaciones").HasMaxLength(500);
        builder.Property(a => a.FechaCreacion).HasColumnName("FechaCreacion");

        builder.HasOne(a => a.Tecnico)
            .WithMany(u => u.RutasComoTecnico)
            .HasForeignKey(a => a.IdUsuarioApp)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(a => a.Asignador)
            .WithMany(u => u.RutasComoAsignador)
            .HasForeignKey(a => a.IdUsuarioAsignador)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
