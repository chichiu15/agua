using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/rutas")]
public class RutasController : ControllerBase
{
    private readonly RutaService _service;

    public RutasController(RutaService service) => _service = service;

    [HttpPost("asignar")]
    public async Task<IActionResult> Asignar([FromBody] AsignarRutaRequestDto request)
    {
        var result = await _service.AsignarAsync(request);
        return Created($"/api/rutas/{result.IdAsignacion}", result);
    }

    [HttpGet("tecnico/{idTecnico:int}")]
    public async Task<IActionResult> ObtenerPorTecnico(int idTecnico, [FromQuery] DateTime? fecha)
    {
        var result = await _service.ObtenerPorTecnicoAsync(idTecnico, fecha);
        return Ok(result);
    }

    [HttpGet("{idAsignacion:int}")]
    public async Task<IActionResult> ObtenerPorId(int idAsignacion)
    {
        var result = await _service.ObtenerPorIdAsync(idAsignacion);
        if (result is null) return NotFound();
        return Ok(result);
    }
}
