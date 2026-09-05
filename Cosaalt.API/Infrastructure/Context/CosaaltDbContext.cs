using Cosaalt.API.Domain.Entities;
using Cosaalt.API.Infrastructure.Configurations;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Context;

/// <summary>
/// Contexto EF del esquema propio de la aplicacion. No mapea tablas dbo institucionales.
/// Las tablas dbo se consultan mediante CosaaltInstitutionalReader para evitar acoplar
/// el modelo nuevo a estructuras historicas que no pertenecen a la aplicacion.
/// </summary>
public class CosaaltDbContext : DbContext
{
    public CosaaltDbContext(DbContextOptions<CosaaltDbContext> options) : base(options) { }

    public DbSet<RolApp> RolesApp => Set<RolApp>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<ParametroNormativo> ParametrosNormativos => Set<ParametroNormativo>();
    public DbSet<AsignacionRuta> AsignacionesRuta => Set<AsignacionRuta>();
    public DbSet<DetalleRuta> DetallesRuta => Set<DetalleRuta>();
    public DbSet<EjecucionCambio> EjecucionesCambio => Set<EjecucionCambio>();
    public DbSet<EvidenciaFotografica> EvidenciasFotograficas => Set<EvidenciaFotografica>();
    public DbSet<Verificacion> Verificaciones => Set<Verificacion>();
    public DbSet<EnsayoVerificacion> EnsayosVerificacion => Set<EnsayoVerificacion>();
    public DbSet<ParticipanteVerificacion> ParticipantesVerificacion => Set<ParticipanteVerificacion>();
    public DbSet<InformeVerificacion> InformesVerificacion => Set<InformeVerificacion>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new RolAppConfiguration());
        modelBuilder.ApplyConfiguration(new UsuarioConfiguration());
        modelBuilder.ApplyConfiguration(new ParametroNormativoConfiguration());
        modelBuilder.ApplyConfiguration(new AsignacionRutaConfiguration());
        modelBuilder.ApplyConfiguration(new DetalleRutaConfiguration());
        modelBuilder.ApplyConfiguration(new EjecucionCambioConfiguration());
        modelBuilder.ApplyConfiguration(new EvidenciaFotograficaConfiguration());
        modelBuilder.ApplyConfiguration(new VerificacionConfiguration());
        modelBuilder.ApplyConfiguration(new EnsayoVerificacionConfiguration());
        modelBuilder.ApplyConfiguration(new ParticipanteVerificacionConfiguration());
        modelBuilder.ApplyConfiguration(new InformeVerificacionConfiguration());
        base.OnModelCreating(modelBuilder);
    }
}
