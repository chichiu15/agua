import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../historial/presentation/screens/historial_screen.dart';
import '../../../recorrido/presentation/controllers/solicitud_controller.dart';
import '../../../recorrido/presentation/screens/detalle_recorrido_screen.dart';
import '../../../sincronizacion/presentation/screens/sincronizacion_screen.dart';

class AsignadorDashboardScreen extends ConsumerStatefulWidget {
  const AsignadorDashboardScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<AsignadorDashboardScreen> createState() =>
      _AsignadorDashboardScreenState();
}

class _AsignadorDashboardScreenState
    extends ConsumerState<AsignadorDashboardScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 3).toInt();
    Future.microtask(
      () => ref.read(solicitudControllerProvider.notifier).cargarDatos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solicitudState = ref.watch(solicitudControllerProvider);
    final resumen = solicitudState.resumen;

    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () {
          ref.read(authControllerProvider.notifier).logout();
        },
      ),
      body: SafeArea(
        child: switch (_tabIndex) {
          1 => const MiRecorridoView(),
          2 => const HistorialView(),
          3 => const SincronizacionView(),
          _ => RefreshIndicator(
            onRefresh: () =>
                ref.read(solicitudControllerProvider.notifier).cargarDatos(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Solicitudes Por Hoy',
                  style: TextStyle(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SummaryMetricCard(
                      value: solicitudState.isLoading && resumen == null
                          ? '…'
                          : '${resumen?.odecoUrgentes ?? 0}',
                      label: 'ODECO',
                      valueColor: AppColors.odecoRed,
                    ),
                    const SizedBox(width: 10),
                    SummaryMetricCard(
                      value: solicitudState.isLoading && resumen == null
                          ? '…'
                          : '${resumen?.lecturasDelMes ?? 0}',
                      label: 'Lectura',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        solicitudState.isLoading && resumen == null
                            ? '…'
                            : '${resumen?.completadasHoy ?? 0}',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 31,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'COMPLETADAS HOY',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (solicitudState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.odecoRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.odecoRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      solicitudState.errorMessage!,
                      style: const TextStyle(color: AppColors.odecoRed),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    SummaryMetricCard(
                      value: solicitudState.isLoading
                          ? '…'
                          : '${solicitudState.tecnicos.where((t) => t.activo).length}',
                      label: 'Técnicos activos',
                      valueColor: AppColors.darkBlue,
                    ),
                    const SizedBox(width: 10),
                    SummaryMetricCard(
                      value: solicitudState.isLoading
                          ? '…'
                          : '${solicitudState.tecnicos.where((t) => t.activo && t.tieneRutaAsignada).length}',
                      label: 'En campo',
                      valueColor: AppColors.primaryGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Atajos Rápidos',
                  style: TextStyle(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                QuickActionTile(
                  icon: Icons.group_add_outlined,
                  label: 'Asignar Ruta a Trabajadores',
                  onTap: () => context.go('/asignador/recorrido/paso1'),
                ),
                const SizedBox(height: 8),
                QuickActionTile(
                  icon: Icons.people_alt_outlined,
                  label: 'Ver Asignaciones a Trabajadores',
                  onTap: () => context.go('/asignador/monitoreo'),
                ),
                const SizedBox(height: 8),
                QuickActionTile(
                  icon: Icons.route_outlined,
                  label: 'Ver Mi Recorrido de Trabajo',
                  onTap: () => setState(() => _tabIndex = 1),
                ),
              ],
            ),
          ),
        },
      ),
      bottomNavigationBar: CosaaltBottomNav(
        currentIndex: _tabIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              setState(() => _tabIndex = 0);
              return;
            case 1:
              setState(() => _tabIndex = 1);
              return;
            case 2:
              setState(() => _tabIndex = 2);
              return;
            case 3:
              setState(() => _tabIndex = 3);
              return;
          }
        },
      ),
    );
  }
}
