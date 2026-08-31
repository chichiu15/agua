import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_models.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ui.dart';

class AdminCatalogosScreen extends ConsumerStatefulWidget {
  const AdminCatalogosScreen({super.key});

  @override
  ConsumerState<AdminCatalogosScreen> createState() => _AdminCatalogosScreenState();
}

class _AdminCatalogosScreenState extends ConsumerState<AdminCatalogosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminControllerProvider.notifier).cargarCatalogos());
  }

  Future<void> _editarMotivo([MotivoCatalogo? motivo]) async {
    final result = await showDialog<GuardarMotivoCatalogo>(
      context: context,
      builder: (_) => _MotivoDialog(motivo: motivo),
    );
    if (result == null || !mounted) return;
    await ref.read(adminControllerProvider.notifier).guardarMotivo(id: motivo?.id, motivo: result);
  }

  Future<void> _cambiarEstado(MotivoCatalogo motivo, bool activo) async {
    final verb = activo ? 'activar' : 'desactivar';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${activo ? 'Activar' : 'Desactivar'} motivo'),
        content: Text(
          activo
              ? 'El motivo "${motivo.descripcion}" volvera a estar disponible para nuevos cambios de medidor.'
              : 'El motivo "${motivo.descripcion}" dejara de aparecer como opcion en nuevos cambios de medidor. Los registros historicos no se modificaran.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(verb[0].toUpperCase() + verb.substring(1))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(adminControllerProvider.notifier).cambiarEstadoMotivo(motivo, activo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    return AdminShell(
      title: 'Catalogos Operativos',
      subtitle: 'Administra los motivos de cambio y consulta las marcas registradas de medidores.',
      currentRoute: '/admin/catalogos',
      actions: [
        OutlinedButton.icon(
          onPressed: state.isLoading ? null : () => ref.read(adminControllerProvider.notifier).cargarCatalogos(),
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminMessage(error: state.errorMessage, success: state.successMessage),
          if (state.isLoading) const LinearProgressIndicator(),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 820;
              final motivos = _MotivosPanel(
                motivos: state.motivos,
                isLoading: state.isLoading,
                isSaving: state.isSaving,
                onNuevo: () => _editarMotivo(),
                onEditar: _editarMotivo,
                onEstado: _cambiarEstado,
              );
              final marcas = _MarcasPanel(marcas: state.marcas, isLoading: state.isLoading);

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [motivos, const SizedBox(height: 16), marcas],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: motivos),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: marcas),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MotivosPanel extends StatelessWidget {
  const _MotivosPanel({
    required this.motivos,
    required this.isLoading,
    required this.isSaving,
    required this.onNuevo,
    required this.onEditar,
    required this.onEstado,
  });

  final List<MotivoCatalogo> motivos;
  final bool isLoading, isSaving;
  final VoidCallback onNuevo;
  final ValueChanged<MotivoCatalogo> onEditar;
  final void Function(MotivoCatalogo, bool) onEstado;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Motivos de cambio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Define las opciones disponibles al registrar un cambio de medidor.', style: TextStyle(fontSize: 12, color: Color(0xFF68737D))),
                ],
              ),
              FilledButton.icon(
                onPressed: isSaving ? null : onNuevo,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo motivo'),
              ),
            ],
          ),
          const Divider(height: 24),
          if (motivos.isEmpty && !isLoading)
            const AdminEmpty('No hay motivos registrados.', icon: Icons.build_circle_outlined)
          else
            ...motivos.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: m.activo ? const Color(0xFFF7F9F8) : const Color(0xFFF3F4F4),
                  border: Border.all(color: const Color(0xFFE0E6E2)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text('#${m.id}', style: const TextStyle(color: Color(0xFF006B3F), fontWeight: FontWeight.w900)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.descripcion, style: TextStyle(fontWeight: FontWeight.w800, color: m.activo ? const Color(0xFF17212B) : Colors.grey.shade600)),
                          if (m.detalle != null && m.detalle!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(m.detalle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF68737D))),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdminStatusChip(m.activo ? 'Activo' : 'Inactivo'),
                    IconButton(
                      tooltip: 'Editar motivo',
                      onPressed: isSaving ? null : () => onEditar(m),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    Switch.adaptive(
                      value: m.activo,
                      onChanged: isSaving ? null : (value) => onEstado(m, value),
                    ),
                  ],
                ),
              ),
            ),
          if (motivos.any((m) => !m.activo))
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Los motivos inactivos se conservan para mantener la trazabilidad de registros anteriores.',
                style: TextStyle(fontSize: 11, color: Color(0xFF68737D)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarcasPanel extends StatelessWidget {
  const _MarcasPanel({required this.marcas, required this.isLoading});
  final List<MarcaCatalogo> marcas;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Marcas de medidor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          const Text('Consulta del padrón institucional de marcas de medidores.', style: TextStyle(fontSize: 12, color: Color(0xFF68737D))),
          const Divider(height: 24),
          if (marcas.isEmpty && !isLoading)
            const AdminEmpty('No se encontraron marcas registradas.', icon: Icons.speed_outlined)
          else
            ...marcas.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F8),
                  border: Border.all(color: const Color(0xFFE3E8E5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 44, child: Text('#${m.id}', style: const TextStyle(color: Color(0xFF006B3F), fontWeight: FontWeight.w800))),
                    Expanded(child: Text(m.nombre.trim().isEmpty ? 'Sin nombre registrado' : m.nombre, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (m.alias != null && m.alias!.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(child: Text(m.alias!, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey))),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MotivoDialog extends StatefulWidget {
  const _MotivoDialog({this.motivo});
  final MotivoCatalogo? motivo;

  @override
  State<_MotivoDialog> createState() => _MotivoDialogState();
}

class _MotivoDialogState extends State<_MotivoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.motivo?.descripcion ?? '');
    _descripcion = TextEditingController(text: widget.motivo?.detalle ?? '');
    _activo = widget.motivo?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.motivo == null ? 'Nuevo motivo de cambio' : 'Editar motivo de cambio'),
      content: SizedBox(
        width: 470,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombre,
                autofocus: true,
                maxLength: 50,
                decoration: const InputDecoration(labelText: 'Nombre *', hintText: 'Ej. Cambio preventivo', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el nombre del motivo.' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcion,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripcion', hintText: 'Detalle de uso del motivo (opcional)', border: OutlineInputBorder()),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible para nuevos cambios'),
                subtitle: Text(_activo ? 'El motivo podra seleccionarse en nuevos registros.' : 'El motivo se conservara solo para consulta historica.'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              GuardarMotivoCatalogo(
                nombre: _nombre.text.trim(),
                descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
                activo: _activo,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
