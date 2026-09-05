import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../historial/presentation/screens/historial_screen.dart';
import '../../../recorrido/presentation/controllers/detalle_recorrido_controller.dart';
import '../../../recorrido/presentation/screens/detalle_recorrido_screen.dart';
import '../../../sincronizacion/presentation/controllers/sync_controller.dart';
import '../../../sincronizacion/presentation/screens/sincronizacion_screen.dart';

class TecnicoDashboardScreen extends ConsumerStatefulWidget {
  const TecnicoDashboardScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<TecnicoDashboardScreen> createState() => _TecnicoDashboardScreenState();
}

class _TecnicoDashboardScreenState extends ConsumerState<TecnicoDashboardScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 3).toInt();
    Future.microtask(() async {
      await ref.read(detalleRecorridoControllerProvider.notifier).cargar();
      await ref.read(syncControllerProvider.notifier).cargarPendientes();
    });
  }

  Future<void> _refrescar() async {
    await ref.read(detalleRecorridoControllerProvider.notifier).cargar();
    await ref.read(syncControllerProvider.notifier).cargarPendientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      body: SafeArea(
        child: switch (_tabIndex) {
          1 => const MiRecorridoView(),
          2 => const HistorialView(),
          3 => const SincronizacionView(),
          _ => _DashboardTecnico(
              onOpenRoute: () => setState(() => _tabIndex = 1),
              onOpenSync: () => setState(() => _tabIndex = 3),
              onRefresh: _refrescar,
            ),
        },
      ),
      bottomNavigationBar: CosaaltBottomNav(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index.clamp(0, 3)),
      ),
    );
  }
}

class _DashboardTecnico extends ConsumerWidget {
  const _DashboardTecnico({
    required this.onOpenRoute,
    required this.onOpenSync,
    required this.onRefresh,
  });

  final VoidCallback onOpenRoute;
  final VoidCallback onOpenSync;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(detalleRecorridoControllerProvider);
    final syncState = ref.watch(syncControllerProvider);
    final ruta = routeState.ruta;
    final detalles = ruta?.detalles ?? const [];
    final odeco = detalles.where((d) => d.tipoOrigen.trim().toUpperCase() == 'ODECO').length;
    final lectura = detalles.where((d) => d.tipoOrigen.trim().toUpperCase() == 'LECTURA').length;
    final completadas = ruta?.completadas ?? 0;
    final pendientes = ruta?.pendientes ?? 0;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Trabajo de Hoy',
                  style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: routeState.isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh, color: AppColors.darkBlue),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ruta == null
                ? 'No hay una ruta asignada para este técnico.'
                : 'Ruta #${ruta.idAsignacion} · ${ruta.totalParadas} parada(s)',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          if (routeState.isLoading && ruta == null)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
          else ...[
            Row(
              children: [
                SummaryMetricCard(value: '$odeco', label: 'ODECO', valueColor: AppColors.odecoRed),
                const SizedBox(width: 10),
                SummaryMetricCard(value: '$lectura', label: 'Lectura'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SummaryMetricCard(value: '$completadas', label: 'Completadas', valueColor: AppColors.successGreen),
                const SizedBox(width: 10),
                SummaryMetricCard(value: '$pendientes', label: 'Pendientes', valueColor: AppColors.overdueOrange),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Avance del recorrido', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800)),
                      ),
                      Text('${((ruta?.progreso ?? 0) * 100).round()}%', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: ruta?.progreso ?? 0,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: Colors.white,
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
          ],
          if (routeState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.overdueOrange.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                routeState.errorMessage!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text('Atajos Rápidos', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          QuickActionTile(icon: Icons.route_outlined, label: 'Ver Mi Recorrido de Trabajo', onTap: onOpenRoute),
          const SizedBox(height: 8),
          QuickActionTile(
            icon: syncState.pendientes > 0 ? Icons.cloud_upload : Icons.cloud_done_outlined,
            label: syncState.pendientes > 0
                ? 'Sincronizar ${syncState.pendientes} trabajo(s) pendiente(s)'
                : 'Sincronización al día',
            onTap: onOpenSync,
          ),
          const SizedBox(height: 12),
          const Text(
            'La ruta descargada y los formularios abiertos quedan disponibles sin conexión. Los cambios se guardan localmente y se envían al servidor cuando vuelva Internet.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}
