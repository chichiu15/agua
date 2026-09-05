namespace Cosaalt.API.Infrastructure.Repositories;

/// <summary>
/// Compatibilidad con versiones anteriores. La persistencia de cambios ahora se realiza
/// exclusivamente en SqlEjecucionRepository sobre medidores.EjecucionCambio.
/// No se escribe directamente en tablas dbo institucionales.
/// </summary>
[Obsolete("Usar IEjecucionRepository/SqlEjecucionRepository.")]
internal static class CambioMedidorPersistence
{
}
