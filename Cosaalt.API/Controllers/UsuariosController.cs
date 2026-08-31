using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/usuarios")]
public class UsuariosController : ControllerBase
{
    private readonly UsuarioService _service;

    public UsuariosController(UsuarioService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> ObtenerUsuarios()
    {
        var usuarios = await _service.ObtenerUsuariosAsync();
        return Ok(new { usuarios });
    }

    [HttpGet("tecnicos")]
    public async Task<IActionResult> ObtenerTecnicos()
    {
        var tecnicos = await _service.ObtenerTecnicosAsync();
        return Ok(new { tecnicos });
    }

    [HttpGet("funcionarios")]
    public async Task<IActionResult> ObtenerFuncionarios()
    {
        var funcionarios = await _service.ObtenerFuncionariosAsync();
        return Ok(new { funcionarios });
    }

    [HttpGet("roles")]
    public async Task<IActionResult> ObtenerRoles()
    {
        var roles = await _service.ObtenerRolesAsync();
        return Ok(new { roles });
    }

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] CrearUsuarioRequestDto request)
    {
        try
        {
            var usuario = await _service.CrearAsync(request);
            return CreatedAtAction(nameof(ObtenerUsuarios), new { id = usuario.Id }, usuario);
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
    public async Task<IActionResult> Actualizar(int id, [FromBody] ActualizarUsuarioRequestDto request)
    {
        try
        {
            var usuario = await _service.ActualizarAsync(id, request);
            return usuario is null ? NotFound() : Ok(usuario);
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
}
