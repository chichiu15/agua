import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/ruta_asignada.dart';
import '../controllers/detalle_recorrido_controller.dart';

class DetalleRecorridoScreen extends ConsumerWidget {
  const DetalleRecorridoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      body: const SafeArea(child: MiRecorridoView()),
    );
  }
}

class MiRecorridoView extends ConsumerStatefulWidget {
  const MiRecorridoView({super.key});

  @override
  ConsumerState<MiRecorridoView> createState() => _MiRecorridoViewState();
}

class _MiRecorridoViewState extends ConsumerState<MiRecorridoView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(detalleRecorridoControllerProvider.notifier).cargar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(detalleRecorridoControllerProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(detalleRecorridoControllerProvider.notifier).cargar(),
      child: _Contenido(state: state),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.state});

  final DetalleRecorridoState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.ruta == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.ruta == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              state.errorMessage!,
              style: const TextStyle(color: AppColors.odecoRed),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                ref.read(detalleRecorridoControllerProvider.notifier).cargar(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    final ruta = state.ruta;
    if (ruta == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.route_outlined, size: 64, color: AppColors.darkBlue),
          SizedBox(height: 12),
          Text(
            'Todavía no tenés una ruta asignada para hoy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _EncabezadoRuta(ruta: ruta),
        const SizedBox(height: 16),
        const Text(
          'Paradas del recorrido',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        for (final parada in ruta.detalles) ...[
          _TarjetaParada(parada: parada),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EncabezadoRuta extends StatelessWidget {
  const _EncabezadoRuta({required this.ruta});

  final RutaAsignada ruta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'N° DE RUTA DE ASIGNACIÓN',
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#${ruta.idAsignacion}',
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ruta.estado == 'Finalizado'
                      ? AppColors.primaryGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ruta.pendientes == 0 ? 'Finalizada' : ruta.estado,
                  style: TextStyle(
                    color: ruta.estado == 'Finalizado'
                        ? Colors.white
                        : AppColors.darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Asignada a: ${ruta.nombreTecnico}',
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ruta.completadas} de ${ruta.totalParadas} paradas completadas',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ruta.progreso,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaParada extends StatelessWidget {
  const _TarjetaParada({required this.parada});

  final DetalleRutaAsignada parada;

  Future<void> _abrirNavegacion(BuildContext context) async {
    final destino = parada.latitud != null && parada.longitud != null
        ? '${parada.latitud},${parada.longitud}'
        : parada.direccion.trim();
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {'api': '1', 'destination': destino},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la aplicación de navegación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esUrgente = parada.esUrgente;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: parada.completada
                  ? AppColors.primaryGreen
                  : AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${parada.ordenVisita}',
              style: TextStyle(
                color: parada.completada ? Colors.white : AppColors.darkBlue,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        parada.nombreCliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (esUrgente) ...[
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.odecoRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ODECO',
                          style: TextStyle(
                            color: AppColors.odecoRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  parada.direccion,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.speed_outlined,
                      size: 15,
                      color: AppColors.darkBlue,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        parada.numeroMedidor ?? 'Sin medidor registrado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: parada.numeroMedidor == null
                              ? AppColors.textSecondary
                              : AppColors.darkBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (parada.codCon != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        'N° ${parada.codCon}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (parada.completadaServidor)
            const Column(
              children: [
                Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 26),
                SizedBox(height: 2),
                Text(
                  'Completada',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else if (parada.pendienteSincronizacion)
            Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: AppColors.overdueOrange, size: 25),
                const SizedBox(height: 2),
                const Text(
                  'Pendiente sync',
                  style: TextStyle(
                    color: AppColors.overdueOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => context.go('/trabajo/cambio/${parada.solicitudId}'),
                  child: const Text('REVISAR'),
                ),
              ],
            )
          else
            Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _abrirNavegacion(context),
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text('CÓMO LLEGAR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: () => context.go('/trabajo/cambio/${parada.solicitudId}'),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('EJECUTAR'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
