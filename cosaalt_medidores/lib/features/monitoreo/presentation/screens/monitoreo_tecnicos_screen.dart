import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../recorrido/domain/entities/ruta_asignada.dart';
import '../controllers/monitoreo_controller.dart';

class MonitoreoTecnicosScreen extends ConsumerStatefulWidget {
  const MonitoreoTecnicosScreen({super.key});

  @override
  ConsumerState<MonitoreoTecnicosScreen> createState() =>
      _MonitoreoTecnicosScreenState();
}

class _MonitoreoTecnicosScreenState
    extends ConsumerState<MonitoreoTecnicosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(monitoreoControllerProvider.notifier).cargar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monitoreoControllerProvider);

    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(monitoreoControllerProvider.notifier).cargar(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/asignador'),
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.darkBlue,
                  ),
                  const Expanded(
                    child: Text(
                      'MONITOREO DE ASIGNACIONES',
                      style: TextStyle(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 48, bottom: 16),
                child: Text(
                  'Avance de las rutas asignadas a técnicos o al asignador para hoy.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              if (state.isLoading && state.rutas.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null && state.rutas.isEmpty)
                _ErrorCard(
                  message: state.errorMessage!,
                  onRetry: () =>
                      ref.read(monitoreoControllerProvider.notifier).cargar(),
                )
              else if (state.rutas.isEmpty)
                const _EmptyCard()
              else
                ...state.rutas.map((ruta) => _RutaCard(ruta: ruta)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CosaaltBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) context.go('/asignador');
          if (index == 1) context.go('/asignador/recorrido/paso1');
        },
      ),
    );
  }
}

class _RutaCard extends StatelessWidget {
  const _RutaCard({required this.ruta});

  final RutaAsignada ruta;

  Color get estadoColor {
    switch (ruta.estado.toLowerCase()) {
      case 'finalizado':
        return AppColors.successGreen;
      case 'encurso':
        return AppColors.actionBlue;
      default:
        return AppColors.darkBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = (ruta.progreso * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(
          '/asignador/monitoreo/ruta/${ruta.idAsignacion}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.lightBlue,
                    child: Icon(Icons.engineering_outlined, color: AppColors.darkBlue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ruta.nombreTecnico,
                          style: const TextStyle(
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Ruta #${ruta.idAsignacion}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ruta.estado.toUpperCase(),
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ruta.progreso,
                        minHeight: 10,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ruta.progreso == 1
                              ? AppColors.successGreen
                              : AppColors.actionBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$porcentaje%',
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${ruta.completadas} de ${ruta.totalParadas} completadas',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '${ruta.pendientes} pendientes',
                    style: TextStyle(
                      color: ruta.pendientes == 0
                          ? AppColors.successGreen
                          : AppColors.odecoRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'VER DETALLE  ›',
                  style: TextStyle(
                    color: AppColors.actionBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.route_outlined, size: 52, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No hay rutas asignadas para hoy.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
