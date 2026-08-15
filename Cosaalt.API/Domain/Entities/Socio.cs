namespace Cosaalt.API.Domain.Entities;

public class Socio
{
    public int RegistroSocio { get; set; }
    public string? CodigoCatastral { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Direccion { get; set; } = string.Empty;
    public string? Categoria { get; set; }
    public string? Ruta { get; set; }
    public int? Recorrido { get; set; }
    public string? Ci { get; set; }
    public string? Telefono { get; set; }
    public string? Sexo { get; set; }

    // NOTA: Latitud/Longitud se movieron a Medidor, porque un socio puede
    // tener más de un medidor a su nombre (y cada medidor tiene su propia
    // ubicación física real). Se mantiene la relación 1:1 Socio-Medidor
    // que ya tenías (no se amplía el alcance a 1:N en este cambio); si en
    // el futuro un socio necesita varios medidores, ahí sí conviene migrar
    // esta relación a colección.
    public Medidor? Medidor { get; set; }
    public ICollection<DetalleSolicitudLectura> DetallesLectura { get; set; } = [];
    public ICollection<ReclamoOdeco> ReclamosOdeco { get; set; } = [];
}
