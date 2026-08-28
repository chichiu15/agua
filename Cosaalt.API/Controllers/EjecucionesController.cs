using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/ejecuciones")]
public class EjecucionesController : ControllerBase
{
    private readonly EjecucionService _ejecucionService;

    public EjecucionesController(EjecucionService ejecucionService) => _ejecucionService = ejecucionService;

    [HttpPost]
    public async Task<IActionResult> Registrar([FromBody] EjecucionCambioRequestDto request)
    {
        var result = await _ejecucionService.RegistrarAsync(request);
        return Created($"/api/ejecuciones/{result.Id}", result);
    }

    [HttpGet("historial")]
    public async Task<IActionResult> Historial([FromQuery] int? registroSocio = null)
    {
        var result = await _ejecucionService.ObtenerHistorialAsync(registroSocio);
        return Ok(result);
    }
}
