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

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(solicitudRepositoryProvider);
      final tecnicos = await repository.obtenerTecnicos();
      final usuarioActual = ref.read(authControllerProvider).user;

      // El endpoint /usuarios/tecnicos sólo devuelve técnicos. Como el
      // asignador también puede usar "Asignarme a mí", agregamos explícitamente
      // al usuario autenticado para consultar también sus rutas.
      final idsUsuarios = <int>{
        ...tecnicos.where((t) => t.activo).map((t) => t.id),
        if (usuarioActual != null && usuarioActual.active) usuarioActual.id,
      };

      final resultados = await Future.wait(
        idsUsuarios.map(
          (idUsuario) => repository.obtenerRutasTecnico(idUsuario),
        ),
      );

      // Evita duplicados si en algún momento el usuario actual también aparece
      // en el listado retornado por la API.
      final porId = <int, RutaAsignada>{};
      for (final ruta in resultados.expand((r) => r)) {
        porId[ruta.idAsignacion] = ruta;
      }

      final rutas = porId.values.toList()
        ..sort((a, b) => b.fechaAsignacion.compareTo(a.fechaAsignacion));

      state = state.copyWith(rutas: rutas, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
