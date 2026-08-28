import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_historial_repository.dart';
import '../../domain/entities/ejecucion_historial.dart';

final historialRepositoryProvider = Provider<ApiHistorialRepository>(
  (ref) => ApiHistorialRepository(),
);

class HistorialState {
  const HistorialState({
    this.ejecuciones = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<EjecucionHistorial> ejecuciones;
  final bool isLoading;
  final String? errorMessage;

  HistorialState copyWith({
    List<EjecucionHistorial>? ejecuciones,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HistorialState(
      ejecuciones: ejecuciones ?? this.ejecuciones,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final historialControllerProvider =
    NotifierProvider<HistorialController, HistorialState>(
      HistorialController.new,
    );

class HistorialController extends Notifier<HistorialState> {
  @override
  HistorialState build() => const HistorialState();

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(historialRepositoryProvider);
      final ejecuciones = await repository.obtenerHistorial();
      state = state.copyWith(ejecuciones: ejecuciones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
