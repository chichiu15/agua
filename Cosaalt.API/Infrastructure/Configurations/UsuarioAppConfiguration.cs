using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class UsuarioAppConfiguration : IEntityTypeConfiguration<UsuarioApp>
{
    public void Configure(EntityTypeBuilder<UsuarioApp> builder)
    {
        builder.ToTable("UsuarioApp");
        builder.HasKey(u => u.Id);
        builder.Property(u => u.Id).HasColumnName("IdUsuarioApp");
        builder.Property(u => u.NombreUsuario).HasColumnName("NombreUsuario").HasMaxLength(50);
        builder.Property(u => u.ContrasenaHash).HasColumnName("ContrasenaHash").HasMaxLength(200);
        builder.Property(u => u.NombreCompleto).HasColumnName("NombreCompleto").HasMaxLength(200);
        builder.Property(u => u.Rol).HasColumnName("Rol").HasMaxLength(20);
        builder.Property(u => u.Activo).HasColumnName("Activo");
    }
}
