import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../recorrido/domain/entities/ruta_asignada.dart';
import '../../../recorrido/presentation/controllers/solicitud_controller.dart';

class DetalleMonitoreoRutaScreen extends ConsumerWidget {
  const DetalleMonitoreoRutaScreen({
    required this.idAsignacion,
    super.key,
  });

  final int idAsignacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(solicitudRepositoryProvider);

    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      body: FutureBuilder<RutaAsignada>(
        future: repository.obtenerRutaPorId(idAsignacion),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error?.toString() ?? 'No se pudo cargar la ruta.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.odecoRed),
                ),
              ),
            );
          }

          final ruta = snapshot.data!;
          final porcentaje = (ruta.progreso * 100).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/asignador/monitoreo'),
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.darkBlue,
                  ),
                  Expanded(
                    child: Text(
                      'RUTA #${ruta.idAsignacion}',
                      style: const TextStyle(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  ruta.nombreTecnico,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '$porcentaje%',
                          style: const TextStyle(
                            color: AppColors.darkBlue,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${ruta.completadas} de ${ruta.totalParadas} visitas completadas',
                            style: const TextStyle(
                              color: AppColors.darkBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ruta.progreso,
                        minHeight: 10,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ruta.progreso == 1
                              ? AppColors.successGreen
                              : AppColors.actionBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'PUNTOS DEL RECORRIDO',
                style: TextStyle(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              ...ruta.detalles.map((detalle) => _DetalleCard(detalle: detalle)),
            ],
          );
        },
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

class _DetalleCard extends StatelessWidget {
  const _DetalleCard({required this.detalle});
  final DetalleRutaAsignada detalle;

  @override
  Widget build(BuildContext context) {
    final completada = detalle.completada;
    final tipoColor = detalle.tipoOrigen.toUpperCase() == 'ODECO'
        ? AppColors.odecoRed
        : AppColors.actionBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: completada
            ? AppColors.successGreen.withValues(alpha: .06)
            : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: completada
              ? AppColors.successGreen.withValues(alpha: .35)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completada ? AppColors.successGreen : AppColors.lightBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: completada
                ? const Icon(Icons.check, color: Colors.white)
                : Text(
                    '${detalle.ordenVisita}',
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: tipoColor.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        detalle.tipoOrigen,
                        style: TextStyle(
                          color: tipoColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      completada ? 'COMPLETADA' : detalle.estado.toUpperCase(),
                      style: TextStyle(
                        color: completada
                            ? AppColors.successGreen
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  detalle.direccion,
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detalle.nombreCliente,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detalle.solicitudId,
                  style: const TextStyle(
                    color: AppColors.actionBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
