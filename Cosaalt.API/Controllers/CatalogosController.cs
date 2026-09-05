using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Cosaalt.API.Infrastructure.Repositories;
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
            return BadRequest(new { mensaje = ex.Message });
        }
        catch (IntegrationPendingException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { codigo = "INTEGRACION_PENDIENTE", mensaje = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { mensaje = ex.Message });
        }
    }

    [HttpPut("motivos/{id:int}")]
    public async Task<IActionResult> ActualizarMotivo(int id, [FromBody] GuardarMotivoCambioRequestDto request)
    {
        try
        {
            var result = await _catalogoService.ActualizarMotivoAsync(id, request);
            return result is null ? NotFound(new { mensaje = "No se encontro el motivo indicado." }) : Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
        catch (IntegrationPendingException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { codigo = "INTEGRACION_PENDIENTE", mensaje = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { mensaje = ex.Message });
        }
    }

    [HttpPatch("motivos/{id:int}/estado")]
    public async Task<IActionResult> CambiarEstadoMotivo(int id, [FromBody] CambiarEstadoMotivoRequestDto request)
    {
        var result = await _catalogoService.CambiarEstadoMotivoAsync(id, request.Activo);
        return result is null ? NotFound(new { mensaje = "No se encontro el motivo indicado." }) : Ok(result);
    }

    [HttpGet("marcas")]
    public async Task<IActionResult> ObtenerMarcas([FromQuery] bool incluirInactivos = true)
        => Ok(await _catalogoService.ObtenerMarcasAsync(incluirInactivos));

    [HttpPost("marcas")]
    public async Task<IActionResult> CrearMarca([FromBody] GuardarMarcaMedidorRequestDto request)
    {
        try
        {
            var result = await _catalogoService.CrearMarcaAsync(request);
            return CreatedAtAction(nameof(ObtenerMarcas), new { incluirInactivos = true }, result);
        }
        catch (ArgumentException ex) { return BadRequest(new { mensaje = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { mensaje = ex.Message }); }
    }

    [HttpPut("marcas/{id:int}")]
    public async Task<IActionResult> ActualizarMarca(int id, [FromBody] GuardarMarcaMedidorRequestDto request)
    {
        try
        {
            var result = await _catalogoService.ActualizarMarcaAsync(id, request);
            return result is null ? NotFound(new { mensaje = "No se encontro la marca indicada." }) : Ok(result);
        }
        catch (ArgumentException ex) { return BadRequest(new { mensaje = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { mensaje = ex.Message }); }
    }

    [HttpPatch("marcas/{id:int}/estado")]
    public async Task<IActionResult> CambiarEstadoMarca(int id, [FromBody] CambiarEstadoMotivoRequestDto request)
    {
        var result = await _catalogoService.CambiarEstadoMarcaAsync(id, request.Activo);
        return result is null ? NotFound(new { mensaje = "No se encontro la marca indicada." }) : Ok(result);
    }

    [HttpGet("medidores-disponibles")]
    public async Task<IActionResult> ObtenerMedidoresDisponibles([FromQuery] string? buscar = null, [FromQuery] int limite = 100)
        => Ok(new { medidores = await _catalogoService.ObtenerMedidoresDisponiblesAsync(buscar, limite) });
}
