import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../domain/entities/admin_models.dart';
import '../controllers/admin_controller.dart';
import '../controllers/admin_supervision_controller.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ui.dart';

class AdminMovimientosScreen extends ConsumerStatefulWidget {
  const AdminMovimientosScreen({super.key});

  @override
  ConsumerState<AdminMovimientosScreen> createState() => _AdminMovimientosScreenState();
}

class _AdminMovimientosScreenState extends ConsumerState<AdminMovimientosScreen> {
  final _buscar = TextEditingController();
  final _codConCorporativo = TextEditingController();

  bool _corporativo = false;

  DateTime? _desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime? _hasta = DateTime.now();
  int? _tecnicoId;
  int? _motivoId;
  String _origen = 'Todos';
  String? _marca;
  String _sync = 'Todos';
  int _pageApp = 1;
  AdminMovimiento? _seleccionado;

  String _vigenteCorporativo = 'Todos';
  int _pageCorporativo = 1;
  AdminMovimientoCorporativo? _seleccionadoCorporativo;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(adminControllerProvider.notifier).cargarTodo();
      await _load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _buscar.dispose();
    _codConCorporativo.dispose();
    super.dispose();
  }

  void _programarBusqueda(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (_corporativo) { _pageCorporativo = 1; } else { _pageApp = 1; }
      _load();
    });
  }

  bool? get _syncValue => switch (_sync) {
        'Sincronizado' => true,
        'Pendiente' => false,
        _ => null,
      };

  bool? get _vigenteValue => switch (_vigenteCorporativo) {
        'Vigente' => true,
        'Historico' => false,
        _ => null,
      };

  int? get _codConValue {
    final raw = _codConCorporativo.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<void> _load({int? page}) async {
    if (_corporativo) {
      await _loadCorporativo(page: page);
    } else {
      await _loadApp(page: page);
    }
  }

  Future<void> _loadApp({int? page}) async {
    if (page != null) _pageApp = page;
    await ref.read(adminSupervisionControllerProvider.notifier).cargarMovimientos(
          desde: _desde,
          hasta: _hasta,
          tecnicoId: _tecnicoId,
          motivoId: _motivoId,
          origen: _origen,
          marca: _marca,
          sincronizado: _syncValue,
          buscar: _buscar.text,
          page: _pageApp,
        );
    if (!mounted) return;
    final current = ref.read(adminSupervisionControllerProvider).movimientos;
    if (current != null && current.items.isNotEmpty) {
      final stillExists = _seleccionado != null &&
          current.items.any((e) => e.idEjecucion == _seleccionado!.idEjecucion);
      setState(() => _seleccionado = stillExists ? _seleccionado : current.items.first);
    } else {
      setState(() => _seleccionado = null);
    }
  }

  Future<void> _loadCorporativo({int? page}) async {
    if (page != null) _pageCorporativo = page;
    await ref.read(adminSupervisionControllerProvider.notifier).cargarHistoricoCorporativo(
          codCon: _codConValue,
          vigente: _vigenteValue,
          motivoId: _motivoId,
          marca: _marca,
          buscar: _buscar.text,
          page: _pageCorporativo,
        );
    if (!mounted) return;
    final current = ref.read(adminSupervisionControllerProvider).historicoCorporativo;
    if (current != null && current.items.isNotEmpty) {
      final stillExists = _seleccionadoCorporativo != null &&
          current.items.any((e) => e.codCaMe == _seleccionadoCorporativo!.codCaMe);
      setState(() => _seleccionadoCorporativo =
          stillExists ? _seleccionadoCorporativo : current.items.first);
    } else {
      setState(() => _seleccionadoCorporativo = null);
    }
  }

  Future<void> _export(bool pdf) async {
    final notifier = ref.read(adminSupervisionControllerProvider.notifier);
    if (_corporativo) {
      await notifier.exportarHistoricoCorporativo(
        pdf: pdf,
        codCon: _codConValue,
        vigente: _vigenteValue,
        motivoId: _motivoId,
        marca: _marca,
        buscar: _buscar.text,
      );
      return;
    }
    await notifier.exportarMovimientos(
      pdf: pdf,
      desde: _desde,
      hasta: _hasta,
      tecnicoId: _tecnicoId,
      motivoId: _motivoId,
      origen: _origen,
      marca: _marca,
      sincronizado: _syncValue,
      buscar: _buscar.text,
    );
  }

  Future<void> _switchSource(bool corporativo) async {
    if (_corporativo == corporativo) return;
    setState(() {
      _corporativo = corporativo;
      _buscar.clear();
      _pageApp = 1;
      _pageCorporativo = 1;
    });
    await _load();
  }

  void _clearFilters() {
    setState(() {
      _buscar.clear();
      _motivoId = null;
      _marca = null;
      if (_corporativo) {
        _codConCorporativo.clear();
        _vigenteCorporativo = 'Todos';
        _pageCorporativo = 1;
      } else {
        _desde = DateTime.now().subtract(const Duration(days: 30));
        _hasta = DateTime.now();
        _tecnicoId = null;
        _origen = 'Todos';
        _sync = 'Todos';
        _pageApp = 1;
      }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupervisionControllerProvider);
    final base = ref.watch(adminControllerProvider);
    final tecnicos = base.usuarios.where((u) => u.rol.toLowerCase() == 'tecnico').toList();
    final marcas = base.marcas
        .map((m) => m.nombre.trim().isNotEmpty ? m.nombre.trim() : (m.alias?.trim() ?? ''))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return AdminShell(
      title: 'Planilla Digital: Movimiento de Medidores',
      subtitle: _corporativo
          ? 'Consulta el historial de medidores registrado en el sistema institucional.'
          : 'Consulta los cambios de medidor realizados desde la aplicacion.',
      currentRoute: '/admin/movimientos',
      actions: [
        OutlinedButton.icon(
          onPressed: state.isLoading ? null : () => _load(),
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
        OutlinedButton.icon(
          onPressed: state.isExporting ? null : () => _export(true),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Exportar PDF'),
        ),
        FilledButton.icon(
          onPressed: state.isExporting ? null : () => _export(false),
          icon: const Icon(Icons.table_view_outlined),
          label: const Text('Exportar Excel'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminMessage(error: state.errorMessage, success: state.successMessage),
          AdminCard(
            child: Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Fuente del reporte:', style: TextStyle(fontWeight: FontWeight.w900)),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.cloud_done_outlined), label: Text('Ejecuciones de la App')),
                    ButtonSegment(value: true, icon: Icon(Icons.account_balance_outlined), label: Text('Historico COSAALT')),
                  ],
                  selected: {_corporativo},
                  onSelectionChanged: state.isLoading
                      ? null
                      : (values) {
                          if (values.isNotEmpty) _switchSource(values.first);
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AdminFilterBox(
            child: _corporativo
                ? _corporateFilters(base, marcas, state)
                : _appFilters(base, tecnicos, marcas, state),
          ),
          if (state.isLoading || state.isExporting) const LinearProgressIndicator(),
          const SizedBox(height: 14),
          if (_corporativo)
            _corporateContent(state.historicoCorporativo)
          else
            _appContent(state.movimientos),
          const SizedBox(height: 12),
          _sourceNote(),
        ],
      ),
    );
  }

  Widget _appFilters(AdminState base, List<AdminUsuario> tecnicos, List<String> marcas, AdminSupervisionState state) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        _DateBox(label: 'Desde', value: _desde, onChanged: (v) => setState(() => _desde = v)),
        _DateBox(label: 'Hasta', value: _hasta, onChanged: (v) => setState(() => _hasta = v)),
        SizedBox(
          width: 210,
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
        _motivoDrop(base),
        _StringDrop(width: 145, label: 'Origen', value: _origen, items: const ['Todos', 'ODECO', 'LECTURA'], onChanged: (v) => setState(() => _origen = v ?? 'Todos')),
        _marcaDrop(marcas),
        _StringDrop(width: 160, label: 'Sincronizacion', value: _sync, items: const ['Todos', 'Sincronizado', 'Pendiente'], onChanged: (v) => setState(() => _sync = v ?? 'Todos')),
        _searchField('CodCon, socio, medidor...', state),
        _searchButton(state, () {
          _pageApp = 1;
          _loadApp();
        }),
        TextButton(onPressed: state.isLoading ? null : _clearFilters, child: const Text('Limpiar')),
      ],
    );
  }

  Widget _corporateFilters(AdminState base, List<String> marcas, AdminSupervisionState state) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 160,
          child: TextField(
            controller: _codConCorporativo,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'CodCon exacto', border: OutlineInputBorder(), isDense: true),
          ),
        ),
        _StringDrop(
          width: 155,
          label: 'Estado medidor',
          value: _vigenteCorporativo,
          items: const ['Todos', 'Vigente', 'Historico'],
          onChanged: (v) => setState(() => _vigenteCorporativo = v ?? 'Todos'),
        ),
        _motivoDrop(base),
        _marcaDrop(marcas),
        _searchField('CodCaMe, socio, serial, motivo...', state),
        _searchButton(state, () {
          _pageCorporativo = 1;
          _loadCorporativo();
        }),
        TextButton(onPressed: state.isLoading ? null : _clearFilters, child: const Text('Limpiar')),
      ],
    );
  }

  Widget _motivoDrop(AdminState base) => SizedBox(
        width: 210,
        child: DropdownButtonFormField<int?>(isExpanded: true, 
          initialValue: _motivoId,
          decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder(), isDense: true),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
            ...base.motivos.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.descripcion, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setState(() => _motivoId = v),
        ),
      );

  Widget _marcaDrop(List<String> marcas) => SizedBox(
        width: 180,
        child: DropdownButtonFormField<String?>(isExpanded: true, 
          initialValue: _marca,
          decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder(), isDense: true),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
            ...marcas.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setState(() => _marca = v),
        ),
      );

  Widget _searchField(String label, AdminSupervisionState state) => SizedBox(
        width: 270,
        child: TextField(
          controller: _buscar,
          onChanged: _programarBusqueda,
          onSubmitted: state.isLoading
              ? null
              : (_) {
                  _searchDebounce?.cancel();
                  if (_corporativo) {
                    _pageCorporativo = 1;
                  } else {
                    _pageApp = 1;
                  }
                  _load();
                },
          decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(), isDense: true),
        ),
      );

  Widget _searchButton(AdminSupervisionState state, VoidCallback onPressed) => FilledButton.icon(
        onPressed: state.isLoading ? null : onPressed,
        icon: const Icon(Icons.search),
        label: const Text('Buscar'),
      );

  Widget _appContent(PagedData<AdminMovimiento>? data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 1130;
        final table = _MovimientosTable(
          data: data,
          seleccionado: _seleccionado,
          onSelect: (m) => setState(() => _seleccionado = m),
          onPage: (p) {
            _pageApp = p;
            _loadApp(page: p);
          },
        );
        final detail = _MovimientoDetail(_seleccionado);
        if (stack) return Column(children: [table, const SizedBox(height: 14), detail]);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: table),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: detail),
          ],
        );
      },
    );
  }

  Widget _corporateContent(PagedData<AdminMovimientoCorporativo>? data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 1080;
        final table = _HistoricoCorporativoTable(
          data: data,
          seleccionado: _seleccionadoCorporativo,
          onSelect: (m) => setState(() => _seleccionadoCorporativo = m),
          onPage: (p) {
            _pageCorporativo = p;
            _loadCorporativo(page: p);
          },
        );
        final detail = _HistoricoCorporativoDetail(_seleccionadoCorporativo);
        if (stack) return Column(children: [table, const SizedBox(height: 14), detail]);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: table),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: detail),
          ],
        );
      },
    );
  }

  Widget _sourceNote() {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_corporativo ? Icons.lock_outline : Icons.info_outline, color: _corporativo ? const Color(0xFF087A4D) : const Color(0xFF1D5FBF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _corporativo
                  ? 'El historial institucional conserva los cambios registrados para cada conexion y permite identificar el medidor vigente.'
                  : 'Esta vista muestra los cambios realizados en campo, incluyendo tecnico, lectura de retiro, sincronizacion y evidencias. '
                      'No modifica ni sustituye el historial corporativo de COSAALT.',
              style: const TextStyle(color: Color(0xFF46515C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovimientosTable extends StatelessWidget {
  const _MovimientosTable({required this.data, required this.seleccionado, required this.onSelect, required this.onPage});
  final PagedData<AdminMovimiento>? data;
  final AdminMovimiento? seleccionado;
  final ValueChanged<AdminMovimiento> onSelect;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: data == null || data!.items.isEmpty
          ? const AdminEmpty('No existen movimientos para los filtros seleccionados.', icon: Icons.table_rows_outlined)
          : Column(
              children: [
                Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7F6)),
                      columns: const [
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Origen')),
                        DataColumn(label: Text('CodCon')),
                        DataColumn(label: Text('Socio')),
                        DataColumn(label: Text('Medidor retirado')),
                        DataColumn(label: Text('Lectura')),
                        DataColumn(label: Text('Motivo')),
                        DataColumn(label: Text('Medidor instalado')),
                        DataColumn(label: Text('Tecnico')),
                        DataColumn(label: Text('Sync')),
                        DataColumn(label: Text('Fotos')),
                      ],
                      rows: data!.items.map((m) {
                        return DataRow(
                          selected: seleccionado?.idEjecucion == m.idEjecucion,
                          onSelectChanged: (_) => onSelect(m),
                          cells: [
                            DataCell(Text(adminDate(m.fechaHora, time: true))),
                            DataCell(AdminStatusChip(m.tipoOrigen)),
                            DataCell(Text('${m.codCon}')),
                            DataCell(SizedBox(width: 170, child: Text(m.nombreCliente, overflow: TextOverflow.ellipsis))),
                            DataCell(SizedBox(width: 150, child: Text('${m.numeroMedidorRetirado}\n${m.marcaRetirado ?? '-'}'))),
                            DataCell(Text(m.lecturaRetiro.toStringAsFixed(2))),
                            DataCell(SizedBox(width: 170, child: Text(m.motivo, overflow: TextOverflow.ellipsis))),
                            DataCell(SizedBox(width: 150, child: Text('${m.numeroMedidorInstalado}\n${m.marcaInstalado ?? '-'}'))),
                            DataCell(SizedBox(width: 145, child: Text(m.nombreTecnico, overflow: TextOverflow.ellipsis))),
                            DataCell(AdminStatusChip(m.sincronizado ? 'Sincronizado' : 'Pendiente')),
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.photo_library_outlined, size: 16), const SizedBox(width: 4), Text('${m.evidencias}')])),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: AdminPager(page: data!.page, totalPages: data!.totalPages, totalItems: data!.totalItems, onPage: onPage),
                ),
              ],
            ),
    );
  }
}

class _HistoricoCorporativoTable extends StatelessWidget {
  const _HistoricoCorporativoTable({required this.data, required this.seleccionado, required this.onSelect, required this.onPage});
  final PagedData<AdminMovimientoCorporativo>? data;
  final AdminMovimientoCorporativo? seleccionado;
  final ValueChanged<AdminMovimientoCorporativo> onSelect;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: data == null || data!.items.isEmpty
          ? const AdminEmpty('No existen filas de historial corporativo para los filtros seleccionados.', icon: Icons.account_balance_outlined)
          : Column(
              children: [
                Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7F6)),
                      columns: const [
                        DataColumn(label: Text('CodCaMe')),
                        DataColumn(label: Text('CodCon')),
                        DataColumn(label: Text('Socio')),
                        DataColumn(label: Text('Medidor')),
                        DataColumn(label: Text('Marca')),
                        DataColumn(label: Text('Vigente')),
                        DataColumn(label: Text('Motivo')),
                        DataColumn(label: Text('Orden trabajo')),
                      ],
                      rows: data!.items.map((m) => DataRow(
                            selected: seleccionado?.codCaMe == m.codCaMe,
                            onSelectChanged: (_) => onSelect(m),
                            cells: [
                              DataCell(Text('${m.codCaMe}')),
                              DataCell(Text('${m.codCon}')),
                              DataCell(SizedBox(width: 190, child: Text(m.nombreCliente, overflow: TextOverflow.ellipsis))),
                              DataCell(Text(m.numeroMedidor)),
                              DataCell(Text(m.marca ?? '-')),
                              DataCell(AdminStatusChip(m.vigente ? 'Vigente' : 'Historico')),
                              DataCell(SizedBox(width: 180, child: Text(m.motivo ?? '-', overflow: TextOverflow.ellipsis))),
                              DataCell(Text(m.codOrdenTrabajo?.toString() ?? '-')),
                            ],
                          )).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: AdminPager(page: data!.page, totalPages: data!.totalPages, totalItems: data!.totalItems, onPage: onPage),
                ),
              ],
            ),
    );
  }
}

class _MovimientoDetail extends StatelessWidget {
  const _MovimientoDetail(this.movimiento);
  final AdminMovimiento? movimiento;

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    if (m == null) {
      return const AdminCard(child: AdminEmpty('Selecciona un movimiento para revisar detalle y evidencias.', icon: Icons.water_drop_outlined));
    }

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Ejecucion #${m.idEjecucion}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              AdminStatusChip(m.sincronizado ? 'Sincronizado' : 'Pendiente'),
            ],
          ),
          const SizedBox(height: 12),
          _Line('Fecha', adminDate(m.fechaHora, time: true)),
          _Line('Origen', '${m.tipoOrigen}-${m.idOrigen}'),
          _Line('CodCon', '${m.codCon}'),
          _Line('Socio', m.nombreCliente),
          _Line('Direccion', m.direccion),
          _Line('Tecnico', m.nombreTecnico),
          const Divider(height: 24),
          const Text('Medidor retirado', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          _Line('Numero', m.numeroMedidorRetirado),
          _Line('Marca', m.marcaRetirado ?? '-'),
          _Line('Lectura', m.lecturaRetiro.toStringAsFixed(2)),
          _Line('Motivo', m.motivo),
          const Divider(height: 24),
          const Text('Medidor instalado', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          _Line('Numero', m.numeroMedidorInstalado),
          _Line('Marca', m.marcaInstalado ?? '-'),
          _Line('Observaciones', m.observaciones?.trim().isNotEmpty == true ? m.observaciones! : '-'),
          _Line('GPS', m.latLong?.trim().isNotEmpty == true ? m.latLong! : 'No registrado'),
          const Divider(height: 24),
          Text('Evidencias (${m.evidencias})', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (m.fotos.isEmpty)
            const Text('No hay fotografias asociadas a esta ejecucion.', style: TextStyle(color: Color(0xFF68737D)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: m.fotos.map((foto) {
                final tipo = '${foto['tipoFoto'] ?? 'Evidencia'}';
                final ruta = '${foto['rutaArchivo'] ?? ''}';
                return _Evidence(tipo: tipo, ruta: ruta);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _HistoricoCorporativoDetail extends StatelessWidget {
  const _HistoricoCorporativoDetail(this.movimiento);
  final AdminMovimientoCorporativo? movimiento;

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    if (m == null) {
      return const AdminCard(child: AdminEmpty('Selecciona una fila del historial corporativo.', icon: Icons.account_balance_outlined));
    }
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Cambio corporativo #${m.codCaMe}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              AdminStatusChip(m.vigente ? 'Vigente' : 'Historico'),
            ],
          ),
          const SizedBox(height: 12),
          _Line('CodCon', '${m.codCon}'),
          _Line('Socio', m.nombreCliente),
          _Line('Direccion', m.direccion),
          const Divider(height: 24),
          _Line('Medidor', m.numeroMedidor),
          _Line('Marca', m.marca ?? '-'),
          _Line('Motivo', m.motivo ?? (m.idMotivo == null ? '-' : 'Motivo #${m.idMotivo}')),
          _Line('Orden', m.codOrdenTrabajo?.toString() ?? '-'),
          _Line('Descripcion', m.descripcion?.trim().isNotEmpty == true ? m.descripcion! : '-'),
          const Divider(height: 24),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF1D5FBF)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Este historial no dispone de una fecha de movimiento confiable para mostrar. Se conserva la informacion tal como esta registrada en el sistema institucional.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5E6975)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Evidence extends StatelessWidget {
  const _Evidence({required this.tipo, required this.ruta});
  final String tipo, ruta;

  @override
  Widget build(BuildContext context) {
    final url = ruta.startsWith('http') ? ruta : '${ApiConfig.baseUrl}$ruta';
    return InkWell(
      onTap: ruta.isEmpty
          ? null
          : () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850, maxHeight: 650),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [Expanded(child: Text(tipo, style: const TextStyle(fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
                        ),
                        Flexible(
                          child: InteractiveViewer(
                            child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Padding(padding: EdgeInsets.all(30), child: Text('No fue posible cargar la evidencia.'))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: const Color(0xFFF7F9F8), borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFDDE4E0))),
        child: Column(
          children: [
            SizedBox(
              height: 78,
              width: double.infinity,
              child: ruta.isEmpty
                  ? const Icon(Icons.image_not_supported_outlined, color: Colors.grey)
                  : ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.grey))),
            ),
            const SizedBox(height: 5),
            Text(tipo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF68737D), fontWeight: FontWeight.w700))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _StringDrop extends StatelessWidget {
  const _StringDrop({required this.width, required this.label, required this.value, required this.items, required this.onChanged});
  final double width;
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: DropdownButtonFormField<String>(isExpanded: true, 
          initialValue: value,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
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
            final d = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) onChanged(d);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: value == null ? const Icon(Icons.calendar_month, size: 18) : IconButton(onPressed: () => onChanged(null), icon: const Icon(Icons.close, size: 17)),
            ),
            child: Text(adminDate(value)),
          ),
        ),
      );
}
