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
    string MotivoObservacion,
    string MedidorMarca,
    string MedidorSerie,
    string MedidorCapacidad,
    string MedidorTipo,
    string MedidorClase,
    string MedidorDiametro,
    string MedidorFechaRegistro,
    string FechaVerificacion,
    string LugarVerificacion,
    string TipoPrueba,
    string InstrumentoBanco,
    string IdentificacionBanco,
    string TrazabilidadCalibracion,
    string TipoCaudal,
    string Caudal,
    string UnidadCaudal,
    string UnidadVolumen,
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
    string CargoResponsable,
    string NombreDestinatario,
    string CargoDestinatario,
    string Referencia,
    string DescripcionTecnica,
    string ConclusionAdicional,
    string Recomendacion,
    IReadOnlyList<(string Nombre, string Cargo, string Rol)> Participantes);

/// <summary>
/// Genera el informe técnico con la misma organización documental utilizada
/// por COSAALT para sus informes de verificación metrológica: encabezado
/// DE/A/REF/FECHA, secciones romanas I-VII, resultados, fórmula, conclusiones,
/// recomendación y firma final.
///
/// Los datos metrológicos provienen de la verificación y los campos narrativos
/// variables de la emisión (DE/A, referencia, textos complementarios y recomendación)
/// son proporcionados por el responsable. Resultado y fugas se mantienen separados
/// para no alterar la regla técnica de M6.
/// </summary>
public static class InformePdfBuilder
{
    private const float Width = 595f;
    private const float PageHeight = 842f;
    private const float MarginLeft = 58f;
    private const float MarginRight = 58f;
    private const float Top = 790f;
    private const float BottomLimit = 62f;
    private const float BodySize = 10.5f;
    private const float LineHeight = 14.2f;

    private const string CargoResponsableDefault =
        "RESPONSABLE LABORATORIO DE MEDIDORES COSAALT R.L.";

    private const string CargoDestinatarioDefault =
        "JEFE DPTO. SERVICIO AL CLIENTE – ODECO COSAALT R.L.";

    public static byte[] Build(InformePdfData d)
    {
        var doc = new DocumentWriter(d);
        doc.Write();

        return BuildPdfDocument(
            doc.Pages
                .Select(x => x.ToString())
                .ToArray());
    }

    private sealed class DocumentWriter
    {
        private readonly InformePdfData _d;
        private StringBuilder _page = NewPage();
        private float _y = Top;

        public DocumentWriter(InformePdfData d)
        {
            _d = d;
            Pages.Add(_page);
        }

        public List<StringBuilder> Pages { get; } = [];

        public void Write()
        {
            WriteHeading();
            WriteDatosGenerales();
            WriteObjetivo();
            WriteParticipantes();
            WriteDescripcionPrueba();
            WriteInterpretacion();
            WriteConclusiones();
            WriteRecomendacion();
            WriteFirma();
        }

        private void WriteHeading()
        {
            DrawCentered(
                _page,
                "INFORME TÉCNICO DE VERIFICACIÓN METROLÓGICA",
                _y,
                13.5f,
                Font.Bold);

            _y -= 40f;

            FieldLine("DE:", SafeValue(_d.Responsable));

            BoldLine(
                IsEmpty(_d.CargoResponsable)
                    ? CargoResponsableDefault
                    : _d.CargoResponsable,
                11.2f);

            _y -= 4f;

            FieldLine("A:", SafeValue(_d.NombreDestinatario));

            BoldLine(
                IsEmpty(_d.CargoDestinatario)
                    ? CargoDestinatarioDefault
                    : _d.CargoDestinatario,
                11.2f);

            _y -= 4f;

            var referencia = BuildReferencia();

            FieldParagraph("REF.:", referencia, Font.Italic);
            FieldLine("FECHA:", SpanishDate(_d.FechaEmision));

            // El NroInforme y la versión se conservan en BD/historial y en el
            // nombre físico del archivo. No se imprimen aquí para respetar el
            // formato institucional entregado por COSAALT.
            _y -= 8f;
        }

        private void WriteDatosGenerales()
        {
            SectionTitle("I. DATOS GENERALES DEL MEDIDOR");

            Ensure(32f);

            DrawText(
                _page,
                "Parámetro",
                MarginLeft,
                _y,
                10.5f,
                Font.Bold);

            DrawText(
                _page,
                "Detalle",
                MarginLeft + 165f,
                _y,
                10.5f,
                Font.Bold);

            _y -= 18f;

            DataRow("Usuario:", _d.SocioNombre);
            DataRow("Código:", _d.CodConexion);
            DataRow("Registro de Usuario:", _d.RegSoc);
            DataRow("Marca:", _d.MedidorMarca);
            DataRow("Número de Serie:", _d.MedidorSerie);

            DataRow(
                "Capacidad Nominal (Q3):",
                FormatWithUnit(_d.MedidorCapacidad, "m³/h"));

            DataRow(
                "Lectura Inicial:",
                FormatWithUnit(_d.PrimeraLectura, _d.UnidadVolumen));

            DataRow(
                "Fecha de Verificación:",
                DateOnly(_d.FechaVerificacion));

            DataRow(
                "Lugar de Verificación:",
                BuildLugar());

            DataRow(
                "Tipo de ensayo:",
                _d.TipoPrueba);

            _y -= 8f;
        }

        private void WriteObjetivo()
        {
            SectionTitle("II. OBJETIVO DE LA PRUEBA");

            Paragraph(
                "Determinar el estado de calibración y exactitud metrológica del " +
                "micromedidor verificado, conforme a los criterios establecidos " +
                "en la Norma Boliviana NB ISO 4064 para medidores de agua, con el " +
                "fin de comprobar si el instrumento se encuentra dentro de los " +
                "límites de error aplicables para su correcta utilización en la " +
                "medición del servicio de agua potable.");

            _y -= 8f;
        }

        private void WriteParticipantes()
        {
            SectionTitle("III. PERSONAL PARTICIPANTE");

            Paragraph(
                "La prueba fue realizada en presencia de:",
                indent: 0f);

            var representantes = _d.Participantes
                .Where(IsRepresentanteUsuario)
                .ToList();

            var personal = _d.Participantes
                .Where(p => !IsRepresentanteUsuario(p))
                .ToList();

            Bullet(
                "Personal de COSAALT R.L.:",
                bold: true);

            if (personal.Count == 0)
            {
                SubBullet(
                    $"Técnico Verificador ({SafeValue(_d.Mecanico)}).");
            }
            else
            {
                foreach (var p in personal)
                {
                    var detalle = JoinParticipant(p);
                    SubBullet(detalle);
                }

                if (!personal.Any(p =>
                        p.Nombre.Equals(
                            _d.Mecanico,
                            StringComparison.OrdinalIgnoreCase)))
                {
                    SubBullet(
                        $"Técnico Verificador ({SafeValue(_d.Mecanico)}).");
                }
            }

            if (representantes.Count > 0)
            {
                Bullet(
                    "Representante del Usuario:",
                    bold: true);

                foreach (var p in representantes)
                {
                    SubBullet(JoinParticipant(p));
                }
            }

            var origen = SafeValue(_d.MotivoOrigen);

            Paragraph(
                $"El procedimiento se desarrolló por solicitud registrada con origen {origen}.",
                indent: 0f);

            _y -= 5f;
        }

        private void WriteDescripcionPrueba()
        {
            SectionTitle("IV. DESCRIPCIÓN DE LA PRUEBA REALIZADA");

            NumberedParagraph(
                1,
                $"Se utilizó {DescribeBanco()}, bajo condiciones registradas para " +
                "la verificación y con la trazabilidad disponible en el sistema.");

            if (!IsEmpty(_d.DescripcionTecnica))
            {
                Paragraph(
                    _d.DescripcionTecnica,
                    indent: 18f);
            }

            BoldLine(
                "Condiciones del Ensayo:",
                BodySize,
                indent: 28f);

            SubBullet(
                $"Tipo de prueba: {SafeValue(_d.TipoPrueba)}.",
                40f);

            SubBullet(
                $"Volumen patrón aplicado: " +
                $"{FormatWithUnit(_d.VolumenPatron, _d.UnidadVolumen)}.",
                40f);

            SubBullet(
                $"Caudal de ensayo: {SafeValue(_d.TipoCaudal)} - " +
                $"{FormatWithUnit(_d.Caudal, _d.UnidadCaudal)}.",
                40f);

            if (!IsEmpty(_d.Condiciones) &&
                _d.Condiciones != "-")
            {
                SubBullet(
                    $"Condiciones registradas: {_d.Condiciones}.",
                    40f);
            }

            var bancoDetalle = string.Join(
                " - ",
                new[]
                {
                    Clean(_d.IdentificacionBanco),
                    Clean(_d.TrazabilidadCalibracion)
                }
                .Where(x => !string.IsNullOrWhiteSpace(x)));

            if (!string.IsNullOrWhiteSpace(bancoDetalle))
            {
                SubBullet(
                    $"Identificación / trazabilidad: {bancoDetalle}.",
                    40f);
            }

            NumberedParagraph(
                2,
                $"Caudal de ensayo: {SafeValue(_d.TipoCaudal)}, " +
                $"{FormatWithUnit(_d.Caudal, _d.UnidadCaudal)}.");

            BoldLine(
                "Resultados obtenidos:",
                BodySize);

            ResultsTable();

            BoldLine(
                "Cálculo del error relativo:",
                BodySize);

            DrawFormula();

            _y -= 10f;
        }

        private void WriteInterpretacion()
        {
            SectionTitle(
                "V. INTERPRETACIÓN DE RESULTADOS SEGÚN NORMA NB ISO 4064");

            var result = NormalizedResult();
            var error = WithPercent(_d.ErrorAbsoluto);
            var limite = WithPercent(_d.LimitePermitido);

            string text;

            if (result == "CUMPLE")
            {
                text =
                    $"El error relativo obtenido del micromedidor ({error}) se encuentra " +
                    $"dentro del límite máximo permitido aplicado ({limite}), correspondiente " +
                    $"al parámetro normativo {SafeValue(_d.ParametroNormativo)}. Por lo tanto, " +
                    "el instrumento CUMPLE con el criterio metrológico evaluado.";
            }
            else if (result == "NO CUMPLE")
            {
                text =
                    $"El error relativo obtenido del micromedidor ({error}) supera el límite " +
                    $"máximo permitido aplicado ({limite}), correspondiente al parámetro " +
                    $"normativo {SafeValue(_d.ParametroNormativo)}. Por lo tanto, el instrumento " +
                    "NO CUMPLE con el criterio metrológico evaluado.";
            }
            else
            {
                text =
                    "El resultado se clasifica como INDETERMINADO debido a que no existe un " +
                    "parámetro normativo aplicable suficiente para emitir una conclusión de " +
                    "cumplimiento para las condiciones registradas. Parámetro registrado: " +
                    $"{SafeValue(_d.ParametroNormativo)}.";
            }

            Paragraph(text);

            _y -= 6f;
        }

        private void WriteConclusiones()
        {
            SectionTitle("VI. CONCLUSIONES TÉCNICAS");

            var result = NormalizedResult();

            var medidor =
                $"{SafeValue(_d.MedidorMarca)} " +
                $"N.° {SafeValue(_d.MedidorSerie)} " +
                $"({FormatWithUnit(_d.MedidorCapacidad, "m³/h")})";

            if (result == "CUMPLE")
            {
                NumberedParagraph(
                    1,
                    $"El micromedidor {medidor} presenta un error relativo de " +
                    $"{WithPercent(_d.ErrorConSigno)}, encontrándose dentro de los límites " +
                    "de error aplicables; por tanto, se considera metrológicamente conforme " +
                    "para las condiciones del ensayo realizado.");
            }
            else if (result == "NO CUMPLE")
            {
                NumberedParagraph(
                    1,
                    $"El micromedidor {medidor} presenta un error relativo de " +
                    $"{WithPercent(_d.ErrorConSigno)}, fuera del límite permitido aplicado; " +
                    "por tanto, se considera metrológicamente no conforme para las condiciones " +
                    "del ensayo realizado.");
            }
            else
            {
                NumberedParagraph(
                    1,
                    $"El micromedidor {medidor} presenta un resultado INDETERMINADO, por no " +
                    "disponerse de un criterio normativo aplicable suficiente para concluir " +
                    "cumplimiento o incumplimiento en las condiciones registradas.");
            }

            NumberedParagraph(
                2,
                $"Volumen registrado por el medidor (Vm): " +
                $"{FormatWithUnit(_d.VolumenRegistrado, _d.UnidadVolumen)}; " +
                $"volumen patrón real (Vr): " +
                $"{FormatWithUnit(_d.VolumenPatron, _d.UnidadVolumen)}; " +
                $"error relativo: {WithPercent(_d.ErrorConSigno)}.");

            if (IsYes(_d.Fugas))
            {
                NumberedParagraph(
                    3,
                    "Al momento de la inspección y/o revisión SÍ se evidenciaron fugas. " +
                    $"Tipo de fuga registrado: {SafeValue(_d.TipoFuga)}. La presencia de fuga " +
                    "se registra como una condición independiente y no modifica por sí sola " +
                    "el resultado metrológico del ensayo.");
            }
            else
            {
                NumberedParagraph(
                    3,
                    "Al momento de la inspección y/o revisión NO se evidenciaron fugas registradas.");
            }

            NumberedParagraph(
                4,
                result == "CUMPLE"
                    ? "La lectura del medidor se considera confiable para el alcance y condiciones del ensayo realizado."
                    : result == "NO CUMPLE"
                        ? "La lectura del medidor requiere evaluación técnica posterior antes de considerarse metrológicamente confiable para el alcance evaluado."
                        : "No corresponde afirmar confiabilidad metrológica definitiva hasta contar con un criterio normativo aplicable.");

            NumberedParagraph(
                5,
                "El ensayo fue realizado bajo supervisión técnica, con registro de " +
                $"instrumento/banco ({SafeValue(_d.InstrumentoBanco)}) y trazabilidad " +
                $"({SafeValue(_d.TrazabilidadCalibracion)}).");

            NumberedParagraph(
                6,
                BuildFinalConclusion(result));

            if (!IsEmpty(_d.ConclusionAdicional))
            {
                Paragraph(_d.ConclusionAdicional);
            }

            _y -= 6f;
        }

        private void WriteRecomendacion()
        {
            SectionTitle("VII. RECOMENDACIÓN");

            // La recomendación es criterio profesional del responsable.
            // El sistema no la inventa ni la modifica a partir de
            // CUMPLE / NO CUMPLE / INDETERMINADO.
            Paragraph(SafeValue(_d.Recomendacion));

            Paragraph(
                "Es cuanto se informa para fines consiguientes.");

            Paragraph("Atentamente,");

            _y -= 12f;
        }

        private void WriteFirma()
        {
            Ensure(115f);

            _y -= 42f;

            DrawCentered(
                _page,
                "________________________________",
                _y,
                10.5f,
                Font.Roman);

            _y -= 18f;

            DrawCentered(
                _page,
                SafeValue(_d.Responsable),
                _y,
                10.5f,
                Font.Roman);

            _y -= 17f;

            DrawCentered(
                _page,
                IsEmpty(_d.CargoResponsable)
                    ? CargoResponsableDefault
                    : _d.CargoResponsable,
                _y,
                10.3f,
                Font.Bold);
        }

        private void ResultsTable()
        {
            Ensure(132f);

            const float labelX = MarginLeft + 4f;
            const float valueX = MarginLeft + 260f;

            DrawText(
                _page,
                "Descripción",
                labelX,
                _y,
                10.5f,
                Font.Bold);

            DrawText(
                _page,
                "Valor",
                valueX,
                _y,
                10.5f,
                Font.Bold);

            _y -= 18f;

            ResultRow(
                "Primera Lectura del medidor",
                FormatWithUnit(
                    _d.PrimeraLectura,
                    _d.UnidadVolumen));

            ResultRow(
                "Segunda Lectura del medidor",
                FormatWithUnit(
                    _d.SegundaLectura,
                    _d.UnidadVolumen));

            ResultRow(
                "Volumen registrado por el medidor (Vm)",
                FormatWithUnit(
                    _d.VolumenRegistrado,
                    _d.UnidadVolumen),
                true);

            ResultRow(
                "Volumen patrón real (Vr)",
                FormatWithUnit(
                    _d.VolumenPatron,
                    _d.UnidadVolumen),
                true);

            ResultRow(
                "Error relativo (%)",
                WithPercent(_d.ErrorConSigno),
                true);

            _y -= 5f;
        }

        private void ResultRow(
            string label,
            string value,
            bool bold = false)
        {
            Ensure(18f);

            DrawText(
                _page,
                label,
                MarginLeft + 4f,
                _y,
                BodySize,
                bold ? Font.Bold : Font.Roman);

            DrawText(
                _page,
                value,
                MarginLeft + 260f,
                _y,
                BodySize,
                bold ? Font.Bold : Font.Roman);

            _y -= 18f;
        }

        private void DrawFormula()
        {
            Ensure(58f);

            var formulaText =
                "Error (%) = (Vm - Vr) / Vr x 100 = " +
                $"({_d.VolumenRegistrado} - {_d.VolumenPatron}) / " +
                $"{_d.VolumenPatron} x 100 = " +
                $"{WithPercent(_d.ErrorConSigno)}";

            foreach (var line in Wrap(formulaText, 88))
            {
                DrawCentered(
                    _page,
                    line,
                    _y,
                    10.5f,
                    Font.Roman);

                _y -= 16f;
            }
        }

        private void DataRow(
            string label,
            string value)
        {
            var valueLines = Wrap(
                    SafeValue(value),
                    48)
                .ToList();

            var rows = Math.Max(
                1,
                valueLines.Count);

            Ensure(
                rows * 16f + 2f);

            DrawText(
                _page,
                label,
                MarginLeft,
                _y,
                BodySize,
                Font.Bold);

            if (valueLines.Count == 0)
            {
                DrawText(
                    _page,
                    "No registrado",
                    MarginLeft + 165f,
                    _y,
                    BodySize,
                    Font.Roman);

                _y -= 16f;
                return;
            }

            foreach (var line in valueLines)
            {
                DrawText(
                    _page,
                    line,
                    MarginLeft + 165f,
                    _y,
                    BodySize,
                    Font.Roman);

                _y -= 16f;
            }
        }

        private void SectionTitle(string text)
        {
            Ensure(32f);

            _y -= 4f;

            DrawText(
                _page,
                text,
                MarginLeft,
                _y,
                11.6f,
                Font.Bold);

            _y -= 20f;
        }

        private void FieldLine(
     string label,
     string value,
     float valueOffset = 92f)
        {
            Ensure(19f);

            DrawText(
                _page,
                label,
                MarginLeft,
                _y,
                BodySize,
                Font.Bold);

            DrawText(
                _page,
                SafeValue(value),
                MarginLeft + valueOffset,
                _y,
                BodySize,
                Font.Roman);

            _y -= 18f;
        }

        private void FieldParagraph(
            string label,
            string value,
            Font valueFont)
        {
            var lines = Wrap(
                    SafeValue(value),
                    73)
                .ToList();

            Ensure(
                18f * Math.Max(
                    1,
                    lines.Count));

            DrawText(
                _page,
                label,
                MarginLeft,
                _y,
                BodySize,
                Font.Bold);

            foreach (var line in lines)
            {
                DrawText(
                    _page,
                    line,
                    MarginLeft + 38f,
                    _y,
                    BodySize,
                    valueFont);

                _y -= 17f;
            }
        }

        private void BoldLine(
            string text,
            float size,
            float indent = 0f)
        {
            var lines = Wrap(
                    SafeValue(text),
                    84)
                .ToList();

            Ensure(
                lines.Count * LineHeight + 2f);

            foreach (var line in lines)
            {
                DrawText(
                    _page,
                    line,
                    MarginLeft + indent,
                    _y,
                    size,
                    Font.Bold);

                _y -= LineHeight;
            }
        }

        private void Paragraph(
            string text,
            float indent = 0f)
        {
            var lines = Wrap(
                    SafeValue(text),
                    indent > 0 ? 78 : 88)
                .ToList();

            Ensure(
                Math.Min(
                    62f,
                    Math.Max(
                        1,
                        lines.Count) * LineHeight + 4f));

            foreach (var line in lines)
            {
                if (_y < BottomLimit + 18f)
                {
                    NewContinuationPage();
                }

                DrawText(
                    _page,
                    line,
                    MarginLeft + indent,
                    _y,
                    BodySize,
                    Font.Roman);

                _y -= LineHeight;
            }

            _y -= 3f;
        }

        private void NumberedParagraph(
            int number,
            string text)
        {
            var prefix = $"{number}.";

            var lines = Wrap(
                    SafeValue(text),
                    80)
                .ToList();

            Ensure(
                Math.Min(
                    65f,
                    Math.Max(
                        1,
                        lines.Count) * LineHeight + 4f));

            DrawText(
                _page,
                prefix,
                MarginLeft + 16f,
                _y,
                BodySize,
                Font.Bold);

            foreach (var line in lines)
            {
                if (_y < BottomLimit + 18f)
                {
                    NewContinuationPage();
                }

                DrawText(
                    _page,
                    line,
                    MarginLeft + 42f,
                    _y,
                    BodySize,
                    Font.Roman);

                _y -= LineHeight;
            }

            _y -= 3f;
        }

        private void Bullet(
            string text,
            bool bold = false,
            float indent = 18f)
        {
            Ensure(18f);

            DrawText(
                _page,
                "•",
                MarginLeft + indent,
                _y,
                BodySize,
                Font.Roman);

            DrawText(
                _page,
                SafeValue(text),
                MarginLeft + indent + 16f,
                _y,
                BodySize,
                bold ? Font.Bold : Font.Roman);

            _y -= 17f;
        }

        private void SubBullet(
            string text,
            float indent = 42f)
        {
            var lines = Wrap(
                    SafeValue(text),
                    72)
                .ToList();

            Ensure(
                Math.Max(
                    1,
                    lines.Count) * 16f);

            DrawText(
                _page,
                "o",
                MarginLeft + indent,
                _y,
                9f,
                Font.Roman);

            foreach (var line in lines)
            {
                DrawText(
                    _page,
                    line,
                    MarginLeft + indent + 18f,
                    _y,
                    BodySize,
                    Font.Roman);

                _y -= 16f;
            }
        }

        private void Ensure(float needed)
        {
            if (_y - needed >= BottomLimit)
            {
                return;
            }

            NewContinuationPage();
        }

        private void NewContinuationPage()
        {
            _page = NewPage();
            Pages.Add(_page);
            _y = Top;
        }

        private string BuildReferencia()
        {
            if (!IsEmpty(_d.Referencia))
            {
                return _d.Referencia;
            }

            var capacidad = SafeValue(
                _d.MedidorCapacidad);

            if (!capacidad.Contains(
                    "m³/h",
                    StringComparison.OrdinalIgnoreCase) &&
                !capacidad.Contains(
                    "m3/h",
                    StringComparison.OrdinalIgnoreCase))
            {
                capacidad =
                    $"{capacidad} m³/h";
            }

            return
                "Informe Técnico sobre Verificación del Micromedidor " +
                $"{SafeValue(_d.MedidorMarca)} " +
                $"{capacidad} " +
                $"N° {SafeValue(_d.MedidorSerie)}";
        }

        private string BuildLugar()
        {
            if (!IsEmpty(_d.LugarVerificacion) &&
                !_d.LugarVerificacion.Equals(
                    "No registrado",
                    StringComparison.OrdinalIgnoreCase))
            {
                if (!IsEmpty(_d.Direccion) &&
                    !_d.Direccion.Equals(
                        "No registrado",
                        StringComparison.OrdinalIgnoreCase))
                {
                    return
                        $"{_d.LugarVerificacion} - {_d.Direccion}";
                }

                return _d.LugarVerificacion;
            }

            if (!IsEmpty(_d.Direccion))
            {
                return
                    $"Domicilio del usuario - {_d.Direccion}";
            }

            return "No registrado";
        }

        private string DescribeBanco()
        {
            var banco = SafeValue(
                _d.InstrumentoBanco);

            var partes = new List<string>
            {
                banco
            };

            if (!IsEmpty(_d.IdentificacionBanco))
            {
                partes.Add(
                    $"identificado como {_d.IdentificacionBanco}");
            }

            if (!IsEmpty(_d.TrazabilidadCalibracion))
            {
                partes.Add(
                    $"con trazabilidad {_d.TrazabilidadCalibracion}");
            }

            return string.Join(
                ", ",
                partes);
        }

        private string BuildFinalConclusion(
            string result)
        {
            if (result == "CUMPLE")
            {
                return
                    "Se concluye que, para las condiciones del ensayo y el criterio " +
                    "normativo aplicado, el volumen registrado por el medidor guarda " +
                    "correspondencia metrológica aceptable con el volumen patrón utilizado.";
            }

            if (result == "NO CUMPLE")
            {
                return
                    "Se concluye que, para las condiciones del ensayo y el criterio " +
                    "normativo aplicado, el volumen registrado por el medidor presenta " +
                    "una desviación superior al límite permitido y requiere una acción " +
                    "técnica posterior.";
            }

            return
                "Se concluye que no corresponde emitir una declaración definitiva de " +
                "cumplimiento o incumplimiento hasta contar con el parámetro normativo " +
                "aplicable para las condiciones del ensayo.";
        }

        private string NormalizedResult()
        {
            var r = (_d.Resultado ?? string.Empty)
                .Trim()
                .ToUpperInvariant();

            return r is "CUMPLE" or "NO CUMPLE"
                ? r
                : "INDETERMINADO";
        }

        private static bool IsRepresentanteUsuario(
            (string Nombre, string Cargo, string Rol) p)
        {
            var value =
                $"{p.Cargo} {p.Rol}"
                    .ToLowerInvariant();

            return
                value.Contains("usuario") ||
                value.Contains("representante") ||
                value.Contains("dueño") ||
                value.Contains("dueno") ||
                value.Contains("propietario");
        }

        private static string JoinParticipant(
            (string Nombre, string Cargo, string Rol) p)
        {
            var detail = string.Join(
                " - ",
                new[]
                {
                    Clean(p.Nombre),
                    Clean(p.Cargo),
                    Clean(p.Rol)
                }
                .Where(x =>
                    !string.IsNullOrWhiteSpace(x) &&
                    x != "-"));

            return string.IsNullOrWhiteSpace(detail)
                ? "Participante no identificado"
                : detail;
        }

        private static bool IsYes(string value)
        {
            var v = (value ?? string.Empty)
                .Trim()
                .ToUpperInvariant();

            return v is
                "SÍ" or
                "SI" or
                "TRUE" or
                "1";
        }
    }

    private enum Font
    {
        Roman,
        Bold,
        Italic
    }

    private static StringBuilder NewPage() =>
        new();

    private static string SpanishDate(
        DateTime value)
    {
        var months = new[]
        {
            "Enero",
            "Febrero",
            "Marzo",
            "Abril",
            "Mayo",
            "Junio",
            "Julio",
            "Agosto",
            "Septiembre",
            "Octubre",
            "Noviembre",
            "Diciembre"
        };

        return
            $"{value:dd} de " +
            $"{months[value.Month - 1]} " +
            $"{value:yyyy}";
    }

    private static string DateOnly(
        string value)
    {
        if (DateTime.TryParse(
                value,
                out var dt))
        {
            return SpanishDate(dt);
        }

        var clean = Clean(value);
        var idx = clean.IndexOf(' ');

        return idx > 0
            ? clean[..idx]
            : clean;
    }

    private static string FormatWithUnit(
        string value,
        string unit)
    {
        var v = SafeValue(value);
        var u = Clean(unit);

        if (string.IsNullOrWhiteSpace(u) ||
            v == "No registrado")
        {
            return v;
        }

        var vNormalized = v.Replace(
            "³",
            "3",
            StringComparison.OrdinalIgnoreCase);

        var uNormalized = u.Replace(
            "³",
            "3",
            StringComparison.OrdinalIgnoreCase);

        if (vNormalized.Contains(
                uNormalized,
                StringComparison.OrdinalIgnoreCase))
        {
            return v;
        }

        return $"{v} {u}";
    }

    private static string WithPercent(
        string value)
    {
        var v = SafeValue(value);

        return v == "No registrado" ||
               v == "N/A"
            ? v
            : $"{v} %";
    }

    private static IEnumerable<string> Wrap(
        string value,
        int maxChars)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            yield break;
        }

        var words = value.Split(
            ' ',
            StringSplitOptions.RemoveEmptyEntries);

        var current = new StringBuilder();

        foreach (var word in words)
        {
            if (current.Length == 0)
            {
                current.Append(word);
                continue;
            }

            if (current.Length + 1 + word.Length <= maxChars)
            {
                current
                    .Append(' ')
                    .Append(word);

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

    private static byte[] BuildPdfDocument(
        IReadOnlyList<string> pageStreams)
    {
        var pageCount = pageStreams.Count;
        var objectCount = 5 + pageCount * 2;

        var objects =
            new string[objectCount + 1];

        objects[1] =
            "<< /Type /Catalog /Pages 2 0 R >>";

        var kids = string.Join(
            " ",
            Enumerable
                .Range(0, pageCount)
                .Select(i =>
                    $"{6 + i * 2} 0 R"));

        objects[2] =
            $"<< /Type /Pages /Kids [{kids}] /Count {pageCount} >>";

        // Se declara Times New Roman para mantener el aspecto institucional.
        objects[3] =
            "<< /Type /Font /Subtype /Type1 " +
            "/BaseFont /TimesNewRomanPSMT " +
            "/Encoding /WinAnsiEncoding >>";

        objects[4] =
            "<< /Type /Font /Subtype /Type1 " +
            "/BaseFont /TimesNewRomanPS-BoldMT " +
            "/Encoding /WinAnsiEncoding >>";

        objects[5] =
            "<< /Type /Font /Subtype /Type1 " +
            "/BaseFont /TimesNewRomanPS-ItalicMT " +
            "/Encoding /WinAnsiEncoding >>";

        for (var i = 0; i < pageCount; i++)
        {
            var pageId =
                6 + i * 2;

            var contentId =
                pageId + 1;

            objects[pageId] =
                $"<< /Type /Page /Parent 2 0 R " +
                $"/MediaBox [0 0 595 842] " +
                $"/Resources << /Font << " +
                $"/F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> " +
                $"/Contents {contentId} 0 R >>";

            var stream =
                pageStreams[i];

            var length =
                Encoding.Latin1.GetByteCount(stream);

            objects[contentId] =
                $"<< /Length {length} >>\n" +
                $"stream\n" +
                $"{stream}\n" +
                $"endstream";
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

        for (var i = 1;
             i <= objectCount;
             i++)
        {
            offsets[i] =
                ms.Position;

            W(
                $"{i} 0 obj\n" +
                $"{objects[i]}\n" +
                $"endobj\n");
        }

        var xref =
            ms.Position;

        W(
            $"xref\n" +
            $"0 {objectCount + 1}\n" +
            $"0000000000 65535 f \n");

        for (var i = 1;
             i <= objectCount;
             i++)
        {
            W(
                $"{offsets[i]:D10} " +
                $"00000 n \n");
        }

        W(
            $"trailer\n" +
            $"<< /Size {objectCount + 1} /Root 1 0 R >>\n" +
            $"startxref\n" +
            $"{xref}\n" +
            $"%%EOF");

        return ms.ToArray();
    }

    private static void DrawCentered(
        StringBuilder sb,
        string text,
        float y,
        float size,
        Font font)
    {
        var safe =
            SafeValue(text);

        var estimated =
            EstimateTextWidth(
                safe,
                size,
                font);

        var x =
            Math.Max(
                MarginLeft,
                (Width - estimated) / 2f);

        DrawText(
            sb,
            safe,
            x,
            y,
            size,
            font);
    }

    private static float EstimateTextWidth(
        string text,
        float size,
        Font font)
    {
        // Métrica aproximada de Times New Roman
        // para centrar el texto institucional.
        var factor =
            font == Font.Bold
                ? .50f
                : .47f;

        return
            text.Length *
            size *
            factor;
    }

    private static void DrawText(
        StringBuilder sb,
        string text,
        float x,
        float y,
        float size,
        Font font,
        float r = 0f,
        float g = 0f,
        float b = 0f)
    {
        var fontName =
            font switch
            {
                Font.Bold => "F2",
                Font.Italic => "F3",
                _ => "F1"
            };

        sb.AppendFormat(
            CultureInfo.InvariantCulture,
            "BT /{0} {1:0.##} Tf " +
            "{2:0.##} {3:0.##} Td " +
            "{4:0.###} {5:0.###} {6:0.###} rg " +
            "({7}) Tj ET\n",
            fontName,
            size,
            x,
            y,
            r,
            g,
            b,
            PdfText(text));
    }

    private static string SafeValue(
        string? value)
    {
        var clean =
            Clean(value);

        return string.IsNullOrWhiteSpace(clean)
            ? "No registrado"
            : clean;
    }

    private static bool IsEmpty(
        string? value) =>
        string.IsNullOrWhiteSpace(value) ||
        value
            .Trim()
            .Equals(
                "No registrado",
                StringComparison.OrdinalIgnoreCase);

    private static string Clean(
        string? value) =>
        (value ?? string.Empty)
            .Replace("\r", " ")
            .Replace("\n", " ")
            .Trim();

    private static string PdfText(
        string value)
    {
        var normalized = value
            .Replace("–", "-")
            .Replace("—", "-")
            .Replace("…", "...")
            .Replace("“", "\"")
            .Replace("”", "\"")
            .Replace("’", "'")
            .Replace("×", "x")
            .Replace("№", "N°");

        return normalized
            .Replace("\\", "\\\\")
            .Replace("(", "\\(")
            .Replace(")", "\\)");
    }
}