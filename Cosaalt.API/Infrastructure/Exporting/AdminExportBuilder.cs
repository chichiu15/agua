using System.Globalization;
using System.IO.Compression;
using System.Security;
using System.Text;
using Cosaalt.API.Application.DTOs;

namespace Cosaalt.API.Infrastructure.Exporting;

public static class AdminExportBuilder
{
    private const string Company = "COSAALT R.L.";
    private const string Module = "Sistema de Gestión de Medidores";

    private sealed record PdfColumn(string Header, float Width, Func<object, string> Value, int MaxChars = 30);

    public static byte[] MovimientosExcel(IReadOnlyList<AdminMovimientoDto> items)
    {
        var headers = new[]
        {
            "Fecha y hora", "Origen", "ID origen", "CodCon", "Socio", "Dirección",
            "Medidor retirado", "Marca retirada", "Lectura retiro", "Motivo",
            "Medidor instalado", "Marca instalada", "Observaciones", "Técnico",
            "Sincronizado", "Evidencias"
        };
        var rows = items.Select(x => (IReadOnlyList<string>)new[]
        {
            x.FechaHora.ToString("dd/MM/yyyy HH:mm"), x.TipoOrigen, x.IdOrigen,
            x.CodCon.ToString(CultureInfo.InvariantCulture), x.NombreCliente, x.Direccion,
            x.NumeroMedidorRetirado, x.MarcaRetirado ?? string.Empty,
            x.LecturaRetiro.ToString("0.00", CultureInfo.InvariantCulture), x.Motivo,
            x.NumeroMedidorInstalado, x.MarcaInstalado ?? string.Empty,
            x.Observaciones ?? string.Empty, x.NombreTecnico,
            x.Sincronizado ? "Sí" : "No", x.Evidencias.ToString(CultureInfo.InvariantCulture)
        }).ToList();
        var widths = new[] { 19d, 12, 15, 12, 28, 36, 20, 18, 16, 26, 20, 18, 40, 28, 14, 12 };
        return BuildProfessionalXlsx(
            "Movimiento de Medidores",
            "Registro de cambios de medidor realizados desde el sistema",
            "Movimientos",
            headers,
            rows,
            widths);
    }

    public static byte[] MovimientosPdf(IReadOnlyList<AdminMovimientoDto> items, string titulo)
    {
        var columns = new[]
        {
            new PdfColumn("FECHA", 78, o => ((AdminMovimientoDto)o).FechaHora.ToString("dd/MM/yy HH:mm"), 16),
            new PdfColumn("ORIGEN", 50, o => ((AdminMovimientoDto)o).TipoOrigen, 9),
            new PdfColumn("CODCON", 58, o => ((AdminMovimientoDto)o).CodCon.ToString(), 10),
            new PdfColumn("SOCIO", 128, o => ((AdminMovimientoDto)o).NombreCliente, 28),
            new PdfColumn("RETIRADO", 88, o => $"{((AdminMovimientoDto)o).NumeroMedidorRetirado} / {((AdminMovimientoDto)o).MarcaRetirado ?? "-"}", 18),
            new PdfColumn("INSTALADO", 88, o => $"{((AdminMovimientoDto)o).NumeroMedidorInstalado} / {((AdminMovimientoDto)o).MarcaInstalado ?? "-"}", 18),
            new PdfColumn("MOTIVO", 110, o => ((AdminMovimientoDto)o).Motivo, 23),
            new PdfColumn("TÉCNICO", 120, o => ((AdminMovimientoDto)o).NombreTecnico, 25)
        };
        return BuildTablePdf(
            titulo,
            "Listado de cambios de medidor registrados en el sistema",
            items.Cast<object>().ToList(),
            columns);
    }

    public static byte[] HistoricoCorporativoExcel(IReadOnlyList<AdminMovimientoCorporativoDto> items)
    {
        var headers = new[]
        {
            "Código movimiento", "CodCon", "Socio", "Dirección", "Medidor", "Marca",
            "Vigente", "ID motivo", "Motivo", "Orden de trabajo", "Descripción"
        };
        var rows = items.Select(x => (IReadOnlyList<string>)new[]
        {
            x.CodCaMe.ToString(), x.CodCon.ToString(), x.NombreCliente, x.Direccion,
            x.NumeroMedidor, x.Marca ?? string.Empty, x.Vigente ? "Sí" : "No",
            x.IdMotivo?.ToString() ?? string.Empty, x.Motivo ?? string.Empty,
            x.CodOrdenTrabajo?.ToString() ?? string.Empty, x.Descripcion ?? string.Empty
        }).ToList();
        var widths = new[] { 18d, 12, 30, 38, 20, 18, 12, 13, 28, 18, 42 };
        return BuildProfessionalXlsx(
            "Histórico de Medidores",
            "Consulta del historial corporativo de medidores por conexión",
            "Histórico",
            headers,
            rows,
            widths);
    }

    public static byte[] HistoricoCorporativoPdf(IReadOnlyList<AdminMovimientoCorporativoDto> items)
    {
        var columns = new[]
        {
            new PdfColumn("CÓDIGO", 65, o => ((AdminMovimientoCorporativoDto)o).CodCaMe.ToString(), 10),
            new PdfColumn("CODCON", 60, o => ((AdminMovimientoCorporativoDto)o).CodCon.ToString(), 10),
            new PdfColumn("SOCIO", 155, o => ((AdminMovimientoCorporativoDto)o).NombreCliente, 34),
            new PdfColumn("MEDIDOR", 100, o => ((AdminMovimientoCorporativoDto)o).NumeroMedidor, 20),
            new PdfColumn("MARCA", 80, o => ((AdminMovimientoCorporativoDto)o).Marca ?? "-", 16),
            new PdfColumn("VIGENTE", 58, o => ((AdminMovimientoCorporativoDto)o).Vigente ? "Sí" : "No", 7),
            new PdfColumn("MOTIVO", 125, o => ((AdminMovimientoCorporativoDto)o).Motivo ?? "-", 27),
            new PdfColumn("O.T.", 70, o => ((AdminMovimientoCorporativoDto)o).CodOrdenTrabajo?.ToString() ?? "-", 12)
        };
        return BuildTablePdf(
            "Histórico Corporativo de Medidores",
            "Consulta institucional del historial de medidores",
            items.Cast<object>().ToList(),
            columns);
    }

    public static byte[] VerificacionesExcel(IReadOnlyList<AdminVerificacionResumenDto> items)
    {
        var headers = new[]
        {
            "Verificación", "Fecha", "Origen", "ID origen", "CodCon", "Socio",
            "Medidor", "Mecánico", "Estado", "Resultado", "Error (%)", "Caudal",
            "Fugas", "Nro. informe", "Informe firmado"
        };
        var rows = items.Select(x => (IReadOnlyList<string>)new[]
        {
            $"VER-{x.IdVerificacion}", x.Fecha.ToString("dd/MM/yyyy HH:mm"), x.TipoOrigen,
            x.IdOrigen, x.CodCon.ToString(), x.NombreCliente, x.NumeroMedidor ?? string.Empty,
            x.NombreMecanico, x.Estado, x.Resultado ?? string.Empty,
            x.Error?.ToString("0.####", CultureInfo.InvariantCulture) ?? string.Empty,
            x.Caudal?.ToString("0.####", CultureInfo.InvariantCulture) ?? string.Empty,
            x.Fugas.HasValue ? (x.Fugas.Value ? "Sí" : "No") : string.Empty,
            x.NroInforme ?? string.Empty, x.InformeFirmado ? "Sí" : "No"
        }).ToList();
        var widths = new[] { 16d, 19, 12, 15, 12, 30, 20, 28, 16, 16, 14, 14, 11, 20, 16 };
        return BuildProfessionalXlsx(
            "Verificaciones de Medidores",
            "Seguimiento de verificaciones metrológicas y resultados",
            "Verificaciones",
            headers,
            rows,
            widths);
    }

    public static byte[] VerificacionesPdf(IReadOnlyList<AdminVerificacionResumenDto> items, string titulo)
    {
        var columns = new[]
        {
            new PdfColumn("ID", 62, o => $"VER-{((AdminVerificacionResumenDto)o).IdVerificacion}", 10),
            new PdfColumn("FECHA", 78, o => ((AdminVerificacionResumenDto)o).Fecha.ToString("dd/MM/yy HH:mm"), 16),
            new PdfColumn("CODCON", 58, o => ((AdminVerificacionResumenDto)o).CodCon.ToString(), 10),
            new PdfColumn("SOCIO", 125, o => ((AdminVerificacionResumenDto)o).NombreCliente, 27),
            new PdfColumn("MECÁNICO", 120, o => ((AdminVerificacionResumenDto)o).NombreMecanico, 25),
            new PdfColumn("ESTADO", 76, o => ((AdminVerificacionResumenDto)o).Estado, 14),
            new PdfColumn("RESULTADO", 82, o => ((AdminVerificacionResumenDto)o).Resultado ?? "-", 14),
            new PdfColumn("ERROR", 58, o => ((AdminVerificacionResumenDto)o).Error.HasValue ? $"{((AdminVerificacionResumenDto)o).Error:0.###}%" : "-", 9),
            new PdfColumn("INFORME", 78, o => ((AdminVerificacionResumenDto)o).NroInforme ?? "-", 14)
        };
        return BuildTablePdf(
            titulo,
            "Resumen administrativo de verificaciones metrológicas",
            items.Cast<object>().ToList(),
            columns);
    }

    private static byte[] BuildProfessionalXlsx(
        string title,
        string subtitle,
        string sheetName,
        IReadOnlyList<string> headers,
        IReadOnlyList<IReadOnlyList<string>> rows,
        IReadOnlyList<double> widths)
    {
        using var stream = new MemoryStream();
        using (var zip = new ZipArchive(stream, ZipArchiveMode.Create, leaveOpen: true))
        {
            Write(zip, "[Content_Types].xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
                </Types>
                """);
            Write(zip, "_rels/.rels", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                </Relationships>
                """);
            Write(zip, "xl/workbook.xml", $"""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                  <sheets><sheet name="{Xml(SafeSheetName(sheetName))}" sheetId="1" r:id="rId1"/></sheets>
                </workbook>
                """);
            Write(zip, "xl/_rels/workbook.xml.rels", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
                </Relationships>
                """);
            Write(zip, "xl/styles.xml", BuildStylesXml());

            var lastCol = ColumnName(headers.Count);
            var sheet = new StringBuilder();
            sheet.Append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>");
            sheet.Append("<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">");
            sheet.Append("<sheetViews><sheetView workbookViewId=\"0\" showGridLines=\"0\"><pane ySplit=\"5\" topLeftCell=\"A6\" activePane=\"bottomLeft\" state=\"frozen\"/></sheetView></sheetViews>");
            sheet.Append("<sheetFormatPr defaultRowHeight=\"18\"/>");
            sheet.Append("<cols>");
            for (var i = 0; i < headers.Count; i++)
            {
                var width = i < widths.Count ? widths[i] : 18;
                sheet.Append($"<col min=\"{i + 1}\" max=\"{i + 1}\" width=\"{width.ToString("0.##", CultureInfo.InvariantCulture)}\" customWidth=\"1\"/>");
            }
            sheet.Append("</cols><sheetData>");

            AddMergedRow(sheet, 1, headers.Count, title, 1, 28);
            AddMergedRow(sheet, 2, headers.Count, subtitle, 2, 22);
            AddMergedRow(sheet, 3, headers.Count, $"Generado: {DateTime.Now:dd/MM/yyyy HH:mm}    |    Total de registros: {rows.Count}", 3, 20);
            AddMergedRow(sheet, 4, headers.Count, string.Empty, 5, 8);

            sheet.Append("<row r=\"5\" ht=\"26\" customHeight=\"1\">");
            for (var c = 0; c < headers.Count; c++)
                AddCell(sheet, ColumnName(c + 1) + "5", headers[c], 4);
            sheet.Append("</row>");

            for (var r = 0; r < rows.Count; r++)
            {
                var excelRow = r + 6;
                var style = r % 2 == 0 ? 5 : 6;
                sheet.Append($"<row r=\"{excelRow}\" ht=\"22\" customHeight=\"1\">");
                for (var c = 0; c < headers.Count; c++)
                {
                    var value = c < rows[r].Count ? rows[r][c] : string.Empty;
                    AddCell(sheet, ColumnName(c + 1) + excelRow, value, style);
                }
                sheet.Append("</row>");
            }
            sheet.Append("</sheetData>");
            // El orden de los elementos de Worksheet importa para Excel.
            // autoFilter debe aparecer antes de mergeCells según SpreadsheetML.
            sheet.Append($"<autoFilter ref=\"A5:{lastCol}{Math.Max(5, rows.Count + 5)}\"/>");
            sheet.Append($"<mergeCells count=\"4\"><mergeCell ref=\"A1:{lastCol}1\"/><mergeCell ref=\"A2:{lastCol}2\"/><mergeCell ref=\"A3:{lastCol}3\"/><mergeCell ref=\"A4:{lastCol}4\"/></mergeCells>");
            sheet.Append("<pageMargins left=\"0.25\" right=\"0.25\" top=\"0.5\" bottom=\"0.5\" header=\"0.2\" footer=\"0.2\"/>");
            sheet.Append("<pageSetup orientation=\"landscape\" paperSize=\"9\" fitToWidth=\"1\" fitToHeight=\"0\"/>");
            sheet.Append("</worksheet>");
            Write(zip, "xl/worksheets/sheet1.xml", sheet.ToString());
        }
        return stream.ToArray();
    }

    private static string BuildStylesXml() => """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="4">
            <font><sz val="10"/><name val="Calibri"/><color rgb="FF1F2933"/></font>
            <font><b/><sz val="16"/><name val="Calibri"/><color rgb="FF006B3F"/></font>
            <font><sz val="11"/><name val="Calibri"/><color rgb="FF5B6570"/></font>
            <font><b/><sz val="10"/><name val="Calibri"/><color rgb="FFFFFFFF"/></font>
          </fonts>
          <fills count="5">
            <fill><patternFill patternType="none"/></fill>
            <fill><patternFill patternType="gray125"/></fill>
            <fill><patternFill patternType="solid"><fgColor rgb="FF006B3F"/><bgColor indexed="64"/></patternFill></fill>
            <fill><patternFill patternType="solid"><fgColor rgb="FFEAF6EF"/><bgColor indexed="64"/></patternFill></fill>
            <fill><patternFill patternType="solid"><fgColor rgb="FFF7F9F8"/><bgColor indexed="64"/></patternFill></fill>
          </fills>
          <borders count="2">
            <border/>
            <border><left style="thin"><color rgb="FFDCE3DF"/></left><right style="thin"><color rgb="FFDCE3DF"/></right><top style="thin"><color rgb="FFDCE3DF"/></top><bottom style="thin"><color rgb="FFDCE3DF"/></bottom></border>
          </borders>
          <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
          <cellXfs count="7">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
            <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>
            <xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>
            <xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>
            <xf numFmtId="0" fontId="3" fillId="2" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="left" vertical="center" wrapText="1"/></xf>
            <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="left" vertical="top" wrapText="1"/></xf>
            <xf numFmtId="0" fontId="0" fillId="4" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="left" vertical="top" wrapText="1"/></xf>
          </cellXfs>
          <cellStyles count="1">
            <cellStyle name="Normal" xfId="0" builtinId="0"/>
          </cellStyles>
          <dxfs count="0"/>
          <tableStyles count="0" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>
        </styleSheet>
        """;

    private static byte[] BuildTablePdf(string title, string subtitle, IReadOnlyList<object> rows, IReadOnlyList<PdfColumn> columns)
    {
        const float width = 842;
        const float height = 595;
        const float marginX = 28;
        const float top = 567;
        const float tableTop = 474;
        const float headerH = 28;
        const float rowH = 26;
        const float footerY = 20;
        var rowsPerPage = (int)Math.Floor((tableTop - footerY - headerH - 18) / rowH);
        rowsPerPage = Math.Max(1, rowsPerPage);
        var pages = rows.Count == 0 ? 1 : (int)Math.Ceiling(rows.Count / (double)rowsPerPage);

        var pdfPages = new List<string>();
        for (var page = 0; page < pages; page++)
        {
            var content = new StringBuilder();
            // Header brand bar
            FillRect(content, 0, height - 9, width, 9, 0f, 0.42f, 0.25f);
            DrawText(content, Company, marginX, top, 15, bold: true, 0f, 0.42f, 0.25f);
            DrawText(content, Module, marginX, top - 19, 8.5f, false, .35f, .39f, .42f);
            DrawText(content, title, marginX, top - 47, 17, true, .10f, .14f, .17f);
            DrawText(content, subtitle, marginX, top - 64, 9.5f, false, .35f, .39f, .42f);
            DrawText(content, $"Generado: {DateTime.Now:dd/MM/yyyy HH:mm}   |   Registros: {rows.Count}", marginX, top - 80, 8, false, .40f, .43f, .46f);

            // Table header
            var x = marginX;
            foreach (var col in columns)
            {
                FillRect(content, x, tableTop - headerH, col.Width, headerH, 0f, 0.42f, 0.25f);
                StrokeRect(content, x, tableTop - headerH, col.Width, headerH, .82f, .86f, .84f);
                DrawText(content, Truncate(col.Header, 18), x + 4, tableTop - 18, 7.2f, true, 1, 1, 1);
                x += col.Width;
            }

            var first = page * rowsPerPage;
            var last = Math.Min(rows.Count, first + rowsPerPage);
            var y = tableTop - headerH;
            for (var i = first; i < last; i++)
            {
                y -= rowH;
                if ((i - first) % 2 == 1)
                    FillRect(content, marginX, y, columns.Sum(c => c.Width), rowH, .97f, .98f, .975f);
                x = marginX;
                foreach (var col in columns)
                {
                    StrokeRect(content, x, y, col.Width, rowH, .84f, .87f, .85f);
                    var value = Truncate(col.Value(rows[i]), col.MaxChars);
                    DrawText(content, value, x + 4, y + 9, 7.1f, false, .12f, .15f, .17f);
                    x += col.Width;
                }
            }

            if (rows.Count == 0)
                DrawText(content, "No existen registros para los filtros seleccionados.", marginX, tableTop - 55, 10, false, .40f, .43f, .46f);

            DrawText(content, $"Página {page + 1} de {pages}", width - 95, footerY, 8, false, .40f, .43f, .46f);
            DrawText(content, Company, marginX, footerY, 8, false, .40f, .43f, .46f);
            pdfPages.Add(content.ToString());
        }
        return BuildPdfDocument(pdfPages, landscape: true);
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

    private static void StrokeRect(StringBuilder sb, float x, float y, float w, float h, float r, float g, float b) =>
        sb.AppendFormat(CultureInfo.InvariantCulture, "{0:0.###} {1:0.###} {2:0.###} RG 0.5 w {3:0.##} {4:0.##} {5:0.##} {6:0.##} re S\n", r, g, b, x, y, w, h);

    private static void AddMergedRow(StringBuilder sheet, int row, int colCount, string value, int style, int height)
    {
        sheet.Append($"<row r=\"{row}\" ht=\"{height}\" customHeight=\"1\">");
        AddCell(sheet, $"A{row}", value, style);
        for (var c = 2; c <= colCount; c++) AddCell(sheet, $"{ColumnName(c)}{row}", string.Empty, style);
        sheet.Append("</row>");
    }

    private static void AddCell(StringBuilder sheet, string cell, string value, int style) =>
        sheet.Append($"<c r=\"{cell}\" t=\"inlineStr\" s=\"{style}\"><is><t xml:space=\"preserve\">{Xml(value)}</t></is></c>");

    private static string Truncate(string? value, int max)
    {
        var v = (value ?? string.Empty).Replace("\r", " ").Replace("\n", " ").Trim();
        return v.Length <= max ? v : v[..Math.Max(1, max - 1)] + "…";
    }

    private static string SafeSheetName(string value)
    {
        var cleaned = string.Concat(value.Select(c => "[]:*?/\\".Contains(c) ? '_' : c));
        return cleaned.Length <= 31 ? cleaned : cleaned[..31];
    }

    private static void Write(ZipArchive zip, string path, string content)
    {
        var entry = zip.CreateEntry(path, CompressionLevel.Optimal);
        using var writer = new StreamWriter(entry.Open(), new UTF8Encoding(false));
        writer.Write(content);
    }

    // SQL Server puede contener caracteres de control heredados (0x00, 0x0B, 0x0C, etc.)
    // que son válidos dentro de un varchar/nvarchar pero NO son válidos en XML 1.0.
    // Si uno de esos caracteres entra a sheet1.xml, Excel abre el .xlsx reparándolo.
    // Limpiamos exclusivamente caracteres inválidos de XML antes de escapar el texto.
    private static string Xml(string? value)
    {
        if (string.IsNullOrEmpty(value))
            return string.Empty;

        var cleaned = new StringBuilder(value.Length);

        foreach (var rune in value.EnumerateRunes())
        {
            var codePoint = rune.Value;
            var validXml10 =
                codePoint == 0x9 ||
                codePoint == 0xA ||
                codePoint == 0xD ||
                (codePoint >= 0x20 && codePoint <= 0xD7FF) ||
                (codePoint >= 0xE000 && codePoint <= 0xFFFD) ||
                (codePoint >= 0x10000 && codePoint <= 0x10FFFF);

            if (validXml10)
                cleaned.Append(rune.ToString());
        }

        return SecurityElement.Escape(cleaned.ToString()) ?? string.Empty;
    }

    private static string ColumnName(int number)
    {
        var name = string.Empty;
        while (number > 0)
        {
            number--;
            name = (char)('A' + number % 26) + name;
            number /= 26;
        }
        return name;
    }

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
