import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/cambio_medidor_controller.dart';

class CambioMedidorScreen extends ConsumerStatefulWidget {
  const CambioMedidorScreen({required this.solicitudId, super.key});

  final String solicitudId;

  @override
  ConsumerState<CambioMedidorScreen> createState() =>
      _CambioMedidorScreenState();
}

class _CambioMedidorScreenState extends ConsumerState<CambioMedidorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lecturaController = TextEditingController();
  final _numeroNuevoController = TextEditingController();
  final _marcaNuevaController = TextEditingController();
  final _observacionesController = TextEditingController();

  int? _motivoId;
  String _estadoNuevo = 'Nuevo';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(cambioMedidorControllerProvider.notifier)
          .cargar(widget.solicitudId),
    );
  }

  @override
  void dispose() {
    _lecturaController.dispose();
    _numeroNuevoController.dispose();
    _marcaNuevaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(cambioMedidorControllerProvider.notifier)
        .guardarLocal(
          lecturaRetiroTexto: _lecturaController.text,
          idMotivo: _motivoId,
          numeroNuevo: _numeroNuevoController.text,
          marcaNueva: _marcaNuevaController.text,
          estadoNuevo: _estadoNuevo,
          observaciones: _observacionesController.text,
        );

    if (!mounted) return;
    final state = ref.read(cambioMedidorControllerProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.successGreen : AppColors.odecoRed,
        content: Text(
          ok
              ? (state.successMessage ?? 'Guardado localmente.')
              : (state.errorMessage ?? 'No se pudo guardar.'),
        ),
      ),
    );

    if (ok) {
      // Opción A: al guardar localmente la parada ya se considera completada.
      // Volvemos al dashboard del técnico en la pestaña "Mi Recorrido", que
      // sí incluye el footer de navegación (a diferencia de la ruta dedicada
      // /tecnico/mi-recorrido, que es un Scaffold sin bottomNavigationBar).
      context.go('${AppRoutes.tecnicoHome}?tab=1');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cambioMedidorControllerProvider);
    final controller = ref.read(cambioMedidorControllerProvider.notifier);
    final solicitud = state.solicitud;

    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : solicitud == null
          ? _ErrorBody(
              message: state.errorMessage ?? 'No se pudo cargar la solicitud.',
              onRetry: () => controller.cargar(widget.solicitudId),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Text(
                    'TAREA: ${solicitud.direccion}',
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N° ${solicitud.codCon} · ${solicitud.nombreCliente}',
                    style: const TextStyle(color: AppColors.darkBlue),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _Badge(
                        text: solicitud.tipoOrigen,
                        color: solicitud.tipoOrigen.toUpperCase() == 'ODECO'
                            ? AppColors.odecoRed
                            : AppColors.actionBlue,
                      ),
                      if (solicitud.esVencida)
                        const _Badge(
                          text: 'VENCIDA',
                          color: AppColors.overdueOrange,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const _SectionTitle(
                    icon: Icons.remove_circle_outline,
                    title: 'Medidor Retirado',
                    color: AppColors.odecoRed,
                  ),
                  const SizedBox(height: 10),
                  _ReadOnlyField(
                    label: 'Nro. Medidor Retirado',
                    value: solicitud.numeroMedidor ?? 'SIN MEDIDOR ACTIVO',
                  ),
                  _ReadOnlyField(
                    label: 'Marca',
                    value: solicitud.marcaMedidor ?? 'Sin marca registrada',
                  ),
                  TextFormField(
                    controller: _lecturaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Lectura de retiro *',
                      hintText: 'Ej. 1250.50',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(
                        (value ?? '').replaceAll(',', '.'),
                      );
                      if (parsed == null || parsed < 0)
                        return 'Ingrese una lectura válida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _motivoId,
                    decoration: const InputDecoration(
                      labelText: 'Motivo del cambio *',
                    ),
                    items: state.motivos
                        .map(
                          (m) => DropdownMenuItem<int>(
                            value: m.id,
                            child: Text(m.descripcion),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _motivoId = value),
                    validator: (value) =>
                        value == null ? 'Seleccione un motivo' : null,
                  ),

                  const SizedBox(height: 24),
                  const _SectionTitle(
                    icon: Icons.add_circle_outline,
                    title: 'Medidor Instalado',
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _numeroNuevoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Nro. Medidor Instalado *',
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingrese el número del nuevo medidor'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _marcaNuevaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Marca *'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingrese la marca'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _estadoNuevo,
                    decoration: const InputDecoration(
                      labelText: 'Estado del medidor *',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Nuevo', child: Text('Nuevo')),
                      DropdownMenuItem(
                        value: 'Medio uso',
                        child: Text('Medio uso'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _estadoNuevo = value ?? 'Nuevo'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _observacionesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Fotos de respaldo',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (defaultTargetPlatform == TargetPlatform.android ||
                            defaultTargetPlatform == TargetPlatform.iOS)
                        ? 'La cámara guardará una copia comprimida local.'
                        : 'En Windows se selecciona una imagen para simular la captura de cámara.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PhotoCard(
                          label: 'MED. VIEJO',
                          path: state.fotoRetirado,
                          onTap: controller.tomarFotoRetirado,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PhotoCard(
                          label: 'MED. NUEVO',
                          path: state.fotoNuevo,
                          onTap: controller.tomarFotoNuevo,
                        ),
                      ),
                    ],
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.odecoRed),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: state.isSaving ? null : _guardar,
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      state.isSaving
                          ? 'GUARDANDO...'
                          : 'GUARDAR DATOS LOCALMENTE',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.actionBlue,
                      foregroundColor: AppColors.darkBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                  if (state.archivoLocal != null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '✓ Guardado local pendiente de sincronización',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: CosaaltBottomNav(
        currentIndex: 0,
        onTap: (index) => context.go('/tecnico?tab=$index'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    ],
  );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.label,
    required this.path,
    required this.onTap,
  });
  final String label;
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: path == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt,
                    color: AppColors.textSecondary,
                    size: 30,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'TOMAR FOTO\n$label',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(path!), fit: BoxFit.cover),
                  const Positioned(
                    right: 6,
                    top: 6,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.check,
                        color: AppColors.successGreen,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
