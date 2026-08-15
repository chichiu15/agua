using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class AsignacionRutaConfiguration : IEntityTypeConfiguration<AsignacionRuta>
{
    public void Configure(EntityTypeBuilder<AsignacionRuta> builder)
    {
        builder.ToTable("AsignacionRuta");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.Id).HasColumnName("IdAsignacion");
        builder.Property(a => a.IdUsuarioApp).HasColumnName("IdUsuarioApp");
        builder.Property(a => a.FechaAsignacion).HasColumnName("FechaAsignacion");
        builder.Property(a => a.Estado).HasColumnName("Estado").HasMaxLength(20);

        builder.HasOne(a => a.Usuario)
            .WithMany(u => u.Asignaciones)
            .HasForeignKey(a => a.IdUsuarioApp);
    }
}
