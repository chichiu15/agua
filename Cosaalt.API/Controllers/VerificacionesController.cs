using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/verificaciones")]
public class VerificacionesController : ControllerBase
{
    private readonly VerificacionService _verificacionService;

    public VerificacionesController(VerificacionService verificacionService) => _verificacionService = verificacionService;

    [HttpGet("solicitudes")]
    public async Task<IActionResult> Solicitudes()
    {
        var result = await _verificacionService.ObtenerSolicitudesAsync();
        return Ok(result);
    }

    [HttpPost("tomar")]
    public async Task<IActionResult> Tomar([FromBody] TomarVerificacionRequestDto request)
    {
        try
        {
            var result = await _verificacionService.TomarAsync(request);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { mensaje = ex.Message });
        }
    }

    [HttpGet("mecanico/{idMecanico}")]
    public async Task<IActionResult> PorMecanico(int idMecanico)
    {
        var result = await _verificacionService.ObtenerVerificacionesAsync(idMecanico);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Obtener(int id)
    {
        var result = await _verificacionService.ObtenerVerificacionAsync(id);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpGet("{id}/datos")]
    public async Task<IActionResult> DatosSocioMedidor(int id)
    {
        var result = await _verificacionService.ObtenerDatosSocioMedidorAsync(id);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpPut("{id}/ensayo")]
    public async Task<IActionResult> GuardarEnsayo(int id, [FromBody] GuardarEnsayoRequestDto request)
    {
        var result = await _verificacionService.GuardarEnsayoAsync(id, request);
        return result.IdEnsayo is null ? NotFound() : Ok(result);
    }
}
