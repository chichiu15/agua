import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/admin_models.dart';
import '../controllers/admin_controller.dart';
import '../controllers/admin_supervision_controller.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ui.dart';

class AdminRecorridosScreen extends ConsumerStatefulWidget {
  const AdminRecorridosScreen({super.key});
  @override
  ConsumerState<AdminRecorridosScreen> createState() => _AdminRecorridosScreenState();
}

class _AdminRecorridosScreenState extends ConsumerState<AdminRecorridosScreen> {
  DateTime _fecha = DateTime.now();
  int? _tecnicoId;
  String _estado = 'Todos';
  final _buscar = TextEditingController();
  int _page = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminControllerProvider.notifier).cargarUsuarios();
      _load();
    });
  }

  @override
  void dispose() { _buscar.dispose(); super.dispose(); }

  Future<void> _load({int? page}) async {
    if (page != null) _page = page;
    await ref.read(adminSupervisionControllerProvider.notifier).cargarRutas(fecha: _fecha, tecnicoId: _tecnicoId, estado: _estado, buscar: _buscar.text, page: _page);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupervisionControllerProvider);
    final usuarios = ref.watch(adminControllerProvider).usuarios.where((u) => u.rol == 'tecnico').toList();
    final rutas = state.rutas;
    final selected = state.rutaSeleccionada;
    return AdminShell(
      title: 'Recorridos y Monitoreo en Campo',
      subtitle: 'Seguimiento de rutas asignadas, avance por parada y ultima ejecucion recibida por el servidor.',
      currentRoute: '/admin/recorridos',
      actions: [OutlinedButton.icon(onPressed: state.isLoading ? null : () => _load(), icon: const Icon(Icons.refresh), label: const Text('Actualizar'))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AdminMessage(error: state.errorMessage, success: state.successMessage),
        AdminFilterBox(child: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.end, children: [
          SizedBox(width: 160, child: InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) setState(() => _fecha = d); }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), isDense: true, suffixIcon: Icon(Icons.calendar_month)), child: Text(adminDate(_fecha))))),
          SizedBox(width: 220, child: DropdownButtonFormField<int?>(isExpanded: true, initialValue: _tecnicoId, decoration: const InputDecoration(labelText: 'Tecnico', border: OutlineInputBorder(), isDense: true), items: [const DropdownMenuItem<int?>(value: null, child: Text('Todos')), ...usuarios.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.nombreCompleto, overflow: TextOverflow.ellipsis)))], onChanged: (v) => setState(() => _tecnicoId = v))),
          SizedBox(width: 155, child: DropdownButtonFormField<String>(isExpanded: true, initialValue: _estado, decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder(), isDense: true), items: const ['Todos','Planificado','EnCurso','Completada'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _estado = v ?? 'Todos'))),
          SizedBox(width: 260, child: TextField(controller: _buscar, onSubmitted: (_) => _load(), decoration: const InputDecoration(labelText: 'Ruta, tecnico, socio...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), isDense: true))),
          FilledButton.icon(onPressed: state.isLoading ? null : () { _page = 1; _load(); }, icon: const Icon(Icons.search), label: const Text('Buscar')),
        ])),
        if (state.isLoading) const LinearProgressIndicator(),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final stack = c.maxWidth < 1050;
          final list = AdminCard(padding: const EdgeInsets.all(12), child: rutas == null || rutas.items.isEmpty ? const AdminEmpty('No hay rutas para la fecha seleccionada.') : Column(children: [
            ...rutas.items.map((r) => Material(color: selected?.idAsignacion == r.idAsignacion ? const Color(0xFFEAF7EF) : Colors.transparent, borderRadius: BorderRadius.circular(9), child: InkWell(borderRadius: BorderRadius.circular(9), onTap: () => ref.read(adminSupervisionControllerProvider.notifier).seleccionarRuta(r.idAsignacion), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), child: Row(children: [
              SizedBox(width: 75, child: Text('RUT-${r.idAsignacion}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF006B3F)))),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.nombreTecnico, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${r.totalParadas} paradas - ${adminDate(r.fechaAsignacion)}', style: const TextStyle(fontSize: 10, color: Color(0xFF68737D)))])),
              SizedBox(width: 95, child: LinearProgressIndicator(value: r.avancePorcentaje.clamp(0, 100) / 100, minHeight: 8, borderRadius: BorderRadius.circular(8))), const SizedBox(width: 8), SizedBox(width: 42, child: Text('${r.avancePorcentaje.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800))), AdminStatusChip(r.estado),
            ]))))),
            Padding(padding: const EdgeInsets.only(top: 8), child: AdminPager(page: rutas.page, totalPages: rutas.totalPages, totalItems: rutas.totalItems, onPage: (p) { _page = p; _load(page: p); })),
          ]));
          final detail = _RouteDetail(selected: selected);
          if (stack) return Column(children: [list, const SizedBox(height: 14), detail]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: list), const SizedBox(width: 14), Expanded(flex: 3, child: detail)]);
        }),
      ]),
    );
  }
}

class _RouteDetail extends StatelessWidget {
  const _RouteDetail({required this.selected});
  final AdminRuta? selected;
  @override
  Widget build(BuildContext context) {
    final route = selected;
    if (route == null) return const AdminCard(child: AdminEmpty('Selecciona una ruta para ver el detalle.', icon: Icons.route_outlined));
    final valid = route.detalles.where((d) => d.latitud != null && d.longitud != null && d.latitud != 0 && d.longitud != 0).toList();
    final points = valid.map<LatLng>((d) => LatLng(d.latitud!, d.longitud!)).toList();
    return AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('RUT-${route.idAsignacion}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(route.nombreTecnico, style: const TextStyle(color: Color(0xFF68737D)))])), AdminStatusChip(route.estado)]),
      const SizedBox(height: 12),
      Wrap(spacing: 18, runSpacing: 8, children: [Text('${route.completadas}/${route.totalParadas} completadas', style: const TextStyle(fontWeight: FontWeight.w800)), Text('Avance ${route.avancePorcentaje.toStringAsFixed(1)}%'), Text('Ultima actividad: ${adminDate(route.ultimaEjecucionRecibida, time: true)}')]),
      const Divider(height: 26),
      LayoutBuilder(builder: (context, c) {
        final stack = c.maxWidth < 750;
        final stops = Column(children: route.detalles.map<Widget>((d) => Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: const Color(0xFFF7F9F8), border: Border.all(color: const Color(0xFFDDE4E0)), borderRadius: BorderRadius.circular(8)), child: Row(children: [CircleAvatar(radius: 15, backgroundColor: d.ejecutada ? const Color(0xFFE8F7EE) : const Color(0xFFF1F3F4), child: Text('${d.orden}', style: TextStyle(fontWeight: FontWeight.w900, color: d.ejecutada ? const Color(0xFF08783F) : const Color(0xFF4B5563)))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.direccion, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${d.solicitudId} - ${d.nombreCliente}', style: const TextStyle(fontSize: 10, color: Color(0xFF68737D)))])), AdminStatusChip(d.estado)]))).toList());
        final map = SizedBox(height: 310, child: points.isEmpty ? const DecoratedBox(decoration: BoxDecoration(color: Color(0xFFF2F4F3), borderRadius: BorderRadius.all(Radius.circular(8))), child: AdminEmpty('Esta ruta no tiene coordenadas validas.\nNo se inventan ubicaciones.', icon: Icons.location_off_outlined)) : ClipRRect(borderRadius: BorderRadius.circular(8), child: FlutterMap(options: MapOptions(initialCenter: points.first, initialZoom: 13), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'cosaalt.medidores'), if (points.length > 1) PolylineLayer(polylines: [Polyline(points: points, strokeWidth: 4, color: const Color(0xFF0A7A45))]), MarkerLayer(markers: [for (var i = 0; i < points.length; i++) Marker(point: points[i], width: 34, height: 34, child: CircleAvatar(backgroundColor: const Color(0xFF006B3F), foregroundColor: Colors.white, child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900))))])])));
        if (stack) return Column(children: [stops, const SizedBox(height: 12), map]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: stops), const SizedBox(width: 12), Expanded(child: map)]);
      }),
    ]));
  }
}
