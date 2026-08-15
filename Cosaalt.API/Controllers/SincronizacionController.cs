using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/sincronizacion")]
public class SincronizacionController : ControllerBase
{
    private readonly SincronizacionService _service;

    public SincronizacionController(SincronizacionService service) => _service = service;

    [HttpPost("procesar-cambios")]
    public async Task<IActionResult> ProcesarCambios([FromBody] SincronizacionRequestDto request)
    {
        var result = await _service.ProcesarCambiosAsync(request);
        return Ok(result);
    }
}
