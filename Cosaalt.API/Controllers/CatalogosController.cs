using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/catalogos")]
public class CatalogosController : ControllerBase
{
    private readonly CatalogoService _catalogoService;

    public CatalogosController(CatalogoService catalogoService) => _catalogoService = catalogoService;

    [HttpGet("motivos")]
    public async Task<IActionResult> ObtenerMotivos()
    {
        var result = await _catalogoService.ObtenerMotivosAsync();
        return Ok(result);
    }

    [HttpGet("marcas")]
    public async Task<IActionResult> ObtenerMarcas()
    {
        var result = await _catalogoService.ObtenerMarcasAsync();
        return Ok(result);
    }
}
