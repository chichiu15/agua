import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_models.dart';
import '../controllers/admin_controller.dart';
import '../controllers/admin_supervision_controller.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ui.dart';

class AdminReportesScreen extends ConsumerStatefulWidget {
  const AdminReportesScreen({super.key});

  @override
  ConsumerState<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends ConsumerState<AdminReportesScreen> {
  DateTime? _desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime? _hasta = DateTime.now();
  int? _tecnicoId;
  int? _mecanicoId;
  int? _motivoId;
  String _origen = 'Todos';
  String? _marca;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(adminControllerProvider.notifier).cargarTodo();
      await _load();
    });
  }

  Future<void> _load() => ref.read(adminSupervisionControllerProvider.notifier).cargarEstadisticas(
        desde: _desde,
        hasta: _hasta,
        tecnicoId: _tecnicoId,
        mecanicoId: _mecanicoId,
        motivoId: _motivoId,
        origen: _origen,
        marca: _marca,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupervisionControllerProvider);
    final base = ref.watch(adminControllerProvider);
    final stats = state.estadisticas;
    final tecnicos = base.usuarios.where((u) => u.rol.toLowerCase() == 'tecnico').toList();
    final mecanicos = base.usuarios.where((u) => u.rol.toLowerCase() == 'mecanico').toList();
    final marcas = base.marcas
        .map((m) => m.nombre.trim().isNotEmpty ? m.nombre.trim() : (m.alias?.trim() ?? ''))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return AdminShell(
      title: 'Reportes y Estadisticas Operativas',
      subtitle: 'Analisis de cambios de medidor y verificaciones mecanicas con filtros del periodo seleccionado.',
      currentRoute: '/admin/reportes',
      actions: [
        OutlinedButton.icon(onPressed: state.isLoading ? null : _load, icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminMessage(error: state.errorMessage, success: state.successMessage),
          AdminFilterBox(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _DateBox(label: 'Desde', value: _desde, onChanged: (v) => setState(() => _desde = v)),
                _DateBox(label: 'Hasta', value: _hasta, onChanged: (v) => setState(() => _hasta = v)),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int?>(isExpanded: true, 
                    initialValue: _tecnicoId,
                    decoration: const InputDecoration(labelText: 'Tecnico', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ...tecnicos.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.nombreCompleto, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _tecnicoId = v),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int?>(isExpanded: true, 
                    initialValue: _mecanicoId,
                    decoration: const InputDecoration(labelText: 'Mecanico', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ...mecanicos.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.nombreCompleto, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _mecanicoId = v),
                  ),
                ),
                SizedBox(
                  width: 205,
                  child: DropdownButtonFormField<int?>(isExpanded: true, 
                    initialValue: _motivoId,
                    decoration: const InputDecoration(labelText: 'Motivo de cambio', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ...base.motivos.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.descripcion, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _motivoId = v),
                  ),
                ),
                SizedBox(
                  width: 145,
                  child: DropdownButtonFormField<String>(isExpanded: true, 
                    initialValue: _origen,
                    decoration: const InputDecoration(labelText: 'Origen', border: OutlineInputBorder(), isDense: true),
                    items: const ['Todos', 'ODECO', 'LECTURA'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _origen = v ?? 'Todos'),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String?>(isExpanded: true, 
                    initialValue: _marca,
                    decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                      ...marcas.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _marca = v),
                  ),
                ),
                FilledButton.icon(onPressed: state.isLoading ? null : _load, icon: const Icon(Icons.filter_alt_outlined), label: const Text('Aplicar filtros')),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _desde = DateTime.now().subtract(const Duration(days: 30));
                      _hasta = DateTime.now();
                      _tecnicoId = null;
                      _mecanicoId = null;
                      _motivoId = null;
                      _origen = 'Todos';
                      _marca = null;
                    });
                    _load();
                  },
                  child: const Text('Restablecer'),
                ),
              ],
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 14),
          if (stats == null && !state.isLoading)
            const AdminCard(child: AdminEmpty('No hay estadisticas cargadas.', icon: Icons.bar_chart_outlined))
          else if (stats != null) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AdminMetricCard(label: 'Cambios ejecutados', value: '${stats.totalCambios}', icon: Icons.swap_horiz),
                AdminMetricCard(label: 'Verificaciones', value: '${stats.totalVerificaciones}', icon: Icons.fact_check_outlined, tone: const Color(0xFF6554C0)),
                AdminMetricCard(label: 'Cumplimiento mecanico', value: '${stats.porcentajeCumple.toStringAsFixed(1)} %', detail: '${stats.verificacionesCumple} CUMPLE / ${stats.verificacionesNoCumple} NO CUMPLE', icon: Icons.verified_outlined),
                AdminMetricCard(label: 'Casos con fuga', value: '${stats.casosConFuga}', icon: Icons.water_drop_outlined, tone: const Color(0xFFE27A00)),
                AdminMetricCard(label: 'Error promedio', value: stats.errorPromedio == null ? '-' : '${stats.errorPromedio!.toStringAsFixed(3)} %', icon: Icons.calculate_outlined, tone: const Color(0xFF1D5FBF)),
                AdminMetricCard(label: 'Tiempo prom. atencion', value: stats.horasPromedioAtencion == null ? '-' : '${stats.horasPromedioAtencion!.toStringAsFixed(2)} h', icon: Icons.schedule_outlined, tone: const Color(0xFFB42318)),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final one = c.maxWidth < 830;
              final two = c.maxWidth < 1220;
              final cards = <Widget>[
                AdminBarList(title: 'Motivos de cambio mas frecuentes', items: stats.motivosCambio.map((e) => (e.categoria, e.cantidad)).toList()),
                AdminBarList(title: 'Medidores retirados por marca', items: stats.marcasRetiradas.map((e) => (e.categoria, e.cantidad)).toList()),
                AdminBarList(title: 'Cambios por origen', items: stats.origenesCambio.map((e) => (e.categoria, e.cantidad)).toList()),
              ];
              if (one) return Column(children: cards.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: e)).toList());
              if (two) return Wrap(spacing: 12, runSpacing: 12, children: cards.map((e) => SizedBox(width: (c.maxWidth - 12) / 2, child: e)).toList());
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1]), const SizedBox(width: 12), Expanded(child: cards[2])]);
            }),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 1000;
              final serie = _SeriesCard(stats.cambiosPorDia);
              final result = _VerificationResultCard(stats);
              if (stack) return Column(children: [serie, const SizedBox(height: 12), result]);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: serie), const SizedBox(width: 12), Expanded(flex: 2, child: result)]);
            }),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 1000;
              final tech = _PeopleTable(title: 'Productividad de tecnicos', data: stats.tecnicos, mechanic: false);
              final mech = _PeopleTable(title: 'Resumen por mecanico', data: stats.mecanicos, mechanic: true);
              if (stack) return Column(children: [tech, const SizedBox(height: 12), mech]);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: tech), const SizedBox(width: 12), Expanded(child: mech)]);
            }),
            const SizedBox(height: 12),
            const AdminCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1D5FBF)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Las metricas mecanicas utilizan exclusivamente verificaciones ya registradas por el modulo de Manuel. '
                      'Si una verificacion aun no tiene ensayo o resultado, no se inventa un CUMPLE/NO CUMPLE y sus campos permanecen pendientes.',
                      style: TextStyle(color: Color(0xFF46515C)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard(this.data);
  final List<AdminSerieTemporal> data;

  @override
  Widget build(BuildContext context) {
    final max = data.isEmpty ? 1 : data.map((e) => e.cantidad).reduce((a, b) => a > b ? a : b);
    final visible = data.length > 14 ? data.sublist(data.length - 14) : data;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cambios ejecutados por dia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            const AdminEmpty('Sin cambios en el periodo.')
          else
            SizedBox(
              height: 210,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: visible.map((e) {
                  final h = 150 * (e.cantidad / max);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${e.cantidad}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Container(height: h < 4 ? 4 : h, decoration: BoxDecoration(color: const Color(0xFF1677FF), borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))),
                          const SizedBox(height: 5),
                          Text(e.periodo.length >= 10 ? e.periodo.substring(5) : e.periodo, maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 8, color: Color(0xFF68737D))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _VerificationResultCard extends StatelessWidget {
  const _VerificationResultCard(this.stats);
  final AdminEstadisticas stats;
  @override
  Widget build(BuildContext context) {
    final total = stats.verificacionesCumple + stats.verificacionesNoCumple;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resultado de verificaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          if (total == 0)
            const AdminEmpty('Todavia no hay verificaciones con resultado.')
          else ...[
            _ResultLine('CUMPLE', stats.verificacionesCumple, total, const Color(0xFF0A7A45)),
            const SizedBox(height: 12),
            _ResultLine('NO CUMPLE', stats.verificacionesNoCumple, total, const Color(0xFFB42318)),
            const Divider(height: 28),
            Text('${stats.porcentajeCumple.toStringAsFixed(1)} % cumple', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF08783F))),
            const SizedBox(height: 3),
            Text('Sobre $total verificaciones que ya tienen veredicto.', style: const TextStyle(color: Color(0xFF68737D), fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine(this.label, this.value, this.total, this.color);
  final String label;
  final int value, total;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))), Text('$value')]),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: total == 0 ? 0 : value / total, minHeight: 10, color: color, backgroundColor: const Color(0xFFE8ECEA), borderRadius: BorderRadius.circular(6)),
        ],
      );
}

class _PeopleTable extends StatelessWidget {
  const _PeopleTable({required this.title, required this.data, required this.mechanic});
  final String title;
  final List<AdminPersonaMetrica> data;
  final bool mechanic;

  @override
  Widget build(BuildContext context) => AdminCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
            if (data.isEmpty)
              const AdminEmpty('Sin datos para el periodo.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Nombre')),
                    const DataColumn(label: Text('Atenciones')),
                    if (mechanic) const DataColumn(label: Text('CUMPLE')),
                    if (mechanic) const DataColumn(label: Text('NO CUMPLE')),
                    if (mechanic) const DataColumn(label: Text('Error prom.')),
                  ],
                  rows: data.map((p) => DataRow(cells: [
                        DataCell(SizedBox(width: 180, child: Text(p.nombre, overflow: TextOverflow.ellipsis))),
                        DataCell(Text('${p.atenciones}')),
                        if (mechanic) DataCell(Text('${p.cumple}')),
                        if (mechanic) DataCell(Text('${p.noCumple}')),
                        if (mechanic) DataCell(Text(p.errorPromedio == null ? '-' : '${p.errorPromedio!.toStringAsFixed(3)} %')),
                      ])).toList(),
                ),
              ),
          ],
        ),
      );
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 145,
        child: InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: value ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (d != null) onChanged(d);
          },
          child: InputDecorator(
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, suffixIcon: value == null ? const Icon(Icons.calendar_month, size: 18) : IconButton(onPressed: () => onChanged(null), icon: const Icon(Icons.close, size: 17))),
            child: Text(adminDate(value)),
          ),
        ),
      );
}
