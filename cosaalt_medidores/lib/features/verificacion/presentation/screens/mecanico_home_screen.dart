import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/verificacion_controller.dart';
import 'bandeja_solicitudes_screen.dart';
import 'historial_screen.dart';
import 'informes_mecanico_screen.dart';
import 'verificaciones_en_curso_screen.dart';

class MecanicoHomeScreen extends ConsumerStatefulWidget {
  const MecanicoHomeScreen({
    this.initialTab = 0,
    super.key,
  });

  final int initialTab;

  @override
  ConsumerState<MecanicoHomeScreen> createState() =>
      _MecanicoHomeScreenState();
}

class _MecanicoHomeScreenState extends ConsumerState<MecanicoHomeScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();

    _tabIndex = widget.initialTab.clamp(0, 2).toInt();

    Future.microtask(() async {
      await ref
          .read(verificacionControllerProvider.notifier)
          .cargarDashboard();
    });
  }

  Future<void> _refrescar() async {
    final notifier =
        ref.read(verificacionControllerProvider.notifier);

    await notifier.cargarDashboard();
  }

  @override
  void didUpdateWidget(
    covariant MecanicoHomeScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    _tabIndex = widget.initialTab.clamp(0, 2).toInt();

    if (_tabIndex == 0 &&
        oldWidget.initialTab != widget.initialTab) {
      Future.microtask(_refrescar);
    }
  }

  Future<void> _abrirEnCurso() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            const VerificacionesEnCursoScreen(),
      ),
    );

    if (mounted) {
      await _refrescar();
    }
  }

  Future<void> _abrirInformes() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            const InformesMecanicoScreen(),
      ),
    );

    if (mounted) {
      await _refrescar();
    }
  }

  void _irATab(int tab) {
    context.go(
      '${AppRoutes.mecanicoHome}?tab=$tab',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () {
          ref
              .read(authControllerProvider.notifier)
              .logout();
        },
      ),
      body: SafeArea(
        child: switch (_tabIndex) {
          1 => const BandejaSolicitudesScreen(),
          2 => const HistorialScreen(),
          _ => _DashboardMecanico(
              onRefresh: _refrescar,
              onOpenBandeja: () => _irATab(1),
              onOpenEnCurso: _abrirEnCurso,
              onOpenInformes: _abrirInformes,
              onOpenHistorial: () => _irATab(2),
            ),
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: _irATab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.darkBlue,
        backgroundColor: Colors.white,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

class _DashboardMecanico extends ConsumerWidget {
  const _DashboardMecanico({
    required this.onRefresh,
    required this.onOpenBandeja,
    required this.onOpenEnCurso,
    required this.onOpenInformes,
    required this.onOpenHistorial,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback onOpenBandeja;
  final VoidCallback onOpenEnCurso;
  final VoidCallback onOpenInformes;
  final VoidCallback onOpenHistorial;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final state =
        ref.watch(verificacionControllerProvider);

    final dashboard = state.dashboard;

    final nombreMecanico =
        ref.watch(authControllerProvider).user?.fullName;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verificaciones',
                      style: TextStyle(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    if (nombreMecanico != null &&
                        nombreMecanico.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Mecánico: $nombreMecanico',
                        style: const TextStyle(
                          color:
                              AppColors.primaryGreen,
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed:
                    state.isLoading ? null : onRefresh,
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.darkBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'Resumen de verificaciones mecánicas',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          if (state.errorMessage != null)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 12),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),

          if (state.isLoading && dashboard == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child:
                    CircularProgressIndicator(),
              ),
            )
          else ...[
            Row(
              children: [
                SummaryMetricCard(
                  value:
                      '${dashboard?.enCurso ?? 0}',
                  label: 'En curso',
                  valueColor:
                      AppColors.actionBlue,
                ),
                const SizedBox(width: 10),
                SummaryMetricCard(
                  value:
                      '${dashboard?.pendientes ?? 0}',
                  label:
                      'Solicitudes\npendientes',
                  valueColor:
                      AppColors.overdueOrange,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                SummaryMetricCard(
                  value:
                      '${dashboard?.completadas ?? 0}',
                  label: 'Completadas',
                  valueColor:
                      AppColors.successGreen,
                ),
                const SizedBox(width: 10),
                SummaryMetricCard(
                  value:
                      '${dashboard?.total ?? 0}',
                  label: 'Total',
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text(
              'Resultados',
              style: TextStyle(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                SummaryMetricCard(
                  value:
                      '${dashboard?.cumple ?? 0}',
                  label: 'Cumple',
                  valueColor:
                      AppColors.successGreen,
                ),
                const SizedBox(width: 10),
                SummaryMetricCard(
                  value:
                      '${dashboard?.noCumple ?? 0}',
                  label: 'No cumple',
                  valueColor:
                      AppColors.odecoRed,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                SummaryMetricCard(
                  value:
                      '${dashboard?.indeterminados ?? 0}',
                  label: 'Indeterminados',
                  valueColor:
                      AppColors.warningYellow,
                ),
                const SizedBox(width: 10),

                /*
                 * Se conserva una segunda tarjeta vacía
                 * para mantener el mismo ancho y diseño
                 * del dashboard.
                 */
                const SummaryMetricCard(
                  value: '-',
                  label: '',
                  valueColor:
                      AppColors.lightBlue,
                ),
              ],
            ),

            const SizedBox(height: 22),

            QuickActionTile(
              icon:
                  Icons.add_circle_outline,
              label: 'Nueva verificación',
              onTap: onOpenBandeja,
            ),

            const SizedBox(height: 10),

            QuickActionTile(
              icon: Icons
                  .assignment_turned_in_outlined,
              label:
                  'Verificaciones en curso',
              onTap: onOpenEnCurso,
            ),

            const SizedBox(height: 10),

            QuickActionTile(
              icon:
                  Icons.description_outlined,
              label:
                  'Informes de verificación',
              onTap: onOpenInformes,
            ),

            const SizedBox(height: 10),

            QuickActionTile(
              icon: Icons.history,
              label:
                  'Historial de verificaciones',
              onTap: onOpenHistorial,
            ),
          ],
        ],
      ),
    );
  }
}