using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/usuarios")]
public class UsuariosController : ControllerBase
{
    private readonly UsuarioService _service;

    public UsuariosController(UsuarioService service) => _service = service;

    [HttpGet("tecnicos")]
    public async Task<IActionResult> ObtenerTecnicos()
    {
        var tecnicos = await _service.ObtenerTecnicosAsync();
        return Ok(new { tecnicos });
    }
}
