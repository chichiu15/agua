import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TecnicoDashboardScreen extends ConsumerWidget {
  const TecnicoDashboardScreen({super.key});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature se implementará con el módulo de Ruta del Día.',
        ),
      ),
    );
  }

  Future<void> _abrirFormularioPrueba(BuildContext context) async {
    String solicitudId = 'LEC-1001';

    final id = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Probar Cambio de Medidor'),
          content: TextFormField(
            initialValue: solicitudId,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'ID de solicitud',
              hintText: 'LEC-1001 u ODECO-2001',
            ),
            onChanged: (value) {
              solicitudId = value;
            },
            onFieldSubmitted: (value) {
              final idLimpio = value.trim();

              if (idLimpio.isNotEmpty) {
                Navigator.of(dialogContext).pop(idLimpio);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final idLimpio = solicitudId.trim();

                if (idLimpio.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(idLimpio);
              },
              child: const Text('Abrir'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    if (id == null || id.trim().isEmpty) {
      return;
    }

    context.go('/trabajo/cambio/${id.trim()}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () {
          ref.read(authControllerProvider.notifier).logout();
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Solicitudes Asignadas Por Hoy',
              style: TextStyle(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            const Row(
              children: [
                SummaryMetricCard(
                  value: '—',
                  label: 'ODECO',
                  valueColor: AppColors.odecoRed,
                ),
                SizedBox(width: 10),
                SummaryMetricCard(
                  value: '—',
                  label: 'Lectura',
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Text(
                    '—',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 31,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'COMPLETADAS HOY',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Atajos Rápidos',
              style: TextStyle(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            QuickActionTile(
              icon: Icons.route_outlined,
              label: 'Ver Mi Recorrido de Trabajo',
              onTap: () {
                _comingSoon(
                  context,
                  'Ruta del día',
                );
              },
            ),

            const SizedBox(height: 8),

            QuickActionTile(
              icon: Icons.build_circle_outlined,
              label: 'DESARROLLO · Probar Cambio de Medidor',
              onTap: () {
                _abrirFormularioPrueba(context);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CosaaltBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            return;
          }

          _comingSoon(
            context,
            'Esta sección',
          );
        },
      ),
    );
  }
}