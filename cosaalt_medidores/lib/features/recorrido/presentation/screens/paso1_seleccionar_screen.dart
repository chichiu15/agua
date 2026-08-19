import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/solicitud.dart';
import '../../presentation/controllers/solicitud_controller.dart';
import 'armar_recorrido_scaffold.dart';

class Paso1SeleccionarSolicitudesScreen extends ConsumerStatefulWidget {
  const Paso1SeleccionarSolicitudesScreen({super.key});

  @override
  ConsumerState<Paso1SeleccionarSolicitudesScreen> createState() =>
      _Paso1SeleccionarSolicitudesScreenState();
}

class _Paso1SeleccionarSolicitudesScreenState
    extends ConsumerState<Paso1SeleccionarSolicitudesScreen> {
  final _mapController = MapController();

  bool _filtroOdeco = true;
  bool _filtroLectura = true;
  bool _filtroAsignadas = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(solicitudControllerProvider.notifier).cargarDatos());
  }

  List<Solicitud> _filtrar(List<Solicitud> solicitudes) {
    return solicitudes.where((s) {
      if (s.tipo == TipoSolicitud.odeco && !_filtroOdeco) return false;
      if (s.tipo == TipoSolicitud.lectura && !_filtroLectura) return false;
      if (s.estado == 'Asignada' && !_filtroAsignadas) return false;
      return true;
    }).toList();
  }

  Color _colorTipo(TipoSolicitud tipo) {
    switch (tipo) {
      case TipoSolicitud.odeco:
        return AppColors.odecoRed;
      case TipoSolicitud.lectura:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitudState = ref.watch(solicitudControllerProvider);
    final controller = ref.read(solicitudControllerProvider.notifier);
    final puntosVisibles = _filtrar(solicitudState.solicitudes);

    return ArmarRecorridoScaffold(
      paso: 1,
      subtitulo:
          'Paso 1: Selecciona todas las solicitudes que irán en este recorrido.',
      primaryLabel:
          '${solicitudState.seleccionadas.length} SELECCIONADOS / ORDENAR PUNTOS DE RECORRIDO',
      primaryOnPressed: solicitudState.seleccionadas.isNotEmpty
          ? () => context.go('/asignador/recorrido/paso2')
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'ODECO',
                  icon: Icons.location_on,
                  color: AppColors.odecoRed,
                  active: _filtroOdeco,
                  onTap: () => setState(() => _filtroOdeco = !_filtroOdeco),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'LECTURA',
                  icon: Icons.location_on,
                  color: AppColors.primaryGreen,
                  active: _filtroLectura,
                  onTap: () =>
                      setState(() => _filtroLectura = !_filtroLectura),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'ASIGNADAS',
                  icon: Icons.check_circle_outline,
                  color: AppColors.textSecondary,
                  active: _filtroAsignadas,
                  onTap: () =>
                      setState(() => _filtroAsignadas = !_filtroAsignadas),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (solicitudState.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (solicitudState.errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      solicitudState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => controller.cargarDatos(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(-21.5350, -64.7260),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.cosaalt_medidores',
                  ),
                  MarkerLayer(
                    markers: puntosVisibles.map((solicitud) {
                      if (solicitud.latitud == null ||
                          solicitud.longitud == null) {
                        return Marker(
                          point: LatLng(-21.5350, -64.7260),
                          width: 0,
                          height: 0,
                          child: const SizedBox.shrink(),
                        );
                      }

                      final asignada = solicitud.estado == 'Asignada';
                      final seleccionado = solicitudState.seleccionadas
                          .contains(solicitud.id);

                      return Marker(
                        point: LatLng(
                          solicitud.latitud!,
                          solicitud.longitud!,
                        ),
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: asignada
                              ? null
                              : () => controller
                                  .toggleSeleccion(solicitud.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: asignada
                                  ? AppColors.textSecondary
                                  : seleccionado
                                      ? _colorTipo(solicitud.tipo)
                                      : _colorTipo(solicitud.tipo)
                                          .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              asignada
                                  ? Icons.check
                                  : Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active ? color : color.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? color : color.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
