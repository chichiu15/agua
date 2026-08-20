import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ArmarRecorridoScaffold extends ConsumerWidget {
  const ArmarRecorridoScaffold({
    required this.paso,
    required this.subtitulo,
    required this.body,
    required this.primaryLabel,
    this.primaryOnPressed,
    this.secondaryLabel = 'CANCELAR',
    this.secondaryOnPressed,
    this.showBackButton = false,
    this.onBack,
    super.key,
  });

  final int paso;
  final String subtitulo;
  final Widget body;
  final String primaryLabel;
  final VoidCallback? primaryOnPressed;
  final String secondaryLabel;
  final VoidCallback? secondaryOnPressed;
  final bool showBackButton;
  final VoidCallback? onBack;

  void _handleBottomNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/asignador');
        break;
      case 1:
        context.go('/asignador/recorrido/paso1');
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historial se implementará en el módulo correspondiente.'),
          ),
        );
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización se implementará en el módulo correspondiente.'),
          ),
        );
        break;
    }
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ARMAR RECORRIDO',
                      style: const TextStyle(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (showBackButton)
                    TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.chevron_left, size: 20),
                      label: const Text('Volver Atrás'),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.actionBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitulo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            Expanded(child: body),
            _ActionButtons(
              primaryLabel: primaryLabel,
              primaryOnPressed: primaryOnPressed,
              secondaryLabel: secondaryLabel,
              secondaryOnPressed: secondaryOnPressed,
            ),
          ],
        ),
      ),
      bottomNavigationBar: CosaaltBottomNav(
        currentIndex: 1,
        onTap: (index) => _handleBottomNavigation(context, index),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.primaryLabel,
    this.primaryOnPressed,
    required this.secondaryLabel,
    this.secondaryOnPressed,
  });

  final String primaryLabel;
  final VoidCallback? primaryOnPressed;
  final String secondaryLabel;
  final VoidCallback? secondaryOnPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: primaryOnPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                primaryLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: secondaryOnPressed ?? () => context.go('/asignador'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.odecoRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                secondaryLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
