import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/admin_controller.dart';
import '../controllers/admin_supervision_controller.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ui.dart';
import '../../domain/entities/admin_models.dart';

class AdminVerificacionesScreen extends StatelessWidget {
  const AdminVerificacionesScreen({super.key});
  @override Widget build(BuildContext context) => const _AdminVerificacionesView(soloInformes: false);
}

class AdminInformesScreen extends StatelessWidget {
  const AdminInformesScreen({super.key});
  @override Widget build(BuildContext context) => const _AdminVerificacionesView(soloInformes: true);
}

class _AdminVerificacionesView extends ConsumerStatefulWidget {
  const _AdminVerificacionesView({required this.soloInformes});
  final bool soloInformes;
  @override ConsumerState<_AdminVerificacionesView> createState() => _AdminVerificacionesViewState();
}

class _AdminVerificacionesViewState extends ConsumerState<_AdminVerificacionesView> {
  final _buscar = TextEditingController();
  DateTime? _desde, _hasta;
  int? _mecanicoId;
  String _estado = 'Todos', _resultado = 'Todos';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() { ref.read(adminControllerProvider.notifier).cargarUsuarios(); _load(); });
  }
  @override void dispose() { _buscar.dispose(); super.dispose(); }

  Future<void> _load({int? page}) async {
    if (page != null) _page = page;
    await ref.read(adminSupervisionControllerProvider.notifier).cargarVerificaciones(
      desde: _desde, hasta: _hasta, mecanicoId: _mecanicoId, estado: _estado, resultado: _resultado,
      buscar: _buscar.text, soloConInforme: widget.soloInformes ? true : null, page: _page,
    );
  }

  Future<void> _export(bool pdf) async {
    await ref.read(adminSupervisionControllerProvider.notifier).exportarVerificaciones(
      pdf: pdf,
      desde: _desde,
      hasta: _hasta,
      mecanicoId: _mecanicoId,
      estado: widget.soloInformes ? null : _estado,
      resultado: _resultado,
      buscar: _buscar.text,
      soloConInforme: widget.soloInformes ? true : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupervisionControllerProvider);
    final users = ref.watch(adminControllerProvider).usuarios.where((u) => u.rol == 'mecanico').toList();
    final data = state.verificaciones;
    final selected = state.verificacionSeleccionada;
    final title = widget.soloInformes ? 'Informes Tecnicos de Verificacion' : 'Verificaciones de Medidores';
    return AdminShell(
      title: title,
      subtitle: widget.soloInformes ? 'Consulta y descarga los informes tecnicos emitidos.' : 'Consulta el avance y resultado de las verificaciones de medidores.',
      currentRoute: widget.soloInformes ? '/admin/informes' : '/admin/verificaciones',
      actions: [
        OutlinedButton.icon(onPressed: state.isLoading ? null : () => _load(), icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
        OutlinedButton.icon(onPressed: state.isExporting ? null : () => _export(true), icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Exportar listado PDF')),
        FilledButton.icon(onPressed: state.isExporting ? null : () => _export(false), icon: const Icon(Icons.table_view_outlined), label: const Text('Exportar Excel')),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AdminMessage(error: state.errorMessage, success: state.successMessage),
        AdminFilterBox(child: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.end, children: [
          _DateBox(label: 'Desde', value: _desde, onChanged: (v) => setState(() => _desde = v)),
          _DateBox(label: 'Hasta', value: _hasta, onChanged: (v) => setState(() => _hasta = v)),
          SizedBox(width: 210, child: DropdownButtonFormField<int?>(isExpanded: true, initialValue: _mecanicoId, decoration: const InputDecoration(labelText: 'Mecanico', border: OutlineInputBorder(), isDense: true), items: [const DropdownMenuItem<int?>(value: null, child: Text('Todos')), ...users.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.nombreCompleto, overflow: TextOverflow.ellipsis)))], onChanged: (v) => setState(() => _mecanicoId = v))),
          if (!widget.soloInformes) SizedBox(width: 150, child: DropdownButtonFormField<String>(isExpanded: true, initialValue: _estado, decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder(), isDense: true), items: const ['Todos','Pendiente','EnCurso','Completada'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _estado = v ?? 'Todos'))),
          SizedBox(width: 155, child: DropdownButtonFormField<String>(isExpanded: true, initialValue: _resultado, decoration: const InputDecoration(labelText: 'Resultado', border: OutlineInputBorder(), isDense: true), items: const ['Todos','CUMPLE','NO CUMPLE'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _resultado = v ?? 'Todos'))),
          SizedBox(width: 250, child: TextField(controller: _buscar, onSubmitted: (_) => _load(), decoration: const InputDecoration(labelText: 'ID, CodCon, socio, medidor...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), isDense: true))),
          FilledButton.icon(onPressed: state.isLoading ? null : () { _page = 1; _load(); }, icon: const Icon(Icons.search), label: const Text('Buscar')),
        ])),
        if (state.isLoading) const LinearProgressIndicator(),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final stack = c.maxWidth < 1050;
          final list = AdminCard(padding: EdgeInsets.zero, child: data == null || data.items.isEmpty ? AdminEmpty(widget.soloInformes ? 'Aun no hay informes emitidos con estos filtros.' : 'No hay verificaciones con estos filtros.') : Column(children: [
            Scrollbar(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7F6)),
              columns: [const DataColumn(label: Text('ID')), const DataColumn(label: Text('Fecha')), const DataColumn(label: Text('CodCon')), const DataColumn(label: Text('Socio')), const DataColumn(label: Text('Mecanico')), if (!widget.soloInformes) const DataColumn(label: Text('Estado')), const DataColumn(label: Text('Resultado')), const DataColumn(label: Text('Error')), const DataColumn(label: Text('Caudal')), const DataColumn(label: Text('Informe')), const DataColumn(label: Text(''))],
              rows: data.items.map((v) => DataRow(selected: selected?.resumen.idVerificacion == v.idVerificacion, cells: [
                DataCell(Text('VER-${v.idVerificacion}', style: const TextStyle(fontWeight: FontWeight.w800))), DataCell(Text(adminDate(v.fecha))), DataCell(Text('${v.codCon}')), DataCell(SizedBox(width: 160, child: Text(v.nombreCliente, overflow: TextOverflow.ellipsis))), DataCell(SizedBox(width: 150, child: Text(v.nombreMecanico, overflow: TextOverflow.ellipsis))), if (!widget.soloInformes) DataCell(AdminStatusChip(v.estado)), DataCell(v.resultado == null ? const Text('-') : AdminStatusChip(v.resultado!)), DataCell(Text(v.error == null ? '-' : '${v.error!.toStringAsFixed(3)} %')), DataCell(Text(v.caudal == null ? '-' : v.caudal!.toStringAsFixed(2))), DataCell(v.tieneInforme ? AdminStatusChip(v.informeFirmado ? 'Firmado' : 'Emitido') : const Text('-')), DataCell(IconButton(tooltip: 'Ver detalle', onPressed: () => ref.read(adminSupervisionControllerProvider.notifier).seleccionarVerificacion(v.idVerificacion), icon: const Icon(Icons.visibility_outlined))),
              ])).toList(),
            ))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: AdminPager(page: data.page, totalPages: data.totalPages, totalItems: data.totalItems, onPage: (p) { _page = p; _load(page: p); })),
          ]));
          final detail = _VerificationDetail(selected);
          if (stack) return Column(children: [list, const SizedBox(height: 14), detail]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: list), const SizedBox(width: 14), Expanded(flex: 2, child: detail)]);
        }),
      ]),
    );
  }
}

class _VerificationDetail extends ConsumerWidget {
  const _VerificationDetail(this.d);
  final AdminVerificacionDetalle? d;
  @override Widget build(BuildContext context, WidgetRef ref) {
    if (d == null) return const AdminCard(child: AdminEmpty('Selecciona una verificacion para consultar el ensayo y sus informes.', icon: Icons.fact_check_outlined));
    final r = d!.resumen;
    final ensayo = d!.ensayo;
    String val(String key) => '${d!.datosSocio[key] ?? '-'}';
    return AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('VER-${r.idVerificacion}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), AdminStatusChip(r.resultado ?? r.estado)]),
      const SizedBox(height: 12),
      _Line('Socio', r.nombreCliente), _Line('CodCon', '${r.codCon}'), _Line('Direccion', val('direccion')), _Line('Medidor', '${val('numeroMedidor')} / ${val('marcaMedidor')}'), _Line('Mecanico', r.nombreMecanico), _Line('Fecha', adminDate(r.fecha, time: true)),
      const Divider(height: 24), const Text('Ensayo', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 7),
      if (ensayo == null) const Text('La verificacion todavia no tiene datos de ensayo registrados.', style: TextStyle(color: Color(0xFF68737D))) else ...[
        _Line('Condiciones', '${ensayo['condiciones'] ?? '-'}'), _Line('Lectura inicial / final', '${ensayo['lecturaInicial'] ?? '-'} / ${ensayo['lecturaFinal'] ?? '-'}'), _Line('Volumen patron', '${ensayo['volumenPatron'] ?? '-'}'), _Line('Volumen registrado', '${ensayo['volumenRegistrado'] ?? '-'}'), _Line('Caudal', '${ensayo['caudal'] ?? '-'}'), _Line('Error', '${ensayo['error'] ?? '-'} %'), _Line('Fugas', ensayo['fugas'] == true ? 'SI' : ensayo['fugas'] == false ? 'NO' : '-'), _Line('Observaciones', '${ensayo['observaciones'] ?? '-'}'),
      ],
      const Divider(height: 24), Text('Participantes (${d!.participantes.length})', style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5),
      if (d!.participantes.isEmpty) const Text('Sin participantes registrados.', style: TextStyle(color: Color(0xFF68737D))) else ...d!.participantes.map((p) => Text('• ${p['nombre'] ?? '-'} — ${p['rol'] ?? p['cargo'] ?? '-'}', style: const TextStyle(fontSize: 12))),
      const Divider(height: 24), Text('Informes (${d!.informes.length})', style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 6),
      if (d!.informes.isEmpty)
        const Text('Todavia no existe un informe emitido para esta verificacion.', style: TextStyle(color: Color(0xFF68737D)))
      else
        ...d!.informes.map((i) {
          final hasPdf = i.rutaPdf != null && i.rutaPdf!.trim().isNotEmpty;
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF7F9F8), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.nroInforme, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${adminDate(i.fechaEmision, time: true)} — ${hasPdf ? 'PDF disponible' : 'PDF pendiente de generacion'}', style: const TextStyle(fontSize: 10, color: Color(0xFF68737D))),
              ])),
              AdminStatusChip(i.firmado ? 'Firmado' : 'Emitido'),
              const SizedBox(width: 4),
              IconButton(
                tooltip: hasPdf ? 'Descargar informe PDF' : 'El informe aun no tiene PDF generado',
                onPressed: hasPdf ? () => ref.read(adminSupervisionControllerProvider.notifier).descargarInforme(i) : null,
                icon: const Icon(Icons.download_outlined, size: 19),
              ),
            ]),
          );
        }),
    ]));
  }
}
class _Line extends StatelessWidget { const _Line(this.label, this.value); final String label, value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 115, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF68737D), fontWeight: FontWeight.w700))), Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))) ])); }
class _DateBox extends StatelessWidget { const _DateBox({required this.label, required this.value, required this.onChanged}); final String label; final DateTime? value; final ValueChanged<DateTime?> onChanged; @override Widget build(BuildContext context) => SizedBox(width: 145, child: InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: value ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) onChanged(d); }, child: InputDecorator(decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, suffixIcon: value == null ? const Icon(Icons.calendar_month, size: 18) : IconButton(onPressed: () => onChanged(null), icon: const Icon(Icons.close, size: 17))), child: Text(adminDate(value))))); }
