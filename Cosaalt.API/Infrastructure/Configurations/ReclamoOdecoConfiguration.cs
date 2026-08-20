using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cosaalt.API.Infrastructure.Configurations;

public class ReclamoOdecoConfiguration : IEntityTypeConfiguration<ReclamoOdeco>
{
    public void Configure(EntityTypeBuilder<ReclamoOdeco> builder)
    {
        builder.ToTable("ReclamoODECO");
        builder.HasKey(r => r.Folio);
        builder.Property(r => r.Folio).HasColumnName("Folio_odeco").ValueGeneratedNever();
        builder.Property(r => r.FechaReclamo).HasColumnName("Fecha_rec_odeco");
        builder.Property(r => r.RegistroSocio).HasColumnName("Reg_soc");
        builder.Property(r => r.NombreSolicitante).HasColumnName("Nombre_sol_odeco").HasMaxLength(200);
        builder.Property(r => r.CiSolicitante).HasColumnName("CI_sol_odeco").HasMaxLength(20);
        builder.Property(r => r.TelefonoSolicitante).HasColumnName("Telf_sol__odeco").HasMaxLength(30);
        builder.Property(r => r.TipoVisita).HasColumnName("Tipo_visita_odeco").HasMaxLength(50);
        builder.Property(r => r.MotivoReclamo).HasColumnName("Motivo_rec__odeco").HasMaxLength(200);
        builder.Property(r => r.FechaEstimadaRespuesta).HasColumnName("Fecha_est_resp_odeco");
        builder.Property(r => r.RespuestaAtencion).HasColumnName("Resp_atc_odeco").HasMaxLength(500);
        builder.Property(r => r.LecturaAnteriorAnalisis).HasColumnName("Lect_ant_anali_odeco");
        builder.Property(r => r.LecturaActualAnalisis).HasColumnName("Lect_act_anali_odeco");
        builder.Property(r => r.ConsumoAnalisis).HasColumnName("Consumo_anali_odeco");
        builder.Property(r => r.Grifos).HasColumnName("Grifos_odeco").HasMaxLength(100);
        builder.Property(r => r.LlavePaso).HasColumnName("Llave_paso_odeco").HasMaxLength(100);
        builder.Property(r => r.MedidorParado).HasColumnName("Medidor_parado_odeco");
        builder.Property(r => r.Inspeccion).HasColumnName("Inspección_odeco").HasMaxLength(500);
        builder.Property(r => r.Diagnostico).HasColumnName("Diagnostico_odeco").HasMaxLength(500);
        builder.Property(r => r.Comentarios).HasColumnName("Comentarios_odeco").HasMaxLength(1000);
        builder.Property(r => r.TipoReclamo).HasColumnName("Tipo_reclamo_odeco").HasMaxLength(100);
        builder.Property(r => r.FechaInspeccion).HasColumnName("Fecha_inspeccion_odeco");
        builder.Property(r => r.Conclusion).HasColumnName("Conclusion_odeco").HasMaxLength(200);
        builder.Property(r => r.PrioridadNota).HasColumnName("Prioridad_nota_odeco").HasMaxLength(50);

        builder.HasOne(r => r.Socio)
            .WithMany(s => s.ReclamosOdeco)
            .HasForeignKey(r => r.RegistroSocio);
    }
}