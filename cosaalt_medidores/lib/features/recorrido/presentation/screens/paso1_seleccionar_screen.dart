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
  bool _soloVencidas = false;
  bool _mostrarAsignadas = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(solicitudControllerProvider.notifier).cargarDatos(),
    );
  }

  bool _estadoEs(Solicitud solicitud, String estado) =>
      solicitud.estado.trim().toLowerCase() == estado.toLowerCase();

  List<Solicitud> _filtrar(List<Solicitud> solicitudes) {
    return solicitudes.where((s) {
      if (s.tipo == TipoSolicitud.odeco && !_filtroOdeco) return false;
      if (s.tipo == TipoSolicitud.lectura && !_filtroLectura) return false;
      if (_soloVencidas && !s.esVencida) return false;

      // Las completadas ya no deben volver a formar parte de un recorrido.
      if (_estadoEs(s, 'Completada')) return false;

      // Las asignadas sólo se muestran cuando el usuario activa el filtro.
      if (_estadoEs(s, 'Asignada') && !_mostrarAsignadas) return false;

      return true;
    }).toList();
  }

  Color _colorTipo(TipoSolicitud tipo) {
    switch (tipo) {
      case TipoSolicitud.odeco:
        return AppColors.odecoRed;
      case TipoSolicitud.lectura:
        return AppColors.actionBlue;
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'ODECO',
                    icon: Icons.location_on,
                    color: AppColors.odecoRed,
                    active: _filtroOdeco,
                    onTap: () => setState(() => _filtroOdeco = !_filtroOdeco),
                  ),
                  _FilterChip(
                    label: 'LECTURA',
                    icon: Icons.location_on,
                    color: AppColors.actionBlue,
                    active: _filtroLectura,
                    onTap: () =>
                        setState(() => _filtroLectura = !_filtroLectura),
                  ),
                  _FilterChip(
                    label: 'VENCIDAS',
                    icon: Icons.schedule_rounded,
                    color: AppColors.overdueOrange,
                    active: _soloVencidas,
                    onTap: () => setState(() => _soloVencidas = !_soloVencidas),
                  ),
                  _FilterChip(
                    label: 'ASIGNADAS',
                    icon: Icons.check_circle_outline,
                    color: AppColors.textSecondary,
                    active: _mostrarAsignadas,
                    onTap: () =>
                        setState(() => _mostrarAsignadas = !_mostrarAsignadas),
                  ),
                ],
              ),
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        solicitudState.errorMessage!,
                        style: const TextStyle(color: AppColors.odecoRed),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: controller.cargarDatos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (puntosVisibles.where((s) => s.latitud != null && s.longitud != null).isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No hay solicitudes con ubicación para los filtros seleccionados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
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
                    markers: puntosVisibles
                        .where((s) => s.latitud != null && s.longitud != null)
                        .map((solicitud) {
                      final asignada = _estadoEs(solicitud, 'Asignada');
                      final asignable = _estadoEs(solicitud, 'Pendiente');
                      final seleccionado = solicitudState.seleccionadas
                          .contains(solicitud.id);
                      final colorTipo = _colorTipo(solicitud.tipo);

                      return Marker(
                        point: LatLng(
                          solicitud.latitud!,
                          solicitud.longitud!,
                        ),
                        width: 42,
                        height: 42,
                        child: Tooltip(
                          message:
                              '${solicitud.tipoOrigen} · ${solicitud.nombreCliente}\n${solicitud.direccion}${solicitud.esVencida ? '\nVENCIDA' : ''}',
                          child: GestureDetector(
                            onTap: asignable
                                ? () => controller.toggleSeleccion(solicitud.id)
                                : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: asignada
                                    ? AppColors.textSecondary
                                    : seleccionado
                                        ? colorTipo
                                        : colorTipo.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: solicitud.esVencida
                                      ? AppColors.overdueOrange
                                      : Colors.white,
                                  width: solicitud.esVencida ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                asignada
                                    ? Icons.check
                                    : solicitud.esVencida
                                        ? Icons.priority_high_rounded
                                        : Icons.location_on,
                                color: Colors.white,
                                size: 21,
                              ),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
            Icon(
              icon,
              size: 16,
              color: active ? color : color.withValues(alpha: 0.5),
            ),
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
