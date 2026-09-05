import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_historial_repository.dart';
import '../../domain/entities/ejecucion_historial.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../sincronizacion/presentation/controllers/sync_controller.dart';

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

    final usuario = ref.read(authControllerProvider).user;
    if (usuario == null) {
      state = const HistorialState(errorMessage: 'No hay una sesión activa.');
      return;
    }

    final drafts = await ref
        .read(syncLocalServiceProvider)
        .cargarDraftsPendientes(idUsuarioApp: usuario.id);
    final locales = drafts.map((d) => EjecucionHistorial(
          idEjecucion: -d.fechaHoraEjecucion.millisecondsSinceEpoch,
          tipoOrigen: d.tipoOrigen,
          idOrigen: d.idOrigen,
          solicitudId: d.solicitudId,
          fechaHoraEjecucion: d.fechaHoraEjecucion,
          codCon: d.codCon,
          nombreCliente: d.nombreSocio,
          direccion: d.direccion,
          numeroMedidorRetirado: d.numeroMedidorRetirado,
          marcaRetirado: d.marcaRetirado,
          lecturaRetiro: d.lecturaRetiro,
          numeroMedidorInstalado: d.numeroMedidorInstalado,
          marcaInstalado: d.marcaInstalado,
          observaciones: d.observaciones,
          nombreTecnico: usuario.fullName,
          motivoDescripcion: 'Motivo #${d.idMotivo}',
          evidencias: [
            if (d.fotoMedidorRetirado?.trim().isNotEmpty == true)
              EvidenciaHistorial(tipoFoto: 'MedidorRetirado', rutaArchivo: d.fotoMedidorRetirado!),
            if (d.fotoMedidorNuevo?.trim().isNotEmpty == true)
              EvidenciaHistorial(tipoFoto: 'MedidorNuevo', rutaArchivo: d.fotoMedidorNuevo!),
          ],
          sincronizado: false,
        )).toList();

    // Mostrar primero lo local hace que Historial funcione aun sin Internet.
    state = state.copyWith(ejecuciones: locales, isLoading: locales.isEmpty);

    try {
      final repository = ref.read(historialRepositoryProvider);
      final remotas = await repository.obtenerHistorial(idUsuarioApp: usuario.id);
      final ejecuciones = [...locales, ...remotas]
        ..sort((a, b) => b.fechaHoraEjecucion.compareTo(a.fechaHoraEjecucion));
      state = state.copyWith(ejecuciones: ejecuciones, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        ejecuciones: locales,
        isLoading: false,
        errorMessage: locales.isEmpty
            ? e.toString()
            : 'Sin conexión: se muestran los trabajos pendientes guardados en este dispositivo.',
      );
    }
  }
}
