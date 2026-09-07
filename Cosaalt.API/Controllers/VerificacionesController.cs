using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/verificaciones")]
[TypeFilter(typeof(VerificacionExceptionFilter))]
public class VerificacionesController : ControllerBase
{
    private readonly VerificacionService _verificacionService;

    public VerificacionesController(
        VerificacionService verificacionService)
    {
        _verificacionService = verificacionService;
    }

    [HttpGet("solicitudes")]
    public async Task<IActionResult> Solicitudes()
    {
        var result =
            await _verificacionService.ObtenerSolicitudesAsync();

        return Ok(result);
    }

    [HttpPost("tomar")]
    public async Task<IActionResult> Tomar(
        [FromBody] TomarVerificacionRequestDto request)
    {
        var result =
            await _verificacionService.TomarAsync(request);

        return Ok(result);
    }

    [HttpGet("mecanico/{idMecanico}")]
    public async Task<IActionResult> PorMecanico(
        int idMecanico)
    {
        var result =
            await _verificacionService.ObtenerVerificacionesAsync(
                idMecanico);

        return Ok(result);
    }

    [HttpGet("dashboard/{idMecanico}")]
    public async Task<IActionResult> Dashboard(
        int idMecanico)
    {
        var result =
            await _verificacionService.ObtenerDashboardAsync(
                idMecanico);

        return Ok(result);
    }

    [HttpGet("historial/{idMecanico}")]
    public async Task<IActionResult> Historial(
        int idMecanico,
        [FromQuery] DateTime? desde,
        [FromQuery] DateTime? hasta,
        [FromQuery] string? estado,
        [FromQuery] string? resultado,
        [FromQuery] string? buscar,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        var filtro =
            new VerificacionHistorialFiltro(
                desde,
                hasta,
                estado,
                resultado,
                buscar,
                page,
                pageSize);

        var result =
            await _verificacionService.ObtenerHistorialAsync(
                idMecanico,
                filtro);

        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Obtener(
        int id)
    {
        var result =
            await _verificacionService.ObtenerVerificacionAsync(id);

        return result is null
            ? NotFound(new
            {
                codigo = "VERIFICACION_NO_ENCONTRADA",
                mensaje = "No se encontró la verificación solicitada."
            })
            : Ok(result);
    }

    [HttpGet("{id}/datos")]
    public async Task<IActionResult> DatosSocioMedidor(
        int id)
    {
        var result =
            await _verificacionService.ObtenerDatosSocioMedidorAsync(id);

        return result is null
            ? NotFound(new
            {
                codigo = "DATOS_NO_ENCONTRADOS",
                mensaje = "No se encontraron los datos del socio o medidor."
            })
            : Ok(result);
    }

    [HttpPut("{id}/ensayo")]
    public async Task<IActionResult> GuardarEnsayo(
        int id,
        [FromBody] GuardarEnsayoRequestDto request)
    {
        var result =
            await _verificacionService.GuardarEnsayoAsync(
                id,
                request);

        return result.IdEnsayo is null
            ? NotFound(new
            {
                codigo = "VERIFICACION_NO_ENCONTRADA",
                mensaje = "No se encontró la verificación solicitada."
            })
            : Ok(result);
    }

    [HttpPut("{id}/participantes")]
    public async Task<IActionResult> GuardarParticipantes(
        int id,
        [FromBody]
        IReadOnlyList<ParticipanteVerificacionDto> request)
    {
        var result =
            await _verificacionService.GuardarParticipantesAsync(
                id,
                request);

        return result is null
            ? NotFound(new
            {
                codigo = "VERIFICACION_NO_ENCONTRADA",
                mensaje = "No se encontró la verificación solicitada."
            })
            : Ok(result);
    }

    [HttpPost("calcular")]
    public async Task<IActionResult> Calcular(
        [FromBody] GuardarEnsayoRequestDto request)
    {
        var result =
            await _verificacionService.CalcularAsync(request);

        return Ok(result);
    }

    [HttpPost("{id}/finalizar")]
    public async Task<IActionResult> Finalizar(
        int id)
    {
        var result =
            await _verificacionService.FinalizarAsync(id);

        return result is null
            ? NotFound(new
            {
                codigo = "VERIFICACION_NO_ENCONTRADA",
                mensaje = "No se encontró la verificación solicitada."
            })
            : Ok(result);
    }

    [HttpGet("{id}/informes")]
    public async Task<IActionResult> Informes(
        int id)
    {
        var result =
            await _verificacionService.ObtenerInformesAsync(id);

        return Ok(result);
    }

    [HttpPost("{id}/informe")]
    public async Task<IActionResult> GenerarInforme(
        int id,
        [FromBody] GenerarInformeRequestDto? request)
    {
        request ??=
            new GenerarInformeRequestDto(
                null,
                null);

        var result =
            await _verificacionService.GenerarInformeAsync(
                id,
                request);

        return Ok(result);
    }
}
