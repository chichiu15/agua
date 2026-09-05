import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/cambio_medidor.dart';
import '../controllers/cambio_medidor_controller.dart';

class CambioMedidorScreen extends ConsumerStatefulWidget {
  const CambioMedidorScreen({required this.solicitudId, super.key});

  final String solicitudId;

  @override
  ConsumerState<CambioMedidorScreen> createState() => _CambioMedidorScreenState();
}

class _CambioMedidorScreenState extends ConsumerState<CambioMedidorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lecturaController = TextEditingController();
  final _buscarMedidorController = TextEditingController();
  final _observacionesController = TextEditingController();

  int? _motivoId;
  int? _codMedidorSeleccionado;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(cambioMedidorControllerProvider.notifier).cargar(widget.solicitudId),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _lecturaController.dispose();
    _buscarMedidorController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  MedidorDisponible? _seleccionado(CambioMedidorState state) {
    final code = _codMedidorSeleccionado;
    if (code == null) return null;
    for (final item in state.medidoresDisponibles) {
      if (item.codMedidor == code) return item;
    }
    return null;
  }

  Future<void> _buscar([String? texto]) async {
    setState(() => _codMedidorSeleccionado = null);
    await ref
        .read(cambioMedidorControllerProvider.notifier)
        .buscarMedidoresDisponibles(texto ?? _buscarMedidorController.text);
  }

  void _programarBusqueda(String texto) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _buscar(texto);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final current = ref.read(cambioMedidorControllerProvider);
    final medidor = _seleccionado(current);

    final ok = await ref.read(cambioMedidorControllerProvider.notifier).guardarLocal(
      lecturaRetiroTexto: _lecturaController.text,
      idMotivo: _motivoId,
      medidorInstalado: medidor,
      observaciones: _observacionesController.text,
    );

    if (!mounted) return;
    final state = ref.read(cambioMedidorControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.successGreen : AppColors.odecoRed,
        content: Text(ok
            ? (state.successMessage ?? 'Trabajo guardado localmente.')
            : (state.errorMessage ?? 'No se pudo guardar el trabajo.')),
      ),
    );

    if (ok) {
      final role = ref.read(authControllerProvider).user?.role;
      final home = role == UserRole.asignador
          ? AppRoutes.asignadorHome
          : AppRoutes.tecnicoHome;
      context.go('$home?tab=1');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cambioMedidorControllerProvider);
    final controller = ref.read(cambioMedidorControllerProvider.notifier);
    final solicitud = state.solicitud;
    final seleccionado = _seleccionado(state);

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
                        'Socio ${solicitud.codCon} · ${solicitud.nombreCliente}',
                        style: const TextStyle(color: AppColors.darkBlue),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Badge(
                            text: solicitud.tipoOrigen,
                            color: solicitud.tipoOrigen.toUpperCase() == 'ODECO'
                                ? AppColors.odecoRed
                                : AppColors.actionBlue,
                          ),
                          if (solicitud.esVencida)
                            const _Badge(text: 'VENCIDA', color: AppColors.overdueOrange),
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Lectura de retiro *',
                          hintText: 'Ej. 1250.50',
                        ),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                          return parsed == null || parsed < 0 ? 'Ingrese una lectura válida' : null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _motivoId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Motivo del cambio *'),
                        items: state.motivos
                            .map((m) => DropdownMenuItem<int>(
                                  value: m.id,
                                  child: Text(m.descripcion, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _motivoId = value),
                        validator: (value) => value == null ? 'Seleccione un motivo' : null,
                      ),

                      const SizedBox(height: 24),
                      const _SectionTitle(
                        icon: Icons.add_circle_outline,
                        title: 'Medidor a Instalar',
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Seleccione un medidor registrado por COSAALT. El servidor vuelve a comprobar que esté PERFECTO, LIBRE y sin socio antes de aceptar la sincronización.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _buscarMedidorController,
                        textInputAction: TextInputAction.search,
                        onChanged: _programarBusqueda,
                        onSubmitted: _buscar,
                        decoration: InputDecoration(
                          labelText: 'Buscar medidor disponible',
                          hintText: 'Escriba serie, marca o código',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: state.isSearchingMeters
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MeterResultsList(
                        items: state.medidoresDisponibles,
                        selectedCode: _codMedidorSeleccionado,
                        onSelected: (item) {
                          FocusScope.of(context).unfocus();
                          setState(() => _codMedidorSeleccionado = item.codMedidor);
                        },
                      ),
                      if (_codMedidorSeleccionado == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Seleccione un medidor de la lista.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                      if (seleccionado != null) ...[
                        const SizedBox(height: 10),
                        _MeterSelectionCard(medidor: seleccionado),
                      ],
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones de instalación',
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Fotos de respaldo (opcionales)',
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
                            ? 'La cámara guarda una copia comprimida en el dispositivo hasta sincronizar.'
                            : 'En Windows se selecciona una imagen para simular la captura de campo.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.odecoRed.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.odecoRed.withValues(alpha: .25)),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(color: AppColors.odecoRed),
                          ),
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
                        label: Text(state.isSaving ? 'GUARDANDO...' : 'GUARDAR EN EL DISPOSITIVO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.actionBlue,
                          foregroundColor: AppColors.darkBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .3),
                        ),
                      ),
                      if (state.archivoLocal != null) ...[
                        const SizedBox(height: 10),
                        const Text(
                          '✓ Guardado local · Pendiente de sincronización',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: CosaaltBottomNav(
        currentIndex: 1,
        onTap: (index) {
          final role = ref.read(authControllerProvider).user?.role;
          final home = role == UserRole.asignador
              ? AppRoutes.asignadorHome
              : AppRoutes.tecnicoHome;
          context.go('$home?tab=$index');
        },
      ),
    );
  }
}

class _MeterResultsList extends StatelessWidget {
  const _MeterResultsList({
    required this.items,
    required this.selectedCode,
    required this.onSelected,
  });

  final List<MedidorDisponible> items;
  final int? selectedCode;
  final ValueChanged<MedidorDisponible> onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'No hay medidores disponibles con ese criterio.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    const itemHeight = 62.0;
    final visibleItems = items.length > 5 ? 5 : items.length;
    return Container(
      height: itemHeight * visibleItems,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.codMedidor == selectedCode;
            return SizedBox(
              height: itemHeight,
              child: Material(
                color: selected
                    ? AppColors.primaryGreen.withValues(alpha: .10)
                    : Colors.white,
                child: InkWell(
                  onTap: () => onSelected(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                      Icon(
                        selected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: selected ? AppColors.primaryGreen : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.serie.isEmpty ? 'Sin serie · Cód. ${item.codMedidor}' : item.serie,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${item.marca.isEmpty ? 'Sin marca' : item.marca} · Cód. ${item.codMedidor}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const _Badge(text: 'LIBRE', color: AppColors.successGreen),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MeterSelectionCard extends StatelessWidget {
  const _MeterSelectionCard({required this.medidor});
  final MedidorDisponible medidor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${medidor.serie} · ${medidor.marca}',
                  style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900),
                ),
              ),
              const _Badge(text: 'LIBRE', color: AppColors.successGreen),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Código institucional: ${medidor.codMedidor} · Estado: ${medidor.estado ?? 'PERFECTO'}${medidor.diametro == null || medidor.diametro!.isEmpty ? '' : ' · Diámetro: ${medidor.diametro}'}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, required this.color});
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
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
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
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
      );
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.label, required this.path, required this.onTap});
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
                  const Icon(Icons.camera_alt, color: AppColors.textSecondary, size: 30),
                  const SizedBox(height: 6),
                  Text(
                    'TOMAR FOTO\n$label',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800),
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
                      child: Icon(Icons.check, color: AppColors.successGreen, size: 18),
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
