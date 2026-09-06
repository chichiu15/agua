import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(verificacionControllerProvider.notifier).cargarVerificacion(widget.id);
      await ref.read(verificacionControllerProvider.notifier).cargarInformes(widget.id);
    });
  }

  @override
  void dispose() {
    _observacionesCtrl.dispose();
    _responsableCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificacionControllerProvider);
    final v = state.verificacionActual;
    final informes = state.informes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informe Tecnico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.mecanicoHome),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VerMessageBar(error: state.errorMessage, success: state.successMessage),
          VerSection(
            title: 'Estado del informe',
            child: v == null
                ? const Text('No se encontro la verificacion.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VerDataRow(label: 'Verificacion', value: '#${v.id}'),
                      VerDataRow(label: 'Socio', value: v.nombreCliente ?? 'Socio ${v.codCon}'),
                      VerDataRow(label: 'Estado', value: v.estado),
                      VerDataRow(label: 'Resultado', value: v.resultado ?? 'Sin definir'),
                      const SizedBox(height: 6),
                      Text(
                        v.finalizada
                            ? 'Puede generar o volver a generar el informe tecnico. Cada emision crea una nueva version sin borrar las anteriores.'
                            : 'Finalice la verificacion para poder generar el informe tecnico.',
                        style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
                      ),
                      if (!v.finalizada) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.go('${AppRoutes.mecanicoHome}/verificacion/${widget.id}/finalizar'),
                            icon: const Icon(Icons.task_alt),
                            label: const Text('Ir a finalizar'),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          if (informes.isNotEmpty)
            VerSection(
              title: 'Versiones emitidas',
              child: Column(
                children: [
                  ...informes.map((informe) => _InformeRow(
                        informe: informe,
                        onDescargar: () => _descargar(context, informe),
                      )),
                ],
              ),
            ),
          if ((v?.finalizada ?? false))
            VerSection(
              title: 'Nueva emision',
              child: Column(
                children: [
                  TextField(
                    controller: _responsableCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del responsable (firma)', isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _observacionesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observaciones del informe', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.isAccion ? null : _generar,
                      icon: state.isAccion
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Generar informe'),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go(AppRoutes.mecanicoHome),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Volver al inicio'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generar() async {
    await ref.read(verificacionControllerProvider.notifier).generarInforme(
          widget.id,
          observaciones: _observacionesCtrl.text,
          nombreResponsable: _responsableCtrl.text,
        );
  }

  Future<void> _descargar(BuildContext context, InformeVerificacion informe) async {
    try {
      final repo = ref.read(verificacionRepositoryProvider);
      final path = await repo.descargarInforme(informe.id, informe.nroInforme);
      if (path.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF guardado en: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

class _InformeRow extends StatelessWidget {
  const _InformeRow({required this.informe, required this.onDescargar});

  final InformeVerificacion informe;
  final VoidCallback onDescargar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE4E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.darkBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  informe.nroInforme,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version ${informe.versionInforme} · ${verDate(informe.fechaEmision, time: true)}',
                  style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
                ),
              ],
            ),
          ),
          VerStatusChip(informe.firmado ? 'Firmado' : 'Pendiente firma'),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Descargar PDF',
            onPressed: onDescargar,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
    ),
  );
}