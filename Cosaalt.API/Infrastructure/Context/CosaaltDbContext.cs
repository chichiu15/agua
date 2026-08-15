using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Context;

public class CosaaltDbContext : DbContext
{
    public CosaaltDbContext(DbContextOptions<CosaaltDbContext> options) : base(options)
    {
    }

    public DbSet<Socio> Socios => Set<Socio>();
    public DbSet<Medidor> Medidores => Set<Medidor>();
    public DbSet<SolicitudLectura> SolicitudesLectura => Set<SolicitudLectura>();
    public DbSet<DetalleSolicitudLectura> DetallesSolicitudLectura => Set<DetalleSolicitudLectura>();
    public DbSet<ReclamoOdeco> ReclamosOdeco => Set<ReclamoOdeco>();
    public DbSet<UsuarioApp> UsuariosApp => Set<UsuarioApp>();
    public DbSet<MotivoCambioMedidor> MotivosCambio => Set<MotivoCambioMedidor>();
    public DbSet<EjecucionCambio> EjecucionesCambio => Set<EjecucionCambio>();
    public DbSet<AsignacionRuta> AsignacionesRuta => Set<AsignacionRuta>();
    public DbSet<DetalleRuta> DetallesRuta => Set<DetalleRuta>();
    public DbSet<EvidenciaFotografica> EvidenciasFotograficas => Set<EvidenciaFotografica>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CosaaltDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
