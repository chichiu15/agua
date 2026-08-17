import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TecnicoDashboardScreen extends ConsumerWidget {
  const TecnicoDashboardScreen({super.key});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature se implementará en el siguiente sprint.'),
      ),
    );
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

            // Valores MOCK solamente para Sprint 1.
            const Row(
              children: [
                SummaryMetricCard(
                  value: '1',
                  label: 'ODECO',
                  valueColor: AppColors.odecoRed,
                ),
                SizedBox(width: 10),
                SummaryMetricCard(value: '3', label: 'Lectura'),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Text(
                    '0',
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
              onTap: () => _comingSoon(context, 'Ruta del día'),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CosaaltBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;

          _comingSoon(context, 'Esta sección');
        },
      ),
    );
  }
}
