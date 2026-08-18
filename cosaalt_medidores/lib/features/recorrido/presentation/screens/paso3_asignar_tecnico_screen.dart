import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import 'armar_recorrido_scaffold.dart';

class Paso3AsignarTecnicoScreen extends StatefulWidget {
  const Paso3AsignarTecnicoScreen({super.key});

  @override
  State<Paso3AsignarTecnicoScreen> createState() =>
      _Paso3AsignarTecnicoScreenState();
}

class _Paso3AsignarTecnicoScreenState extends State<Paso3AsignarTecnicoScreen> {
  int? _tecnicoSeleccionado;

  final _tecnicos = const [
    _Tecnico(id: 1, nombre: 'Juan Pérez García', disponible: true),
    _Tecnico(id: 2, nombre: 'Luis Mamani Condori', disponible: true),
    _Tecnico(id: 3, nombre: 'Carlos Rojas Mendoza', disponible: false),
    _Tecnico(id: 4, nombre: 'Miguel Ángel Torres', disponible: true),
  ];

  void _asignarme() {
    setState(() {
      _tecnicoSeleccionado = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ArmarRecorridoScaffold(
      paso: 3,
      subtitulo:
          'Paso 3: Seleccione el personal técnico disponible para cubrir este recorrido.',
      showBackButton: true,
      onBack: () => context.go('/asignador/recorrido/paso2'),
      primaryLabel: 'CONFIRMAR ASIGNACIÓN',
      primaryOnPressed: _tecnicoSeleccionado != null
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Asignación confirmada correctamente.'),
                ),
              );
            }
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tecnicos.length,
              itemBuilder: (context, index) {
                final tecnico = _tecnicos[index];
                final isSelected = _tecnicoSeleccionado == tecnico.id;
                final isAssignedSelf = _tecnicoSeleccionado == 0;

                return _TecnicoCard(
                  tecnico: tecnico,
                  isSelected: isSelected || isAssignedSelf && tecnico.disponible,
                  onTap: tecnico.disponible
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

class _Tecnico {
  const _Tecnico({
    required this.id,
    required this.nombre,
    required this.disponible,
  });

  final int id;
  final String nombre;
  final bool disponible;
}

class _TecnicoCard extends StatelessWidget {
  const _TecnicoCard({
    required this.tecnico,
    required this.isSelected,
    this.onTap,
  });

  final _Tecnico tecnico;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disponible = tecnico.disponible;

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
                    tecnico.nombre,
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
                    disponible ? 'Disponible' : 'Ocupado · Con ruta asignada',
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
