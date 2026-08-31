using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/solicitudes")]
public class SolicitudesController : ControllerBase
{
    private readonly SolicitudService _service;

    public SolicitudesController(SolicitudService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> ObtenerSolicitudes([FromQuery] string? filtro)
    {
        var result = await _service.ObtenerSolicitudesAsync(filtro);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObtenerPorId(string id)
    {
        var solicitud = await _service.ObtenerPorIdAsync(id);
        if (solicitud is null)
            return NotFound(new { mensaje = "Solicitud no encontrada." });

        return Ok(solicitud);
    }
}
