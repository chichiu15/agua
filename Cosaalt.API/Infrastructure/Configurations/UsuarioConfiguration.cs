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
        builder.Property(u => u.CodFunCorporativo).HasColumnName("CodFunCorporativo").HasConversion(NumericConversions.NullableIntToDecimal);
        builder.Property(u => u.NombreUsuario).HasColumnName("NombreUsuario").HasMaxLength(50);
        builder.Property(u => u.HashPassword).HasColumnName("HashPassword").HasMaxLength(200);
        builder.Property(u => u.IdRol).HasColumnName("IdRol");
        builder.Property(u => u.Activo).HasColumnName("Activo");
        builder.Property(u => u.FechaCreacion).HasColumnName("FechaCreacion");

        // NombreCompleto es computado (Funcionario→Persona), no una columna.
        builder.Ignore(u => u.NombreCompleto);

        builder.HasOne(u => u.Rol)
            .WithMany(r => r.Usuarios)
            .HasForeignKey(u => u.IdRol);

        // dbo.Funcionarios se lee, nunca se escribe.
        builder.HasOne(u => u.Funcionario)
            .WithMany()
            .HasForeignKey(u => u.CodFunCorporativo)
            .IsRequired(false);
    }
}