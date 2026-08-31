using Cosaalt.API.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/admin/dashboard")]
public class DashboardController : ControllerBase
{
    private readonly AdminService _service;
    public DashboardController(AdminService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> Obtener([FromQuery] DateTime? desde = null, [FromQuery] DateTime? hasta = null)
        => Ok(await _service.ObtenerDashboardAsync(desde, hasta));
}
