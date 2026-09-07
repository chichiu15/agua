using System.Globalization;
using System.Text;

namespace Cosaalt.API.Infrastructure.Exporting;

public sealed record InformePdfData(
    string NroInforme,
    int Version,
    DateTime FechaEmision,
    string Mecanico,
    string SocioNombre,
    string RegSoc,
    string CodConexion,
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

public static class InformePdfBuilder
{
    private const string Company = "COSAALT R.L.";

    private const string Module =
        "Sistema de Gestión, Cambio y Verificación de Medidores";

    private const float Width = 595;
    private const float PageHeight = 842;
    private const float MarginX = 36;
    private const float Top = 800;
    private const float BottomLimit = 55;

    public static byte[] Build(InformePdfData d)
    {
        var pages = new List<StringBuilder>();

        var page = NuevaPagina();
        pages.Add(page);

        var y = DibujarCabecera(page, d);

        void EnsureSpace(float needed)
        {
            if (y - needed >= BottomLimit)
                return;

            page = NuevaPagina();
            pages.Add(page);
            y = DibujarCabeceraContinuacion(page, d);
        }

        void Section(
            string title,
            IEnumerable<string> lines)
        {
            var processed = lines
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .SelectMany(x => Wrap(Safe(x), 88))
                .ToList();

            var required =
                23f + processed.Count * 13.2f;

            EnsureSpace(
                Math.Min(required, 150));

            DrawText(
                page,
                title,
                MarginX,
                y,
                8.6f,
                true,
                0f,
                0.42f,
                0.25f);

            y -= 15;

            foreach (var line in processed)
            {
                if (y < BottomLimit + 18)
                {
                    page = NuevaPagina();
                    pages.Add(page);
                    y = DibujarCabeceraContinuacion(
                        page,
                        d);
                }

                DrawText(
                    page,
                    line,
                    MarginX + 6,
                    y,
                    8,
                    false,
                    .12f,
                    .15f,
                    .17f);

                y -= 13.2f;
            }

            y -= 8;
        }

        Section(
            "1. DATOS DEL TÉCNICO Y EL SOCIO",
            new[]
            {
                $"Mecánico: {d.Mecanico}",
                $"Registro socio: {d.RegSoc}",
                $"Código/Conexión: {d.CodConexion}",
                $"Socio: {d.SocioNombre}",
                $"Dirección: {d.Direccion}",
                $"Documento/RUC: {d.DocumentoRuc}",
                $"Origen: {d.MotivoOrigen}"
            });

        Section(
            "2. DATOS DEL MEDIDOR",
            new[]
            {
                $"Marca: {d.MedidorMarca}",
                $"Serie: {d.MedidorSerie}",
                $"Capacidad nominal Q3: {d.MedidorCapacidad}",
                $"Tipo: {d.MedidorTipo}",
                $"Clase: {d.MedidorClase}",
                $"Diámetro: {d.MedidorDiametro}",
                $"Fecha de conexión/registro: {d.MedidorFechaRegistro}"
            });

        Section(
            "3. VERIFICACIÓN",
            new[]
            {
                $"Fecha/hora de verificación: {d.FechaVerificacion}",
                $"Tipo de ensayo: {d.TipoPrueba}",
                $"Instrumento o banco: {d.InstrumentoBanco}",
                $"Tipo de caudal: {d.TipoCaudal}",
                $"Caudal: {d.Caudal} {d.UnidadCaudal}".Trim()
            });

        Section(
            "4. PARTICIPANTES",
            d.Participantes.Count == 0
                ? new[]
                {
                    "Sin participantes registrados."
                }
                : d.Participantes.Select(
                    p =>
                        $"{p.Nombre} - {p.Cargo} - {p.Rol}"));

        Section(
            "5. LECTURAS Y VOLÚMENES",
            new[]
            {
                $"Primera lectura: {d.PrimeraLectura}",
                $"Segunda lectura: {d.SegundaLectura}",
                $"Volumen registrado: {d.VolumenRegistrado}",
                $"Volumen patrón: {d.VolumenPatron}",
                $"Diferencia: {d.Diferencia}"
            });

        Section(
            "6. ERROR Y RESULTADO",
            new[]
            {
                $"Error con signo: {d.ErrorConSigno} %",
                $"Error absoluto: {d.ErrorAbsoluto} %",
                $"Parámetro normativo utilizado: {d.ParametroNormativo}",
                $"Límite permitido: {d.LimitePermitido} %",
                $"RESULTADO: {d.Resultado}"
            });

        Section(
            "7. FUGAS",
            new[]
            {
                $"Registra fuga: {d.Fugas}",
                $"Tipo de fuga: {d.TipoFuga}"
            });

        Section(
            "8. CONDICIONES Y OBSERVACIONES",
            new[]
            {
                $"Condiciones: {d.Condiciones}",
                $"Observaciones: {d.Observaciones}"
            });

        Section(
            "9. RESPONSABLE",
            new[]
            {
                $"Responsable: {d.Responsable}",
                "",
                "Firma del responsable:",
                "",
                "________________________________________"
            });

        for (var i = 0; i < pages.Count; i++)
        {
            Footer(
                pages[i],
                d,
                i + 1,
                pages.Count);
        }

        return BuildPdfDocument(
            pages.Select(x => x.ToString()).ToArray(),
            landscape: false);
    }

    private static StringBuilder NuevaPagina()
    {
        var sb = new StringBuilder();

        FillRect(
            sb,
            0,
            PageHeight - 10,
            Width,
            10,
            0f,
            0.42f,
            0.25f);

        return sb;
    }

    private static float DibujarCabecera(
        StringBuilder sb,
        InformePdfData d)
    {
        DrawText(
            sb,
            Company,
            MarginX,
            Top,
            16,
            true,
            0f,
            0.42f,
            0.25f);

        DrawText(
            sb,
            Module,
            MarginX,
            Top - 20,
            8.5f,
            false,
            .35f,
            .39f,
            .42f);

        var y = Top - 50;

        DrawText(
            sb,
            "INFORME TÉCNICO DE VERIFICACIÓN DE MEDIDOR",
            MarginX,
            y,
            14,
            true,
            .10f,
            .14f,
            .17f);

        y -= 22;

        DrawText(
            sb,
            $"{d.NroInforme}  -  Versión {d.Version}  -  {d.FechaEmision:dd/MM/yyyy HH:mm}",
            MarginX,
            y,
            9,
            false,
            .35f,
            .39f,
            .42f);

        return y - 24;
    }

    private static float DibujarCabeceraContinuacion(
        StringBuilder sb,
        InformePdfData d)
    {
        DrawText(
            sb,
            Company,
            MarginX,
            Top,
            13,
            true,
            0f,
            0.42f,
            0.25f);

        DrawText(
            sb,
            $"{d.NroInforme} - continuación",
            MarginX,
            Top - 19,
            8.5f,
            false,
            .35f,
            .39f,
            .42f);

        return Top - 45;
    }

    private static IEnumerable<string> Wrap(
        string value,
        int maxChars)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            yield break;
        }

        var words = value
            .Split(
                ' ',
                StringSplitOptions.RemoveEmptyEntries);

        var current =
            new StringBuilder();

        foreach (var word in words)
        {
            if (current.Length == 0)
            {
                current.Append(word);
                continue;
            }

            if (current.Length + 1 + word.Length <= maxChars)
            {
                current.Append(' ');
                current.Append(word);
                continue;
            }

            yield return current.ToString();

            current.Clear();
            current.Append(word);
        }

        if (current.Length > 0)
        {
            yield return current.ToString();
        }
    }

    private static void Footer(
        StringBuilder sb,
        InformePdfData d,
        int page,
        int total)
    {
        DrawText(
            sb,
            $"Página {page} de {total}",
            Width - 100,
            20,
            8,
            false,
            .40f,
            .43f,
            .46f);

        DrawText(
            sb,
            Company,
            36,
            20,
            8,
            false,
            .40f,
            .43f,
            .46f);

        DrawText(
            sb,
            $"Documento de verificación técnica - {d.NroInforme} v{d.Version}",
            36,
            12,
            7,
            false,
            .40f,
            .43f,
            .46f);
    }

    private static byte[] BuildPdfDocument(
        IReadOnlyList<string> pageStreams,
        bool landscape)
    {
        var pageCount =
            pageStreams.Count;

        var objectCount =
            4 + pageCount * 2;

        var objects =
            new string[objectCount + 1];

        objects[1] =
            "<< /Type /Catalog /Pages 2 0 R >>";

        var kids = string.Join(
            " ",
            Enumerable
                .Range(0, pageCount)
                .Select(i => $"{5 + i * 2} 0 R"));

        objects[2] =
            $"<< /Type /Pages /Kids [{kids}] /Count {pageCount} >>";

        objects[3] =
            "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>";

        objects[4] =
            "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>";

        for (var i = 0; i < pageCount; i++)
        {
            var pageId =
                5 + i * 2;

            var contentId =
                pageId + 1;

            var media =
                landscape
                    ? "[0 0 842 595]"
                    : "[0 0 595 842]";

            objects[pageId] =
                $"<< /Type /Page /Parent 2 0 R /MediaBox {media} /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents {contentId} 0 R >>";

            var stream =
                pageStreams[i];

            var length =
                Encoding.Latin1.GetByteCount(
                    stream);

            objects[contentId] =
                $"<< /Length {length} >>\nstream\n{stream}\nendstream";
        }

        using var ms =
            new MemoryStream();

        var encoding =
            Encoding.Latin1;

        void W(string value)
        {
            var bytes =
                encoding.GetBytes(value);

            ms.Write(
                bytes,
                0,
                bytes.Length);
        }

        W("%PDF-1.4\n%âãÏÓ\n");

        var offsets =
            new long[objectCount + 1];

        for (var i = 1; i <= objectCount; i++)
        {
            offsets[i] =
                ms.Position;

            W(
                $"{i} 0 obj\n{objects[i]}\nendobj\n");
        }

        var xref =
            ms.Position;

        W(
            $"xref\n0 {objectCount + 1}\n0000000000 65535 f \n");

        for (var i = 1; i <= objectCount; i++)
        {
            W(
                $"{offsets[i]:D10} 00000 n \n");
        }

        W(
            $"trailer\n<< /Size {objectCount + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF");

        return ms.ToArray();
    }

    private static void DrawText(
        StringBuilder sb,
        string text,
        float x,
        float y,
        float size,
        bool bold,
        float r,
        float g,
        float b)
    {
        sb.AppendFormat(
            CultureInfo.InvariantCulture,
            "BT /{0} {1:0.##} Tf {2:0.##} {3:0.##} Td {4:0.###} {5:0.###} {6:0.###} rg ({7}) Tj ET\n",
            bold ? "F2" : "F1",
            size,
            x,
            y,
            r,
            g,
            b,
            PdfText(text));
    }

    private static void FillRect(
        StringBuilder sb,
        float x,
        float y,
        float w,
        float h,
        float r,
        float g,
        float b)
    {
        sb.AppendFormat(
            CultureInfo.InvariantCulture,
            "{0:0.###} {1:0.###} {2:0.###} rg {3:0.##} {4:0.##} {5:0.##} {6:0.##} re f\n",
            r,
            g,
            b,
            x,
            y,
            w,
            h);
    }

    private static string Safe(string value)
    {
        return (value ?? string.Empty)
            .Replace("\r", " ")
            .Replace("\n", " ")
            .Trim();
    }

    private static string PdfText(string value)
    {
        var normalized =
            value
                .Replace("–", "-")
                .Replace("—", "-")
                .Replace("…", "...")
                .Replace("“", "\"")
                .Replace("”", "\"")
                .Replace("’", "'");

        return normalized
            .Replace("\\", "\\\\")
            .Replace("(", "\\(")
            .Replace(")", "\\)");
    }
}