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

    // Un socio puede haber tenido varios medidores a lo largo del tiempo.
    // En condiciones normales solo uno debe permanecer con Estado = "Activo".
    public ICollection<Medidor> Medidores { get; set; } = [];

    public ICollection<DetalleSolicitudLectura> DetallesLectura { get; set; } = [];
    public ICollection<ReclamoOdeco> ReclamosOdeco { get; set; } = [];
}
