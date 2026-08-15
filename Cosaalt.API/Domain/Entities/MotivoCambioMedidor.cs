namespace Cosaalt.API.Domain.Entities;

public class MotivoCambioMedidor
{
    public int Id { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    public bool Activo { get; set; } = true;

    public ICollection<EjecucionCambio> Ejecuciones { get; set; } = [];
}
