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
    _puntos = List<Solicitud>.from(
      ref.read(solicitudControllerProvider.notifier).solicitudesSeleccionadasOrdenadas,
    );
  }

  void _guardarOrden() {
    ref.read(solicitudControllerProvider.notifier).guardarOrden(
          _puntos.map((s) => s.id).toList(),
        );
  }

  void _sugerirOrden() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La sugerencia automática de orden se implementará cuando definamos el criterio de optimización.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArmarRecorridoScaffold(
      paso: 2,
      subtitulo:
          'Paso 2: Ordena los puntos de la mejor manera para poder armar una ruta optimizada.',
      showBackButton: true,
      onBack: () {
        _guardarOrden();
        context.go('/asignador/recorrido/paso1');
      },
      primaryLabel: 'ASIGNAR RECORRIDO',
      primaryOnPressed: _puntos.isEmpty
          ? null
          : () {
              _guardarOrden();
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.actionBlue,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Arrastra las tarjetas para cambiar el orden de visita',
                                style: TextStyle(
                                  color: AppColors.actionBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _sugerirOrden,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                        label: const Text('SUGERIR ORDEN'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    itemCount: _puntos.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = _puntos.removeAt(oldIndex);
                      _puntos.insert(newIndex, item);
                      _guardarOrden();
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final solicitud = _puntos[index];
                      return _SolicitudCard(
                        key: ValueKey(solicitud.id),
                        solicitud: solicitud,
                        orden: index + 1,
                        dragIndex: index,
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
    required this.dragIndex,
    super.key,
  });

  final Solicitud solicitud;
  final int orden;
  final int dragIndex;

  Color get _tipoColor => solicitud.tipo == TipoSolicitud.odeco
      ? AppColors.odecoRed
      : AppColors.actionBlue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Container(
            width: 48,
            color: AppColors.lightBlue,
            alignment: Alignment.center,
            child: Text(
              '$orden',
              style: const TextStyle(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _TipoBadge(
                              texto: solicitud.tipoOrigen,
                              color: _tipoColor,
                            ),
                            if (solicitud.esVencida) ...[
                              const SizedBox(width: 6),
                              const _TipoBadge(
                                texto: 'VENCIDA',
                                color: AppColors.overdueOrange,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          solicitud.direccion,
                          style: const TextStyle(
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
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
                  const SizedBox(width: 8),
                  ReorderableDragStartListener(
                    index: dragIndex,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({
    required this.texto,
    required this.color,
  });

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
