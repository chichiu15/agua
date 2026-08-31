using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Application.Services;
using Cosaalt.API.Infrastructure.Exporting;
using Cosaalt.API.Infrastructure.Context;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Cosaalt.API.Controllers;

[ApiController]
[Route("api/reportes")]
public class ReportesController : ControllerBase
{
    private readonly AdminService _service;
    private readonly IWebHostEnvironment _environment;

    public ReportesController(AdminService service, IWebHostEnvironment environment)
    {
        _service = service;
        _environment = environment;
    }

    [HttpGet("movimientos")]
    public async Task<IActionResult> Movimientos(
        [FromQuery] DateTime? desde = null,
        [FromQuery] DateTime? hasta = null,
        [FromQuery] int? tecnicoId = null,
        [FromQuery] int? motivoId = null,
        [FromQuery] string? origen = null,
        [FromQuery] string? marca = null,
        [FromQuery] bool? sincronizado = null,
        [FromQuery] string? buscar = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25)
        => Ok(await _service.ObtenerMovimientosAsync(new AdminMovimientoFiltro(
            desde, hasta, tecnicoId, motivoId, origen, marca, sincronizado, buscar, page, pageSize)));

    [HttpGet("movimientos/excel")]
    public async Task<IActionResult> MovimientosExcel(
        [FromQuery] DateTime? desde = null,
        [FromQuery] DateTime? hasta = null,
        [FromQuery] int? tecnicoId = null,
        [FromQuery] int? motivoId = null,
        [FromQuery] string? origen = null,
        [FromQuery] string? marca = null,
        [FromQuery] bool? sincronizado = null,
        [FromQuery] string? buscar = null)
    {
        var items = await _service.ObtenerMovimientosExportAsync(new AdminMovimientoFiltro(
            desde, hasta, tecnicoId, motivoId, origen, marca, sincronizado, buscar));
        var bytes = AdminExportBuilder.MovimientosExcel(items);
        return File(bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"movimiento_medidores_{DateTime.Now:yyyyMMdd_HHmm}.xlsx");
    }

    [HttpGet("movimientos/pdf")]
    public async Task<IActionResult> MovimientosPdf(
        [FromQuery] DateTime? desde = null,
        [FromQuery] DateTime? hasta = null,
        [FromQuery] int? tecnicoId = null,
        [FromQuery] int? motivoId = null,
        [FromQuery] string? origen = null,
        [FromQuery] string? marca = null,
        [FromQuery] bool? sincronizado = null,
        [FromQuery] string? buscar = null)
    {
        var items = await _service.ObtenerMovimientosExportAsync(new AdminMovimientoFiltro(
            desde, hasta, tecnicoId, motivoId, origen, marca, sincronizado, buscar));
        var periodo = $"Movimiento de Medidores - {(desde?.ToString("dd/MM/yyyy") ?? "inicio")} a {(hasta?.ToString("dd/MM/yyyy") ?? "hoy")}";
        var bytes = AdminExportBuilder.MovimientosPdf(items, periodo);
        return File(bytes, "application/pdf", $"movimiento_medidores_{DateTime.Now:yyyyMMdd_HHmm}.pdf");
    }

    [HttpGet("historico-corporativo")]
    public async Task<IActionResult> HistoricoCorporativo(
        [FromQuery] int? codCon = null,
        [FromQuery] bool? vigente = null,
        [FromQuery] int? motivoId = null,
        [FromQuery] string? marca = null,
        [FromQuery] string? buscar = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25)
        => Ok(await _service.ObtenerHistoricoCorporativoAsync(new AdminMovimientoCorporativoFiltro(
            codCon, vigente, motivoId, marca, buscar, page, pageSize)));

    [HttpGet("historico-corporativo/excel")]
    public async Task<IActionResult> HistoricoCorporativoExcel(
        [FromQuery] int? codCon = null,
        [FromQuery] bool? vigente = null,
        [FromQuery] int? motivoId = null,
        [FromQuery] string? marca = null,
        [FromQuery] string? buscar = null)
    {
        var filtro = new AdminMovimientoCorporativoFiltro(codCon, vigente, motivoId, marca, buscar);
        var items = await _service.ObtenerHistoricoCorporativoExportAsync(filtro);
        var bytes = AdminExportBuilder.HistoricoCorporativoExcel(items);
        return File(bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"historico_corporativo_{DateTime.Now:yyyyMMdd_HHmm}.xlsx");
    }

    [HttpGet("historico-corporativo/pdf")]
    public async Task<IActionResult> HistoricoCorporativoPdf(
        [FromQuery] int? codCon = null,
        [FromQuery] bool? vigente = null,
        [FromQuery] int? motivoId = null,
        [FromQuery] string? marca = null,
        [FromQuery] string? buscar = null)
    {
        var filtro = new AdminMovimientoCorporativoFiltro(codCon, vigente, motivoId, marca, buscar);
        var items = await _service.ObtenerHistoricoCorporativoExportAsync(filtro);
        var bytes = AdminExportBuilder.HistoricoCorporativoPdf(items);
        return File(bytes, "application/pdf", $"historico_corporativo_{DateTime.Now:yyyyMMdd_HHmm}.pdf");
    }

    [HttpGet("verificaciones/excel")]
    public async Task<IActionResult> VerificacionesExcel(
        [FromQuery] DateTime? desde = null,
        [FromQuery] DateTime? hasta = null,
        [FromQuery] int? mecanicoId = null,
        [FromQuery] string? estado = null,
        [FromQuery] string? resultado = null,
        [FromQuery] string? buscar = null,
        [FromQuery] bool? soloConInforme = null)
    {
        var filtro = new AdminVerificacionFiltro(desde, hasta, mecanicoId, estado, resultado, buscar, soloConInforme);
        var items = await _service.ObtenerVerificacionesExportAsync(filtro);
        var bytes = AdminExportBuilder.VerificacionesExcel(items);
        return File(bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"verificaciones_{DateTime.Now:yyyyMMdd_HHmm}.xlsx");
    }

    [HttpGet("verificaciones/pdf")]
    public async Task<IActionResult> VerificacionesPdf(
        [FromQuery] DateTime? desde = null,
        [FromQuery] DateTime? hasta = null,
        [FromQuery] int? mecanicoId = null,
        [FromQuery] string? estado = null,
        [FromQuery] string? resultado = null,
        [FromQuery] string? buscar = null,
        [FromQuery] bool? soloConInforme = null)
    {
        var filtro = new AdminVerificacionFiltro(desde, hasta, mecanicoId, estado, resultado, buscar, soloConInforme);
        var items = await _service.ObtenerVerificacionesExportAsync(filtro);
        var periodo = $"Verificaciones - {(desde?.ToString("dd/MM/yyyy") ?? "inicio")} a {(hasta?.ToString("dd/MM/yyyy") ?? "hoy")}";
        var bytes = AdminExportBuilder.VerificacionesPdf(items, periodo);
        return File(bytes, "application/pdf", $"verificaciones_{DateTime.Now:yyyyMMdd_HHmm}.pdf");
    }

    [HttpGet("informes/{idInforme:int}/pdf")]
    public async Task<IActionResult> DescargarInformePdf(int idInforme)
    {
        // En modo Mock no se registra CosaaltDbContext. Los reportes de listado y
        // estadisticas siguen funcionando mediante AdminService/IAdminRepository.
        // El PDF individual solo existe cuando hay un informe real almacenado en SQL.
        var context = HttpContext.RequestServices.GetService(typeof(CosaaltDbContext)) as CosaaltDbContext;
        if (context is null)
            return NotFound(new { message = "El PDF individual esta disponible cuando el informe ha sido generado y almacenado en el sistema." });

        Cosaalt.API.Domain.Entities.InformeVerificacion? informe;
        try
        {
            informe = await context.InformesVerificacion
                .AsNoTracking()
                .FirstOrDefaultAsync(i => i.Id == idInforme);
        }
        catch (Microsoft.Data.SqlClient.SqlException)
        {
            return NotFound(new { message = "El informe tecnico aun no esta disponible para descarga." });
        }

        if (informe is null)
            return NotFound(new { message = "No se encontro el informe solicitado." });
        if (string.IsNullOrWhiteSpace(informe.RutaPdf))
            return NotFound(new { message = "El informe tecnico aun no tiene un PDF generado." });

        var ruta = informe.RutaPdf.Trim();
        string? physicalPath = null;

        if (Path.IsPathRooted(ruta))
        {
            physicalPath = ruta;
        }
        else
        {
            var clean = ruta.Replace('\\', '/').TrimStart('/');
            if (clean.StartsWith("wwwroot/", StringComparison.OrdinalIgnoreCase))
                clean = clean[8..];
            physicalPath = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), clean.Replace('/', Path.DirectorySeparatorChar));
        }

        if (!System.IO.File.Exists(physicalPath))
            return NotFound(new { message = "El PDF fue registrado, pero el archivo no esta disponible en el servidor." });

        var bytes = await System.IO.File.ReadAllBytesAsync(physicalPath);
        var safe = string.Join("_", informe.NroInforme.Split(Path.GetInvalidFileNameChars(), StringSplitOptions.RemoveEmptyEntries));
        if (string.IsNullOrWhiteSpace(safe)) safe = $"informe_{idInforme}";
        return File(bytes, "application/pdf", $"{safe}.pdf");
    }

    [HttpGet("estadisticas")]
    public async Task<IActionResult> Estadisticas(
        [FromQuery] DateTime? desde = null,
        [FromQuery] DateTime? hasta = null,
        [FromQuery] int? tecnicoId = null,
        [FromQuery] int? mecanicoId = null,
        [FromQuery] int? motivoId = null,
        [FromQuery] string? origen = null,
        [FromQuery] string? marca = null)
        => Ok(await _service.ObtenerEstadisticasAsync(new AdminEstadisticasFiltro(
            desde, hasta, tecnicoId, mecanicoId, motivoId, origen, marca)));
}
