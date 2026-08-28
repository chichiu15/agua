using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class ConexionConfiguration : IEntityTypeConfiguration<Conexion>
{
    public void Configure(EntityTypeBuilder<Conexion> builder)
    {
        builder.ToTable("Conexiones", "dbo");
        builder.HasKey(c => c.CodCon);
        builder.Property(c => c.CodCon).HasColumnName("CodCon");
        builder.Property(c => c.FecCon).HasColumnName("FecCon");
        builder.Property(c => c.ObsCon).HasColumnName("ObsCon").HasMaxLength(500);
        builder.Property(c => c.CooX2Con).HasColumnName("CooX2Con");
        builder.Property(c => c.CooY2Con).HasColumnName("CooY2Con");
        builder.Property(c => c.CooZ2Con).HasColumnName("CooZ2Con");
        builder.Property(c => c.TipCon).HasColumnName("TipCon");
        builder.Property(c => c.CanPerCon).HasColumnName("CanPerCon");
        builder.Property(c => c.CanFamCon).HasColumnName("CanFamCon");
        builder.Property(c => c.NomSoc).HasColumnName("NomSoc").HasMaxLength(100);
        builder.Property(c => c.CodUbiSoc).HasColumnName("CodUbiSoc").HasMaxLength(15);
        builder.Property(c => c.DnuSoc).HasColumnName("DnuSoc").HasMaxLength(100);
        builder.Property(c => c.NumDoc).HasColumnName("NumDoc").HasMaxLength(15);
        builder.Property(c => c.TipDoc).HasColumnName("Tip_Doc").HasMaxLength(4);
        builder.Property(c => c.RucSoc).HasColumnName("Ruc_Soc").HasMaxLength(15);
        builder.Property(c => c.CodPre).HasColumnName("CodPre");

        builder.HasOne(c => c.Predio)
            .WithMany(p => p.Conexiones)
            .HasForeignKey(c => c.CodPre);
    }
}
