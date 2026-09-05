namespace Cosaalt.API.Infrastructure.Repositories;

/// <summary>
/// Compatibilidad con versiones anteriores. La bandeja ODECO ahora se construye mediante
/// CosaaltInstitutionalReader y SqlSolicitudRepository usando la estructura auditada de cosaalt.
/// </summary>
[Obsolete("Usar CosaaltInstitutionalReader/SqlSolicitudRepository.")]
internal static class BandejaOdecoBuilder
{
    public const int MaxTop = 5000;
}
