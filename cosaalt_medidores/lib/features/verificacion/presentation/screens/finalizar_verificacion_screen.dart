import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/verificacion_ui.dart';

class FinalizarVerificacionScreen extends ConsumerStatefulWidget {
  const FinalizarVerificacionScreen({
    required this.id,
    super.key,
  });

  final int id;

  @override
  ConsumerState<FinalizarVerificacionScreen> createState() =>
      _FinalizarVerificacionScreenState();
}

class _FinalizarVerificacionScreenState
    extends ConsumerState<FinalizarVerificacionScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref
          .read(verificacionControllerProvider.notifier)
          .cargarVerificacion(widget.id);
    });
  }

  Future<void> _finalizar() async {
    final state = ref.read(verificacionControllerProvider);
    final v = state.verificacionActual;

    if (v == null) {
      _mensaje('No se encontró la verificación.');
      return;
    }

    if (v.finalizada) {
      _mensaje('La verificación ya fue finalizada.');
      return;
    }

    final validacion = _validarAntesDeFinalizar(v);

    if (validacion != null) {
      _mensaje(validacion);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Finalizar verificación'),
          content: const Text(
            'Una vez finalizada, la verificación quedará cerrada '
            'y ya no podrá editarse normalmente.\n\n'
            '¿Confirma que revisó todos los datos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.task_alt),
              label: const Text('Sí, finalizar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    final ok = await ref
        .read(verificacionControllerProvider.notifier)
        .finalizar(widget.id);

    if (!ok || !mounted) {
      return;
    }

    context.go(
      '${AppRoutes.mecanicoHome}/verificacion/${widget.id}/informe',
    );
  }

  Future<void> _guardarBorrador() async {
    final state = ref.read(verificacionControllerProvider);
    final v = state.verificacionActual;
    final e = v?.ensayo;

    if (v == null || e == null) {
      _mensaje(
        'Aún no hay datos de ensayo para guardar como borrador.',
      );
      return;
    }

    if (v.finalizada) {
      _mensaje(
        'La verificación ya está finalizada y no admite modificaciones.',
      );
      return;
    }

    final request = <String, dynamic>{
      if (e.condiciones != null &&
          e.condiciones!.trim().isNotEmpty)
        'condiciones': e.condiciones!.trim(),

      'lecturaInicial': e.lecturaInicial,
      'lecturaFinal': e.lecturaFinal,
      'volumenPatron': e.volumenPatron,
      'caudal': e.caudal,
      'fugas': e.fugas ?? false,

      if (e.observaciones != null &&
          e.observaciones!.trim().isNotEmpty)
        'observaciones': e.observaciones!.trim(),

      'participantes':
          v.participantes.map((p) => p.toJson()).toList(),

      if (e.tipoPrueba != null &&
          e.tipoPrueba!.trim().isNotEmpty)
        'tipoPrueba': e.tipoPrueba!.trim(),

      if (e.instrumentoBanco != null &&
          e.instrumentoBanco!.trim().isNotEmpty)
        'instrumentoBanco': e.instrumentoBanco!.trim(),

      if (e.identificacionBanco != null &&
          e.identificacionBanco!.trim().isNotEmpty)
        'identificacionBanco': e.identificacionBanco!.trim(),

      if (e.trazabilidadCalibracion != null &&
          e.trazabilidadCalibracion!.trim().isNotEmpty)
        'trazabilidadCalibracion':
            e.trazabilidadCalibracion!.trim(),

      if (e.capacidadNominalQ3 != null &&
          e.capacidadNominalQ3!.trim().isNotEmpty)
        'capacidadNominalQ3':
            e.capacidadNominalQ3!.trim(),

      if (e.tipoCaudal != null &&
          e.tipoCaudal!.trim().isNotEmpty)
        'tipoCaudal': e.tipoCaudal!.trim(),

      if (e.unidadCaudal != null &&
          e.unidadCaudal!.trim().isNotEmpty)
        'unidadCaudal': e.unidadCaudal!.trim(),

      if (e.unidadVolumen != null &&
          e.unidadVolumen!.trim().isNotEmpty)
        'unidadVolumen': e.unidadVolumen!.trim(),

      if ((e.fugas ?? false) &&
          e.tipoFuga != null &&
          e.tipoFuga!.trim().isNotEmpty)
        'tipoFuga': e.tipoFuga!.trim(),
    };

    final result = await ref
        .read(verificacionControllerProvider.notifier)
        .guardarEnsayo(
          widget.id,
          request,
        );

    if (result == null || !mounted) {
      return;
    }

    _mensaje('Borrador guardado correctamente.');
  }

  void _volverAEditar() {
    context.go(
      '${AppRoutes.mecanicoHome}/verificacion/${widget.id}/ensayo',
    );
  }

  String? _validarAntesDeFinalizar(
    VerificacionMecanico v,
  ) {
    final e = v.ensayo;

    if (e == null) {
      return 'Debe registrar el ensayo antes de finalizar.';
    }

    if (e.lecturaInicial == null) {
      return 'Falta la primera lectura.';
    }

    if (e.lecturaFinal == null) {
      return 'Falta la segunda lectura.';
    }

    if (e.lecturaFinal! < e.lecturaInicial!) {
      return 'La segunda lectura no puede ser menor que la primera.';
    }

    if (e.volumenPatron == null ||
        e.volumenPatron! <= 0) {
      return 'El volumen patrón debe ser mayor que cero.';
    }

    if (e.caudal == null || e.caudal! <= 0) {
      return 'El caudal del ensayo debe ser mayor que cero.';
    }

    if (_vacio(e.condiciones)) {
      return 'Faltan las condiciones del ensayo.';
    }

    if (_vacio(e.tipoPrueba)) {
      return 'Falta el tipo de prueba.';
    }

    if (_vacio(e.instrumentoBanco)) {
      return 'Falta el instrumento o banco utilizado.';
    }

    if (_vacio(e.identificacionBanco)) {
      return 'Falta la identificación del banco.';
    }

    if (_vacio(e.trazabilidadCalibracion)) {
      return 'Falta la trazabilidad o calibración.';
    }

    if (_vacio(e.capacidadNominalQ3)) {
      return 'Falta la capacidad nominal Q3.';
    }

    if (_vacio(e.tipoCaudal)) {
      return 'Falta el tipo de caudal.';
    }

    if (_vacio(e.unidadCaudal)) {
      return 'Falta la unidad del caudal.';
    }

    if (_vacio(e.unidadVolumen)) {
      return 'Falta la unidad del volumen.';
    }

    if ((e.fugas ?? false) && _vacio(e.tipoFuga)) {
      return 'Debe indicar si la fuga es visible o no visible.';
    }

    /*
     * INDETERMINADO es válido para M6 cuando no existe
     * parámetro normativo aplicable.
     *
     * Por eso NO bloqueamos la finalización solamente
     * porque el resultado sea INDETERMINADO.
     */
    if (_vacio(v.resultado)) {
      return 'El ensayo todavía no tiene un resultado calculado.';
    }

    return null;
  }

  bool _vacio(String? value) {
    return value == null || value.trim().isEmpty;
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificacionControllerProvider);
    final v = state.verificacionActual;
    final e = v?.ensayo;
    final datos = state.datosSocio;

    final unidadVolumen =
        !_vacio(e?.unidadVolumen)
            ? e!.unidadVolumen!.trim()
            : '';

    final unidadCaudal =
        !_vacio(e?.unidadCaudal)
            ? e!.unidadCaudal!.trim()
            : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Revisión y finalización',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (v?.finalizada ?? false) {
              context.go(
                '${AppRoutes.mecanicoHome}/verificacion/${widget.id}',
              );
            } else {
              _volverAEditar();
            }
          },
        ),
      ),
      body: state.isLoading && v == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VerMessageBar(
                  error: state.errorMessage,
                  success: state.successMessage,
                ),

                if (v == null)
                  const VerSection(
                    title: 'Verificación',
                    child: Text(
                      'No se encontró la verificación.',
                    ),
                  )
                else ...[
                  if (v.finalizada)
                    VerSection(
                      title: 'Estado',
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Esta verificación ya fue finalizada. '
                              'Los datos se encuentran bloqueados para edición.',
                            ),
                          ),
                          const SizedBox(width: 12),
                          VerStatusChip(
                            v.resultado ?? 'INDETERMINADO',
                          ),
                        ],
                      ),
                    ),

                  /*
                   * DATOS DEL SOCIO
                   */
                  VerSection(
                    title: 'Datos del socio',
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _valor(
                            v.nombreCliente ??
                                datos?.nombreCliente,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),

                        const Divider(height: 18),

                        VerDataRow(
                          label: 'Registro socio',
                          value: _valor(
                            datos?.regSoc?.toString() ??
                                v.codCon.toString(),
                          ),
                        ),

                        VerDataRow(
                          label: 'Código / Conexión',
                          value: _valor(
                            datos?.codConexion?.toString(),
                          ),
                        ),

                        VerDataRow(
                          label: 'Dirección',
                          value: _valor(
                            datos?.direccion,
                          ),
                        ),

                        VerDataRow(
                          label: 'Documento',
                          value: _documento(
                            datos?.tipDocumento,
                            datos?.numeroDocumento,
                          ),
                        ),

                        VerDataRow(
                          label: 'RUC',
                          value: _valor(datos?.ruc),
                        ),
                      ],
                    ),
                  ),

                  /*
                   * MEDIDOR
                   */
                  VerSection(
                    title: 'Datos del medidor',
                    child: Column(
                      children: [
                        VerDataRow(
                          label: 'Marca',
                          value: _valor(
                            datos?.marcaMedidor,
                          ),
                        ),

                        VerDataRow(
                          label: 'Serie',
                          value: _valor(
                            datos?.numeroMedidor ??
                                v.idMedidor,
                          ),
                        ),

                        VerDataRow(
                          label: 'Q3',
                          value: _valor(
                            e?.capacidadNominalQ3 ??
                                datos?.capacidadQ3,
                          ),
                        ),

                        VerDataRow(
                          label: 'Tipo',
                          value: _valor(
                            datos?.tipoMedidor,
                          ),
                        ),

                        VerDataRow(
                          label: 'Clase',
                          value: _valor(
                            datos?.claseMedidor,
                          ),
                        ),

                        VerDataRow(
                          label: 'Diámetro',
                          value: _valor(
                            datos?.diametroMedidor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /*
                   * PARTICIPANTES
                   */
                  VerSection(
                    title:
                        'Participantes (${v.participantes.length})',
                    child: v.participantes.isEmpty
                        ? const Text(
                            'No se registraron participantes.',
                          )
                        : Column(
                            children: [
                              for (var i = 0;
                                  i < v.participantes.length;
                                  i++) ...[
                                _ParticipanteResumen(
                                  numero: i + 1,
                                  participante:
                                      v.participantes[i],
                                ),
                                if (i <
                                    v.participantes.length - 1)
                                  const Divider(
                                    height: 20,
                                  ),
                              ],
                            ],
                          ),
                  ),

                  /*
                   * DATOS DEL ENSAYO
                   */
                  VerSection(
                    title: 'Datos del ensayo',
                    child: Column(
                      children: [
                        VerDataRow(
                          label: 'Tipo de prueba',
                          value: _valor(
                            e?.tipoPrueba,
                          ),
                        ),

                        VerDataRow(
                          label:
                              'Instrumento / banco',
                          value: _valor(
                            e?.instrumentoBanco,
                          ),
                        ),

                        VerDataRow(
                          label:
                              'Identificación del banco',
                          value: _valor(
                            e?.identificacionBanco,
                          ),
                        ),

                        VerDataRow(
                          label:
                              'Trazabilidad / calibración',
                          value: _valor(
                            e?.trazabilidadCalibracion,
                          ),
                        ),

                        VerDataRow(
                          label: 'Tipo de caudal',
                          value: _valor(
                            e?.tipoCaudal,
                          ),
                        ),

                        VerDataRow(
                          label: 'Caudal',
                          value: _numeroUnidad(
                            e?.caudal,
                            unidadCaudal,
                          ),
                        ),

                        const Divider(height: 18),

                        VerDataRow(
                          label: 'Primera lectura',
                          value: _numeroUnidad(
                            e?.lecturaInicial,
                            unidadVolumen,
                          ),
                        ),

                        VerDataRow(
                          label: 'Segunda lectura',
                          value: _numeroUnidad(
                            e?.lecturaFinal,
                            unidadVolumen,
                          ),
                        ),

                        VerDataRow(
                          label: 'Volumen registrado',
                          value: _numeroUnidad(
                            e?.volumenRegistrado,
                            unidadVolumen,
                          ),
                        ),

                        VerDataRow(
                          label: 'Volumen patrón',
                          value: _numeroUnidad(
                            e?.volumenPatron,
                            unidadVolumen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /*
                   * CONDICIONES Y OBSERVACIONES
                   */
                  VerSection(
                    title: 'Condiciones y observaciones',
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        VerDataRow(
                          label: 'Condiciones',
                          value: _valor(
                            e?.condiciones,
                          ),
                        ),

                        VerDataRow(
                          label: 'Observaciones',
                          value: _valor(
                            e?.observaciones,
                          ),
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
                        VerDataRow(
                          label: '¿Registra fuga?',
                          value:
                              e?.fugas == true ? 'Sí' : 'No',
                        ),

                        if (e?.fugas == true)
                          VerDataRow(
                            label: 'Tipo de fuga',
                            value: _valor(
                              e?.tipoFuga,
                            ),
                          ),
                      ],
                    ),
                  ),

                  /*
                   * RESULTADO M6
                   */
                  VerSection(
                    title: 'Resultado de la verificación',
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        VerDataRow(
                          label: 'Error',
                          value: e?.error == null
                              ? 'No registrado'
                              : '${e!.error!.toStringAsFixed(2)} %',
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Text(
                              'Resultado: ',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            VerStatusChip(
                              v.resultado ??
                                  'INDETERMINADO',
                            ),
                          ],
                        ),

                        if (v.resultado ==
                            'INDETERMINADO') ...[
                          const SizedBox(height: 10),
                          const Text(
                            'No se encontró un parámetro normativo '
                            'aplicable al caudal registrado. '
                            'La verificación puede conservar el resultado '
                            'INDETERMINADO.',
                            style: TextStyle(
                              color: Color(0xFF667085),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (!v.finalizada) ...[
                    /*
                     * ACCIÓN 1: VOLVER A EDITAR
                     */
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            state.isAccion
                                ? null
                                : _volverAEditar,
                        icon: const Icon(
                          Icons.edit_outlined,
                        ),
                        label: const Text(
                          'Volver a editar',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /*
                     * ACCIÓN 2: GUARDAR BORRADOR
                     */
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            state.isAccion
                                ? null
                                : _guardarBorrador,
                        icon: const Icon(
                          Icons.save_outlined,
                        ),
                        label: const Text(
                          'Guardar borrador',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /*
                     * ACCIÓN 3: FINALIZAR
                     */
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            state.isAccion
                                ? null
                                : _finalizar,
                        icon: state.isAccion
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.task_alt,
                              ),
                        label: Text(
                          state.isAccion
                              ? 'Finalizando...'
                              : 'Finalizar verificación',
                        ),
                      ),
                    ),
                  ] else ...[
                    /*
                     * FINALIZADA:
                     * NO SE OFRECEN BOTONES DE EDICIÓN.
                     */
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.go(
                            '${AppRoutes.mecanicoHome}/verificacion/${widget.id}/informe',
                          );
                        },
                        icon: const Icon(
                          Icons.description_outlined,
                        ),
                        label: const Text(
                          'Ir al informe',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.go(
                            AppRoutes.mecanicoHome,
                          );
                        },
                        icon: const Icon(
                          Icons.home_outlined,
                        ),
                        label: const Text(
                          'Volver al inicio',
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }

  String _valor(Object? value) {
    if (value == null) {
      return 'No registrado';
    }

    final texto = value.toString().trim();

    return texto.isEmpty
        ? 'No registrado'
        : texto;
  }

  String _documento(
    String? tipo,
    String? numero,
  ) {
    final t = tipo?.trim() ?? '';
    final n = numero?.trim() ?? '';

    if (t.isEmpty && n.isEmpty) {
      return 'No registrado';
    }

    if (t.isEmpty) {
      return n;
    }

    if (n.isEmpty) {
      return t;
    }

    return '$t $n';
  }

  String _numeroUnidad(
    double? value,
    String unidad,
  ) {
    if (value == null) {
      return 'No registrado';
    }

    final numero = value.toStringAsFixed(4);

    if (unidad.trim().isEmpty) {
      return numero;
    }

    return '$numero ${unidad.trim()}';
  }
}

class _ParticipanteResumen extends StatelessWidget {
  const _ParticipanteResumen({
    required this.numero,
    required this.participante,
  });

  final int numero;
  final ParticipanteVerificacion participante;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Participante $numero',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        VerDataRow(
          label: 'Nombre',
          value: _valor(
            participante.nombre,
          ),
        ),

        VerDataRow(
          label: 'Cargo',
          value: _valor(
            participante.cargo,
          ),
        ),

        VerDataRow(
          label: 'Tipo / rol',
          value: _valor(
            participante.rol,
          ),
        ),
      ],
    );
  }

  String _valor(String? value) {
    final texto = value?.trim() ?? '';

    return texto.isEmpty
        ? 'No registrado'
        : texto;
  }
}