namespace Cosaalt.API.Infrastructure.Repositories;

/// <summary>
/// Compatibilidad con versiones anteriores. El medidor vigente se resuelve desde dbo.Medidor
/// a traves de CosaaltInstitutionalReader; no se usa dbo.CambioMedidores.
/// </summary>
[Obsolete("Usar CosaaltInstitutionalReader.")]
public static class MedidorVigenteResolver
{
}
