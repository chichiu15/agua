import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/verificacion_ui.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  static const int _pageSize = 20;

  DateTime? _desde;
  DateTime? _hasta;
  String? _estado;
  String? _resultado;

  final _buscarCtrl = TextEditingController();
  Timer? _buscarDebounce;

  int _page = 1;

  bool get _tieneFiltros =>
      _desde != null ||
      _hasta != null ||
      _estado != null ||
      _resultado != null ||
      _buscarCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargar);
  }

  @override
  void dispose() {
    _buscarDebounce?.cancel();
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    await ref
        .read(verificacionControllerProvider.notifier)
        .cargarHistorial(
          desde: _desde,
          hasta: _hasta,
          estado: _estado,
          resultado: _resultado,
          buscar: _buscarCtrl.text,
          page: _page,
          pageSize: _pageSize,
        );
  }

  void _reload() {
    _page = 1;
    _cargar();
  }

  Future<void> _pickFecha(bool esDesde) async {
    final inicial = esDesde ? _desde : _hasta;

    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (fecha == null || !mounted) {
      return;
    }

    setState(() {
      if (esDesde) {
        _desde = fecha;

        if (_hasta != null && fecha.isAfter(_hasta!)) {
          _hasta = fecha;
        }
      } else {
        _hasta = fecha;

        if (_desde != null && fecha.isBefore(_desde!)) {
          _desde = fecha;
        }
      }
    });

    _reload();
  }

  void _limpiarFiltros() {
    _buscarDebounce?.cancel();

    setState(() {
      _desde = null;
      _hasta = null;
      _estado = null;
      _resultado = null;
      _page = 1;
      _buscarCtrl.clear();
    });

    _cargar();
  }

  void _onBuscar(String _) {
    setState(() {});

    _buscarDebounce?.cancel();
    _buscarDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        if (!mounted) {
          return;
        }

        _page = 1;
        _cargar();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(verificacionControllerProvider);

    final historial =
        state.historial;

    final items =
        historial?.items ??
        const <HistorialVerificacionItem>[];

    final total =
        historial?.total ?? 0;

    final totalPages = total == 0
        ? 1
        : (total + _pageSize - 1) ~/ _pageSize;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de Verificaciones',
                      style: TextStyle(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulte verificaciones en curso y completadas, sus resultados y el último informe emitido.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed:
                    state.isLoading ? null : _cargar,
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.darkBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          VerMessageBar(
            error: state.errorMessage,
            success: state.successMessage,
          ),

          _buildFiltros(),

          const SizedBox(height: 12),

          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(),
            ),

          if (state.isLoading && items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (items.isEmpty)
            const VerEmpty(
              'No hay verificaciones que coincidan con los filtros.',
            )
          else ...[
            _buildResumenPaginacion(
              total: total,
              totalPages: totalPages,
            ),

            const SizedBox(height: 6),

            ...items.map(
              (item) => _HistorialCard(
                item: item,
              ),
            ),

            if (totalPages > 1) ...[
              const SizedBox(height: 4),
              _buildPaginacionInferior(
                totalPages,
              ),
            ],
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFD9E2E7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      _tieneFiltros ? _limpiarFiltros : null,
                  icon: const Icon(
                    Icons.filter_alt_off_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Limpiar',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            TextField(
              controller: _buscarCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText:
                    'Buscar socio, RegSoc, conexión, serie o informe',
                hintText:
                    'Ej. CASTRO, 12558, 682733...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    _buscarCtrl.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _buscarDebounce?.cancel();
                              _buscarCtrl.clear();
                              setState(() {});
                              _reload();
                            },
                            icon: const Icon(
                              Icons.close,
                            ),
                          ),
                isDense: true,
              ),
              onChanged: _onBuscar,
            ),

            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 680;

                final ancho = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: ancho,
                      child: _DateFilterButton(
                        label: 'Desde',
                        value: _desde,
                        onTap: () => _pickFecha(true),
                        onClear: _desde == null
                            ? null
                            : () {
                                setState(() {
                                  _desde = null;
                                });
                                _reload();
                              },
                      ),
                    ),
                    SizedBox(
                      width: ancho,
                      child: _DateFilterButton(
                        label: 'Hasta',
                        value: _hasta,
                        onTap: () => _pickFecha(false),
                        onClear: _hasta == null
                            ? null
                            : () {
                                setState(() {
                                  _hasta = null;
                                });
                                _reload();
                              },
                      ),
                    ),
                    SizedBox(
                      width: ancho,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey(
                          'estado-${_estado ?? 'todos'}',
                        ),
                        initialValue: _estado,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText:
                              'Estado de verificación',
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'EnCurso',
                            child: Text('En curso'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'Completada',
                            child: Text('Completada'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _estado = value;
                          });
                          _reload();
                        },
                      ),
                    ),
                    SizedBox(
                      width: ancho,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey(
                          'resultado-${_resultado ?? 'todos'}',
                        ),
                        initialValue: _resultado,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Resultado',
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'CUMPLE',
                            child: Text('Cumple'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'NO CUMPLE',
                            child: Text('No cumple'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'INDETERMINADO',
                            child: Text('Indeterminado'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _resultado = value;
                          });
                          _reload();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenPaginacion({
    required int total,
    required int totalPages,
  }) {
    final desdeRegistro =
        total == 0 ? 0 : ((_page - 1) * _pageSize) + 1;

    final hastaRegistro =
        (_page * _pageSize) > total
            ? total
            : _page * _pageSize;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$total registro(s) · mostrando $desdeRegistro-$hastaRegistro',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Página anterior',
          onPressed: _page > 1
              ? () {
                  setState(() {
                    _page -= 1;
                  });
                  _cargar();
                }
              : null,
          icon: const Icon(
            Icons.chevron_left,
          ),
        ),
        Text(
          '$_page / $totalPages',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        IconButton(
          tooltip: 'Página siguiente',
          onPressed: _page < totalPages
              ? () {
                  setState(() {
                    _page += 1;
                  });
                  _cargar();
                }
              : null,
          icon: const Icon(
            Icons.chevron_right,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginacionInferior(
    int totalPages,
  ) {
    return Align(
      alignment: Alignment.center,
      child: Wrap(
        spacing: 6,
        crossAxisAlignment:
            WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _page > 1
                ? () {
                    setState(() {
                      _page -= 1;
                    });
                    _cargar();
                  }
                : null,
            icon: const Icon(
              Icons.chevron_left,
              size: 18,
            ),
            label: const Text('Anterior'),
          ),
          Text(
            'Página $_page de $totalPages',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          OutlinedButton.icon(
            onPressed: _page < totalPages
                ? () {
                    setState(() {
                      _page += 1;
                    });
                    _cargar();
                  }
                : null,
            icon: const Icon(
              Icons.chevron_right,
              size: 18,
            ),
            label: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onTap,
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
              ),
              icon: const Icon(
                Icons.event_outlined,
                size: 18,
              ),
              label: Text(
                value == null
                    ? 'Seleccionar fecha'
                    : verDate(value),
              ),
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Quitar fecha',
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: const Icon(
                Icons.close,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  const _HistorialCard({
    required this.item,
  });

  final HistorialVerificacionItem item;

  String get _resultadoVisible {
    final value = item.resultado?.trim();

    if (value == null || value.isEmpty) {
      return item.enCurso
          ? 'Pendiente de resultado'
          : 'Sin resultado';
    }

    return value;
  }

  String get _conexionVisible =>
      item.codConexion?.toString() ?? 'No registrada';

  String get _fugasVisible {
    if (item.fugas == null) {
      return 'No registrado';
    }

    return item.fugas! ? 'Sí' : 'No';
  }

  String get _medidorVisible {
    final parts = <String>[
      if (item.marcaMedidor != null &&
          item.marcaMedidor!.trim().isNotEmpty)
        item.marcaMedidor!.trim(),
      if (item.numeroMedidor != null &&
          item.numeroMedidor!.trim().isNotEmpty)
        item.numeroMedidor!.trim(),
    ];

    return parts.isEmpty
        ? 'No registrado'
        : parts.join(' · ');
  }

  String _errorVisible() {
    final error = item.error;

    if (error == null) {
      return 'No registrado';
    }

    final prefix = error > 0 ? '+' : '';
    return '$prefix${error.toStringAsFixed(2)} %';
  }

  void _abrirDetalle(BuildContext context) {
    context.push<void>(
      '${AppRoutes.mecanicoHome}/verificacion/${item.idVerificacion}',
    );
  }

  void _abrirInforme(BuildContext context) {
    context.push<void>(
      '${AppRoutes.mecanicoHome}/verificacion/${item.idVerificacion}/informe',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFD9E2E7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombreCliente ??
                            'Socio ${item.regSoc}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Verificación #${item.idVerificacion} · ${verDate(item.fecha, time: true)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                VerStatusChip(
                  item.estado == 'EnCurso'
                      ? 'En curso'
                      : item.estado,
                ),
              ],
            ),

            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 680;

                final ancho = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    SizedBox(
                      width: ancho,
                      child: _line(
                        Icons.badge_outlined,
                        'Registro socio',
                        '${item.regSoc}',
                      ),
                    ),
                    SizedBox(
                      width: ancho,
                      child: _line(
                        Icons.link_outlined,
                        'Código / conexión',
                        _conexionVisible,
                      ),
                    ),
                    SizedBox(
                      width: ancho,
                      child: _line(
                        Icons.speed_outlined,
                        'Medidor',
                        _medidorVisible,
                      ),
                    ),
                    SizedBox(
                      width: ancho,
                      child: _line(
                        Icons.percent,
                        'Error',
                        _errorVisible(),
                      ),
                    ),
                    SizedBox(
                      width: ancho,
                      child: _line(
                        Icons.water_drop_outlined,
                        'Fugas',
                        _fugasVisible,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                VerStatusChip(
                  _resultadoVisible,
                ),
                VerStatusChip(
                  item.estadoInforme,
                ),
              ],
            ),

            if (item.tieneInforme) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD9E5F3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nroInforme ?? 'Informe emitido',
                      style: const TextStyle(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (item.versionInforme != null)
                          'Versión ${item.versionInforme}',
                        if (item.fechaEmisionInforme != null)
                          'Emitido ${verDate(item.fechaEmisionInforme, time: true)}',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (item.enCurso)
                    FilledButton.icon(
                      onPressed: () =>
                          _abrirDetalle(context),
                      icon: const Icon(
                        Icons.play_arrow_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Continuar verificación',
                      ),
                    )
                  else ...[
                    OutlinedButton.icon(
                      onPressed: () =>
                          _abrirDetalle(context),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Ver detalle',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          _abrirInforme(context),
                      icon: Icon(
                        item.tieneInforme
                            ? Icons.description_outlined
                            : Icons.picture_as_pdf_outlined,
                        size: 18,
                      ),
                      label: Text(
                        item.tieneInforme
                            ? 'Ver informe'
                            : 'Emitir informe',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
