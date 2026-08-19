import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/solicitud.dart';
import '../../presentation/controllers/solicitud_controller.dart';
import 'armar_recorrido_scaffold.dart';

class Paso2ReordenarScreen extends ConsumerStatefulWidget {
  const Paso2ReordenarScreen({super.key});

  @override
  ConsumerState<Paso2ReordenarScreen> createState() =>
      _Paso2ReordenarScreenState();
}

class _Paso2ReordenarScreenState extends ConsumerState<Paso2ReordenarScreen> {
  late List<Solicitud> _puntos;

  @override
  void initState() {
    super.initState();
    final state = ref.read(solicitudControllerProvider);
    _puntos = state.solicitudes
        .where((s) => state.seleccionadas.contains(s.id))
        .toList();
  }

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
      body: _puntos.isEmpty
          ? const Center(
              child: Text(
                'No hay solicitudes seleccionadas.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.actionBlue),
                      SizedBox(width: 6),
                      Text(
                        'Mantén presionado y arrastra para reordenar',
                        style: TextStyle(
                          color: AppColors.actionBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _puntos.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = _puntos.removeAt(oldIndex);
                      _puntos.insert(newIndex, item);
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final solicitud = _puntos[index];
                      return _SolicitudCard(
                        key: ValueKey(solicitud.id),
                        solicitud: solicitud,
                        orden: index + 1,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  const _SolicitudCard({
    required this.solicitud,
    required this.orden,
    super.key,
  });

  final Solicitud solicitud;
  final int orden;

  Color get _colorTipo =>
      solicitud.tipo == TipoSolicitud.odeco
          ? AppColors.odecoRed
          : AppColors.primaryGreen;

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
              color: _colorTipo,
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
                  solicitud.direccion,
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${solicitud.nombreCliente} - ${solicitud.numeroMedidor ?? "S/N"}',
                  style: const TextStyle(
                    color: AppColors.actionBlue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
