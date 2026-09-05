using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class UsuarioConfiguration : IEntityTypeConfiguration<Usuario>
{
    public void Configure(EntityTypeBuilder<Usuario> builder)
    {
        builder.ToTable("Usuarios", "medidores");
        builder.HasKey(u => u.Id);
        builder.Property(u => u.Id).HasColumnName("Id");
        builder.Property(u => u.CodPersonaCorporativa).HasColumnName("CodPersonaCorporativa").HasConversion<decimal?>().HasPrecision(18, 0);
        builder.Property(u => u.NombreUsuario).HasColumnName("NombreUsuario").HasMaxLength(50).IsRequired();
        builder.Property(u => u.HashPassword).HasColumnName("HashPassword").HasMaxLength(255).IsRequired();
        builder.Property(u => u.IdRol).HasColumnName("IdRol");
        builder.Property(u => u.Activo).HasColumnName("Activo");
        builder.Property(u => u.FechaCreacion).HasColumnName("FechaCreacion");
        builder.Property(u => u.FechaActualizacion).HasColumnName("FechaActualizacion");

        builder.HasOne(u => u.Rol)
            .WithMany(r => r.Usuarios)
            .HasForeignKey(u => u.IdRol)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
