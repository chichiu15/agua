import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import 'ficha_verificacion_screen.dart';

final _enCursoProvider = FutureProvider.autoDispose<List<VerificacionMecanico>>((ref) {
  final id = ref.watch(authControllerProvider).user?.id;
  if (id == null) throw StateError('No se identificó al mecánico conectado.');
  return ref.watch(verificacionRepositoryProvider).obtenerEnCurso(id);
});

class VerificacionesEnCursoScreen extends ConsumerWidget {
  const VerificacionesEnCursoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificaciones = ref.watch(_enCursoProvider);
    Future<void> actualizar() async {
      ref.invalidate(_enCursoProvider);
      try {
        await ref.read(_enCursoProvider.future);
      } catch (_) {
        // El estado del proveedor muestra el error y permite reintentar.
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificaciones en curso'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: actualizar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: verificaciones.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: actualizar, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: actualizar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text('Mis verificaciones en curso: ${items.length}'),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No tienes verificaciones en curso.', textAlign: TextAlign.center),
                ),
              for (final v in items)
                Card(
                  child: ListTile(
                    title: Text(v.nombreCliente ?? 'Socio ${v.codCon}'),
                    subtitle: Text('Verificación #${v.id} · ${v.tipoOrigen}\n'
                        'Conexión: ${v.codCon} · Medidor: ${v.idMedidor ?? "No registrado"}\n'
                        'Estado: En curso'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      ref.read(verificacionControllerProvider.notifier).setVerificacion(v);
                      await Navigator.of(context).push<void>(MaterialPageRoute(
                        builder: (_) => FichaVerificacionScreen(id: v.id),
                      ));
                      if (context.mounted) await actualizar();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}