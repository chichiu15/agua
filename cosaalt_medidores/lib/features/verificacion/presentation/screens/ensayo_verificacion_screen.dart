import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/verificacion_ui.dart';

class EnsayoVerificacionScreen extends ConsumerStatefulWidget {
  const EnsayoVerificacionScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<EnsayoVerificacionScreen> createState() =>
      _EnsayoVerificacionScreenState();
}

class _EnsayoVerificacionScreenState
    extends ConsumerState<EnsayoVerificacionScreen> {
  static const List<String> _tiposPrueba = ['In situ', 'Laboratorio', 'Otro'];

  static const List<String> _tiposCaudal = [
    'Q1 mínimo',
    'Q2 transición',
    'Q3 permanente',
    'Otro',
  ];

  static const List<String> _tiposFuga = ['Visible', 'No visible'];

  final _condicionesCtrl = TextEditingController();
  final _lecturaInicialCtrl = TextEditingController();
  final _lecturaFinalCtrl = TextEditingController();
  final _volumenPatronCtrl = TextEditingController();
  final _caudalCtrl = TextEditingController();

  final _tipoPruebaCtrl = TextEditingController();
  final _instrumentoCtrl = TextEditingController();
  final _identificacionCtrl = TextEditingController();
  final _trazabilidadCtrl = TextEditingController();
  final _capacidadQ3Ctrl = TextEditingController();

  final _tipoCaudalCtrl = TextEditingController();
  final _unidadCaudalCtrl = TextEditingController();
  final _unidadVolumenCtrl = TextEditingController();

  final _tipoFugaCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  bool _fugas = false;

  CalculoEnsayo? _calculo;

  Timer? _debounce;

  final TextInputFormatter _decimalFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final valido = RegExp(r'^\d*([.,]\d*)?$').hasMatch(newValue.text);

    return valido ? newValue : oldValue;
  });

  @override
  void initState() {
    super.initState();

    /*
     * Las unidades continúan con los valores
     * que tu proyecto ya utilizaba.
     *
     * No inventamos una conversión nueva,
     * porque posteriormente M6 utiliza el
     * caudal para buscar el parámetro normativo.
     */
    _unidadCaudalCtrl.text = 'm³/h';
    _unidadVolumenCtrl.text = 'm³';

    Future.microtask(() async {
      await ref
          .read(verificacionControllerProvider.notifier)
          .cargarVerificacion(widget.id);

      if (mounted) {
        _cargarEnsayoExistente();
      }
    });
  }

  void _cargarEnsayoExistente() {
    final state = ref.read(verificacionControllerProvider);

    final ensayo = state.verificacionActual?.ensayo;

    /*
     * Si todavía no existe ensayo, intentamos
     * precargar Q3 desde la ficha institucional
     * obtenida en M3.
     */
    if (ensayo == null) {
      final q3 = state.datosSocio?.capacidadQ3?.trim();

      if (q3 != null && q3.isNotEmpty) {
        setState(() {
          _capacidadQ3Ctrl.text = q3;
        });
      }

      return;
    }

    setState(() {
      _condicionesCtrl.text = ensayo.condiciones ?? '';

      _lecturaInicialCtrl.text = ensayo.lecturaInicial?.toString() ?? '';

      _lecturaFinalCtrl.text = ensayo.lecturaFinal?.toString() ?? '';

      _volumenPatronCtrl.text = ensayo.volumenPatron?.toString() ?? '';

      _caudalCtrl.text = ensayo.caudal?.toString() ?? '';

      _tipoPruebaCtrl.text = _normalizarOpcion(ensayo.tipoPrueba, _tiposPrueba);

      _instrumentoCtrl.text = ensayo.instrumentoBanco ?? '';

      _identificacionCtrl.text = ensayo.identificacionBanco ?? '';

      _trazabilidadCtrl.text = ensayo.trazabilidadCalibracion ?? '';

      _capacidadQ3Ctrl.text = ensayo.capacidadNominalQ3 ?? '';

      _tipoCaudalCtrl.text = _normalizarOpcion(ensayo.tipoCaudal, _tiposCaudal);

      _unidadCaudalCtrl.text = ensayo.unidadCaudal?.trim().isNotEmpty == true
          ? ensayo.unidadCaudal!
          : 'm³/h';

      _unidadVolumenCtrl.text = ensayo.unidadVolumen?.trim().isNotEmpty == true
          ? ensayo.unidadVolumen!
          : 'm³';

      _fugas = ensayo.fugas == true;

      _tipoFugaCtrl.text = _normalizarOpcion(ensayo.tipoFuga, _tiposFuga);

      _observacionesCtrl.text = ensayo.observaciones ?? '';
    });

    _agendarCalculo();
  }

  String _normalizarOpcion(String? value, List<String> opciones) {
    final limpio = value?.trim();

    if (limpio == null || limpio.isEmpty) {
      return '';
    }

    for (final opcion in opciones) {
      if (opcion.toLowerCase() == limpio.toLowerCase()) {
        return opcion;
      }
    }

    /*
     * Compatibilidad con datos antiguos:
     * si antes se guardó texto libre,
     * se representa como "Otro".
     */
    if (opciones.contains('Otro')) {
      return 'Otro';
    }

    return '';
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _condicionesCtrl.dispose();
    _lecturaInicialCtrl.dispose();
    _lecturaFinalCtrl.dispose();
    _volumenPatronCtrl.dispose();
    _caudalCtrl.dispose();

    _tipoPruebaCtrl.dispose();
    _instrumentoCtrl.dispose();
    _identificacionCtrl.dispose();
    _trazabilidadCtrl.dispose();
    _capacidadQ3Ctrl.dispose();

    _tipoCaudalCtrl.dispose();
    _unidadCaudalCtrl.dispose();
    _unidadVolumenCtrl.dispose();

    _tipoFugaCtrl.dispose();
    _observacionesCtrl.dispose();

    super.dispose();
  }

  double? _numero(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  double? _volumenRegistradoLocal() {
    final inicial = _numero(_lecturaInicialCtrl.text);

    final finalLectura = _numero(_lecturaFinalCtrl.text);

    if (inicial == null || finalLectura == null || finalLectura < inicial) {
      return null;
    }

    return finalLectura - inicial;
  }

  void _agendarCalculo([String? _]) {
    /*
     * Redibujamos también el volumen registrado
     * mostrado en pantalla.
     */
    if (mounted) {
      setState(() {});
    }

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), _calcular);
  }

  Future<void> _calcular() async {
    final lecturaInicial = _numero(_lecturaInicialCtrl.text);

    final lecturaFinal = _numero(_lecturaFinalCtrl.text);

    final volumenPatron = _numero(_volumenPatronCtrl.text);

    final caudal = _numero(_caudalCtrl.text);

    /*
     * No enviamos cálculos incompletos al backend.
     * Además evitamos dejar visible un resultado
     * antiguo cuando los nuevos valores todavía
     * no son válidos.
     */
    if (lecturaInicial == null ||
        lecturaFinal == null ||
        lecturaFinal < lecturaInicial ||
        volumenPatron == null ||
        volumenPatron <= 0 ||
        caudal == null ||
        caudal <= 0) {
      if (mounted) {
        setState(() {
          _calculo = null;
        });
      }

      return;
    }

    final calculo = await ref
        .read(verificacionControllerProvider.notifier)
        .calcularEnsayo(_request());

    if (!mounted) return;

    setState(() {
      _calculo = calculo;
    });
  }

  Map<String, dynamic> _request() {
    return {
      if (_condicionesCtrl.text.trim().isNotEmpty)
        'condiciones': _condicionesCtrl.text.trim(),

      'lecturaInicial': _numero(_lecturaInicialCtrl.text),

      'lecturaFinal': _numero(_lecturaFinalCtrl.text),

      'volumenPatron': _numero(_volumenPatronCtrl.text),

      'caudal': _numero(_caudalCtrl.text),

      'fugas': _fugas,

      if (_observacionesCtrl.text.trim().isNotEmpty)
        'observaciones': _observacionesCtrl.text.trim(),

      'participantes': _participantes(),

      if (_tipoPruebaCtrl.text.trim().isNotEmpty)
        'tipoPrueba': _tipoPruebaCtrl.text.trim(),

      if (_instrumentoCtrl.text.trim().isNotEmpty)
        'instrumentoBanco': _instrumentoCtrl.text.trim(),

      if (_identificacionCtrl.text.trim().isNotEmpty)
        'identificacionBanco': _identificacionCtrl.text.trim(),

      if (_trazabilidadCtrl.text.trim().isNotEmpty)
        'trazabilidadCalibracion': _trazabilidadCtrl.text.trim(),

      if (_capacidadQ3Ctrl.text.trim().isNotEmpty)
        'capacidadNominalQ3': _capacidadQ3Ctrl.text.trim(),

      if (_tipoCaudalCtrl.text.trim().isNotEmpty)
        'tipoCaudal': _tipoCaudalCtrl.text.trim(),

      if (_unidadCaudalCtrl.text.trim().isNotEmpty)
        'unidadCaudal': _unidadCaudalCtrl.text.trim(),

      if (_unidadVolumenCtrl.text.trim().isNotEmpty)
        'unidadVolumen': _unidadVolumenCtrl.text.trim(),

      if (_fugas && _tipoFugaCtrl.text.trim().isNotEmpty)
        'tipoFuga': _tipoFugaCtrl.text.trim(),
    };
  }

  List<Map<String, dynamic>> _participantes() {
    final state = ref.read(verificacionControllerProvider);

    final participantes =
        state.participantesBorrador ??
        state.verificacionActual?.participantes ??
        const <ParticipanteVerificacion>[];

    return participantes
        .map(
          (p) => {
            'nombre': p.nombre.trim(),
            if (p.cargo != null && p.cargo!.trim().isNotEmpty)
              'cargo': p.cargo!.trim(),
            if (p.rol != null && p.rol!.trim().isNotEmpty) 'rol': p.rol!.trim(),
          },
        )
        .toList();
  }

  String? _validar({required bool exigirCompletos}) {
    final lecturaInicial = _numero(_lecturaInicialCtrl.text);

    final lecturaFinal = _numero(_lecturaFinalCtrl.text);

    final volumenPatron = _numero(_volumenPatronCtrl.text);

    final caudal = _numero(_caudalCtrl.text);

    final q3 = _numero(_capacidadQ3Ctrl.text);

    /*
     * Primero validamos cualquier campo numérico
     * que haya sido ingresado.
     */
    if (_lecturaInicialCtrl.text.trim().isNotEmpty && lecturaInicial == null) {
      return 'La primera lectura debe ser numérica.';
    }

    if (_lecturaFinalCtrl.text.trim().isNotEmpty && lecturaFinal == null) {
      return 'La segunda lectura debe ser numérica.';
    }

    if (lecturaInicial != null &&
        lecturaFinal != null &&
        lecturaFinal < lecturaInicial) {
      return 'La segunda lectura debe ser mayor o igual que la primera.';
    }

    if (_volumenPatronCtrl.text.trim().isNotEmpty) {
      if (volumenPatron == null || volumenPatron <= 0) {
        return 'El volumen patrón debe ser mayor que cero.';
      }
    }

    if (_caudalCtrl.text.trim().isNotEmpty) {
      if (caudal == null || caudal <= 0) {
        return 'El caudal del ensayo debe ser mayor que cero.';
      }
    }

    if (_capacidadQ3Ctrl.text.trim().isNotEmpty) {
      if (q3 == null || q3 <= 0) {
        return 'La capacidad nominal Q3 debe ser un valor mayor que cero.';
      }
    }

    /*
     * Guardar ensayo funciona también como
     * borrador.
     *
     * Pero para CONTINUAR A FINALIZAR sí
     * exigimos todos los datos esenciales.
     */
    if (!exigirCompletos) {
      return null;
    }

    if (_condicionesCtrl.text.trim().isEmpty) {
      return 'Ingrese las condiciones del ensayo.';
    }

    if (_tipoPruebaCtrl.text.trim().isEmpty) {
      return 'Seleccione el tipo de prueba.';
    }

    if (_instrumentoCtrl.text.trim().isEmpty) {
      return 'Ingrese el instrumento o banco utilizado.';
    }

    if (_identificacionCtrl.text.trim().isEmpty) {
      return 'Ingrese la identificación del banco.';
    }

    if (_trazabilidadCtrl.text.trim().isEmpty) {
      return 'Ingrese la trazabilidad o calibración.';
    }

    if (q3 == null || q3 <= 0) {
      return 'Ingrese la capacidad nominal Q3.';
    }

    if (_tipoCaudalCtrl.text.trim().isEmpty) {
      return 'Seleccione el tipo de caudal.';
    }

    if (caudal == null || caudal <= 0) {
      return 'Ingrese un caudal del ensayo mayor que cero.';
    }

    if (_unidadCaudalCtrl.text.trim().isEmpty) {
      return 'Ingrese la unidad del caudal.';
    }

    if (lecturaInicial == null) {
      return 'Ingrese la primera lectura.';
    }

    if (lecturaFinal == null) {
      return 'Ingrese la segunda lectura.';
    }

    if (lecturaFinal < lecturaInicial) {
      return 'La segunda lectura debe ser mayor o igual que la primera.';
    }

    if (volumenPatron == null || volumenPatron <= 0) {
      return 'Ingrese un volumen patrón mayor que cero.';
    }

    if (_unidadVolumenCtrl.text.trim().isEmpty) {
      return 'Ingrese la unidad del volumen.';
    }

    if (_fugas && _tipoFugaCtrl.text.trim().isEmpty) {
      return 'Seleccione el tipo de fuga.';
    }

    return null;
  }

  Future<bool> _guardar({bool exigirCompletos = false}) async {
    final validacion = _validar(exigirCompletos: exigirCompletos);

    if (validacion != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validacion)));
      }

      return false;
    }

    final result = await ref
        .read(verificacionControllerProvider.notifier)
        .guardarEnsayo(widget.id, _request());

    if (!mounted) {
      return result != null;
    }

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar el ensayo. Revise los datos e inténtelo nuevamente.',
          ),
        ),
      );

      return false;
    }

    setState(() {
      _calculo = result.calculo ?? _calculo;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exigirCompletos
              ? 'Ensayo guardado correctamente.'
              : 'Borrador del ensayo guardado correctamente.',
        ),
      ),
    );

    return true;
  }

  Future<void> _guardarYContinuar() async {
    /*
     * CORRECCIÓN IMPORTANTE DE M5:
     *
     * Antes:
     *
     *   _guardar();
     *   context.go(...);
     *
     * La navegación ocurría aunque guardar
     * hubiera fallado.
     *
     * Ahora se espera la respuesta del backend.
     */
    final guardado = await _guardar(exigirCompletos: true);

    if (!mounted || !guardado) {
      return;
    }

    context.go('${AppRoutes.mecanicoHome}/verificacion/${widget.id}/finalizar');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificacionControllerProvider);

    final verificacion = state.verificacionActual;

    final volumenRegistrado = _volumenRegistradoLocal();

    final unidadVolumen = _unidadVolumenCtrl.text.trim().isEmpty
        ? 'unidad'
        : _unidadVolumenCtrl.text.trim();

    final unidadCaudal = _unidadCaudalCtrl.text.trim().isEmpty
        ? 'unidad'
        : _unidadCaudalCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ensayo de Verificación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go('${AppRoutes.mecanicoHome}/verificacion/${widget.id}'),
        ),
      ),
      body: state.isLoading && verificacion == null
          ? const Center(child: CircularProgressIndicator())
          : (verificacion?.finalizada ?? false)
          ? _FinalizadaView(
              id: widget.id,
              resultado: verificacion?.resultado,
              ensayo: verificacion?.ensayo,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VerMessageBar(
                  error: state.errorMessage,
                  success: state.successMessage,
                ),

                /*
                     * DATOS GENERALES DEL ENSAYO
                     */
                VerSection(
                  title: 'Datos del ensayo',
                  child: Column(
                    children: [
                      _selector(
                        controller: _tipoPruebaCtrl,
                        label: 'Tipo de prueba *',
                        opciones: _tiposPrueba,
                        onChanged: (_) => _agendarCalculo(),
                      ),

                      const SizedBox(height: 10),

                      _campo(
                        _instrumentoCtrl,
                        'Instrumento o banco utilizado *',
                      ),

                      const SizedBox(height: 10),

                      _campo(_identificacionCtrl, 'Identificación del banco *'),

                      const SizedBox(height: 10),

                      _campo(_trazabilidadCtrl, 'Trazabilidad / calibración *'),

                      const SizedBox(height: 10),

                      _campo(
                        _capacidadQ3Ctrl,
                        'Capacidad nominal Q3 *',
                        numerico: true,
                      ),
                    ],
                  ),
                ),

                /*
                     * CAUDAL
                     */
                VerSection(
                  title: 'Caudal',
                  child: Column(
                    children: [
                      _selector(
                        controller: _tipoCaudalCtrl,
                        label: 'Tipo de caudal *',
                        opciones: _tiposCaudal,
                        onChanged: (_) => _agendarCalculo(),
                      ),

                      const SizedBox(height: 10),

                      _campo(
                        _caudalCtrl,
                        'Caudal del ensayo *',
                        numerico: true,
                        suffixText: unidadCaudal,
                        onChange: _agendarCalculo,
                      ),

                      const SizedBox(height: 10),

                      _campo(
                        _unidadCaudalCtrl,
                        'Unidad del caudal *',
                        onChange: _agendarCalculo,
                      ),
                    ],
                  ),
                ),

                /*
                     * LECTURAS Y VOLÚMENES
                     */
                VerSection(
                  title: 'Lecturas y volúmenes',
                  child: Column(
                    children: [
                      _campo(
                        _lecturaInicialCtrl,
                        'Primera lectura *',
                        onChange: _agendarCalculo,
                        numerico: true,
                        suffixText: unidadVolumen,
                      ),

                      const SizedBox(height: 10),

                      _campo(
                        _lecturaFinalCtrl,
                        'Segunda lectura *',
                        onChange: _agendarCalculo,
                        numerico: true,
                        suffixText: unidadVolumen,
                      ),

                      const SizedBox(height: 10),

                      _campoSoloLectura(
                        label: 'Volumen registrado',
                        value: volumenRegistrado == null
                            ? 'Se calcula con las lecturas'
                            : verDecimal(volumenRegistrado),
                        suffixText: unidadVolumen,
                      ),

                      const SizedBox(height: 10),

                      _campo(
                        _volumenPatronCtrl,
                        'Volumen patrón *',
                        onChange: _agendarCalculo,
                        numerico: true,
                        suffixText: unidadVolumen,
                      ),

                      const SizedBox(height: 10),

                      _campo(
                        _unidadVolumenCtrl,
                        'Unidad del volumen *',
                        onChange: _agendarCalculo,
                      ),
                    ],
                  ),
                ),

                /*
                     * FUGAS
                     */
                VerSection(
                  title: 'Fugas',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '¿Se registran fugas?',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_fugas ? 'Sí' : 'No'),
                        value: _fugas,
                        activeThumbColor: AppColors.odecoRed,
                        onChanged: (value) {
                          setState(() {
                            _fugas = value;

                            if (!value) {
                              _tipoFugaCtrl.clear();
                            }
                          });

                          _agendarCalculo();
                        },
                      ),

                      if (_fugas) ...[
                        const SizedBox(height: 8),
                        _selector(
                          controller: _tipoFugaCtrl,
                          label: 'Tipo de fuga *',
                          opciones: _tiposFuga,
                        ),
                      ],
                    ],
                  ),
                ),

                /*
                     * CONDICIONES Y OBSERVACIONES
                     */
                VerSection(
                  title: 'Condiciones y observaciones',
                  child: Column(
                    children: [
                      TextField(
                        controller: _condicionesCtrl,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Condiciones del ensayo *',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: _observacionesCtrl,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),

                /*
                     * PREVISUALIZACIÓN DEL CÁLCULO.
                     *
                     * El cálculo completo pertenece a M6,
                     * pero tu proyecto ya lo realizaba,
                     * por lo que no lo eliminamos.
                     */
                VerSection(
                  title: 'Resultado del cálculo',
                  child: _calculo == null
                      ? const Text(
                          'Complete las lecturas, el volumen patrón y el caudal para calcular el error.',
                          style: TextStyle(color: Color(0xFF667085)),
                        )
                      : _CalculoPanel(
                          calculo: _calculo!,
                          unidadVolumen: unidadVolumen,
                        ),
                ),

                const SizedBox(height: 8),

                /*
                     * GUARDAR BORRADOR
                     */
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isAccion
                        ? null
                        : () async {
                            await _guardar();
                          },
                    icon: state.isAccion
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      state.isAccion ? 'Guardando...' : 'Guardar ensayo',
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                /*
                     * GUARDAR Y CONTINUAR
                     */
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.isAccion ? null : _guardarYContinuar,
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Guardar y continuar a finalizar'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String label, {
    ValueChanged<String>? onChange,
    bool numerico = false,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numerico
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numerico ? [_decimalFormatter] : null,
      textCapitalization: numerico
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      onChanged: onChange,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _selector({
    required TextEditingController controller,
    required String label,
    required List<String> opciones,
    ValueChanged<String?>? onChanged,
  }) {
    final actual = controller.text.trim();

    final value = opciones.contains(actual) ? actual : null;

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: opciones
          .map(
            (opcion) =>
                DropdownMenuItem<String>(value: opcion, child: Text(opcion)),
          )
          .toList(),
      onChanged: (nuevo) {
        setState(() {
          controller.text = nuevo ?? '';
        });

        onChanged?.call(nuevo);
      },
    );
  }

  Widget _campoSoloLectura({
    required String label,
    required String value,
    String? suffixText,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        filled: true,
        fillColor: const Color(0xFFF5F7F8),
        border: const OutlineInputBorder(),
      ),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _CalculoPanel extends StatelessWidget {
  const _CalculoPanel({required this.calculo, required this.unidadVolumen});

  final CalculoEnsayo calculo;
  final String unidadVolumen;

  @override
  Widget build(BuildContext context) {
    final resultado = calculo.resultado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VerDataRow(
          label: 'Volumen registrado',
          value: '${verDecimal(calculo.volumenRegistrado)} $unidadVolumen',
        ),

        VerDataRow(
          label: 'Volumen patrón',
          value: '${verDecimal(calculo.volumenPatron)} $unidadVolumen',
        ),

        VerDataRow(
          label: 'Diferencia',
          value: '${verDecimal(calculo.diferencia)} $unidadVolumen',
        ),

        VerDataRow(
          label: 'Error con signo',
          value: '${verDecimal(calculo.errorConSigno, decimals: 2)} %',
        ),

        VerDataRow(
          label: 'Error absoluto',
          value: '${verDecimal(calculo.errorAbsoluto, decimals: 2)} %',
        ),

        VerDataRow(
          label: 'Límite permitido',
          value: '${verDecimal(calculo.limitePermitido, decimals: 2)} %',
        ),

        VerDataRow(
          label: 'Parámetro normativo',
          value: calculo.parametroNormativo ?? 'No disponible',
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            const Text(
              'Resultado: ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            if (resultado != null)
              VerStatusChip(resultado)
            else
              VerStatusChip('Sin calcular'),
          ],
        ),
      ],
    );
  }
}

class _FinalizadaView extends StatelessWidget {
  const _FinalizadaView({required this.id, this.resultado, this.ensayo});

  final int id;
  final String? resultado;
  final EnsayoVerificacion? ensayo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        VerSection(
          title: 'Verificación finalizada',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Resultado: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  VerStatusChip(resultado ?? 'INDETERMINADO'),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                'El ensayo ya está cerrado y no admite modificaciones.',
                style: TextStyle(color: Color(0xFF667085)),
              ),

              const SizedBox(height: 14),

              VerDataRow(
                label: 'Error',
                value: '${verDecimal(ensayo?.error, decimals: 2)} %',
              ),

              VerDataRow(
                label: 'Volumen registrado',
                value: verDecimal(ensayo?.volumenRegistrado),
              ),

              VerDataRow(
                label: 'Fugas',
                value: ensayo?.fugas == true ? 'Sí' : 'No',
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go(
                    '${AppRoutes.mecanicoHome}/verificacion/$id/informe',
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Ir al informe'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
