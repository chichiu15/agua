import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tecnico.dart';
import '../../presentation/controllers/solicitud_controller.dart';
import 'armar_recorrido_scaffold.dart';

class Paso3AsignarTecnicoScreen extends ConsumerStatefulWidget {
  const Paso3AsignarTecnicoScreen({super.key});

  @override
  ConsumerState<Paso3AsignarTecnicoScreen> createState() =>
      _Paso3AsignarTecnicoScreenState();
}

class _Paso3AsignarTecnicoScreenState
    extends ConsumerState<Paso3AsignarTecnicoScreen> {
  int? _tecnicoSeleccionado;

  void _asignarme() {
    setState(() {
      _tecnicoSeleccionado = 0;
    });
  }

  Future<void> _confirmarAsignacion() async {
    if (_tecnicoSeleccionado == null) return;

    final controller = ref.read(solicitudControllerProvider.notifier);
    final exito = await controller.asignarRuta(_tecnicoSeleccionado!);

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignación confirmada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/asignador');
    } else {
      final error = ref.read(solicitudControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al asignar ruta.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitudState = ref.watch(solicitudControllerProvider);
    final tecnicos = solicitudState.tecnicos;

    return ArmarRecorridoScaffold(
      paso: 3,
      subtitulo:
          'Paso 3: Seleccione el personal técnico disponible para cubrir este recorrido.',
      showBackButton: true,
      onBack: () => context.go('/asignador/recorrido/paso2'),
      primaryLabel: solicitudState.isAsignando
          ? 'ASIGNANDO...'
          : 'CONFIRMAR ASIGNACIÓN',
      primaryOnPressed: (_tecnicoSeleccionado != null && !solicitudState.isAsignando)
          ? _confirmarAsignacion
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _asignarme,
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text(
                  'Asignarme a mí',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SELECCIONAR TÉCNICO',
                style: TextStyle(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: solicitudState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : tecnicos.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay técnicos disponibles.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tecnicos.length,
                        itemBuilder: (context, index) {
                          final tecnico = tecnicos[index];
                          final isSelected =
                              _tecnicoSeleccionado == tecnico.id;
                          final isAssignedSelf = _tecnicoSeleccionado == 0;
                          final ocupado = tecnico.tieneRutaAsignada;

                          return _TecnicoCard(
                            tecnico: tecnico,
                            isSelected: isSelected ||
                                (isAssignedSelf && tecnico.activo && !ocupado),
                            ocupado: ocupado,
                            onTap: (tecnico.activo && !ocupado)
                                ? () {
                                    setState(() {
                                      _tecnicoSeleccionado = tecnico.id;
                                    });
                                  }
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TecnicoCard extends StatelessWidget {
  const _TecnicoCard({
    required this.tecnico,
    required this.isSelected,
    required this.ocupado,
    this.onTap,
  });

  final Tecnico tecnico;
  final bool isSelected;
  final bool ocupado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disponible = tecnico.activo && !ocupado;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightBlue
              : disponible
                  ? const Color(0xFFEEF5FF)
                  : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.actionBlue
                : disponible
                    ? AppColors.lightBlue
                    : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tecnico.nombreCompleto,
                    style: TextStyle(
                      color: disponible
                          ? AppColors.darkBlue
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !tecnico.activo
                        ? 'Inactivo'
                        : ocupado
                            ? 'Ocupado · Con ruta asignada'
                            : 'Disponible',
                    style: TextStyle(
                      color: disponible
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.check_circle_outline,
              color: isSelected
                  ? AppColors.actionBlue
                  : disponible
                      ? AppColors.actionBlue.withValues(alpha: 0.4)
                      : AppColors.textSecondary.withValues(alpha: 0.3),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
