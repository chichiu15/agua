using Cosaalt.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Infrastructure.Context;

public class CosaaltDbContext : DbContext
{
    public CosaaltDbContext(DbContextOptions<CosaaltDbContext> options) : base(options)
    {
    }

    public DbSet<SolicitudLectura> SolicitudesLectura => Set<SolicitudLectura>();
    public DbSet<DetalleSolicitudLectura> DetallesSolicitudLectura => Set<DetalleSolicitudLectura>();
    public DbSet<RolApp> RolesApp => Set<RolApp>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
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
    public DbSet<MedidorDbo> MedidoresDbo => Set<MedidorDbo>();
    public DbSet<CambioMedidorDbo> CambiosMedidoresDbo => Set<CambioMedidorDbo>();
    public DbSet<MarcaDbo> MarcasDbo => Set<MarcaDbo>();
    public DbSet<MotivoCambioMedidorDbo> MotivosCambioMedidorDbo => Set<MotivoCambioMedidorDbo>();
    public DbSet<ClaseMedidor> ClasesMedidores => Set<ClaseMedidor>();
    public DbSet<CategoriaConexion> CategoriasConexiones => Set<CategoriaConexion>();
    public DbSet<TipoConexion> TiposConexiones => Set<TipoConexion>();
    public DbSet<Verificacion> Verificaciones => Set<Verificacion>();
    public DbSet<EnsayoVerificacion> EnsayosVerificacion => Set<EnsayoVerificacion>();
    public DbSet<ParticipanteVerificacion> ParticipantesVerificacion => Set<ParticipanteVerificacion>();
    public DbSet<InformeVerificacion> InformesVerificacion => Set<InformeVerificacion>();
    public DbSet<ParametroNormativo> ParametrosNormativos => Set<ParametroNormativo>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CosaaltDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
