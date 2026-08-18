import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/punto_recorrido.dart';
import 'armar_recorrido_scaffold.dart';

class Paso1SeleccionarSolicitudesScreen extends StatefulWidget {
  const Paso1SeleccionarSolicitudesScreen({super.key});

  @override
  State<Paso1SeleccionarSolicitudesScreen> createState() =>
      _Paso1SeleccionarSolicitudesScreenState();
}

class _Paso1SeleccionarSolicitudesScreenState
    extends State<Paso1SeleccionarSolicitudesScreen> {
  final _mapController = MapController();

  bool _filtroOdeco = true;
  bool _filtroLectura = true;
  bool _filtroVencidos = false;

  final _puntos = const [
    PuntoRecorrido(
      id: 1,
      direccion: 'Av. Las Américas #452, Zona Sur',
      propietario: 'María Elena Vargas',
      numeroMedidor: 'M-789012',
      ubicacion: LatLng(-21.5445, -64.7285),
      tipo: TipoSolicitud.odeco,
    ),
    PuntoRecorrido(
      id: 2,
      direccion: 'Calle Junín #890, Centro',
      propietario: 'Carlos Mendoza Ríos',
      numeroMedidor: 'M-456789',
      ubicacion: LatLng(-21.5310, -64.7295),
      tipo: TipoSolicitud.lectura,
    ),
    PuntoRecorrido(
      id: 3,
      direccion: 'Pasaje Los Olivos #23, Zona Norte',
      propietario: 'Ana Lucía Fernández',
      numeroMedidor: 'M-123456',
      ubicacion: LatLng(-21.5185, -64.7340),
      tipo: TipoSolicitud.lectura,
    ),
    PuntoRecorrido(
      id: 4,
      direccion: 'Parque Industrial Mz. 3 Lote 12',
      propietario: 'Industrias del Altiplano S.A.',
      numeroMedidor: 'M-998877',
      ubicacion: LatLng(-21.5510, -64.7120),
      tipo: TipoSolicitud.vencido,
    ),
  ];

  final _seleccionados = <int>{1, 2, 3};

  List<PuntoRecorrido> get _puntosFiltrados {
    return _puntos.where((p) {
      if (p.tipo == TipoSolicitud.odeco && !_filtroOdeco) return false;
      if (p.tipo == TipoSolicitud.lectura && !_filtroLectura) return false;
      if (p.tipo == TipoSolicitud.vencido && !_filtroVencidos) return false;
      return true;
    }).toList();
  }

  Color _colorTipo(TipoSolicitud tipo) {
    switch (tipo) {
      case TipoSolicitud.odeco:
        return AppColors.odecoRed;
      case TipoSolicitud.lectura:
        return AppColors.primaryGreen;
      case TipoSolicitud.vencido:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final puntosVisibles = _puntosFiltrados;

    return ArmarRecorridoScaffold(
      paso: 1,
      subtitulo:
          'Paso 1: Selecciona todas las solicitudes que irán en este recorrido.',
      primaryLabel:
          '${_seleccionados.length} SELECCIONADOS / ORDENAR PUNTOS DE RECORRIDO',
      primaryOnPressed: _seleccionados.isNotEmpty
          ? () {
              context.go('/asignador/recorrido/paso2');
            }
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
                  label: 'VENCIDOS',
                  icon: Icons.location_on,
                  color: AppColors.textSecondary,
                  active: _filtroVencidos,
                  onTap: () =>
                      setState(() => _filtroVencidos = !_filtroVencidos),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                  markers: puntosVisibles.map((punto) {
                    final seleccionado =
                        _seleccionados.contains(punto.id);
                    return Marker(
                      point: punto.ubicacion,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (seleccionado) {
                              _seleccionados.remove(punto.id);
                            } else {
                              _seleccionados.add(punto.id);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? _colorTipo(punto.tipo)
                                : _colorTipo(punto.tipo).withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: seleccionado
                                ? Colors.white
                                : _colorTipo(punto.tipo),
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
            Icon(icon, size: 16, color: active ? color : color.withValues(alpha: 0.5)),
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
