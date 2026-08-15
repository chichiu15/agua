namespace Cosaalt.API.Application.DTOs;

/// <summary>
/// Respuesta al subir una foto de evidencia (medidor retirado/instalado).
/// RutaArchivo es lo que luego se manda dentro de EvidenciaFotoDto.RutaArchivo
/// al registrar la ejecución o al sincronizar.
/// </summary>
public record UploadEvidenciaResponseDto(
    string RutaArchivo,
    string TipoFoto,
    long TamanoBytes);
