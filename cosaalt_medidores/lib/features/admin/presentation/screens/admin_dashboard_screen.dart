import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/admin_controller.dart';
import '../widgets/admin_shell.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminControllerProvider.notifier).cargarInicio());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final activos = state.usuarios.where((u) => u.activo).length;
    final rolesActivos = state.roles.where((r) => r.activo).length;
    final parametrosActivos = state.parametros.where((p) => p.activo).length;

    return AdminShell(
      title: 'Dashboard de Administracion',
      subtitle: 'Base administrativa R1-R5 del Modulo Medidores.',
      currentRoute: '/admin',
      actions: [
        IconButton(tooltip: 'Actualizar', onPressed: state.isLoading ? null : () => ref.read(adminControllerProvider.notifier).cargarTodo(), icon: const Icon(Icons.refresh)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminMessage(error: state.errorMessage, success: state.successMessage),
          if (state.isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14, runSpacing: 14,
            children: [
              _Metric(label: 'Usuarios registrados', value: '${state.usuarios.length}', detail: '$activos activos', icon: Icons.people_outline, color: const Color(0xFF1677FF)),
              _Metric(label: 'Roles disponibles', value: '$rolesActivos', detail: 'tecnico, asignador, admin, mecanico', icon: Icons.badge_outlined, color: const Color(0xFF7A5AF8)),
              _Metric(label: 'Motivos COSAALT', value: '${state.motivos.length}', detail: 'solo lectura desde dbo', icon: Icons.build_circle_outlined, color: const Color(0xFFF59E0B)),
              _Metric(label: 'Marcas COSAALT', value: '${state.marcas.length}', detail: 'solo lectura desde dbo', icon: Icons.speed_outlined, color: const Color(0xFF0891B2)),
              _Metric(label: 'Parametros normativos', value: '${state.parametros.length}', detail: '$parametrosActivos activos', icon: Icons.rule_outlined, color: const Color(0xFF0A7A45)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AdminCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Avance R1-R5', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    const _ProgressRow(code: 'R1', title: 'Login y router por rol', detail: 'Administrador y mecanico reconocidos por Flutter.', done: true),
                    const _ProgressRow(code: 'R2', title: 'Gestion de usuarios', detail: 'Listado, alta, edicion y activar/inactivar.', done: true),
                    const _ProgressRow(code: 'R3', title: 'Motivos de cambio', detail: 'Consulta oficial de dbo.MotivosCambioMedidor.', done: true),
                    const _ProgressRow(code: 'R4', title: 'Marcas de medidor', detail: 'Consulta oficial de dbo.Marcas.', done: true),
                    const _ProgressRow(code: 'R5', title: 'Parametros normativos', detail: 'CRUD y consulta vigente para M12 del mecanico.', done: true),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AdminCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Accesos rapidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _Quick(icon: Icons.person_add_alt_1, title: 'Gestionar usuarios', subtitle: 'Crear y editar accesos', onTap: () => context.go('/admin/usuarios')),
                    _Quick(icon: Icons.inventory_2_outlined, title: 'Consultar catalogos', subtitle: 'Motivos y marcas oficiales', onTap: () => context.go('/admin/catalogos')),
                    _Quick(icon: Icons.rule_outlined, title: 'Parametros normativos', subtitle: 'Configurar tolerancias del laboratorio', onTap: () => context.go('/admin/parametros')),
                    const Divider(height: 26),
                    const Text('Las pantallas de solicitudes, recorridos, verificaciones y reportes corresponden a R6-R14 y se incorporaran en la siguiente fase.', style: TextStyle(color: Color(0xFF68737D), height: 1.45)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.detail, required this.icon, required this.color});
  final String label, value, detail; final IconData icon; final Color color;
  @override Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: AdminCard(child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF68737D), fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey))])),
    ])),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.code, required this.title, required this.detail, required this.done});
  final String code, title, detail; final bool done;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(width: 42, padding: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: const Color(0xFFE9F4EE), borderRadius: BorderRadius.circular(8)), child: Text(code, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF006B3F), fontWeight: FontWeight.w900))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(detail, style: const TextStyle(color: Color(0xFF68737D), fontSize: 12))])),
      Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? const Color(0xFF0A7A45) : Colors.grey),
    ]),
  );
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  @override Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: const Color(0xFFE9F4EE), child: Icon(icon, color: const Color(0xFF006B3F))),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap,
  );
}
