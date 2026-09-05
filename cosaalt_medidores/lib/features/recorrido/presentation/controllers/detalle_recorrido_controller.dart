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
    final usuario = ref.read(authControllerProvider).user;
    if (usuario == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No hay usuario autenticado.',
      );
      return;
    }

    final repository = ref.read(solicitudRepositoryProvider);

    // 1) Pintamos inmediatamente la copia local si existe. Esto evita que al
    // cortar Internet la pantalla quede esperando el timeout HTTP.
    try {
      final local = await repository.obtenerRutaActualTecnico(
        usuario.id,
        soloCache: true,
      );
      if (local != null) {
        state = state.copyWith(
          ruta: await _aplicarPendientesLocales(local, usuario.id),
          isLoading: false,
          errorMessage: null,
        );
      }
    } catch (_) {}

    // 2) Intentamos refrescar desde servidor. Si falla y ya había cache,
    // mantenemos la ruta local visible.
    try {
      final remota = await repository.obtenerRutaActualTecnico(usuario.id);
      if (remota == null) {
        if (state.ruta == null) {
          state = state.copyWith(ruta: null, isLoading: false, errorMessage: null);
        }
        return;
      }
      state = state.copyWith(
        ruta: await _aplicarPendientesLocales(remota, usuario.id),
        isLoading: false,
        errorMessage: null,
      );
    } catch (_) {
      if (state.ruta == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'No hay conexion y este tecnico todavia no tiene una ruta descargada.',
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<RutaAsignada> _aplicarPendientesLocales(
    RutaAsignada ruta,
    int idUsuario,
  ) async {
    final drafts = await ref
        .read(syncLocalServiceProvider)
        .cargarDraftsPendientes(idUsuarioApp: idUsuario);
    final idsPendientes = drafts.map((d) => d.solicitudId).toSet();

    final detallesActualizados = ruta.detalles.map((d) {
      if (!idsPendientes.contains(d.solicitudId)) return d;
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
        pendienteSincronizacion: true,
      );
    }).toList();

    return RutaAsignada(
      idAsignacion: ruta.idAsignacion,
      idUsuarioTecnico: ruta.idUsuarioTecnico,
      nombreTecnico: ruta.nombreTecnico,
      fechaAsignacion: ruta.fechaAsignacion,
      estado: ruta.estado,
      totalParadas: ruta.totalParadas,
      detalles: detallesActualizados,
    );
  }
}
