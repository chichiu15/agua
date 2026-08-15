namespace Cosaalt.API.Domain.Entities;

public class DetalleRuta
{
    public int Id { get; set; }
    public int IdAsignacion { get; set; }
    public string TipoOrigen { get; set; } = string.Empty;   // ODECO o LECTURA
    public string IdOrigen { get; set; } = string.Empty;     // Folio o Id de detalle de lectura
    public int OrdenVisita { get; set; }
    public string Estado { get; set; } = "Pendiente";

    // --- Snapshot de datos del cliente al momento de armar la ruta ---
    // Se copian aquí (en vez de solo referenciar) para que el celular pueda
    // mostrar toda la parada sin depender de conexión ni de otro join.
    public string SolicitudId { get; set; } = string.Empty;  // ej "ODECO-1042" / "LEC-201"
    public string NombreCliente { get; set; } = string.Empty;
    public string Direccion { get; set; } = string.Empty;
    public double? Latitud { get; set; }
    public double? Longitud { get; set; }

    public AsignacionRuta Asignacion { get; set; } = null!;
}
