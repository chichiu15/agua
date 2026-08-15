using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/solicitudes")]
public class SolicitudesController : ControllerBase
{
    private readonly SolicitudService _solicitudService;

    public SolicitudesController(SolicitudService solicitudService) => _solicitudService = solicitudService;

    [HttpGet]
    public async Task<IActionResult> ObtenerSolicitudes([FromQuery] string? filtro)
    {
        var result = await _solicitudService.ObtenerSolicitudesAsync(filtro);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObtenerPorId(string id)
    {
        var result = await _solicitudService.ObtenerPorIdAsync(id);
        if (result is null)
            return NotFound(new { mensaje = "Solicitud no encontrada." });

        return Ok(result);
    }
}
