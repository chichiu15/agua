import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';

class MecanicoHomeScreen extends ConsumerWidget {
  const MecanicoHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('COSAALT - Modulo Mecanico'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(user?.fullName ?? 'Mecanico')),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.precision_manufacturing_outlined, size: 68, color: Color(0xFF006B3F)),
                  const SizedBox(height: 16),
                  const Text('Acceso de mecanico habilitado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'R1 ya reconoce y protege el rol mecanico. Esta pantalla es un punto de entrada temporal para no invadir el frontend que Manuel desarrollara para M1-M21.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  const Text('El backend de verificaciones M1-M5 permanece intacto en este paquete.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
