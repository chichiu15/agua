using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/catalogos")]
public class CatalogosController : ControllerBase
{
    private readonly CatalogoService _catalogoService;

    public CatalogosController(CatalogoService catalogoService) => _catalogoService = catalogoService;

    // Uso operativo (tecnico/asignador): por defecto solo devuelve motivos activos.
    // Administracion puede solicitar tambien los inactivos para gestionarlos.
    [HttpGet("motivos")]
    public async Task<IActionResult> ObtenerMotivos([FromQuery] bool incluirInactivos = false)
        => Ok(await _catalogoService.ObtenerMotivosAsync(incluirInactivos));

    [HttpPost("motivos")]
    public async Task<IActionResult> CrearMotivo([FromBody] GuardarMotivoCambioRequestDto request)
    {
        try
        {
            var result = await _catalogoService.CrearMotivoAsync(request);
            return CreatedAtAction(nameof(ObtenerMotivos), new { incluirInactivos = true }, result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPut("motivos/{id:int}")]
    public async Task<IActionResult> ActualizarMotivo(int id, [FromBody] GuardarMotivoCambioRequestDto request)
    {
        try
        {
            var result = await _catalogoService.ActualizarMotivoAsync(id, request);
            return result is null ? NotFound(new { message = "No se encontro el motivo indicado." }) : Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPatch("motivos/{id:int}/estado")]
    public async Task<IActionResult> CambiarEstadoMotivo(int id, [FromBody] CambiarEstadoMotivoRequestDto request)
    {
        var result = await _catalogoService.CambiarEstadoMotivoAsync(id, request.Activo);
        return result is null ? NotFound(new { message = "No se encontro el motivo indicado." }) : Ok(result);
    }

    [HttpGet("marcas")]
    public async Task<IActionResult> ObtenerMarcas()
        => Ok(await _catalogoService.ObtenerMarcasAsync());
}
