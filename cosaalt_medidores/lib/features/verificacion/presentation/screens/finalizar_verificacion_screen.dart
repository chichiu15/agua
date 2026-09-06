import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/verificacion_ui.dart';

class FinalizarVerificacionScreen extends ConsumerStatefulWidget {
  const FinalizarVerificacionScreen({required this.id, super.key});

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
      await ref.read(verificacionControllerProvider.notifier).cargarVerificacion(widget.id);
    });
  }

  Future<void> _finalizar() async {
    final ok = await ref.read(verificacionControllerProvider.notifier).finalizar(widget.id);
    if (!ok || !mounted) return;
    context.go('${AppRoutes.mecanicoHome}/verificacion/${widget.id}/informe');
  }

  Future<void> _guardarBorrador() async {
    final v = ref.read(verificacionControllerProvider).verificacionActual;
    final e = v?.ensayo;
    if (v == null || e == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aun no hay datos de ensayo para guardar como borrador.')),
      );
      return;
    }
    final request = <String, dynamic>{
      if (e.condiciones != null && e.condiciones!.isNotEmpty) 'condiciones': e.condiciones,
      'lecturaInicial': e.lecturaInicial,
      'lecturaFinal': e.lecturaFinal,
      'volumenPatron': e.volumenPatron,
      'caudal': e.caudal,
      'fugas': e.fugas ?? false,
      if (e.observaciones != null && e.observaciones!.isNotEmpty) 'observaciones': e.observaciones,
      'participantes': v.participantes.map((p) => p.toJson()).toList(),
      if (e.tipoPrueba != null && e.tipoPrueba!.isNotEmpty) 'tipoPrueba': e.tipoPrueba,
      if (e.instrumentoBanco != null && e.instrumentoBanco!.isNotEmpty) 'instrumentoBanco': e.instrumentoBanco,
      if (e.identificacionBanco != null && e.identificacionBanco!.isNotEmpty) 'identificacionBanco': e.identificacionBanco,
      if (e.trazabilidadCalibracion != null && e.trazabilidadCalibracion!.isNotEmpty) 'trazabilidadCalibracion': e.trazabilidadCalibracion,
      if (e.capacidadNominalQ3 != null && e.capacidadNominalQ3!.isNotEmpty) 'capacidadNominalQ3': e.capacidadNominalQ3,
      if (e.tipoCaudal != null && e.tipoCaudal!.isNotEmpty) 'tipoCaudal': e.tipoCaudal,
      if (e.unidadCaudal != null && e.unidadCaudal!.isNotEmpty) 'unidadCaudal': e.unidadCaudal,
      if (e.unidadVolumen != null && e.unidadVolumen!.isNotEmpty) 'unidadVolumen': e.unidadVolumen,
      if ((e.fugas ?? false) && e.tipoFuga != null && e.tipoFuga!.isNotEmpty) 'tipoFuga': e.tipoFuga,
    };
    final result = await ref
        .read(verificacionControllerProvider.notifier)
        .guardarEnsayo(widget.id, request);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borrador guardado correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificacionControllerProvider);
    final v = state.verificacionActual;
    final e = v?.ensayo;
    final datos = state.datosSocio;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Verificacion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('${AppRoutes.mecanicoHome}/verificacion/${widget.id}/ensayo'),
        ),
      ),
      body: state.isLoading && v == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VerMessageBar(error: state.errorMessage, success: state.successMessage),
                VerSection(
                  title: 'Resumen de la verificacion',
                  child: v == null
                      ? const Text('No se encontro la verificacion.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.nombreCliente ?? datos?.nombreCliente ?? 'Socio ${v.codCon}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const Divider(height: 18),
                            VerDataRow(label: 'Conexion', value: '${v.codCon}'),
                            VerDataRow(label: 'Direccion', value: datos?.direccion ?? '-'),
                            VerDataRow(
                              label: 'Medidor',
                              value: '${datos?.marcaMedidor ?? ''} ${datos?.numeroMedidor ?? ''}'.trim().isEmpty
                                  ? v.idMedidor ?? '-'
                                  : '${datos?.marcaMedidor ?? ''} ${datos?.numeroMedidor ?? ''}'.trim(),
                            ),
                            const Divider(height: 18),
                            VerDataRow(label: 'Lectura inicial', value: _dec(e?.lecturaInicial)),
                            VerDataRow(label: 'Lectura final', value: _dec(e?.lecturaFinal)),
                            VerDataRow(label: 'Volumen registrado', value: _dec(e?.volumenRegistrado)),
                            VerDataRow(label: 'Volumen patron', value: _dec(e?.volumenPatron)),
                            VerDataRow(label: 'Caudal', value: _dec(e?.caudal)),
                            VerDataRow(label: 'Error', value: e?.error == null ? '-' : '${e!.error!.toStringAsFixed(2)} %'),
                            VerDataRow(label: 'Fugas', value: e?.fugas == true ? 'Si' : 'No'),
                            VerDataRow(label: 'Participantes', value: '${v.participantes.length}'),
                            if (e?.condiciones?.isNotEmpty == true)
                              VerDataRow(label: 'Condiciones', value: e!.condiciones!),
                            if (e?.observaciones?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              VerDataRow(label: 'Observaciones', value: e!.observaciones!),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text('Resultado: ', style: TextStyle(fontWeight: FontWeight.w700)),
                                VerStatusChip(v.resultado ?? 'INDETERMINADO'),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isAccion || (v?.finalizada ?? false)
                        ? null
                        : _finalizar,
                    icon: state.isAccion
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.task_alt),
                    label: Text(v?.finalizada ?? false ? 'Ya finalizada' : 'Finalizar verificacion'),
                  ),
                ),
                if (!(v?.finalizada ?? false)) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: state.isAccion ? null : _guardarBorrador,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar borrador'),
                    ),
                  ),
                ],
                if (v?.finalizada ?? false) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('${AppRoutes.mecanicoHome}/verificacion/${widget.id}/informe'),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Ir al informe'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String _dec(double? value) => value == null ? '-' : value.toStringAsFixed(4);
}