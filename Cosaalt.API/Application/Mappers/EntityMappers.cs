using System.Text.Json;
using Cosaalt.API.Application.DTOs;
using Cosaalt.API.Domain.Entities;

namespace Cosaalt.API.Application.Mappers;

/// <summary>
/// Mientras COSAALT no autorice ampliar el esquema medidores.*,
/// los campos adicionales del ensayo
/// (banco, trazabilidad, tipo de caudal, unidades, etc.)
/// se serializan provisionalmente dentro de la columna Condiciones.
///
/// M6:
/// También se conserva un snapshot del parámetro normativo
/// realmente aplicado y de su límite de error, para que una
/// verificación histórica no cambie si Administración modifica
/// posteriormente el catálogo de parámetros.
/// </summary>
public static class EnsayoCamposProvisionales
{
    private sealed record Meta(
        string? Descripcion,
        string? TipoPrueba,
        string? InstrumentoBanco,
        string? IdentificacionBanco,
        string? TrazabilidadCalibracion,
        string? CapacidadNominalQ3,
        string? TipoCaudal,
        string? UnidadCaudal,
        string? UnidadVolumen,
        string? TipoFuga,

        // M6 - snapshot histórico.
        string? ParametroNormativoCodigoAplicado,
        decimal? LimiteNormativoAplicado);

    private static readonly JsonSerializerOptions Options =
        new(JsonSerializerDefaults.Web);

    public static string? Encode(
        string? descripcion,
        string? tipoPrueba,
        string? instrumentoBanco,
        string? identificacionBanco,
        string? trazabilidadCalibracion,
        string? capacidadNominalQ3,
        string? tipoCaudal,
        string? unidadCaudal,
        string? unidadVolumen,
        string? tipoFuga,
        string? parametroNormativoCodigoAplicado = null,
        decimal? limiteNormativoAplicado = null)
    {
        var tieneExtra =
            !string.IsNullOrWhiteSpace(tipoPrueba)
            || !string.IsNullOrWhiteSpace(instrumentoBanco)
            || !string.IsNullOrWhiteSpace(identificacionBanco)
            || !string.IsNullOrWhiteSpace(trazabilidadCalibracion)
            || !string.IsNullOrWhiteSpace(capacidadNominalQ3)
            || !string.IsNullOrWhiteSpace(tipoCaudal)
            || !string.IsNullOrWhiteSpace(unidadCaudal)
            || !string.IsNullOrWhiteSpace(unidadVolumen)
            || !string.IsNullOrWhiteSpace(tipoFuga)
            || !string.IsNullOrWhiteSpace(parametroNormativoCodigoAplicado)
            || limiteNormativoAplicado.HasValue;

        /*
         * Compatibilidad:
         *
         * Si solamente existen condiciones de texto y no hay ningún
         * campo adicional, conservamos el formato antiguo y guardamos
         * únicamente el texto.
         */
        if (!tieneExtra)
        {
            return string.IsNullOrWhiteSpace(descripcion)
                ? null
                : descripcion.Trim();
        }

        var meta = new Meta(
            Descripcion: V(descripcion),
            TipoPrueba: V(tipoPrueba),
            InstrumentoBanco: V(instrumentoBanco),
            IdentificacionBanco: V(identificacionBanco),
            TrazabilidadCalibracion: V(trazabilidadCalibracion),
            CapacidadNominalQ3: V(capacidadNominalQ3),
            TipoCaudal: V(tipoCaudal),
            UnidadCaudal: V(unidadCaudal),
            UnidadVolumen: V(unidadVolumen),
            TipoFuga: V(tipoFuga),
            ParametroNormativoCodigoAplicado:
                V(parametroNormativoCodigoAplicado),
            LimiteNormativoAplicado:
                limiteNormativoAplicado);

        return JsonSerializer.Serialize(
            meta,
            Options);
    }

    public static (
        string? Descripcion,
        string? TipoPrueba,
        string? InstrumentoBanco,
        string? IdentificacionBanco,
        string? TrazabilidadCalibracion,
        string? CapacidadNominalQ3,
        string? TipoCaudal,
        string? UnidadCaudal,
        string? UnidadVolumen,
        string? TipoFuga,
        string? ParametroNormativoCodigoAplicado,
        decimal? LimiteNormativoAplicado)
        Decode(string? condiciones)
    {
        /*
         * Compatibilidad con ensayos antiguos:
         *
         * Antes los campos adicionales podían no existir y Condiciones
         * podía contener únicamente texto plano.
         */
        if (string.IsNullOrWhiteSpace(condiciones)
            || !condiciones.TrimStart().StartsWith('{'))
        {
            return (
                Descripcion: condiciones,
                TipoPrueba: null,
                InstrumentoBanco: null,
                IdentificacionBanco: null,
                TrazabilidadCalibracion: null,
                CapacidadNominalQ3: null,
                TipoCaudal: null,
                UnidadCaudal: null,
                UnidadVolumen: null,
                TipoFuga: null,
                ParametroNormativoCodigoAplicado: null,
                LimiteNormativoAplicado: null);
        }

        try
        {
            var meta =
                JsonSerializer.Deserialize<Meta>(
                    condiciones,
                    Options);

            if (meta is null)
            {
                return (
                    Descripcion: condiciones,
                    TipoPrueba: null,
                    InstrumentoBanco: null,
                    IdentificacionBanco: null,
                    TrazabilidadCalibracion: null,
                    CapacidadNominalQ3: null,
                    TipoCaudal: null,
                    UnidadCaudal: null,
                    UnidadVolumen: null,
                    TipoFuga: null,
                    ParametroNormativoCodigoAplicado: null,
                    LimiteNormativoAplicado: null);
            }

            return (
                Descripcion: meta.Descripcion,
                TipoPrueba: meta.TipoPrueba,
                InstrumentoBanco: meta.InstrumentoBanco,
                IdentificacionBanco: meta.IdentificacionBanco,
                TrazabilidadCalibracion:
                    meta.TrazabilidadCalibracion,
                CapacidadNominalQ3:
                    meta.CapacidadNominalQ3,
                TipoCaudal: meta.TipoCaudal,
                UnidadCaudal: meta.UnidadCaudal,
                UnidadVolumen: meta.UnidadVolumen,
                TipoFuga: meta.TipoFuga,
                ParametroNormativoCodigoAplicado:
                    meta.ParametroNormativoCodigoAplicado,
                LimiteNormativoAplicado:
                    meta.LimiteNormativoAplicado);
        }
        catch (JsonException)
        {
            /*
             * Si existe algún registro antiguo con JSON incompatible,
             * no hacemos caer la pantalla.
             *
             * Se conserva el contenido original como descripción.
             */
            return (
                Descripcion: condiciones,
                TipoPrueba: null,
                InstrumentoBanco: null,
                IdentificacionBanco: null,
                TrazabilidadCalibracion: null,
                CapacidadNominalQ3: null,
                TipoCaudal: null,
                UnidadCaudal: null,
                UnidadVolumen: null,
                TipoFuga: null,
                ParametroNormativoCodigoAplicado: null,
                LimiteNormativoAplicado: null);
        }
    }

    private static string? V(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? null
            : value.Trim();
    }
}

public static class EjecucionMapper
{
    public static EjecucionCambioResponseDto ToResponse(
        EjecucionCambio entity,
        bool yaExistia = false) =>
        new(
            entity.Id,
            yaExistia
                ? "La ejecucion ya habia sido registrada; no se duplico."
                : "Ejecucion registrada correctamente.",
            entity.Sincronizado,
            yaExistia);
}

public static class RutaMapper
{
    public static DetalleRutaResponseDto ToResponse(
        DetalleRuta entity,
        string? numeroMedidor = null) =>
        new(
            Id: entity.Id,
            SolicitudId: entity.SolicitudId,
            TipoOrigen: entity.TipoOrigen,
            OrdenVisita: entity.OrdenVisita,
            Estado: entity.Estado,
            NombreCliente: entity.NombreCliente,
            Direccion: entity.Direccion,
            Latitud: entity.Latitud.HasValue
                ? (double?)entity.Latitud.Value
                : null,
            Longitud: entity.Longitud.HasValue
                ? (double?)entity.Longitud.Value
                : null,
            EsUrgente:
                entity.TipoOrigen.Equals(
                    "ODECO",
                    StringComparison.OrdinalIgnoreCase),
            CodCon: entity.RegSoc,
            NumeroMedidor: numeroMedidor);
}

public static class VerificacionMapper
{
    public static VerificacionDto ToDto(
        Verificacion entity,
        string? nombreCliente = null,
        string? nombreMecanico = null) =>
        new(
            Id: entity.Id,
            TipoOrigen: entity.TipoOrigen,
            IdOrigen: entity.IdOrigen,
            CodCon: entity.RegSoc,
            IdUsuarioMecanico:
                entity.IdUsuarioMecanico,
            IdMedidor:
                entity.CodMedidor.ToString(),
            FechaVerificacion:
                entity.FechaVerificacion,
            Estado: entity.Estado,
            Resultado: entity.Resultado,
            NombreCliente: nombreCliente,
            NombreMecanico: nombreMecanico,
            Ensayo: entity.Ensayo is null
                ? null
                : MapEnsayo(entity.Ensayo),
            Participantes: entity.Participantes
                .OrderBy(p => p.Id)
                .Select(
                    p =>
                        new ParticipanteVerificacionDto(
                            p.Id,
                            p.Nombre,
                            p.Cargo,
                            p.Rol))
                .ToList());

    private static EnsayoVerificacionDto MapEnsayo(
        EnsayoVerificacion e)
    {
        var (
            descripcion,
            tipoPrueba,
            instrumentoBanco,
            identificacionBanco,
            trazabilidadCalibracion,
            capacidadNominalQ3,
            tipoCaudal,
            unidadCaudal,
            unidadVolumen,
            tipoFuga,
            _,
            _) =
            EnsayoCamposProvisionales.Decode(
                e.Condiciones);

        return new EnsayoVerificacionDto(
            Id: e.Id,
            Condiciones: descripcion,
            LecturaInicial: e.LecturaInicial,
            LecturaFinal: e.LecturaFinal,
            VolumenPatron: e.VolumenPatron,
            Caudal: e.Caudal,
            VolumenRegistrado:
                e.VolumenRegistrado,
            Error: e.Error,
            Fugas: e.Fugas,
            Observaciones:
                e.Observaciones,
            TipoPrueba: tipoPrueba,
            InstrumentoBanco:
                instrumentoBanco,
            IdentificacionBanco:
                identificacionBanco,
            TrazabilidadCalibracion:
                trazabilidadCalibracion,
            CapacidadNominalQ3:
                capacidadNominalQ3,
            TipoCaudal: tipoCaudal,
            UnidadCaudal:
                unidadCaudal,
            UnidadVolumen:
                unidadVolumen,
            TipoFuga: tipoFuga);
    }
}