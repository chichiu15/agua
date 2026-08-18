import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/punto_recorrido.dart';
import 'armar_recorrido_scaffold.dart';

class Paso2ReordenarScreen extends StatefulWidget {
  const Paso2ReordenarScreen({super.key});

  @override
  State<Paso2ReordenarScreen> createState() => _Paso2ReordenarScreenState();
}

class _Paso2ReordenarScreenState extends State<Paso2ReordenarScreen> {
  final _puntos = [
    PuntoRecorrido(
      id: 1,
      direccion: 'Av. Las Américas #452, Zona Sur',
      propietario: 'María Elena Vargas',
      numeroMedidor: 'M-789012',
      ubicacion: const LatLng(0, 0),
      tipo: TipoSolicitud.odeco,
    ),
    PuntoRecorrido(
      id: 2,
      direccion: 'Calle Junín #890, Centro',
      propietario: 'Carlos Mendoza Ríos',
      numeroMedidor: 'M-456789',
      ubicacion: const LatLng(0, 0),
      tipo: TipoSolicitud.lectura,
    ),
    PuntoRecorrido(
      id: 3,
      direccion: 'Pasaje Los Olivos #23, Zona Norte',
      propietario: 'Ana Lucía Fernández',
      numeroMedidor: 'M-123456',
      ubicacion: const LatLng(0, 0),
      tipo: TipoSolicitud.lectura,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ArmarRecorridoScaffold(
      paso: 2,
      subtitulo:
          'Paso 2: Ordena los puntos de la mejor manera para poder armar una ruta optimizada.',
      showBackButton: true,
      onBack: () => context.go('/asignador/recorrido/paso1'),
      primaryLabel: 'SUGERIR ORDEN Y / ASIGNAR RECORRIDO',
      primaryOnPressed: () {
        context.go('/asignador/recorrido/paso3');
      },
      body: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _puntos.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _puntos.removeAt(oldIndex);
            _puntos.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final punto = _puntos[index];
          return _PuntoCard(
            key: ValueKey(punto.id),
            punto: punto,
            orden: index + 1,
          );
        },
      ),
    );
  }
}

class _PuntoCard extends StatelessWidget {
  const _PuntoCard({
    required this.punto,
    required this.orden,
    super.key,
  });

  final PuntoRecorrido punto;
  final int orden;

  Color get _colorOrden => AppColors.actionBlue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _colorOrden,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$orden',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  punto.direccion,
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${punto.propietario} - ${punto.numeroMedidor}',
                  style: const TextStyle(
                    color: AppColors.actionBlue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.drag_indicator,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}
