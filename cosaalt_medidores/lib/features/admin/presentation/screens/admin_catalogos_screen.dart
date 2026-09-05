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

  Future<void> _cambiarEstadoMotivo(MotivoCatalogo motivo, bool activo) async {
    final ok = await _confirmarEstado(
      titulo: '${activo ? 'Activar' : 'Desactivar'} motivo',
      mensaje: activo
          ? 'El motivo "${motivo.descripcion}" volvera a estar disponible para nuevos cambios.'
          : 'El motivo "${motivo.descripcion}" dejara de aparecer en nuevos cambios. El historial se conserva.',
      accion: activo ? 'Activar' : 'Desactivar',
    );
    if (ok == true && mounted) {
      await ref.read(adminControllerProvider.notifier).cambiarEstadoMotivo(motivo, activo);
    }
  }

  Future<void> _editarMarca([MarcaCatalogo? marca]) async {
    final result = await showDialog<GuardarMarcaCatalogo>(
      context: context,
      builder: (_) => _MarcaDialog(marca: marca),
    );
    if (result == null || !mounted) return;
    await ref.read(adminControllerProvider.notifier).guardarMarca(id: marca?.id, marca: result);
  }

  Future<void> _cambiarEstadoMarca(MarcaCatalogo marca, bool activo) async {
    final ok = await _confirmarEstado(
      titulo: '${activo ? 'Activar' : 'Desactivar'} marca',
      mensaje: activo
          ? 'La marca "${marca.nombre}" volvera a estar habilitada en el catalogo administrativo.'
          : 'La marca "${marca.nombre}" quedara inactiva. No se modifica ningun medidor historico de dbo.Medidor.',
      accion: activo ? 'Activar' : 'Desactivar',
    );
    if (ok == true && mounted) {
      await ref.read(adminControllerProvider.notifier).cambiarEstadoMarca(marca, activo);
    }
  }

  Future<bool?> _confirmarEstado({required String titulo, required String mensaje, required String accion}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(accion)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    return AdminShell(
      title: 'Catalogos Operativos',
      subtitle: 'Administra motivos de cambio y el catalogo auxiliar de marcas del modulo de medidores.',
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
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              final motivos = _MotivosPanel(
                motivos: state.motivos,
                isLoading: state.isLoading,
                isSaving: state.isSaving,
                onNuevo: () => _editarMotivo(),
                onEditar: _editarMotivo,
                onEstado: _cambiarEstadoMotivo,
              );
              final marcas = _MarcasPanel(
                marcas: state.marcas,
                isLoading: state.isLoading,
                isSaving: state.isSaving,
                onNuevo: () => _editarMarca(),
                onEditar: _editarMarca,
                onEstado: _cambiarEstadoMarca,
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [motivos, const SizedBox(height: 16), marcas],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: motivos),
                  const SizedBox(width: 16),
                  Expanded(child: marcas),
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
  final bool isLoading;
  final bool isSaving;
  final VoidCallback onNuevo;
  final ValueChanged<MotivoCatalogo> onEditar;
  final void Function(MotivoCatalogo, bool) onEstado;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Motivos de cambio',
            subtitle: 'Opciones que el tecnico puede seleccionar al registrar un cambio.',
            buttonLabel: 'Nuevo motivo',
            onPressed: isSaving ? null : onNuevo,
          ),
          const Divider(height: 24),
          if (motivos.isEmpty && !isLoading)
            const AdminEmpty('No hay motivos registrados.', icon: Icons.build_circle_outlined)
          else
            ...motivos.map(
              (m) => _CatalogRow(
                code: '#${m.id}',
                title: m.descripcion,
                subtitle: m.detalle,
                active: m.activo,
                onEdit: isSaving ? null : () => onEditar(m),
                onState: isSaving ? null : (value) => onEstado(m, value),
              ),
            ),
          if (motivos.any((m) => !m.activo))
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Los motivos inactivos se conservan para trazabilidad y dejan de aparecer en nuevos cambios.',
                style: TextStyle(fontSize: 11, color: Color(0xFF68737D)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarcasPanel extends StatelessWidget {
  const _MarcasPanel({
    required this.marcas,
    required this.isLoading,
    required this.isSaving,
    required this.onNuevo,
    required this.onEditar,
    required this.onEstado,
  });

  final List<MarcaCatalogo> marcas;
  final bool isLoading;
  final bool isSaving;
  final VoidCallback onNuevo;
  final ValueChanged<MarcaCatalogo> onEditar;
  final void Function(MarcaCatalogo, bool) onEstado;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Marcas de medidor',
            subtitle: 'Administra codigo, nombre, alias y estado sin alterar los medidores historicos de COSAALT.',
            buttonLabel: 'Nueva marca',
            onPressed: isSaving ? null : onNuevo,
          ),
          const Divider(height: 24),
          if (marcas.isEmpty && !isLoading)
            const AdminEmpty('No se encontraron marcas registradas.', icon: Icons.speed_outlined)
          else
            ...marcas.map(
              (m) => _CatalogRow(
                code: m.codigo.isEmpty ? '#${m.id}' : m.codigo,
                title: m.nombre.trim().isEmpty ? 'Sin nombre registrado' : m.nombre,
                subtitle: m.alias,
                active: m.activo,
                onEdit: isSaving ? null : () => onEditar(m),
                onState: isSaving ? null : (value) => onEstado(m, value),
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.subtitle, required this.buttonLabel, required this.onPressed});
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF68737D))),
            ],
          ),
        ),
        FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.add), label: Text(buttonLabel)),
      ],
    );
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.code,
    required this.title,
    this.subtitle,
    required this.active,
    required this.onEdit,
    required this.onState,
  });
  final String code;
  final String title;
  final String? subtitle;
  final bool active;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onState;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF7F9F8) : const Color(0xFFF3F4F4),
        border: Border.all(color: const Color(0xFFE0E6E2)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(code, style: const TextStyle(color: Color(0xFF006B3F), fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: active ? const Color(0xFF17212B) : Colors.grey.shade600)),
                if (subtitle != null && subtitle!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF68737D))),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AdminStatusChip(active ? 'Activo' : 'Inactivo'),
          IconButton(tooltip: 'Editar', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          Switch.adaptive(value: active, onChanged: onState),
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
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Nombre *', hintText: 'Ej. Medidor danado', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el nombre del motivo.' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcion,
                maxLength: 250,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripcion', border: OutlineInputBorder()),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible para nuevos cambios'),
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

class _MarcaDialog extends StatefulWidget {
  const _MarcaDialog({this.marca});
  final MarcaCatalogo? marca;

  @override
  State<_MarcaDialog> createState() => _MarcaDialogState();
}

class _MarcaDialogState extends State<_MarcaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _alias;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _codigo = TextEditingController(text: widget.marca?.codigo ?? '');
    _nombre = TextEditingController(text: widget.marca?.nombre ?? '');
    _alias = TextEditingController(text: widget.marca?.alias ?? '');
    _activo = widget.marca?.activo ?? true;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _alias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.marca == null ? 'Nueva marca de medidor' : 'Editar marca de medidor'),
      content: SizedBox(
        width: 470,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigo,
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Codigo institucional *', hintText: 'Ej. ITR', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el codigo de la marca.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombre,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Nombre *', hintText: 'Ej. Itron', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el nombre de la marca.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alias,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Alias / detalle', border: OutlineInputBorder()),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marca activa'),
                subtitle: const Text('Desactivar no modifica dbo.Medidor ni registros historicos.'),
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
              GuardarMarcaCatalogo(
                codigo: _codigo.text.trim().toUpperCase(),
                nombre: _nombre.text.trim(),
                alias: _alias.text.trim().isEmpty ? null : _alias.text.trim(),
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
