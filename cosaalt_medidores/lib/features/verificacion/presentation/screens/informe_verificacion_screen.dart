import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/api_verificacion_repository.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/mecanico_shell.dart';
import '../widgets/verificacion_ui.dart';

class InformeVerificacionScreen extends ConsumerStatefulWidget {
  const InformeVerificacionScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<InformeVerificacionScreen> createState() =>
      _InformeVerificacionScreenState();
}

class _InformeVerificacionScreenState
    extends ConsumerState<InformeVerificacionScreen> {
  final _observacionesCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();
  final _cargoResponsableCtrl = TextEditingController(
    text: 'RESPONSABLE LABORATORIO DE MEDIDORES COSAALT R.L.',
  );
  final _destinatarioCtrl = TextEditingController();
  final _cargoDestinatarioCtrl = TextEditingController(
    text: 'JEFE DPTO. SERVICIO AL CLIENTE – ODECO COSAALT R.L.',
  );
  final _referenciaCtrl = TextEditingController();
  final _lugarVerificacionCtrl = TextEditingController();
  final _tipoEnsayoTextoCtrl = TextEditingController();
  final _descripcionTecnicaCtrl = TextEditingController();
  final _conclusionAdicionalCtrl = TextEditingController();
  final _recomendacionCtrl = TextEditingController();

  final Set<int> _pdfBusy = <int>{};

  DatosSocioMedidor? _datosSocio;
  bool _cargandoDatos = true;
  String? _errorDatos;

  @override
  void initState() {
    super.initState();

    Future.microtask(_cargarInicial);
  }

  Future<void> _cargarInicial() async {
    final notifier = ref.read(verificacionControllerProvider.notifier);

    await notifier.cargarVerificacion(widget.id);

    await notifier.cargarInformes(widget.id);

    try {
      final repo = ref.read(verificacionRepositoryProvider);

      final datos = await repo.obtenerDatosSocioMedidor(widget.id);

      if (!mounted) {
        return;
      }

      final actual = ref.read(verificacionControllerProvider).verificacionActual;

      if (_responsableCtrl.text.trim().isEmpty &&
          (actual?.nombreMecanico?.trim().isNotEmpty ?? false)) {
        _responsableCtrl.text = actual!.nombreMecanico!.trim();
      }

      if (_lugarVerificacionCtrl.text.trim().isEmpty) {
        _lugarVerificacionCtrl.text =
            (datos.lugarVerificacion?.trim().isNotEmpty ?? false)
            ? datos.lugarVerificacion!.trim()
            : 'Domicilio del usuario';
      }

      if (_tipoEnsayoTextoCtrl.text.trim().isEmpty) {
        final tipo = datos.tipoEnsayo?.trim().isNotEmpty == true
            ? datos.tipoEnsayo!.trim()
            : actual?.ensayo?.tipoPrueba?.trim() ?? '';
        _tipoEnsayoTextoCtrl.text = tipo;
      }

      setState(() {
        _datosSocio = datos;
        _errorDatos = null;
        _cargandoDatos = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorDatos = mensajeVerificacionError(
          e,
          fallback: 'No se pudieron cargar los datos del informe.',
        );
        _cargandoDatos = false;
      });
    }
  }

  @override
  void dispose() {
    _observacionesCtrl.dispose();
    _responsableCtrl.dispose();
    _cargoResponsableCtrl.dispose();
    _destinatarioCtrl.dispose();
    _cargoDestinatarioCtrl.dispose();
    _referenciaCtrl.dispose();
    _lugarVerificacionCtrl.dispose();
    _tipoEnsayoTextoCtrl.dispose();
    _descripcionTecnicaCtrl.dispose();
    _conclusionAdicionalCtrl.dispose();
    _recomendacionCtrl.dispose();
    super.dispose();
  }

  void _volverAtras() {
    final router = GoRouter.of(context);

    // Las pantallas del módulo Mecánico ahora navegan mediante
    // GoRouter dentro de un shell persistente. Si existe una ruta
    // anterior, volvemos a ella; si el informe fue abierto de forma
    // directa, regresamos de forma segura al inicio.
    if (router.canPop()) {
      router.pop();
      return;
    }

    router.go(AppRoutes.mecanicoHome);
  }

  void _volverAlInicio() {
    // El shell mantiene header/footer. Para volver al dashboard no
    // hay que manipular manualmente la pila de Navigator.
    GoRouter.of(context).go(AppRoutes.mecanicoHome);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificacionControllerProvider);

    final v = state.verificacionActual;

    final informes = state.informes;

    final proximaVersion = _obtenerProximaVersion(informes);

    final nroPrevisto = _obtenerNumeroPrevisto(informes);

    return Scaffold(
      appBar: MecanicoPageAppBar(
        title: const Text('Informe Técnico'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: _volverAtras,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.isLoading || _cargandoDatos)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),

              VerMessageBar(
                error: state.errorMessage ?? _errorDatos,
                success: state.successMessage,
              ),

              _buildEstado(context, v),

              if (v != null && v.finalizada)
                _buildNuevaEmision(state.isAccion, nroPrevisto, proximaVersion),

              if (v != null && v.finalizada)
                _buildVistaPrevia(v, _datosSocio),

              if (informes.isNotEmpty) _buildVersiones(context, informes),

              const SizedBox(height: 20),

              Center(
                child: TextButton.icon(
                  onPressed: _volverAlInicio,
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Volver al inicio'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstado(BuildContext context, VerificacionMecanico? v) {
    return VerSection(
      title: 'Estado del informe',
      child: v == null
          ? const Text('No se encontró la verificación.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VerDataRow(label: 'Verificación', value: '#${v.id}'),

                VerDataRow(
                  label: 'Socio',
                  value: v.nombreCliente ?? 'Socio ${v.codCon}',
                ),

                VerDataRow(label: 'Estado', value: v.estado),

                VerDataRow(
                  label: 'Resultado',
                  value: v.resultado ?? 'Sin definir',
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      v.finalizada
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      size: 18,
                      color: v.finalizada
                          ? const Color(0xFF137A4A)
                          : const Color(0xFF667085),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        v.finalizada
                            ? 'La verificación está finalizada. Revise los datos antes de emitir el informe técnico.'
                            : 'Debe finalizar la verificación antes de generar el informe técnico.',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                if (!v.finalizada) ...[
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.go(
                        '${AppRoutes.mecanicoHome}/verificacion/${widget.id}/finalizar',
                      ),
                      icon: const Icon(Icons.task_alt),
                      label: const Text('Ir a finalizar'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildVistaPrevia(
    VerificacionMecanico v,
    DatosSocioMedidor? datos,
  ) {
    final ensayo = v.ensayo;
    final unidadVolumen = _texto(ensayo?.unidadVolumen, fallback: 'm³');
    final unidadCaudal = _texto(ensayo?.unidadCaudal, fallback: 'm³/h');
    final errorConSigno = ensayo?.error;
    final errorAbsoluto = errorConSigno?.abs();
    final resultado = _texto(v.resultado, fallback: 'INDETERMINADO').toUpperCase();
    final fugas = ensayo?.fugas == true;

    String interpretacion() {
      final error = errorAbsoluto == null
          ? 'No registrado'
          : '${errorAbsoluto.toStringAsFixed(2)} %';
      final limite = ensayo?.limiteNormativoAplicado == null
          ? 'N/A'
          : '${ensayo!.limiteNormativoAplicado!.toStringAsFixed(2)} %';
      final parametro = _texto(
        ensayo?.parametroNormativoCodigoAplicado,
        fallback: 'Sin parámetro aplicable',
      );

      if (resultado == 'CUMPLE') {
        return 'El error relativo obtenido del micromedidor ($error) se encuentra '
            'dentro del límite máximo permitido aplicado ($limite), correspondiente '
            'al parámetro normativo $parametro. Por lo tanto, el instrumento CUMPLE '
            'con el criterio metrológico evaluado.';
      }

      if (resultado == 'NO CUMPLE') {
        return 'El error relativo obtenido del micromedidor ($error) supera el '
            'límite máximo permitido aplicado ($limite), correspondiente al '
            'parámetro normativo $parametro. Por lo tanto, el instrumento NO CUMPLE '
            'con el criterio metrológico evaluado.';
      }

      return 'El resultado se clasifica como INDETERMINADO debido a que no existe '
          'un parámetro normativo aplicable suficiente para emitir una conclusión '
          'de cumplimiento para las condiciones registradas.';
    }

    Widget institucionalTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            fontFamily: 'Times New Roman',
          ),
        ),
      );
    }

    Widget linea(String etiqueta, String valor, {bool boldValue = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 190,
              child: Text(
                etiqueta,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
            Expanded(
              child: Text(
                valor,
                style: TextStyle(
                  fontWeight: boldValue ? FontWeight.w700 : FontWeight.w400,
                  fontFamily: 'Times New Roman',
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget parrafo(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            height: 1.48,
            fontSize: 13.5,
          ),
        ),
      );
    }

    final listenable = Listenable.merge([
      _responsableCtrl,
      _cargoResponsableCtrl,
      _destinatarioCtrl,
      _cargoDestinatarioCtrl,
      _referenciaCtrl,
      _lugarVerificacionCtrl,
      _tipoEnsayoTextoCtrl,
      _descripcionTecnicaCtrl,
      _conclusionAdicionalCtrl,
      _recomendacionCtrl,
    ]);

    return VerSection(
      title: 'Vista previa del informe',
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, child) {
          final responsable = _responsableCtrl.text.trim().isEmpty
              ? 'Pendiente de ingresar'
              : _responsableCtrl.text.trim();
          final cargoResponsable = _cargoResponsableCtrl.text.trim().isEmpty
              ? 'RESPONSABLE LABORATORIO DE MEDIDORES COSAALT R.L.'
              : _cargoResponsableCtrl.text.trim();
          final destinatario = _destinatarioCtrl.text.trim().isEmpty
              ? 'Pendiente de ingresar'
              : _destinatarioCtrl.text.trim();
          final cargoDestinatario = _cargoDestinatarioCtrl.text.trim().isEmpty
              ? 'JEFE DPTO. SERVICIO AL CLIENTE – ODECO COSAALT R.L.'
              : _cargoDestinatarioCtrl.text.trim();
          final referencia = _referenciaCtrl.text.trim().isEmpty
              ? _referenciaAutomatica(datos, ensayo)
              : _referenciaCtrl.text.trim();
          final lugar = _lugarVerificacionCtrl.text.trim().isEmpty
              ? _texto(datos?.lugarVerificacion, fallback: 'Domicilio del usuario')
              : _lugarVerificacionCtrl.text.trim();
          final direccion = _texto(datos?.direccion, fallback: '');
          final lugarCompleto = direccion.isEmpty ||
                  lugar.toLowerCase().contains(direccion.toLowerCase())
              ? lugar
              : '$lugar – $direccion';
          final tipoEnsayo = _tipoEnsayoTextoCtrl.text.trim().isEmpty
              ? _texto(ensayo?.tipoPrueba ?? datos?.tipoEnsayo)
              : _tipoEnsayoTextoCtrl.text.trim();
          final recomendacion = _recomendacionCtrl.text.trim().isEmpty
              ? 'Pendiente de ingresar por el responsable.'
              : _recomendacionCtrl.text.trim();

          final representantes = v.participantes.where((p) {
            final texto = '${p.cargo ?? ''} ${p.rol ?? ''}'.toLowerCase();
            return texto.contains('usuario') ||
                texto.contains('representante') ||
                texto.contains('dueño') ||
                texto.contains('dueno') ||
                texto.contains('propietario');
          }).toList();
          final personal = v.participantes
              .where((p) => !representantes.contains(p))
              .toList();

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFD6D6D6)),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13.5,
                fontFamily: 'Times New Roman',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'INFORME TÉCNICO DE VERIFICACIÓN METROLÓGICA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  linea('DE:', responsable),
                  Text(
                    cargoResponsable,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                  const SizedBox(height: 8),
                  linea('A:', destinatario),
                  Text(
                    cargoDestinatario,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                  const SizedBox(height: 8),
                  linea('REF.:', referencia),
                  linea('FECHA:', _fechaInstitucional(DateTime.now())),

                  institucionalTitle('I. DATOS GENERALES DEL MEDIDOR'),
                  Row(
                    children: const [
                      SizedBox(
                        width: 190,
                        child: Text(
                          'Parámetro',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('Detalle', style: TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  linea('Usuario:', _texto(datos?.nombreCliente ?? v.nombreCliente)),
                  linea('Código:', datos?.codConexion?.toString() ?? 'No registrado'),
                  linea('Registro de Usuario:', '${datos?.regSoc ?? v.codCon}'),
                  linea('Marca:', _texto(datos?.marcaMedidor)),
                  linea('Número de Serie:', _texto(datos?.numeroMedidor)),
                  linea(
                    'Capacidad Nominal (Q₃):',
                    _capacidadConUnidad(
                      ensayo?.capacidadNominalQ3 ?? datos?.capacidadQ3,
                    ),
                  ),
                  linea(
                    'Lectura Inicial:',
                    ensayo?.lecturaInicial == null
                        ? 'No registrado'
                        : '${_numero(ensayo!.lecturaInicial)} $unidadVolumen',
                  ),
                  linea('Fecha de Verificación:', verDate(v.fechaVerificacion)),
                  linea('Lugar de Verificación:', lugarCompleto),
                  linea('Tipo de ensayo:', tipoEnsayo),

                  institucionalTitle('II. OBJETIVO DE LA PRUEBA'),
                  parrafo(
                    'Determinar el estado de calibración y exactitud metrológica del '
                    'micromedidor verificado, conforme a los criterios establecidos '
                    'en la Norma Boliviana NB ISO 4064 para medidores de agua, con el '
                    'fin de comprobar si el instrumento se encuentra dentro de los '
                    'límites de error aplicables para su correcta utilización en la '
                    'medición del servicio de agua potable.',
                  ),

                  institucionalTitle('III. PERSONAL PARTICIPANTE'),
                  parrafo('La prueba fue realizada en presencia de:'),
                  const Text(
                    '•  Personal de COSAALT R.L.:',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (personal.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, top: 5),
                      child: Text('○  Técnico Verificador (${_texto(v.nombreMecanico)}).'),
                    )
                  else
                    ...personal.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(left: 28, top: 5),
                        child: Text(
                          '○  ${p.nombre} - ${_texto(p.cargo, fallback: '-')} - '
                          '${_texto(p.rol, fallback: '-')}',
                        ),
                      ),
                    ),
                  if (representantes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '•  Representante del Usuario:',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    ...representantes.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(left: 28, top: 5),
                        child: Text(
                          '○  ${p.nombre} - ${_texto(p.cargo, fallback: '-')} - '
                          '${_texto(p.rol, fallback: '-')}',
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: parrafo(
                      'El procedimiento se desarrolló por solicitud registrada con '
                      'origen ${v.tipoOrigen} - ${v.idOrigen}.',
                    ),
                  ),

                  institucionalTitle('IV. DESCRIPCIÓN DE LA PRUEBA REALIZADA'),
                  parrafo(
                    '1. Se utilizó ${_texto(ensayo?.instrumentoBanco)}, bajo las '
                    'condiciones registradas para la verificación y con la trazabilidad '
                    'disponible en el sistema.',
                  ),
                  if (_descripcionTecnicaCtrl.text.trim().isNotEmpty)
                    parrafo(_descripcionTecnicaCtrl.text.trim()),
                  const Text(
                    'Condiciones del Ensayo:',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 26, top: 5),
                    child: Text(
                      '○  Tipo de prueba: $tipoEnsayo.\n'
                      '○  Volumen patrón aplicado: '
                      '${ensayo?.volumenPatron == null ? 'No registrado' : '${_numero(ensayo!.volumenPatron)} $unidadVolumen'}.\n'
                      '○  Caudal de ensayo: ${_texto(ensayo?.tipoCaudal)} - '
                      '${ensayo?.caudal == null ? 'No registrado' : '${_numero(ensayo!.caudal)} $unidadCaudal'}.\n'
                      '○  Identificación / trazabilidad: '
                      '${_texto(ensayo?.identificacionBanco)} / '
                      '${_texto(ensayo?.trazabilidadCalibracion)}.',
                      style: const TextStyle(height: 1.55),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '2. Caudal de ensayo: ${_texto(ensayo?.tipoCaudal)}, '
                    '${ensayo?.caudal == null ? 'No registrado' : '${_numero(ensayo!.caudal)} $unidadCaudal'}.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Resultados obtenidos:',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  _InstitutionalResultRow(
                    description: 'Primera Lectura del medidor',
                    value: ensayo?.lecturaInicial == null
                        ? 'No registrado'
                        : '${_numero(ensayo!.lecturaInicial)} $unidadVolumen',
                  ),
                  _InstitutionalResultRow(
                    description: 'Segunda Lectura del medidor',
                    value: ensayo?.lecturaFinal == null
                        ? 'No registrado'
                        : '${_numero(ensayo!.lecturaFinal)} $unidadVolumen',
                  ),
                  _InstitutionalResultRow(
                    description: 'Volumen registrado por el medidor (Vm)',
                    value: ensayo?.volumenRegistrado == null
                        ? 'No registrado'
                        : '${_numero(ensayo!.volumenRegistrado)} $unidadVolumen',
                    bold: true,
                  ),
                  _InstitutionalResultRow(
                    description: 'Volumen patrón real (Vr)',
                    value: ensayo?.volumenPatron == null
                        ? 'No registrado'
                        : '${_numero(ensayo!.volumenPatron)} $unidadVolumen',
                    bold: true,
                  ),
                  _InstitutionalResultRow(
                    description: 'Error relativo (%)',
                    value: _porcentajeSigno(errorConSigno),
                    bold: true,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cálculo del error relativo:',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      ensayo?.volumenRegistrado == null || ensayo?.volumenPatron == null
                          ? 'Error (%) = (Vm - Vr) / Vr × 100'
                          : 'Error (%) = (Vm - Vr) / Vr × 100 = '
                              '(${ensayo!.volumenRegistrado!.toStringAsFixed(4)} - '
                              '${ensayo.volumenPatron!.toStringAsFixed(4)}) / '
                              '${ensayo.volumenPatron!.toStringAsFixed(4)} × 100 '
                              '= ${_porcentajeSigno(errorConSigno)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 13.5,
                      ),
                    ),
                  ),

                  institucionalTitle(
                    'V. INTERPRETACIÓN DE RESULTADOS SEGÚN NORMA NB ISO 4064',
                  ),
                  parrafo(interpretacion()),

                  institucionalTitle('VI. CONCLUSIONES TÉCNICAS'),
                  parrafo(
                    '1. El micromedidor ${_texto(datos?.marcaMedidor)} '
                    'N.° ${_texto(datos?.numeroMedidor)} presenta un error relativo '
                    'de ${_porcentajeSigno(errorConSigno)}. Resultado metrológico: '
                    '$resultado.',
                  ),
                  parrafo(
                    '2. Volumen registrado por el medidor (Vm): '
                    '${ensayo?.volumenRegistrado == null ? 'No registrado' : '${_numero(ensayo!.volumenRegistrado)} $unidadVolumen'}; '
                    'volumen patrón real (Vr): '
                    '${ensayo?.volumenPatron == null ? 'No registrado' : '${_numero(ensayo!.volumenPatron)} $unidadVolumen'}.',
                  ),
                  parrafo(
                    fugas
                        ? '3. Al momento de la inspección y/o revisión SÍ se evidenciaron '
                            'fugas. Tipo registrado: ${_texto(ensayo?.tipoFuga)}. La fuga '
                            'se registra como condición independiente y no modifica por sí '
                            'sola el resultado metrológico.'
                        : '3. Al momento de la inspección y/o revisión NO se evidenciaron '
                            'fugas registradas.',
                  ),
                  parrafo(
                    '4. El ensayo fue realizado bajo supervisión técnica y con registro '
                    'del instrumento/banco, identificación y trazabilidad.',
                  ),
                  parrafo(
                    '5. Condiciones registradas: ${_texto(ensayo?.condiciones, fallback: '-')}.',
                  ),
                  parrafo('6. El resultado final de la evaluación metrológica es $resultado.'),
                  if (_conclusionAdicionalCtrl.text.trim().isNotEmpty)
                    parrafo(_conclusionAdicionalCtrl.text.trim()),

                  institucionalTitle('VII. RECOMENDACIÓN'),
                  parrafo(recomendacion),
                  parrafo('Es cuanto se informa para fines consiguientes.'),
                  parrafo('Atentamente,'),

                  const SizedBox(height: 42),
                  const Center(child: Text('_______________________________')),
                  const SizedBox(height: 8),
                  Center(child: Text(responsable)),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      cargoResponsable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'La vista previa reproduce la estructura institucional del informe. '
                      'Los campos editables se reflejan aquí antes de generar el PDF. '
                      'Las observaciones de la emisión se guardan como trazabilidad y no '
                      'se imprimen dentro del documento.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF765F13),
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _referenciaAutomatica(
    DatosSocioMedidor? datos,
    EnsayoVerificacion? ensayo,
  ) {
    final marca = _texto(datos?.marcaMedidor);
    final capacidad = _capacidadConUnidad(
      ensayo?.capacidadNominalQ3 ?? datos?.capacidadQ3,
    );
    final serie = _texto(datos?.numeroMedidor);
    return 'Informe Técnico sobre Verificación del Micromedidor '
        '$marca $capacidad N° $serie';
  }

  String _capacidadConUnidad(String? value) {
    final capacidad = _texto(value);
    final lower = capacidad.toLowerCase();
    if (capacidad == 'No registrado' ||
        lower.contains('m³/h') ||
        lower.contains('m3/h')) {
      return capacidad;
    }
    return '$capacidad m³/h';
  }

  String _fechaInstitucional(DateTime value) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final dia = value.day.toString().padLeft(2, '0');
    return '$dia de ${meses[value.month - 1]} ${value.year}';
  }

  Widget _buildVersiones(
    BuildContext context,
    List<InformeVerificacion> informes,
  ) {
    return VerSection(
      title: 'Versiones emitidas (${informes.length})',
      child: Column(
        children: [
          ...informes.map(
            (informe) => _InformeRow(
              informe: informe,
              busy: _pdfBusy.contains(informe.id),
              onAbrir: () => _abrir(context, informe),
              onDescargar: () => _descargar(context, informe),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNuevaEmision(
    bool isAccion,
    String nroPrevisto,
    int proximaVersion,
  ) {
    InputDecoration fieldDecoration({
      required String label,
      String? hint,
      String? helper,
      IconData? icon,
      bool alignLabelWithHint = false,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        prefixIcon: icon == null ? null : Icon(icon),
        alignLabelWithHint: alignLabelWithHint,
        isDense: true,
      );
    }

    return VerSection(
      title: 'Nueva emisión',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Text(
                  'Informe: $nroPrevisto',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Versión: $proximaVersion',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Text(
                  'Firma digital: No',
                  style: TextStyle(color: Color(0xFF667085)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Encabezado del informe',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _responsableCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: fieldDecoration(
              label: 'DE: Nombre del responsable *',
              hint: 'Ej. Tec. Nal. Int. Mamerto Gutiérrez L.',
              helper: 'Se refleja inmediatamente en la vista previa y en la firma.',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cargoResponsableCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: fieldDecoration(
              label: 'Cargo del responsable',
              hint: 'RESPONSABLE LABORATORIO DE MEDIDORES COSAALT R.L.',
              icon: Icons.badge_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destinatarioCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: fieldDecoration(
              label: 'A: Nombre del destinatario *',
              hint: 'Ej. Gilberto Torrez N.',
              icon: Icons.forward_to_inbox_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cargoDestinatarioCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: fieldDecoration(
              label: 'Cargo del destinatario',
              hint: 'JEFE DPTO. SERVICIO AL CLIENTE – ODECO COSAALT R.L.',
              icon: Icons.account_balance_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenciaCtrl,
            minLines: 1,
            maxLines: 2,
            decoration: fieldDecoration(
              label: 'REF. (opcional)',
              hint: 'Si se deja vacío se arma automáticamente con marca, Q3 y serie.',
              icon: Icons.subject_outlined,
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'Datos variables del contenido',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _lugarVerificacionCtrl,
            minLines: 1,
            maxLines: 2,
            decoration: fieldDecoration(
              label: 'Lugar de verificación',
              hint: 'Ej. Domicilio del usuario',
              helper: 'La dirección del socio se agrega automáticamente si corresponde.',
              icon: Icons.place_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tipoEnsayoTextoCtrl,
            minLines: 1,
            maxLines: 2,
            decoration: fieldDecoration(
              label: 'Tipo de ensayo',
              hint: 'Ej. Verificación metrológica in situ con banco portátil de referencia',
              icon: Icons.science_outlined,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descripcionTecnicaCtrl,
            minLines: 2,
            maxLines: 5,
            decoration: fieldDecoration(
              label: 'Descripción técnica complementaria',
              hint: 'Opcional. Se agrega en la sección IV sin reemplazar los datos del ensayo.',
              icon: Icons.description_outlined,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conclusionAdicionalCtrl,
            minLines: 2,
            maxLines: 5,
            decoration: fieldDecoration(
              label: 'Conclusión técnica adicional',
              hint: 'Opcional. Complementa las conclusiones calculadas por el sistema.',
              icon: Icons.fact_check_outlined,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recomendacionCtrl,
            minLines: 4,
            maxLines: 9,
            decoration: fieldDecoration(
              label: 'VII. Recomendación *',
              hint: 'Escriba la recomendación profesional que debe aparecer en el informe.',
              helper: 'El sistema no genera ni modifica esta recomendación.',
              icon: Icons.edit_note_outlined,
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 18),
          TextField(
            controller: _observacionesCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: fieldDecoration(
              label: 'Observaciones de la emisión',
              hint: 'Ej. Reemisión solicitada por ODECO.',
              helper: 'Solo trazabilidad de la versión. No se imprime en el PDF.',
              icon: Icons.notes_outlined,
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD4E7DC)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF137A4A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los datos institucionales y la recomendación se reflejan en la vista previa mientras escribe. Cada emisión crea una nueva versión y conserva las anteriores.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isAccion ? null : _generar,
              icon: isAccion
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                isAccion
                    ? 'Generando...'
                    : 'Generar informe - versión $proximaVersion',
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _obtenerProximaVersion(List<InformeVerificacion> informes) {
    if (informes.isEmpty) {
      return 1;
    }

    var maxVersion = 0;

    for (final informe in informes) {
      if (informe.versionInforme > maxVersion) {
        maxVersion = informe.versionInforme;
      }
    }

    return maxVersion + 1;
  }

  /*
   * M8:
   *
   * Debe reproducir exactamente la misma regla
   * utilizada por SqlVerificacionRepository.
   *
   * v1:
   * INF-VER-2026-000002
   *
   * v2:
   * INF-VER-2026-000002-V2
   *
   * v3:
   * INF-VER-2026-000002-V3
   *
   * Esto permite conservar el índice SQL:
   *
   * UNIQUE (NroInforme)
   */
  String _obtenerNumeroPrevisto(List<InformeVerificacion> informes) {
    final year = DateTime.now().year;

    final nroBase = 'INF-VER-$year-${widget.id.toString().padLeft(6, '0')}';

    final proximaVersion = _obtenerProximaVersion(informes);

    if (proximaVersion <= 1) {
      return nroBase;
    }

    return '$nroBase-V$proximaVersion';
  }

  String _texto(String? value, {String fallback = 'No registrado'}) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) {
      return fallback;
    }

    return clean;
  }

  String _numero(double? value, {int decimals = 4}) {
    if (value == null) {
      return 'No registrado';
    }

    return value.toStringAsFixed(decimals);
  }

  String _porcentajeSigno(double? value) {
    if (value == null) {
      return 'No registrado';
    }

    final prefix = value > 0 ? '+' : '';

    return '$prefix${value.toStringAsFixed(2)} %';
  }

  Future<void> _generar() async {
    final responsable = _responsableCtrl.text.trim();
    final destinatario = _destinatarioCtrl.text.trim();
    final recomendacion = _recomendacionCtrl.text.trim();

    if (responsable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingrese el nombre del responsable antes de generar el informe.',
          ),
        ),
      );
      return;
    }

    if (destinatario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingrese el nombre del destinatario antes de generar el informe.',
          ),
        ),
      );
      return;
    }

    if (recomendacion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingrese la recomendación técnica antes de generar el informe.',
          ),
        ),
      );
      return;
    }

    final state = ref.read(verificacionControllerProvider);
    final v = state.verificacionActual;

    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la verificación.')),
      );
      return;
    }

    if (!v.finalizada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La verificación debe estar finalizada antes de emitir el informe.',
          ),
        ),
      );
      return;
    }

    final nroInforme = _obtenerNumeroPrevisto(state.informes);
    final version = _obtenerProximaVersion(state.informes);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generar informe técnico'),
          content: Text(
            'Se generará:\n\n'
            '$nroInforme\n'
            'Versión $version\n\n'
            'DE: $responsable\n'
            'A: $destinatario\n\n'
            'La recomendación escrita será incorporada tal como fue registrada.\n\n'
            'Las versiones anteriores se conservarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    try {
      final notifier = ref.read(verificacionControllerProvider.notifier);

      await notifier.generarInforme(
        widget.id,
        observaciones: _observacionesCtrl.text.trim(),
        nombreResponsable: responsable,
        cargoResponsable: _cargoResponsableCtrl.text.trim(),
        nombreDestinatario: destinatario,
        cargoDestinatario: _cargoDestinatarioCtrl.text.trim(),
        referencia: _referenciaCtrl.text.trim(),
        lugarVerificacion: _lugarVerificacionCtrl.text.trim(),
        tipoEnsayoTexto: _tipoEnsayoTextoCtrl.text.trim(),
        descripcionTecnica: _descripcionTecnicaCtrl.text.trim(),
        conclusionAdicional: _conclusionAdicionalCtrl.text.trim(),
        recomendacion: recomendacion,
      );

      await notifier.cargarInformes(widget.id);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensajeVerificacionError(
              e,
              fallback: 'No se pudo generar el informe.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _abrir(BuildContext context, InformeVerificacion informe) async {
    if (_pdfBusy.contains(informe.id)) {
      return;
    }

    setState(() {
      _pdfBusy.add(informe.id);
    });

    try {
      final repo = ref.read(verificacionRepositoryProvider);

      final nombreVersionado =
          '${informe.nroInforme}_v${informe.versionInforme}';

      final path = await repo.prepararInformeTemporal(
        informe.id,
        nombreVersionado,
      );

      if (path.isEmpty) {
        return;
      }

      final result = await OpenFilex.open(path);

      if (!context.mounted) {
        return;
      }

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No se pudo abrir el PDF. Verifique que exista una aplicación para leer archivos PDF.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mensajeVerificacionError(e, fallback: 'No se pudo abrir el PDF.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pdfBusy.remove(informe.id);
        });
      }
    }
  }

  /*
   * M8:
   *
   * Cada informe se descarga con nombre propio.
   *
   * v1:
   * INF-VER-2026-000002_v1.pdf
   *
   * v2:
   * INF-VER-2026-000002-V2_v2.pdf
   *
   * v3:
   * INF-VER-2026-000002-V3_v3.pdf
   */
  Future<void> _descargar(
    BuildContext context,
    InformeVerificacion informe,
  ) async {
    if (_pdfBusy.contains(informe.id)) {
      return;
    }

    setState(() {
      _pdfBusy.add(informe.id);
    });

    try {
      final repo = ref.read(verificacionRepositoryProvider);

      final nombreVersionado =
          '${informe.nroInforme}_v${informe.versionInforme}';

      final path = await repo.descargarInforme(informe.id, nombreVersionado);

      if (path.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF guardado en:\n$path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mensajeVerificacionError(
                e,
                fallback: 'No se pudo descargar el PDF.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pdfBusy.remove(informe.id);
        });
      }
    }
  }
}

class _InstitutionalResultRow extends StatelessWidget {
  const _InstitutionalResultRow({
    required this.description,
    required this.value,
    this.bold = false,
  });

  final String description;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Times New Roman',
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      height: 1.35,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(description, style: style)),
          const SizedBox(width: 18),
          Expanded(flex: 2, child: Text(value, style: style)),
        ],
      ),
    );
  }
}

class _InformeRow extends StatelessWidget {
  const _InformeRow({
    required this.informe,
    required this.busy,
    required this.onAbrir,
    required this.onDescargar,
  });

  final InformeVerificacion informe;
  final bool busy;
  final VoidCallback onAbrir;
  final VoidCallback onDescargar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE4E0)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;

            final info = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: AppColors.darkBlue,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        informe.nroInforme,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Versión ${informe.versionInforme} · '
                        '${verDate(informe.fechaEmision, time: true)}',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),

                      if (informe.observaciones != null &&
                          informe.observaciones!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),

                        Text(
                          informe.observaciones!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                VerStatusChip(informe.firmado ? 'Firmado' : 'Pendiente firma'),

                if (busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  IconButton(
                    tooltip: 'Abrir PDF',
                    onPressed: onAbrir,
                    icon: const Icon(Icons.open_in_new_outlined),
                  ),

                  IconButton(
                    tooltip: 'Descargar PDF',
                    onPressed: onDescargar,
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  info,

                  const SizedBox(height: 10),

                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: info),

                const SizedBox(width: 12),

                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
