import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
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
  int? _usuarioDestinoSeleccionado;
  bool _asignadoAMi = false;

  void _asignarme() {
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay usuario autenticado.'),
          backgroundColor: AppColors.odecoRed,
        ),
      );
      return;
    }

    setState(() {
      _usuarioDestinoSeleccionado = currentUser.id;
      _asignadoAMi = true;
    });
  }

  Future<void> _confirmarAsignacion() async {
    if (_usuarioDestinoSeleccionado == null) return;

    final controller = ref.read(solicitudControllerProvider.notifier);
    final exito = await controller.asignarRuta(_usuarioDestinoSeleccionado!);

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignación confirmada correctamente.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.go('/asignador');
    } else {
      final error = ref.read(solicitudControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al asignar ruta.'),
          backgroundColor: AppColors.odecoRed,
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
      primaryOnPressed:
          (_usuarioDestinoSeleccionado != null && !solicitudState.isAsignando)
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
                icon: Icon(
                  _asignadoAMi ? Icons.check_circle : Icons.person_add,
                  size: 20,
                ),
                label: Text(
                  _asignadoAMi ? 'Asignado a mí' : 'Asignarme a mí',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _asignadoAMi
                      ? AppColors.primaryGreen
                      : AppColors.actionBlue,
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
                          final isSelected = !_asignadoAMi &&
                              _usuarioDestinoSeleccionado == tecnico.id;
                          final ocupado = tecnico.tieneRutaAsignada;

                          return _TecnicoCard(
                            tecnico: tecnico,
                            isSelected: isSelected,
                            ocupado: ocupado,
                            onTap: (tecnico.activo && !ocupado)
                                ? () {
                                    setState(() {
                                      _usuarioDestinoSeleccionado = tecnico.id;
                                      _asignadoAMi = false;
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
