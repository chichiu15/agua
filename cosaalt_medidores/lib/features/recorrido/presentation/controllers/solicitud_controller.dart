import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/solicitud.dart';
import '../../domain/entities/tecnico.dart';
import '../../domain/repositories/solicitud_repository.dart';
import '../../data/repositories/api_solicitud_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SolicitudState {
  const SolicitudState({
    this.resumen,
    this.solicitudes = const [],
    this.tecnicos = const [],
    this.seleccionadas = const {},
    this.isLoading = false,
    this.isAsignando = false,
    this.errorMessage,
    this.exitoMessage,
  });

  final DashboardResumen? resumen;
  final List<Solicitud> solicitudes;
  final List<Tecnico> tecnicos;
  final Set<String> seleccionadas;
  final bool isLoading;
  final bool isAsignando;
  final String? errorMessage;
  final String? exitoMessage;

  SolicitudState copyWith({
    DashboardResumen? resumen,
    List<Solicitud>? solicitudes,
    List<Tecnico>? tecnicos,
    Set<String>? seleccionadas,
    bool? isLoading,
    bool? isAsignando,
    String? errorMessage,
    String? exitoMessage,
  }) {
    return SolicitudState(
      resumen: resumen ?? this.resumen,
      solicitudes: solicitudes ?? this.solicitudes,
      tecnicos: tecnicos ?? this.tecnicos,
      seleccionadas: seleccionadas ?? this.seleccionadas,
      isLoading: isLoading ?? this.isLoading,
      isAsignando: isAsignando ?? this.isAsignando,
      errorMessage: errorMessage,
      exitoMessage: exitoMessage,
    );
  }
}

final solicitudRepositoryProvider = Provider<SolicitudRepository>((ref) {
  return ApiSolicitudRepository();
});

final solicitudControllerProvider =
    NotifierProvider<SolicitudController, SolicitudState>(
  SolicitudController.new,
);

class SolicitudController extends Notifier<SolicitudState> {
  @override
  SolicitudState build() {
    return const SolicitudState();
  }

  Future<void> cargarDatos() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(solicitudRepositoryProvider);

      final results = await Future.wait([
        repository.obtenerSolicitudes(),
        repository.obtenerTecnicos(),
      ]);

      final solicitudesResponse = results[0] as SolicitudesResponse;
      final tecnicos = results[1] as List<Tecnico>;

      state = state.copyWith(
        resumen: solicitudesResponse.resumen,
        solicitudes: solicitudesResponse.solicitudes,
        tecnicos: tecnicos,
        isLoading: false,
      );
    } on SolicitudException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al cargar datos.',
      );
    }
  }

  void toggleSeleccion(String solicitudId) {
    final nuevas = Set<String>.from(state.seleccionadas);
    if (nuevas.contains(solicitudId)) {
      nuevas.remove(solicitudId);
    } else {
      nuevas.add(solicitudId);
    }
    state = state.copyWith(seleccionadas: nuevas);
  }

  Future<bool> asignarRuta(int idTecnico) async {
    state = state.copyWith(isAsignando: true, errorMessage: null, exitoMessage: null);

    try {
      final authUser = ref.read(authControllerProvider).user;
      if (authUser == null) {
        state = state.copyWith(isAsignando: false, errorMessage: 'No hay usuario autenticado.');
        return false;
      }

      final solicitudesSeleccionadas = state.solicitudes
          .where((s) => state.seleccionadas.contains(s.id))
          .toList();

      if (solicitudesSeleccionadas.isEmpty) {
        state = state.copyWith(isAsignando: false, errorMessage: 'No hay solicitudes seleccionadas.');
        return false;
      }

      final repository = ref.read(solicitudRepositoryProvider);
      await repository.asignarRuta(AsignarRutaParams(
        idUsuarioAsignador: authUser.id,
        idUsuarioTecnico: idTecnico,
        solicitudes: solicitudesSeleccionadas,
      ));

      state = state.copyWith(
        isAsignando: false,
        seleccionadas: {},
        exitoMessage: 'Asignación confirmada correctamente.',
      );
      return true;
    } on SolicitudException catch (e) {
      state = state.copyWith(isAsignando: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isAsignando: false,
        errorMessage: 'Error inesperado al asignar ruta.',
      );
      return false;
    }
  }

  List<Solicitud> get solicitudesFiltradas {
    return state.solicitudes
        .where((s) => state.seleccionadas.contains(s.id))
        .toList();
  }
}
