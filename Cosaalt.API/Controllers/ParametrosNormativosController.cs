using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/parametros-normativos")]
public class ParametrosNormativosController : ControllerBase
{
    private readonly ParametroNormativoService _service;

    public ParametrosNormativosController(ParametroNormativoService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> ObtenerTodos()
    {
        var parametros = await _service.ObtenerTodosAsync();
        return Ok(new { parametros });
    }

    [HttpGet("vigente")]
    public async Task<IActionResult> ObtenerVigente([FromQuery] decimal caudal, [FromQuery] DateTime? fecha = null)
    {
        var parametro = await _service.ObtenerVigenteAsync(caudal, fecha);
        return parametro is null
            ? NotFound(new { mensaje = "No existe un parametro normativo vigente para el caudal y fecha indicados." })
            : Ok(parametro);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObtenerPorId(int id)
    {
        var parametro = await _service.ObtenerPorIdAsync(id);
        return parametro is null ? NotFound() : Ok(parametro);
    }

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] GuardarParametroNormativoRequestDto request)
    {
        try
        {
            var parametro = await _service.CrearAsync(request);
            return CreatedAtAction(nameof(ObtenerPorId), new { id = parametro.Id }, parametro);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { mensaje = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Actualizar(int id, [FromBody] GuardarParametroNormativoRequestDto request)
    {
        try
        {
            var parametro = await _service.ActualizarAsync(id, request);
            return parametro is null ? NotFound() : Ok(parametro);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { mensaje = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPatch("{id:int}/estado")]
    public async Task<IActionResult> CambiarEstado(int id, [FromBody] CambiarEstadoParametroRequestDto request)
    {
        var parametro = await _service.CambiarEstadoAsync(id, request.Activo);
        return parametro is null ? NotFound() : Ok(parametro);
    }
}
