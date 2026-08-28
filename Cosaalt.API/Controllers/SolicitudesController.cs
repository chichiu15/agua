using Cosaalt.API.Application.Services;
using Cosaalt.API.Infrastructure.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/solicitudes")]
public class SolicitudesController : ControllerBase
{
    private readonly SolicitudVirtualService _virtualService;

    public SolicitudesController(SolicitudVirtualService virtualService) => _virtualService = virtualService;

    [HttpGet]
    public async Task<IActionResult> ObtenerSolicitudes([FromQuery] string? filtro)
    {
        var result = await _virtualService.ObtenerSolicitudesOdecoAsync(filtro);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObtenerPorId(string id)
    {
        var result = await _virtualService.ObtenerSolicitudesOdecoAsync();
        var solicitud = result.Solicitudes.FirstOrDefault(s => s.Id == id);
        if (solicitud is null)
            return NotFound(new { mensaje = "Solicitud no encontrada." });

        return Ok(solicitud);
    }
}
