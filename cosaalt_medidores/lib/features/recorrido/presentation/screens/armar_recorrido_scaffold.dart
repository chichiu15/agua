import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class ArmarRecorridoScaffold extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_cosaalt.png',
              height: 42,
              width: 42,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 34,
                );
              },
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COSAALT',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Text(
                  'Módulo Medidores',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, size: 30),
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                      style: TextStyle(
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
