namespace Cosaalt.API.Infrastructure.Repositories;

/// <summary>
/// Clase conservada solo para que instalaciones anteriores puedan ser reemplazadas sin dejar
/// codigo obsoleto que dependa de tablas inexistentes. Ya no se registra ni se utiliza.
/// </summary>
[Obsolete("Usar ISolicitudRepository/SqlSolicitudRepository.")]
public sealed class SolicitudVirtualService
{
}
