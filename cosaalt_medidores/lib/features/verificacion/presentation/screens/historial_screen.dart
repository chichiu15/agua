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
  DateTime? _desde;
  DateTime? _hasta;
  String? _estado;
  String? _resultado;
  final _buscarCtrl = TextEditingController();
  Timer? _buscarDebounce;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _cargar());
  }

  @override
  void dispose() {
    _buscarDebounce?.cancel();
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    await ref.read(verificacionControllerProvider.notifier).cargarHistorial(
          desde: _desde,
          hasta: _hasta,
          estado: _estado,
          resultado: _resultado,
          buscar: _buscarCtrl.text,
          page: _page,
          pageSize: 50,
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha == null) return;
    setState(() {
      if (esDesde) {
        _desde = fecha;
      } else {
        _hasta = fecha;
      }
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificacionControllerProvider);
    final historial = state.historial;
    final items = historial?.items ?? const <HistorialVerificacionItem>[];

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Historial de Verificaciones',
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verificaciones realizadas por este mecanico',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          VerMessageBar(error: state.errorMessage, success: state.successMessage),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFD9E2E7)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickFecha(true),
                          icon: const Icon(Icons.event, size: 18),
                          label: Text(_desde == null
                              ? 'Desde'
                              : verDate(_desde)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickFecha(false),
                          icon: const Icon(Icons.event, size: 18),
                          label: Text(_hasta == null ? 'Hasta' : verDate(_hasta)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _estado,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Estado'),
                          items: const [
                            DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                            DropdownMenuItem<String?>(value: 'EnCurso', child: Text('En curso')),
                            DropdownMenuItem<String?>(value: 'Pendiente', child: Text('Pendiente')),
                            DropdownMenuItem<String?>(value: 'Completada', child: Text('Completada')),
                          ],
                          onChanged: (value) {
                            setState(() => _estado = value);
                            _reload();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _resultado,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Resultado'),
                          items: const [
                            DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                            DropdownMenuItem<String?>(value: 'CUMPLE', child: Text('Cumple')),
                            DropdownMenuItem<String?>(value: 'NO CUMPLE', child: Text('No cumple')),
                            DropdownMenuItem<String?>(value: 'INDETERMINADO', child: Text('Indeterminado')),
                          ],
                          onChanged: (value) {
                            setState(() => _resultado = value);
                            _reload();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _buscarCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por conexion, serie o error',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      _buscarDebounce?.cancel();
                      _buscarDebounce = Timer(const Duration(milliseconds: 400), () {
                        _page = 1;
                        _cargar();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.isLoading && items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (items.isEmpty)
            const VerEmpty('No hay verificaciones que coincidan con los filtros.')
          else ...[
            Row(
              children: [
                Text(
                  '${historial?.total ?? 0} registro(s)',
                  style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _page > 1 ? () { setState(() => _page -= 1); _cargar(); } : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '$_page / ${((historial?.total ?? 0) / 50).ceil()}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: (_page * 50) < (historial?.total ?? 0)
                      ? () { setState(() => _page += 1); _cargar(); }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            ...items.map((item) => _HistorialCard(item: item)),
          ],
        ],
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  const _HistorialCard({required this.item});

  final HistorialVerificacionItem item;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFD9E2E7)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('${AppRoutes.mecanicoHome}/verificacion/${item.idVerificacion}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.nombreCliente ?? 'Socio ${item.codCon}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                VerStatusChip(item.estado),
              ],
            ),
            const SizedBox(height: 8),
            _line(Icons.link, 'Conexion ${item.codCon} · ${verDate(item.fecha, time: true)}'),
            if (item.numeroMedidor != null && item.numeroMedidor!.isNotEmpty)
              _line(Icons.speed_outlined, 'Medidor ${item.marcaMedidor ?? ''} ${item.numeroMedidor}'.trim()),
            if (item.error != null) _line(Icons.percent, 'Error ${item.error!.toStringAsFixed(2)} %'),
            if (item.fugas == true) _line(Icons.warning_amber, 'Registra fuga'),
            const SizedBox(height: 8),
            Row(
              children: [
                VerStatusChip(item.resultado ?? 'Sin resultado'),
                const Spacer(),
                if (item.tieneInforme)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF4FF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFBFD7FF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined, size: 13, color: Color(0xFF1D5FBF)),
                        const SizedBox(width: 4),
                        Text(
                          item.nroInforme ?? 'Informe',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1D5FBF)),
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(Icons.chevron_right, color: Color(0xFF8A949D)),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}