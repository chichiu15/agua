using Cosaalt.API.Application.DTOs;
using Microsoft.AspNetCore.Mvc;

namespace Cosaalt.API.Controllers;

/// <summary>
/// Recibe las fotos que la app móvil toma en campo (medidor viejo/nuevo) y
/// las guarda en el servidor. La app llama esto CUANDO recupera señal
/// (junto con /api/sincronizacion/procesar-cambios); mientras está offline,
/// la foto queda guardada localmente en el celular.
/// </summary>
[ApiController]
[Route("api/evidencias")]
public class EvidenciasController : ControllerBase
{
    private readonly IWebHostEnvironment _env;
    private static readonly string[] ExtensionesPermitidas = [".jpg", ".jpeg", ".png", ".webp"];
    private const long TamanoMaximoBytes = 8 * 1024 * 1024; // 8 MB por foto

    public EvidenciasController(IWebHostEnvironment env) => _env = env;

    /// <summary>
    /// Sube una foto de evidencia como multipart/form-data.
    /// Campos: archivo (IFormFile), tipoFoto (MedidorRetirado | MedidorNuevo),
    /// idOrigen (folio ODECO o id de detalle de lectura, para organizar carpetas).
    /// </summary>
    [HttpPost("upload")]
    [RequestSizeLimit(TamanoMaximoBytes)]
    public async Task<IActionResult> Upload(
        IFormFile archivo,
        [FromForm] string tipoFoto,
        [FromForm] string idOrigen)
    {
        if (archivo is null || archivo.Length == 0)
            return BadRequest(new { mensaje = "No se recibió ningún archivo." });

        if (archivo.Length > TamanoMaximoBytes)
            return BadRequest(new { mensaje = "La foto supera el tamaño máximo permitido (8MB)." });

        var extension = Path.GetExtension(archivo.FileName).ToLowerInvariant();
        if (!ExtensionesPermitidas.Contains(extension))
            return BadRequest(new { mensaje = "Formato de imagen no permitido. Usa jpg, png o webp." });

        if (string.IsNullOrWhiteSpace(tipoFoto))
            return BadRequest(new { mensaje = "Falta indicar el tipo de foto (MedidorRetirado / MedidorNuevo)." });

        // wwwroot/uploads/{idOrigen}/{guid}{ext}  -> se sirve públicamente vía UseStaticFiles()
        var carpetaBase = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", SanitizarNombre(idOrigen));
        Directory.CreateDirectory(carpetaBase);

        var nombreArchivo = $"{Guid.NewGuid()}{extension}";
        var rutaFisica = Path.Combine(carpetaBase, nombreArchivo);

        await using (var stream = new FileStream(rutaFisica, FileMode.Create))
        {
            await archivo.CopyToAsync(stream);
        }

        var rutaRelativa = $"/uploads/{SanitizarNombre(idOrigen)}/{nombreArchivo}";

        return Ok(new UploadEvidenciaResponseDto(rutaRelativa, tipoFoto, archivo.Length));
    }

    private static string SanitizarNombre(string valor)
    {
        var invalidos = Path.GetInvalidFileNameChars();
        var limpio = new string(valor.Where(c => !invalidos.Contains(c)).ToArray());
        return string.IsNullOrWhiteSpace(limpio) ? "sin-origen" : limpio;
    }
}
