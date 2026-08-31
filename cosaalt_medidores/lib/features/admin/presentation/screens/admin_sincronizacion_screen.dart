import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/admin_supervision_controller.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ui.dart';

class AdminSincronizacionScreen extends ConsumerStatefulWidget {
  const AdminSincronizacionScreen({super.key});
  @override
  ConsumerState<AdminSincronizacionScreen> createState() => _AdminSincronizacionScreenState();
}

class _AdminSincronizacionScreenState extends ConsumerState<AdminSincronizacionScreen> {
  DateTime _fecha = DateTime.now();
  @override
  void initState() { super.initState(); Future.microtask(_load); }
  Future<void> _load() => ref.read(adminSupervisionControllerProvider.notifier).cargarSincronizacion(fecha: _fecha);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupervisionControllerProvider);
    final items = state.sincronizacion;
    final revisar = items.where((x) => x.estadoServidor == 'Revisar').length;
    final recibidas = items.fold<int>(0, (a, b) => a + b.ejecucionesRecibidasHoy);
    final sincronizadas = items.fold<int>(0, (a, b) => a + b.ejecucionesSincronizadasHoy);
    final inconsistencias = items.fold<int>(0, (a, b) => a + b.paradasCompletadasSinEjecucion + b.ejecucionesSinParada + b.ejecucionesPendientesServidor + b.ejecucionesDuplicadas);

    return AdminShell(
      title: 'Monitoreo de Sincronizacion',
      subtitle: 'Estado conocido por el servidor: rutas, ejecuciones recibidas e inconsistencias detectables sin modificar la BD.',
      currentRoute: '/admin/sincronizacion',
      actions: [OutlinedButton.icon(onPressed: state.isLoading ? null : _load, icon: const Icon(Icons.refresh), label: const Text('Actualizar'))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AdminMessage(error: state.errorMessage, success: state.successMessage),
        Wrap(spacing: 12, runSpacing: 12, children: [
          AdminMetricCard(label: 'Ejecuciones recibidas', value: '$recibidas', icon: Icons.cloud_download_outlined, tone: const Color(0xFF1677FF)),
          AdminMetricCard(label: 'Marcadas sincronizadas', value: '$sincronizadas', icon: Icons.cloud_done_outlined, tone: const Color(0xFF0A7A45)),
          AdminMetricCard(label: 'Tecnicos a revisar', value: '$revisar', icon: Icons.warning_amber, tone: const Color(0xFFF59E0B)),
          AdminMetricCard(label: 'Inconsistencias', value: '$inconsistencias', icon: Icons.rule_folder_outlined, tone: const Color(0xFFE5484D)),
        ]),
        const SizedBox(height: 14),
        AdminFilterBox(child: Row(children: [
          SizedBox(width: 170, child: InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) { setState(() => _fecha = d); _load(); } }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), isDense: true, suffixIcon: Icon(Icons.calendar_month)), child: Text(adminDate(_fecha))))),
          const SizedBox(width: 14),
          const Expanded(child: Text('Importante: el servidor no puede conocer trabajos que sigan exclusivamente en la cola local del telefono y nunca hayan intentado sincronizar. Esta pantalla no inventa ese dato.', style: TextStyle(color: Color(0xFF68737D), fontSize: 12, height: 1.35))),
        ])),
        if (state.isLoading) const LinearProgressIndicator(),
        const SizedBox(height: 14),
        AdminCard(padding: EdgeInsets.zero, child: items.isEmpty ? const AdminEmpty('No hay tecnicos para mostrar.') : Scrollbar(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7F6)),
          columns: const [DataColumn(label: Text('Tecnico')), DataColumn(label: Text('Ruta')), DataColumn(label: Text('Paradas')), DataColumn(label: Text('Recibidas')), DataColumn(label: Text('Sincronizadas')), DataColumn(label: Text('Pend. servidor')), DataColumn(label: Text('Comp. sin ejec.')), DataColumn(label: Text('Ejec. sin parada')), DataColumn(label: Text('Duplicadas')), DataColumn(label: Text('Ultima actividad')), DataColumn(label: Text('Estado'))],
          rows: items.map((x) => DataRow(cells: [
            DataCell(SizedBox(width: 170, child: Text(x.nombreTecnico, style: const TextStyle(fontWeight: FontWeight.w800)))),
            DataCell(Text('${x.rutasHoy}')), DataCell(Text('${x.paradasCompletadasHoy}/${x.paradasHoy}')), DataCell(Text('${x.ejecucionesRecibidasHoy}')), DataCell(Text('${x.ejecucionesSincronizadasHoy}')), DataCell(Text('${x.ejecucionesPendientesServidor}')), DataCell(Text('${x.paradasCompletadasSinEjecucion}')), DataCell(Text('${x.ejecucionesSinParada}')), DataCell(Text('${x.ejecucionesDuplicadas}')), DataCell(Text(adminDate(x.ultimaEjecucionRecibida, time: true))), DataCell(AdminStatusChip(x.estadoServidor)),
          ])).toList(),
        )))),
      ]),
    );
  }
}
