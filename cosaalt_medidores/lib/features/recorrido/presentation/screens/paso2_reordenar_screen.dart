import 'dart:math' as math;

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
      ref
          .read(solicitudControllerProvider.notifier)
          .solicitudesSeleccionadasOrdenadas,
    );
  }

  void _guardarOrden() {
    ref
        .read(solicitudControllerProvider.notifier)
        .guardarOrden(_puntos.map((s) => s.id).toList());
  }

  void _sugerirOrden() {
    if (_puntos.length < 2) return;

    final conCoordenadas = _puntos.where(_tieneCoordenadasValidas).toList();
    final sinCoordenadas = _puntos.where((p) => !_tieneCoordenadasValidas(p)).toList();

    if (conCoordenadas.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se necesitan coordenadas validas en al menos dos solicitudes.',
          ),
        ),
      );
      return;
    }

    // 1) Construye varias rutas con vecino mas cercano, usando cada punto
    //    como posible inicio. Asi evitamos depender del primer elemento que
    //    el usuario haya seleccionado.
    // 2) Conserva la de menor distancia total.
    // 3) Aplica 2-opt para eliminar cruces y mejorar el recorrido localmente.
    //
    // Es una heuristica local: no requiere Google Maps ni internet, funciona
    // tambien offline y sigue permitiendo ajuste manual por arrastre.
    List<Solicitud>? mejorRuta;
    var mejorDistancia = double.infinity;

    for (final inicio in conCoordenadas) {
      final candidata = _vecinoMasCercano(conCoordenadas, inicio);
      final mejorada = _mejorarConDosOpt(candidata);
      final distancia = _distanciaTotalKm(mejorada);

      if (distancia < mejorDistancia) {
        mejorDistancia = distancia;
        mejorRuta = mejorada;
      }
    }

    final sugeridos = mejorRuta ?? conCoordenadas;
    setState(() => _puntos = [...sugeridos, ...sinCoordenadas]);
    _guardarOrden();

    final km = mejorDistancia.isFinite ? mejorDistancia.toStringAsFixed(2) : '--';
    final sinGps = sinCoordenadas.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sinGps == 0
              ? 'Orden optimizado por cercania (~$km km entre puntos). Puedes ajustarlo arrastrando.'
              : 'Orden optimizado por cercania (~$km km). $sinGps punto(s) sin GPS quedaron al final para ajuste manual.',
        ),
      ),
    );
  }

  bool _tieneCoordenadasValidas(Solicitud p) {
    final lat = p.latitud;
    final lon = p.longitud;
    return lat != null &&
        lon != null &&
        lat != 0 &&
        lon != 0 &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
  }

  List<Solicitud> _vecinoMasCercano(
    List<Solicitud> puntos,
    Solicitud inicio,
  ) {
    final pendientes = List<Solicitud>.from(puntos)..remove(inicio);
    final ruta = <Solicitud>[inicio];

    while (pendientes.isNotEmpty) {
      final actual = ruta.last;
      var mejorIndice = 0;
      var mejorDistancia = double.infinity;

      for (var i = 0; i < pendientes.length; i++) {
        final distancia = _distanciaKm(actual, pendientes[i]);
        if (distancia < mejorDistancia) {
          mejorDistancia = distancia;
          mejorIndice = i;
        }
      }

      ruta.add(pendientes.removeAt(mejorIndice));
    }

    return ruta;
  }

  List<Solicitud> _mejorarConDosOpt(List<Solicitud> ruta) {
    if (ruta.length < 4) return List<Solicitud>.from(ruta);

    var mejor = List<Solicitud>.from(ruta);
    var mejoro = true;
    var pasadas = 0;

    // Limite defensivo: para las rutas normales de campo converge muy rapido
    // y evita bloquear la UI si en el futuro se seleccionan cientos de puntos.
    while (mejoro && pasadas < 20) {
      mejoro = false;
      pasadas++;

      for (var i = 0; i < mejor.length - 2; i++) {
        for (var k = i + 2; k < mejor.length - 1; k++) {
          final a = mejor[i];
          final b = mejor[i + 1];
          final c = mejor[k];
          final d = mejor[k + 1];

          final actual = _distanciaKm(a, b) + _distanciaKm(c, d);
          final alternativo = _distanciaKm(a, c) + _distanciaKm(b, d);

          if (alternativo + 0.000001 < actual) {
            final segmento = mejor.sublist(i + 1, k + 1).reversed.toList();
            mejor = [
              ...mejor.sublist(0, i + 1),
              ...segmento,
              ...mejor.sublist(k + 1),
            ];
            mejoro = true;
          }
        }
      }
    }

    return mejor;
  }

  double _distanciaTotalKm(List<Solicitud> ruta) {
    var total = 0.0;
    for (var i = 0; i < ruta.length - 1; i++) {
      total += _distanciaKm(ruta[i], ruta[i + 1]);
    }
    return total;
  }

  double _distanciaKm(Solicitud a, Solicitud b) {
    const radioTierraKm = 6371.0088;
    final lat1 = _gradosARadianes(a.latitud!);
    final lat2 = _gradosARadianes(b.latitud!);
    final dLat = lat2 - lat1;
    final dLon = _gradosARadianes(b.longitud! - a.longitud!);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return radioTierraKm * c;
  }

  double _gradosARadianes(double grados) => grados * math.pi / 180.0;

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
                    onReorderItem: (oldIndex, newIndex) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
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
  const _TipoBadge({required this.texto, required this.color});

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
