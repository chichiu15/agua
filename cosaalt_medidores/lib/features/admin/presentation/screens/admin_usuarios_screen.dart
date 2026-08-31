import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_models.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_shell.dart';

class AdminUsuariosScreen extends ConsumerStatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  ConsumerState<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends ConsumerState<AdminUsuariosScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminControllerProvider.notifier).cargarUsuarios());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final usuarios = state.usuarios.where((u) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          u.nombreCompleto.toLowerCase().contains(q) ||
          u.nombreUsuario.toLowerCase().contains(q) ||
          u.rol.toLowerCase().contains(q);
    }).toList();

    return AdminShell(
      title: 'Gestion de Usuarios',
      subtitle: 'R2 - Altas, edicion, roles y activacion de cuentas de la aplicacion.',
      currentRoute: '/admin/usuarios',
      actions: [
        FilledButton.icon(
          onPressed: state.isSaving ? null : () => _abrirFormulario(null),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo usuario'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminMessage(error: state.errorMessage, success: state.successMessage),
          AdminCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 240, maxWidth: 520),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nombre, usuario o rol',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => ref.read(adminControllerProvider.notifier).cargarUsuarios(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.isLoading) const LinearProgressIndicator(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F6F4)),
                    columns: const [
                      DataColumn(label: Text('Nombre completo')),
                      DataColumn(label: Text('Usuario')),
                      DataColumn(label: Text('Rol')),
                      DataColumn(label: Text('Funcionario')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: usuarios
                        .map(
                          (u) => DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 210,
                                  child: Text(u.nombreCompleto, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              DataCell(Text(u.nombreUsuario)),
                              DataCell(_RoleBadge(u.rol)),
                              DataCell(Text(u.codFunCorporativo?.toString() ?? 'Sin vincular')),
                              DataCell(
                                Row(
                                  children: [
                                    Switch(
                                      value: u.activo,
                                      onChanged: state.isSaving
                                          ? null
                                          : (v) => ref
                                              .read(adminControllerProvider.notifier)
                                              .cambiarEstadoUsuario(u, v),
                                    ),
                                    Text(u.activo ? 'Activo' : 'Inactivo'),
                                  ],
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: state.isSaving ? null : () => _abrirFormulario(u),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '${usuarios.length} usuario(s) mostrados. No se eliminan usuarios: se inactivan para conservar trazabilidad.',
                    style: const TextStyle(color: Color(0xFF68737D), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormulario(AdminUsuario? usuario) async {
    final state = ref.read(adminControllerProvider);
    final result = await showDialog<GuardarUsuario>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UsuarioFormDialog(
        usuario: usuario,
        roles: state.roles,
        funcionarios: state.funcionarios,
      ),
    );

    if (!mounted || result == null) return;

    await ref.read(adminControllerProvider.notifier).guardarUsuario(
          id: usuario?.id,
          usuario: result,
        );
  }
}

class _UsuarioFormDialog extends StatefulWidget {
  const _UsuarioFormDialog({
    required this.usuario,
    required this.roles,
    required this.funcionarios,
  });

  final AdminUsuario? usuario;
  final List<AdminRol> roles;
  final List<AdminFuncionario> funcionarios;

  @override
  State<_UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<_UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usuarioCtrl;
  late final TextEditingController _passCtrl;
  int? _idRol;
  int? _codFun;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _usuarioCtrl = TextEditingController(text: widget.usuario?.nombreUsuario ?? '');
    _passCtrl = TextEditingController();
    _codFun = widget.usuario?.codFunCorporativo;
    _activo = widget.usuario?.activo ?? true;

    final activos = widget.roles.where((r) => r.activo).toList();
    _idRol = widget.usuario?.idRol ?? (activos.isNotEmpty ? activos.first.id : null);
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;
    return AlertDialog(
      title: Text(usuario == null ? 'Nuevo usuario' : 'Editar usuario'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _codFun ?? 0,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Funcionario corporativo'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text('Sin vincular a funcionario'),
                    ),
                    if (_codFun != null &&
                        !widget.funcionarios.any((f) => f.codFun == _codFun))
                      DropdownMenuItem<int>(
                        value: _codFun,
                        child: Text('$_codFun - Vinculo actual'),
                      ),
                    ...widget.funcionarios.map(
                      (f) => DropdownMenuItem<int>(
                        value: f.codFun,
                        child: Text(
                          '${f.codFun} - ${f.nombreCompleto}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _codFun = v == 0 ? null : v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usuarioCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre de usuario *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: usuario == null
                        ? 'Contrasena *'
                        : 'Nueva contrasena (opcional)',
                  ),
                  validator: (v) => usuario == null && (v == null || v.isEmpty)
                      ? 'La contrasena es obligatoria.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _idRol,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Rol *'),
                  items: widget.roles
                      .where((r) => r.activo || r.id == usuario?.idRol)
                      .map(
                        (r) => DropdownMenuItem<int>(
                          value: r.id,
                          enabled: r.activo || r.id == usuario?.idRol,
                          child: Text(r.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _idRol = v),
                  validator: (v) => v == null ? 'Seleccione un rol.' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usuario activo'),
                  subtitle: const Text('Si se inactiva, no podra iniciar sesion.'),
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true || _idRol == null) return;
            Navigator.pop(
              context,
              GuardarUsuario(
                codFunCorporativo: _codFun,
                nombreUsuario: _usuarioCtrl.text.trim(),
                contrasena: _passCtrl.text.isEmpty ? null : _passCtrl.text,
                idRol: _idRol!,
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);

  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role.toLowerCase()) {
      'administrador' => const Color(0xFF7A5AF8),
      'mecanico' => const Color(0xFFF59E0B),
      'asignador' => const Color(0xFF1677FF),
      _ => const Color(0xFF0A7A45),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
