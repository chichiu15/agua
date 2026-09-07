using Cosaalt.API.Infrastructure.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Data.SqlClient;

namespace Cosaalt.API.Controllers;

/// <summary>
/// M10: convierte errores técnicos del módulo de verificación en respuestas
/// simples para la aplicación, manteniendo el detalle real únicamente en logs.
/// No se exponen excepciones, consultas SQL ni stack traces al cliente.
/// </summary>
public sealed class VerificacionExceptionFilter : IExceptionFilter
{
    private readonly ILogger<VerificacionExceptionFilter> _logger;

    public VerificacionExceptionFilter(
        ILogger<VerificacionExceptionFilter> logger)
    {
        _logger = logger;
    }

    public void OnException(ExceptionContext context)
    {
        var exception = context.Exception;
        var path = context.HttpContext.Request.Path.Value ?? string.Empty;

        _logger.LogError(
            exception,
            "Error controlado por M10 en {Method} {Path}",
            context.HttpContext.Request.Method,
            path);

        var (status, codigo, mensaje) = Mapear(exception, path);

        context.Result = new ObjectResult(new
        {
            codigo,
            mensaje
        })
        {
            StatusCode = status
        };

        context.ExceptionHandled = true;
    }

    private static (int Status, string Codigo, string Mensaje) Mapear(
        Exception exception,
        string path)
    {
        if (exception is IntegrationPendingException)
        {
            return (
                StatusCodes.Status503ServiceUnavailable,
                "INTEGRACION_NO_DISPONIBLE",
                "La VPN o la base institucional no están disponibles.");
        }

        if (exception is SqlException)
        {
            return (
                StatusCodes.Status503ServiceUnavailable,
                "BASE_INSTITUCIONAL_NO_DISPONIBLE",
                "La VPN o la base institucional no están disponibles.");
        }

        if (exception is TimeoutException)
        {
            return (
                StatusCodes.Status504GatewayTimeout,
                "TIEMPO_ESPERA_AGOTADO",
                "No se pudo conectar con el servidor. Intente nuevamente.");
        }

        if (exception is OperationCanceledException)
        {
            return (
                StatusCodes.Status408RequestTimeout,
                "OPERACION_CANCELADA",
                "La operación tardó demasiado. Intente nuevamente.");
        }

        if (exception is UnauthorizedAccessException)
        {
            return (
                StatusCodes.Status500InternalServerError,
                "ARCHIVO_NO_DISPONIBLE",
                EsRutaInforme(path)
                    ? "No se pudo generar o acceder al informe."
                    : "No se pudo completar la operación solicitada.");
        }

        if (exception is IOException)
        {
            return (
                StatusCodes.Status500InternalServerError,
                "ARCHIVO_NO_DISPONIBLE",
                EsRutaInforme(path)
                    ? "No se pudo generar o acceder al informe."
                    : "No se pudo completar la operación solicitada.");
        }

        if (exception is ArgumentException argumentException)
        {
            return (
                StatusCodes.Status400BadRequest,
                "DATOS_INVALIDOS",
                MensajeSeguro(argumentException.Message, "Revise los datos ingresados."));
        }

        if (exception is InvalidOperationException invalidOperationException)
        {
            return MapearOperacionInvalida(invalidOperationException.Message, path);
        }

        return (
            StatusCodes.Status500InternalServerError,
            "ERROR_INTERNO",
            EsRutaInforme(path)
                ? "No se pudo generar el informe. Intente nuevamente."
                : "No se pudo completar la operación en el servidor. Intente nuevamente o contacte al área de Informática.");
    }

    private static (int Status, string Codigo, string Mensaje) MapearOperacionInvalida(
        string? rawMessage,
        string path)
    {
        var message = rawMessage?.Trim() ?? string.Empty;
        var lower = message.ToLowerInvariant();

        if (lower.Contains("ya fue tomada"))
        {
            return (
                StatusCodes.Status409Conflict,
                "SOLICITUD_YA_TOMADA",
                "La solicitud ya fue tomada.");
        }

        if (lower.Contains("parametro normativo") ||
            lower.Contains("parámetro normativo"))
        {
            return (
                StatusCodes.Status400BadRequest,
                "PARAMETRO_NORMATIVO_NO_ENCONTRADO",
                "No existe parámetro normativo para este caudal.");
        }

        if (lower.Contains("campos obligatorios") ||
            lower.Contains("complete los campos"))
        {
            return (
                StatusCodes.Status400BadRequest,
                "CAMPOS_OBLIGATORIOS",
                "Complete los campos obligatorios antes de continuar.");
        }

        if (lower.Contains("ya fue finalizada") ||
            lower.Contains("ya esta finalizada") ||
            lower.Contains("ya está finalizada"))
        {
            return (
                StatusCodes.Status409Conflict,
                "VERIFICACION_FINALIZADA",
                "La verificación ya fue finalizada.");
        }

        if (lower.Contains("finalice la verificacion") ||
            lower.Contains("finalice la verificación"))
        {
            return (
                StatusCodes.Status400BadRequest,
                "VERIFICACION_NO_FINALIZADA",
                "Finalice la verificación antes de generar el informe.");
        }

        if (lower.Contains("no se encontro") ||
            lower.Contains("no se encontró") ||
            lower.Contains("no existe"))
        {
            return (
                StatusCodes.Status404NotFound,
                "RECURSO_NO_ENCONTRADO",
                MensajeSeguro(message, "No se encontró la información solicitada."));
        }

        if (EsRutaInforme(path))
        {
            return (
                StatusCodes.Status400BadRequest,
                "INFORME_NO_GENERADO",
                MensajeSeguro(message, "No se pudo generar el informe."));
        }

        return (
            StatusCodes.Status400BadRequest,
            "OPERACION_NO_VALIDA",
            MensajeSeguro(message, "No se pudo completar la operación solicitada."));
    }

    private static string MensajeSeguro(string? message, string fallback)
    {
        if (string.IsNullOrWhiteSpace(message))
        {
            return fallback;
        }

        var value = message.Trim();

        // Nunca devolver mensajes que claramente contienen detalles técnicos.
        if (value.Contains("SqlException", StringComparison.OrdinalIgnoreCase) ||
            value.Contains("Microsoft.Data", StringComparison.OrdinalIgnoreCase) ||
            value.Contains("System.", StringComparison.OrdinalIgnoreCase) ||
            value.Contains(" at ", StringComparison.OrdinalIgnoreCase) ||
            value.Contains("stack", StringComparison.OrdinalIgnoreCase))
        {
            return fallback;
        }

        return value;
    }

    private static bool EsRutaInforme(string path) =>
        path.Contains("/informe", StringComparison.OrdinalIgnoreCase) ||
        path.Contains("/pdf", StringComparison.OrdinalIgnoreCase);
}
