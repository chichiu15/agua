using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/admin")]
public class AdminSupervisionController : ControllerBase
{
    private readonly AdminService _service;
    public AdminSupervisionController(AdminService service) => _service = service;

    [HttpGet("solicitudes")]
    public async Task<IActionResult> Solicitudes(
        [FromQuery] DateTime? desde = null,
        [FromQuery] DateTime? hasta = null,
        [FromQuery] string? origen = null,
        [FromQuery] string? estado = null,
        [FromQuery] string? prioridad = null,
        [FromQuery] int? tecnicoId = null,
        [FromQuery] string? buscar = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25)
        => Ok(await _service.ObtenerSolicitudesAsync(new AdminSolicitudFiltro(
            desde, hasta, origen, estado, prioridad, tecnicoId, buscar, page, pageSize)));

    [HttpGet("rutas")]
    public async Task<IActionResult> Rutas(
        [FromQuery] DateTime? fecha = null,
        [FromQuery] int? tecnicoId = null,
        [FromQuery] string? estado = null,
        [FromQuery] string? buscar = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
        => Ok(await _service.ObtenerRutasAsync(new AdminRutaFiltro(fecha, tecnicoId, estado, buscar, page, pageSize)));

    [HttpGet("rutas/{id:int}")]
    public async Task<IActionResult> Ruta(int id)
    {
        var ruta = await _service.ObtenerRutaAsync(id);
        return ruta is null ? NotFound(new { mensaje = "Ruta no encontrada." }) : Ok(ruta);
    }

    [HttpGet("sincronizacion")]
    public async Task<IActionResult> Sincronizacion([FromQuery] DateTime? fecha = null)
        => Ok(new { tecnicos = await _service.ObtenerSincronizacionAsync(fecha) });

    [HttpGet("verificaciones")]
    public async Task<IActionResult> Verificaciones(
        [FromQuery] DateTime? desde = null,
        [FromQuery] DateTime? hasta = null,
        [FromQuery] int? mecanicoId = null,
        [FromQuery] string? estado = null,
        [FromQuery] string? resultado = null,
        [FromQuery] string? buscar = null,
        [FromQuery] bool? soloConInforme = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25)
        => Ok(await _service.ObtenerVerificacionesAsync(new AdminVerificacionFiltro(
            desde, hasta, mecanicoId, estado, resultado, buscar, soloConInforme, page, pageSize)));

    [HttpGet("verificaciones/{id:int}")]
    public async Task<IActionResult> Verificacion(int id)
    {
        var item = await _service.ObtenerVerificacionDetalleAsync(id);
        return item is null ? NotFound(new { mensaje = "Verificacion no encontrada." }) : Ok(item);
    }
}
