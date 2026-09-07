import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/verificacion_ui.dart';

class BandejaSolicitudesScreen extends ConsumerStatefulWidget {
  const BandejaSolicitudesScreen({super.key});

  @override
  ConsumerState<BandejaSolicitudesScreen> createState() => _BandejaSolicitudesScreenState();
}

class _BandejaSolicitudesScreenState extends ConsumerState<BandejaSolicitudesScreen> {
  String _busqueda = '';
  String _origen = 'Todos';
  String _estado = 'Todas';

  List<SolicitudVerificacion> _filtrar(List<SolicitudVerificacion> solicitudes) {
    return solicitudes.where((s) {
      final q = _busqueda.trim().toLowerCase();
      final matchBusqueda = q.isEmpty ||
          s.id.toLowerCase().contains(q) ||
          s.nombreCliente.toLowerCase().contains(q) ||
          s.tipoOrigen.toLowerCase().contains(q) ||
          s.codCon.toString().contains(q) ||
          s.direccion.toLowerCase().contains(q) ||
          (s.numeroMedidor?.toLowerCase().contains(q) ?? false) ||
          (s.marcaMedidor?.toLowerCase().contains(q) ?? false) ||
          (s.motivoObservacion?.toLowerCase().contains(q) ?? false);

      final esQa = s.id.toUpperCase().startsWith('QA-');
      final matchOrigen = switch (_origen) {
        'Todos' => true,
        'QA' => esQa,
        _ => s.tipoOrigen.toUpperCase() == _origen.toUpperCase(),
      };

      final matchEstado = _estado == 'Todas' ||
          s.estado.toUpperCase() == _estado.toUpperCase();
      return matchBusqueda && matchOrigen && matchEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificacionControllerProvider);
    final originales = state.solicitudes;
    final solicitudes = _filtrar(originales);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(verificacionControllerProvider.notifier).cargarSolicitudes();
        await ref.read(verificacionControllerProvider.notifier).cargarDashboard();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bandeja de Solicitudes',
                  style: TextStyle(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: state.isLoading
                    ? null
                    : () => ref.read(verificacionControllerProvider.notifier).cargarSolicitudes(),
                icon: const Icon(Icons.refresh, color: AppColors.darkBlue),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Verificaciones disponibles por atender',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: InputDecoration(
              hintText: 'Buscar por conexión, cliente, medidor…',
              prefixIcon: const Icon(Icons.search, color: AppColors.darkBlue),
              isDense: true,
              filled: true,
              fillColor: AppColors.lightBlue,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FiltroChip(label: 'Todos', seleccionado: _origen == 'Todos', onTap: () => setState(() => _origen = 'Todos')),
                _FiltroChip(label: 'ODECO', seleccionado: _origen == 'ODECO', onTap: () => setState(() => _origen = 'ODECO')),
                _FiltroChip(label: 'LECTURA', seleccionado: _origen == 'LECTURA', onTap: () => setState(() => _origen = 'LECTURA')),
                _FiltroChip(label: 'REVISION', seleccionado: _origen == 'REVISION', onTap: () => setState(() => _origen = 'REVISION')),
                _FiltroChip(label: 'QA', seleccionado: _origen == 'QA', onTap: () => setState(() => _origen = 'QA')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FiltroChip(label: 'Todas', seleccionado: _estado == 'Todas', onTap: () => setState(() => _estado = 'Todas')),
                _FiltroChip(label: 'Pendiente', seleccionado: _estado == 'Pendiente', onTap: () => setState(() => _estado = 'Pendiente')),
                _FiltroChip(label: 'Tomada', seleccionado: _estado == 'Tomada', onTap: () => setState(() => _estado = 'Tomada')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          VerMessageBar(error: state.errorMessage, success: state.successMessage),
          if (state.isLoading && originales.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (solicitudes.isEmpty)
            VerEmpty(originales.isEmpty ? 'No hay solicitudes de verificacion disponibles.' : 'No hay solicitudes que coincidan con la busqueda.')
          else
            ...solicitudes.map(
              (s) => _SolicitudCard(
                solicitud: s,
                isAccion: state.isAccion,
                onTomar: () => _tomar(context, s),
                onDetalle: () => _verDetalle(context, s),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _tomar(
    BuildContext context,
    SolicitudVerificacion solicitud,
  ) async {
    final error = await ref
        .read(verificacionControllerProvider.notifier)
        .tomarVerificacion(
          tipoOrigen: solicitud.tipoOrigen,
          idOrigen: solicitud.id,
          codCon: solicitud.codCon,
          idMedidor: solicitud.numeroMedidor,
        );
    if (error != null) return;
    final verificacion = ref.read(verificacionControllerProvider).verificacionActual;
    if (verificacion == null) return;
    if (context.mounted) {
      context.push<void>('${AppRoutes.mecanicoHome}/verificacion/${verificacion.id}');
    }
  }

  void _verDetalle(BuildContext context, SolicitudVerificacion s) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                VerStatusChip(s.tipoOrigen.toUpperCase()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.nombreCliente,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.darkBlue),
                  ),
                ),
                VerStatusChip(s.tomada ? 'Tomada' : 'Pendiente'),
              ],
            ),
            const SizedBox(height: 14),
            _DetalleLine('Solicitud', s.id),
            _DetalleLine('Conexión', s.codCon.toString()),
            _DetalleLine('Dirección', s.direccion),
            if (s.categoria?.isNotEmpty == true) _DetalleLine('Categoría', s.categoria!),
            if (s.numeroMedidor != null && s.numeroMedidor!.isNotEmpty)
              _DetalleLine('Medidor', '${s.marcaMedidor ?? ''} ${s.numeroMedidor}'.trim()),
            if (s.motivoObservacion != null && s.motivoObservacion!.isNotEmpty)
              _DetalleLine('Motivo', s.motivoObservacion!),
            _DetalleLine('Fecha', verDate(s.fechaSolicitud, time: true)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: s.tomada ? null : () {
                  Navigator.pop(context);
                  _tomar(context, s);
                },
                icon: const Icon(Icons.playlist_add_check),
                label: Text(s.tomada ? 'Ya fue tomada' : 'Tomar verificacion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({required this.label, required this.seleccionado, required this.onTap});

  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: seleccionado,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: seleccionado ? Colors.white : AppColors.darkBlue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: AppColors.lightBlue,
        selectedColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _DetalleLine extends StatelessWidget {
  const _DetalleLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 13, fontWeight: FontWeight.w600),
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
    required this.isAccion,
    required this.onTomar,
    required this.onDetalle,
  });

  final SolicitudVerificacion solicitud;
  final bool isAccion;
  final VoidCallback onTomar;
  final VoidCallback onDetalle;

  @override
  Widget build(BuildContext context) {
    final motivo = solicitud.motivoObservacion;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: solicitud.tomada ? const Color(0xFFD9E2E7) : AppColors.primaryGreen.withValues(alpha: .5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                VerStatusChip(solicitud.tipoOrigen.toUpperCase()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    solicitud.nombreCliente,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                VerStatusChip(solicitud.tomada ? 'Tomada' : 'Pendiente'),
              ],
            ),
            const SizedBox(height: 8),
            _line(Icons.person_outline, 'Conexion ${solicitud.codCon}'),
            _line(Icons.place_outlined, solicitud.direccion),
            if (solicitud.numeroMedidor != null && solicitud.numeroMedidor!.isNotEmpty)
              _line(
                Icons.speed_outlined,
                'Medidor ${solicitud.marcaMedidor ?? ''} ${solicitud.numeroMedidor}',
              ),
            if (motivo != null && motivo.isNotEmpty) _line(Icons.notes, motivo),
            _line(Icons.event_outlined, verDate(solicitud.fechaSolicitud, time: true)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDetalle,
                    child: const Text('Ver detalle'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: solicitud.tomada || isAccion ? null : onTomar,
                    icon: isAccion
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.playlist_add_check),
                    label: Text(solicitud.tomada ? 'Ya fue tomada' : 'Tomar verificacion'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
        ),
      ],
    ),
  );
}