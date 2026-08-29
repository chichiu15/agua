using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class RolAppConfiguration : IEntityTypeConfiguration<RolApp>
{
    public void Configure(EntityTypeBuilder<RolApp> builder)
    {
        builder.ToTable("RolApp", "medidores");
        builder.HasKey(r => r.IdRol);
        builder.Property(r => r.IdRol).HasColumnName("IdRol");
        builder.Property(r => r.Nombre).HasColumnName("Nombre").HasMaxLength(50);
        builder.Property(r => r.Descripcion).HasColumnName("Descripcion").HasMaxLength(200);
        builder.Property(r => r.Activo).HasColumnName("Activo");
    }
}