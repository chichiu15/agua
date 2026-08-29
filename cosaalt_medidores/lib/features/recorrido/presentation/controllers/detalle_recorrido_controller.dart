import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../sincronizacion/presentation/controllers/sync_controller.dart';
import '../../domain/entities/ruta_asignada.dart';
import 'solicitud_controller.dart';

class DetalleRecorridoState {
  const DetalleRecorridoState({
    this.ruta,
    this.isLoading = false,
    this.errorMessage,
  });

  final RutaAsignada? ruta;
  final bool isLoading;
  final String? errorMessage;

  DetalleRecorridoState copyWith({
    RutaAsignada? ruta,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DetalleRecorridoState(
      ruta: ruta ?? this.ruta,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final detalleRecorridoControllerProvider =
    NotifierProvider<DetalleRecorridoController, DetalleRecorridoState>(
      DetalleRecorridoController.new,
    );

class DetalleRecorridoController extends Notifier<DetalleRecorridoState> {
  @override
  DetalleRecorridoState build() => const DetalleRecorridoState();

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final usuario = ref.read(authControllerProvider).user;
      if (usuario == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No hay usuario autenticado.',
        );
        return;
      }

      final repository = ref.read(solicitudRepositoryProvider);
      final rutas = await repository.obtenerRutasTecnico(usuario.id);

      // Si el técnico tiene varias asignaciones hoy, mostramos la más reciente.
      final ordenadas = [...rutas]
        ..sort((a, b) => b.fechaAsignacion.compareTo(a.fechaAsignacion));
      final ruta = ordenadas.isEmpty ? null : ordenadas.first;

      // Opción A: una parada ejecutada localmente (draft pendiente de sync)
      // ya cuenta como "Completada" en el dispositivo, aunque el servidor
      // todavía la tenga como pendiente.
      if (ruta != null) {
        final drafts = await ref
            .read(syncLocalServiceProvider)
            .cargarDraftsPendientes();
        final idsPendientes = drafts.map((d) => d.solicitudId).toSet();

        final detallesActualizados = ruta.detalles.map((d) {
          if (idsPendientes.contains(d.solicitudId)) {
            return DetalleRutaAsignada(
              id: d.id,
              solicitudId: d.solicitudId,
              tipoOrigen: d.tipoOrigen,
              ordenVisita: d.ordenVisita,
              estado: 'Completada',
              nombreCliente: d.nombreCliente,
              direccion: d.direccion,
              latitud: d.latitud,
              longitud: d.longitud,
              esUrgente: d.esUrgente,
              codCon: d.codCon,
              numeroMedidor: d.numeroMedidor,
            );
          }
          return d;
        }).toList();

        final rutaConLocales = RutaAsignada(
          idAsignacion: ruta.idAsignacion,
          idUsuarioTecnico: ruta.idUsuarioTecnico,
          nombreTecnico: ruta.nombreTecnico,
          fechaAsignacion: ruta.fechaAsignacion,
          estado: ruta.estado,
          totalParadas: ruta.totalParadas,
          detalles: detallesActualizados,
        );
        state = state.copyWith(ruta: rutaConLocales, isLoading: false);
      } else {
        state = state.copyWith(ruta: ruta, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
