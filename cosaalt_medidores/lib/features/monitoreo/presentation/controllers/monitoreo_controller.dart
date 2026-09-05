import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../recorrido/domain/entities/ruta_asignada.dart';
import '../../../recorrido/presentation/controllers/solicitud_controller.dart';

class MonitoreoState {
  const MonitoreoState({
    this.rutas = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<RutaAsignada> rutas;
  final bool isLoading;
  final String? errorMessage;

  MonitoreoState copyWith({
    List<RutaAsignada>? rutas,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MonitoreoState(
      rutas: rutas ?? this.rutas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final monitoreoControllerProvider =
    NotifierProvider<MonitoreoController, MonitoreoState>(
      MonitoreoController.new,
    );

class MonitoreoController extends Notifier<MonitoreoState> {
  @override
  MonitoreoState build() => const MonitoreoState();

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final repository = ref.read(solicitudRepositoryProvider);
      // Sin filtro de fecha: el backend incluye rutas pendientes arrastradas
      // de otros días y las finalizadas hoy.
      final rutas = await repository.obtenerRutasActivas();
      rutas.sort((a, b) => b.fechaAsignacion.compareTo(a.fechaAsignacion));
      state = state.copyWith(rutas: rutas, isLoading: false, errorMessage: null);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: silencioso
            ? state.errorMessage
            : 'No se pudo actualizar el monitoreo de rutas.',
      );
    }
  }
}
