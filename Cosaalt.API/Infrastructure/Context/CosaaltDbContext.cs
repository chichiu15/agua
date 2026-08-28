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
    public DbSet<Conexion> Conexiones => Set<Conexion>();
    public DbSet<Predio> Predios => Set<Predio>();
    public DbSet<Recurrente> Recurrentes => Set<Recurrente>();
    public DbSet<Reclamo> Reclamos => Set<Reclamo>();
    public DbSet<Barrio> Barrios => Set<Barrio>();
    public DbSet<Calle> Calles => Set<Calle>();
    public DbSet<Zona> Zonas => Set<Zona>();
    public DbSet<Funcionario> Funcionarios => Set<Funcionario>();
    public DbSet<Persona> Personas => Set<Persona>();
    public DbSet<ClaseMedidor> ClasesMedidores => Set<ClaseMedidor>();
    public DbSet<CategoriaConexion> CategoriasConexiones => Set<CategoriaConexion>();
    public DbSet<TipoConexion> TiposConexiones => Set<TipoConexion>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CosaaltDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }

    public async Task EnsureSchemasAsync()
    {
        await Database.ExecuteSqlRawAsync("IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'medidores') EXEC('CREATE SCHEMA medidores')");
    }
}
