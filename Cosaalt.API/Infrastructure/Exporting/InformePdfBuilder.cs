using System.Globalization;
using System.Text;

namespace Cosaalt.API.Infrastructure.Exporting;

public sealed record InformePdfData(
    string NroInforme,
    int Version,
    DateTime FechaEmision,
    string Mecanico,
    string SocioNombre,
    string CodCon,
    string Direccion,
    string DocumentoRuc,
    string MotivoOrigen,
    string MedidorMarca,
    string MedidorSerie,
    string MedidorCapacidad,
    string MedidorTipo,
    string MedidorClase,
    string MedidorDiametro,
    string MedidorFechaRegistro,
    string FechaVerificacion,
    string TipoPrueba,
    string InstrumentoBanco,
    string TipoCaudal,
    string Caudal,
    string UnidadCaudal,
    string PrimeraLectura,
    string SegundaLectura,
    string VolumenRegistrado,
    string VolumenPatron,
    string Diferencia,
    string ErrorConSigno,
    string ErrorAbsoluto,
    string ParametroNormativo,
    string LimitePermitido,
    string Resultado,
    string Fugas,
    string TipoFuga,
    string Condiciones,
    string Observaciones,
    string Responsable,
    IReadOnlyList<(string Nombre, string Cargo, string Rol)> Participantes);

/// <summary>
/// Genera el PDF del informe tecnico de verificacion mecánica.
/// PDF portable crudo (sin dependencias externas), compatible con el
/// generador usado por los reportes de Administración.
/// </summary>
public static class InformePdfBuilder
{
    private const string Company = "COSAALT R.L.";
    private const string Module = "Sistema de Gestión, Cambio y Verificación de Medidores";

    public static byte[] Build(InformePdfData d)
    {
        const float width = 595;
        const float pageHeight = 842;
        const float marginX = 36;
        const float top = 800;
        float y = top;

        var sb = new StringBuilder();
        Footer(sb, d, width);

        // Barra institucional
        FillRect(sb, 0, pageHeight - 10, width, 10, 0f, 0.42f, 0.25f);
        DrawText(sb, Company, marginX, top, 16, bold: true, 0f, 0.42f, 0.25f);
        DrawText(sb, Module, marginX, top - 20, 8.5f, false, .35f, .39f, .42f);
        y = top - 50;
        DrawText(sb, "INFORME TÉCNICO DE VERIFICACIÓN DE MEDIDOR", marginX, y, 14, true, .10f, .14f, .17f);
        y -= 22;
        DrawText(sb, $"{d.NroInforme}  ·  Versión {d.Version}  ·  {d.FechaEmision:dd/MM/yyyy HH:mm}", marginX, y, 9, false, .35f, .39f, .42f);
        y -= 24;

        Row(sb, marginX, ref y, "1. DATOS DEL TÉCNICO Y EL SOCIO", new[] { $"Mecánico: {d.Mecanico}", $"Usuario/Conexión: {d.CodCon}", $"Socio: {d.SocioNombre}", $"Dirección: {d.Direccion}", $"Documento/RUC: {d.DocumentoRuc}", $"Origen: {d.MotivoOrigen}" });
        Row(sb, marginX, ref y, "2. DATOS DEL MEDIDOR", new[] { $"Marca: {d.MedidorMarca}", $"Serie: {d.MedidorSerie}", $"Capacidad nominal Q3: {d.MedidorCapacidad}", $"Tipo: {d.MedidorTipo}", $"Clase: {d.MedidorClase}", $"Diámetro: {d.MedidorDiametro}", $"Fecha de conexión/registro: {d.MedidorFechaRegistro}" });
        Row(sb, marginX, ref y, "3. VERIFICACIÓN", new[] { $"Fecha/hora de verificación: {d.FechaVerificacion}", $"Tipo de ensayo: {d.TipoPrueba}", $"Instrumento o banco: {d.InstrumentoBanco}", $"Tipo de caudal: {d.TipoCaudal}", $"Caudal: {d.Caudal} {d.UnidadCaudal}".Trim() });
        Row(sb, marginX, ref y, "4. PARTICIPANTES", d.Participantes.Count == 0
            ? ["Sin participantes registrados."]
            : d.Participantes.Select(p => $"{p.Nombre} — {p.Cargo ?? "-"} — {p.Rol ?? "-"}").ToArray());
        Row(sb, marginX, ref y, "5. LECTURAS Y VOLUMENES", new[] { $"Primera lectura: {d.PrimeraLectura}", $"Segunda lectura: {d.SegundaLectura}", $"Volumen registrado: {d.VolumenRegistrado}", $"Volumen patrón: {d.VolumenPatron}", $"Diferencia: {d.Diferencia}" });
        Row(sb, marginX, ref y, "6. ERROR Y RESULTADO", new[] { $"Error con signo: {d.ErrorConSigno} %", $"Error absoluto: {d.ErrorAbsoluto} %", $"Parámetro normativo utilizado: {d.ParametroNormativo}", $"Límite permitido: {d.LimitePermitido} %", $"RESULTADO: {d.Resultado}" });
        Row(sb, marginX, ref y, "7. FUGAS", new[] { $"Registra fuga: {d.Fugas}", $"Tipo de fuga: {d.TipoFuga}" });
        Row(sb, marginX, ref y, "8. CONDICIONES Y OBSERVACIONES", new[] { $"Condiciones: {d.Condiciones}", $"Observaciones: {d.Observaciones}" });
        Row(sb, marginX, ref y, "9. RESPONSABLE", new[] { $"Responsable: {d.Responsable}", "Firma del responsable:", "______________________________" });

        return BuildPdfDocument(new[] { sb.ToString() }, landscape: false);
    }

    private static void Row(StringBuilder sb, float x, ref float y, string titulo, string[] lineas)
    {
        DrawText(sb, titulo, x, y, 8.6f, true, 0f, 0.42f, 0.25f);
        y -= 15;
        foreach (var linea in lineas)
        {
            if (string.IsNullOrWhiteSpace(linea)) continue;
            DrawText(sb, Safe(linea), x + 6, y, 8, false, .12f, .15f, .17f);
            y -= 13.2f;
        }
        y -= 8;
    }

    private static void Footer(StringBuilder sb, InformePdfData d, float width)
    {
        DrawText(sb, $"Página 1 de 1", width - 85, 20, 8, false, .40f, .43f, .46f);
        DrawText(sb, Company, 36, 20, 8, false, .40f, .43f, .46f);
        DrawText(sb, $"Documento de verificación técnico — {d.NroInforme} v{d.Version}", 36, 12, 7, false, .40f, .43f, .46f);
    }

    private static byte[] BuildPdfDocument(IReadOnlyList<string> pageStreams, bool landscape)
    {
        var pageCount = pageStreams.Count;
        var objectCount = 4 + pageCount * 2;
        var objects = new string[objectCount + 1];
        objects[1] = "<< /Type /Catalog /Pages 2 0 R >>";
        var kids = string.Join(" ", Enumerable.Range(0, pageCount).Select(i => $"{5 + i * 2} 0 R"));
        objects[2] = $"<< /Type /Pages /Kids [{kids}] /Count {pageCount} >>";
        objects[3] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>";
        objects[4] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>";

        for (var i = 0; i < pageCount; i++)
        {
            var pageId = 5 + i * 2;
            var contentId = pageId + 1;
            var media = landscape ? "[0 0 842 595]" : "[0 0 595 842]";
            objects[pageId] = $"<< /Type /Page /Parent 2 0 R /MediaBox {media} /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents {contentId} 0 R >>";
            var stream = pageStreams[i];
            var length = Encoding.Latin1.GetByteCount(stream);
            objects[contentId] = $"<< /Length {length} >>\nstream\n{stream}\nendstream";
        }

        using var ms = new MemoryStream();
        var encoding = Encoding.Latin1;
        void W(string value)
        {
            var bytes = encoding.GetBytes(value);
            ms.Write(bytes, 0, bytes.Length);
        }
        W("%PDF-1.4\n%âãÏÓ\n");
        var offsets = new long[objectCount + 1];
        for (var i = 1; i <= objectCount; i++)
        {
            offsets[i] = ms.Position;
            W($"{i} 0 obj\n{objects[i]}\nendobj\n");
        }
        var xref = ms.Position;
        W($"xref\n0 {objectCount + 1}\n0000000000 65535 f \n");
        for (var i = 1; i <= objectCount; i++) W($"{offsets[i]:D10} 00000 n \n");
        W($"trailer\n<< /Size {objectCount + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF");
        return ms.ToArray();
    }

    private static void DrawText(StringBuilder sb, string text, float x, float y, float size, bool bold, float r, float g, float b)
    {
        sb.AppendFormat(CultureInfo.InvariantCulture, "BT /{0} {1:0.##} Tf {2:0.##} {3:0.##} Td {4:0.###} {5:0.###} {6:0.###} rg ({7}) Tj ET\n",
            bold ? "F2" : "F1", size, x, y, r, g, b, PdfText(text));
    }

    private static void FillRect(StringBuilder sb, float x, float y, float w, float h, float r, float g, float b) =>
        sb.AppendFormat(CultureInfo.InvariantCulture, "{0:0.###} {1:0.###} {2:0.###} rg {3:0.##} {4:0.##} {5:0.##} {6:0.##} re f\n", r, g, b, x, y, w, h);

    private static string Safe(string value) =>
        (value ?? string.Empty).Replace("\r", " ").Replace("\n", " ").Trim();

    private static string PdfText(string value)
    {
        var normalized = value
            .Replace("–", "-")
            .Replace("—", "-")
            .Replace("…", "...")
            .Replace("“", "\"")
            .Replace("”", "\"")
            .Replace("’", "'");
        return normalized.Replace("\\", "\\\\").Replace("(", "\\(").Replace(")", "\\)");
    }
}