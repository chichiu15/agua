import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/admin_supervision_controller.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ui.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminSupervisionControllerProvider.notifier).cargarDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupervisionControllerProvider);
    final d = state.dashboard;
    return AdminShell(
      title: 'Dashboard Principal y Monitoreo',
      subtitle: 'Resumen operativo del cambio de medidores y verificaciones mecanicas.',
      currentRoute: '/admin',
      actions: [IconButton(tooltip: 'Actualizar', onPressed: state.isLoading ? null : () => ref.read(adminSupervisionControllerProvider.notifier).cargarDashboard(), icon: const Icon(Icons.refresh))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AdminMessage(error: state.errorMessage, success: state.successMessage),
        if (state.isLoading) const LinearProgressIndicator(),
        if (d == null && !state.isLoading) const AdminEmpty('No se pudo cargar el resumen operativo.')
        else if (d != null) ...[
          Wrap(spacing: 12, runSpacing: 12, children: [
            AdminMetricCard(label: 'Solicitudes pendientes', value: '${d.solicitudesPendientes}', detail: '${d.odecoPendientes} ODECO / ${d.lecturaPendientes} Lectura', icon: Icons.assignment_outlined, tone: const Color(0xFFF59E0B)),
            AdminMetricCard(label: 'ODECO urgentes', value: '${d.odecoUrgentes}', detail: '${d.odecoVencidas} vencidas', icon: Icons.timer_outlined, tone: const Color(0xFFE5484D)),
            AdminMetricCard(label: 'Rutas activas hoy', value: '${d.rutasActivasHoy}', detail: '${d.tecnicosConRutaHoy} tecnicos con ruta', icon: Icons.route_outlined, tone: const Color(0xFF0A7A45)),
            AdminMetricCard(label: 'Cambios ejecutados hoy', value: '${d.cambiosEjecutadosHoy}', detail: '${d.cambiosSincronizadosHoy} sincronizados', icon: Icons.swap_horiz, tone: const Color(0xFF7A5AF8)),
            AdminMetricCard(label: 'Verificaciones pendientes', value: '${d.verificacionesPendientes}', detail: '${d.verificacionesEnCurso} en curso', icon: Icons.build_outlined, tone: const Color(0xFFEA7C14)),
            AdminMetricCard(label: 'Verificaciones completadas', value: '${d.verificacionesCompletadas}', detail: '${d.verificacionesCumple} cumple / ${d.verificacionesNoCumple} no cumple', icon: Icons.fact_check_outlined, tone: const Color(0xFF1677FF)),
          ]),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 900;
            final left = Column(children: [
              AdminBarList(title: 'Solicitudes por estado', items: d.solicitudesPorEstado.map((x) => (x.categoria, x.cantidad)).toList()),
              const SizedBox(height: 14),
              AdminBarList(title: 'Motivos de cambio mas frecuentes', items: d.motivosCambioFrecuentes.map((x) => (x.categoria, x.cantidad)).toList()),
            ]);
            final alerts = AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Expanded(child: Text('Alertas de prioridad', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), TextButton(onPressed: () => context.go('/admin/solicitudes'), child: const Text('Ver solicitudes'))]),
              const Divider(),
              if (d.alertas.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('Sin alertas detectadas por el servidor.', style: TextStyle(color: Color(0xFF68737D))))
              else ...d.alertas.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: a.nivel == 'Critica' ? const Color(0xFFFFEEEE) : const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(9), border: Border.all(color: a.nivel == 'Critica' ? const Color(0xFFFFC7C2) : const Color(0xFFFFD79A))),
                child: Row(children: [Icon(a.nivel == 'Critica' ? Icons.error_outline : Icons.warning_amber, color: a.nivel == 'Critica' ? Colors.red : Colors.orange), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w800)), Text(a.detalle, style: const TextStyle(fontSize: 11, color: Color(0xFF68737D)))])), Text('${a.cantidad}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))]),
              )),
            ]));
            if (narrow) return Column(children: [left, const SizedBox(height: 14), alerts]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: left), const SizedBox(width: 14), Expanded(flex: 2, child: alerts)]);
          }),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 1000;
            final tech = AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Expanded(child: Text('Tecnicos en campo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), TextButton(onPressed: () => context.go('/admin/recorridos'), child: const Text('Ver recorridos'))]),
              const Divider(),
              if (d.tecnicos.isEmpty) const AdminEmpty('Sin tecnicos registrados.')
              else ...d.tecnicos.map((t) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
                CircleAvatar(radius: 16, backgroundColor: const Color(0xFFE9F4EE), child: Text(t.nombre.isEmpty ? '?' : t.nombre[0], style: const TextStyle(color: Color(0xFF006B3F), fontWeight: FontWeight.w900))),
                const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), Text('${t.paradasCompletadasHoy}/${t.paradasHoy} paradas - ultima actividad ${adminDate(t.ultimaEjecucionRecibida, time: true)}', style: const TextStyle(fontSize: 10, color: Color(0xFF68737D)))])),
                SizedBox(width: 95, child: LinearProgressIndicator(value: t.avancePorcentaje.clamp(0, 100) / 100, minHeight: 8, borderRadius: BorderRadius.circular(8))), const SizedBox(width: 8), AdminStatusChip(t.estadoOperacion),
              ]))),
            ]));
            final activity = AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Actividad reciente', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const Divider(),
              if (d.actividadReciente.isEmpty) const AdminEmpty('Sin actividad reciente.')
              else ...d.actividadReciente.map((a) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: CircleAvatar(radius: 16, backgroundColor: const Color(0xFFEEF4FF), child: Icon(a.tipo == 'CAMBIO' ? Icons.swap_horiz : Icons.build_outlined, size: 17, color: const Color(0xFF1677FF))), title: Text(a.titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), subtitle: Text('${a.detalle}\n${adminDate(a.fecha, time: true)}', style: const TextStyle(fontSize: 10)), trailing: a.estado == null ? null : AdminStatusChip(a.estado!))),
            ]));
            if (narrow) return Column(children: [tech, const SizedBox(height: 14), activity]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: tech), const SizedBox(width: 14), Expanded(flex: 2, child: activity)]);
          }),
        ],
      ]),
    );
  }
}
