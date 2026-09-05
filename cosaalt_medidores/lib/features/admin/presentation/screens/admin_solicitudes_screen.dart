import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/admin_controller.dart';
import '../controllers/admin_supervision_controller.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ui.dart';
import '../../domain/entities/admin_models.dart';

class AdminSolicitudesScreen extends ConsumerStatefulWidget {
  const AdminSolicitudesScreen({super.key});
  @override
  ConsumerState<AdminSolicitudesScreen> createState() => _AdminSolicitudesScreenState();
}

class _AdminSolicitudesScreenState extends ConsumerState<AdminSolicitudesScreen> {
  final _search = TextEditingController();
  DateTime? _desde, _hasta;
  String _origen = 'Todos', _estado = 'Todos', _prioridad = 'Todas';
  int? _tecnicoId;
  int _page = 1;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminControllerProvider.notifier).cargarUsuarios();
      _load();
    });
  }

  @override
  void dispose() { _searchDebounce?.cancel(); _search.dispose(); super.dispose(); }

  void _programarBusqueda(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _page = 1;
      _load();
    });
  }

  Future<void> _load({int? page}) async {
    if (page != null) _page = page;
    await ref.read(adminSupervisionControllerProvider.notifier).cargarSolicitudes(
      desde: _desde, hasta: _hasta, origen: _origen, estado: _estado, prioridad: _prioridad,
      tecnicoId: _tecnicoId, buscar: _search.text, page: _page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupervisionControllerProvider);
    final base = ref.watch(adminControllerProvider);
    final data = state.solicitudes;
    final tecnicos = base.usuarios.where((u) => u.rol == 'tecnico').toList();
    return AdminShell(
      title: 'Estado Global de Solicitudes',
      subtitle: 'Bandeja centralizada de ODECO y LECTURA con antiguedad, prioridad y asignacion.',
      currentRoute: '/admin/solicitudes',
      actions: [OutlinedButton.icon(onPressed: state.isLoading ? null : () => _load(), icon: const Icon(Icons.refresh), label: const Text('Actualizar'))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AdminMessage(error: state.errorMessage, success: state.successMessage),
        AdminFilterBox(child: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.end, children: [
          _DateFilter(label: 'Desde', value: _desde, onChanged: (v) => setState(() => _desde = v)),
          _DateFilter(label: 'Hasta', value: _hasta, onChanged: (v) => setState(() => _hasta = v)),
          _Drop(label: 'Origen', value: _origen, items: const ['Todos','ODECO','LECTURA'], onChanged: (v) => setState(() => _origen = v!)),
          _Drop(label: 'Estado', value: _estado, items: const ['Todos','Pendiente','Asignada','En proceso','Completada','Vencida'], onChanged: (v) => setState(() => _estado = v!)),
          _Drop(label: 'Prioridad', value: _prioridad, items: const ['Todas','Alta','Media','Normal'], onChanged: (v) => setState(() => _prioridad = v!)),
          SizedBox(width: 210, child: DropdownButtonFormField<int?>(isExpanded: true, initialValue: _tecnicoId, decoration: const InputDecoration(labelText: 'Tecnico', border: OutlineInputBorder(), isDense: true), items: [const DropdownMenuItem<int?>(value: null, child: Text('Todos')), ...tecnicos.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.nombreCompleto, overflow: TextOverflow.ellipsis)))], onChanged: (v) => setState(() => _tecnicoId = v))),
          SizedBox(width: 260, child: TextField(controller: _search, onChanged: _programarBusqueda, onSubmitted: (_) { _searchDebounce?.cancel(); _page = 1; _load(); }, decoration: const InputDecoration(labelText: 'Codigo, CodCon, socio, medidor...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), isDense: true))),
          FilledButton.icon(onPressed: state.isLoading ? null : () { _page = 1; _load(); }, icon: const Icon(Icons.search), label: const Text('Buscar')),
          TextButton(onPressed: () { setState(() { _desde = null; _hasta = null; _origen = 'Todos'; _estado = 'Todos'; _prioridad = 'Todas'; _tecnicoId = null; _search.clear(); _page = 1; }); _load(); }, child: const Text('Limpiar')),
        ])),
        const SizedBox(height: 14),
        if (state.isLoading) const LinearProgressIndicator(),
        AdminCard(
          padding: EdgeInsets.zero,
          child: data == null || data.items.isEmpty
            ? const AdminEmpty('No hay solicitudes para los filtros seleccionados.')
            : Column(children: [
              Scrollbar(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7F6)),
                columns: const [
                  DataColumn(label: Text('Codigo')), DataColumn(label: Text('Fecha')), DataColumn(label: Text('Origen')),
                  DataColumn(label: Text('CodCon')), DataColumn(label: Text('Socio')), DataColumn(label: Text('Motivo')),
                  DataColumn(label: Text('Prioridad')), DataColumn(label: Text('Estado')), DataColumn(label: Text('Dias')),
                  DataColumn(label: Text('Tecnico')), DataColumn(label: Text('Accion')),
                ],
                rows: data.items.map((s) => DataRow(cells: [
                  DataCell(Text(s.id, style: const TextStyle(fontWeight: FontWeight.w800))),
                  DataCell(Text(adminDate(s.fechaSolicitud))), DataCell(AdminStatusChip(s.tipoOrigen)), DataCell(Text('${s.codCon}')),
                  DataCell(SizedBox(width: 170, child: Text(s.nombreCliente, overflow: TextOverflow.ellipsis))),
                  DataCell(SizedBox(width: 210, child: Text(s.motivo ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis))),
                  DataCell(AdminStatusChip(s.prioridad)), DataCell(AdminStatusChip(s.vencida && s.estado != 'Completada' ? 'Vencida' : s.estado)),
                  DataCell(Text('${s.diasTranscurridos}', style: TextStyle(fontWeight: FontWeight.w800, color: s.vencida ? Colors.red : null))),
                  DataCell(SizedBox(width: 150, child: Text(s.nombreTecnico ?? '-'))),
                  DataCell(IconButton(tooltip: 'Ver detalle', onPressed: () => _showDetail(s), icon: const Icon(Icons.visibility_outlined))),
                ])).toList(),
              ))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: AdminPager(page: data.page, totalPages: data.totalPages, totalItems: data.totalItems, onPage: (p) { _page = p; _load(page: p); })),
            ]),
        ),
      ]),
    );
  }

  void _showDetail(AdminSolicitud s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Row(children: [Expanded(child: Text(s.id)), AdminStatusChip(s.vencida && s.estado != 'Completada' ? 'Vencida' : s.estado)]),
      content: SizedBox(width: 650, child: SingleChildScrollView(child: Wrap(runSpacing: 12, spacing: 22, children: [
        _Info('Origen', s.tipoOrigen), _Info('CodCon', '${s.codCon}'), _Info('Socio', s.nombreCliente), _Info('Direccion', s.direccion),
        _Info('Fecha solicitud', adminDate(s.fechaSolicitud, time: true)), _Info('Fecha limite', adminDate(s.fechaLimite, time: true)),
        _Info('Prioridad', s.prioridad), _Info('Tecnico', s.nombreTecnico ?? 'Sin asignar'), _Info('Medidor actual', '${s.numeroMedidor ?? '-'} / ${s.marcaMedidor ?? '-'}'),
        _Info('Motivo / observacion', s.motivo ?? '-'), if (s.lecturaActual != null) _Info('Lecturas', '${s.lecturaAnterior ?? '-'} -> ${s.lecturaActual} (consumo ${s.consumo ?? '-'})'),
        if (s.ultimaEjecucion != null) _Info('Ultima ejecucion', adminDate(s.ultimaEjecucion, time: true)),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    ));
  }
}

class _Info extends StatelessWidget { const _Info(this.label, this.value); final String label, value; @override Widget build(BuildContext context) => SizedBox(width: 290, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF68737D), fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))])); }
class _Drop extends StatelessWidget { const _Drop({required this.label, required this.value, required this.items, required this.onChanged}); final String label, value; final List<String> items; final ValueChanged<String?> onChanged; @override Widget build(BuildContext context) => SizedBox(width: 150, child: DropdownButtonFormField<String>(isExpanded: true, initialValue: value, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged)); }
class _DateFilter extends StatelessWidget { const _DateFilter({required this.label, required this.value, required this.onChanged}); final String label; final DateTime? value; final ValueChanged<DateTime?> onChanged; @override Widget build(BuildContext context) => SizedBox(width: 145, child: InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: value ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) onChanged(d); }, child: InputDecorator(decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, suffixIcon: value == null ? const Icon(Icons.calendar_month, size: 18) : IconButton(onPressed: () => onChanged(null), icon: const Icon(Icons.close, size: 17))), child: Text(adminDate(value))))); }
