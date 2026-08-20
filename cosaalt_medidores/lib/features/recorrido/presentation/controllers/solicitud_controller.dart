import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/api_solicitud_repository.dart';
import '../../domain/entities/solicitud.dart';
import '../../domain/entities/tecnico.dart';
import '../../domain/repositories/solicitud_repository.dart';

class SolicitudState {
  const SolicitudState({
    this.resumen,
    this.solicitudes = const [],
    this.tecnicos = const [],
    this.seleccionadas = const {},
    this.ordenSeleccionadas = const [],
    this.isLoading = false,
    this.isAsignando = false,
    this.errorMessage,
    this.exitoMessage,
  });

  final DashboardResumen? resumen;
  final List<Solicitud> solicitudes;
  final List<Tecnico> tecnicos;
  final Set<String> seleccionadas;
  final List<String> ordenSeleccionadas;
  final bool isLoading;
  final bool isAsignando;
  final String? errorMessage;
  final String? exitoMessage;

  SolicitudState copyWith({
    DashboardResumen? resumen,
    List<Solicitud>? solicitudes,
    List<Tecnico>? tecnicos,
    Set<String>? seleccionadas,
    List<String>? ordenSeleccionadas,
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
      ordenSeleccionadas: ordenSeleccionadas ?? this.ordenSeleccionadas,
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

      final idsDisponibles = solicitudesResponse.solicitudes
          .where((s) => s.estado.trim().toLowerCase() == 'pendiente')
          .map((s) => s.id)
          .toSet();

      final seleccionadasValidas = state.seleccionadas
          .where(idsDisponibles.contains)
          .toSet();

      final ordenValido = state.ordenSeleccionadas
          .where(seleccionadasValidas.contains)
          .toList();

      for (final id in seleccionadasValidas) {
        if (!ordenValido.contains(id)) {
          ordenValido.add(id);
        }
      }

      state = state.copyWith(
        resumen: solicitudesResponse.resumen,
        solicitudes: solicitudesResponse.solicitudes,
        tecnicos: tecnicos,
        seleccionadas: seleccionadasValidas,
        ordenSeleccionadas: ordenValido,
        isLoading: false,
      );
    } on SolicitudException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al cargar datos.',
      );
    }
  }

  void toggleSeleccion(String solicitudId) {
    final nuevas = Set<String>.from(state.seleccionadas);
    final nuevoOrden = List<String>.from(state.ordenSeleccionadas);

    if (nuevas.contains(solicitudId)) {
      nuevas.remove(solicitudId);
      nuevoOrden.remove(solicitudId);
    } else {
      nuevas.add(solicitudId);
      nuevoOrden.add(solicitudId);
    }

    state = state.copyWith(
      seleccionadas: nuevas,
      ordenSeleccionadas: nuevoOrden,
    );
  }

  void guardarOrden(List<String> idsOrdenados) {
    final idsSeleccionados = state.seleccionadas;
    final ordenLimpio = idsOrdenados
        .where(idsSeleccionados.contains)
        .toList();

    for (final id in idsSeleccionados) {
      if (!ordenLimpio.contains(id)) {
        ordenLimpio.add(id);
      }
    }

    state = state.copyWith(ordenSeleccionadas: ordenLimpio);
  }

  Future<bool> asignarRuta(int idUsuarioDestino) async {
    state = state.copyWith(
      isAsignando: true,
      errorMessage: null,
      exitoMessage: null,
    );

    try {
      final authUser = ref.read(authControllerProvider).user;
      if (authUser == null) {
        state = state.copyWith(
          isAsignando: false,
          errorMessage: 'No hay usuario autenticado.',
        );
        return false;
      }

      final porId = {
        for (final solicitud in state.solicitudes) solicitud.id: solicitud,
      };

      final solicitudesOrdenadas = state.ordenSeleccionadas
          .where(state.seleccionadas.contains)
          .map((id) => porId[id])
          .whereType<Solicitud>()
          .toList();

      if (solicitudesOrdenadas.isEmpty) {
        state = state.copyWith(
          isAsignando: false,
          errorMessage: 'No hay solicitudes seleccionadas.',
        );
        return false;
      }

      final repository = ref.read(solicitudRepositoryProvider);
      await repository.asignarRuta(
        AsignarRutaParams(
          idUsuarioAsignador: authUser.id,
          idUsuarioTecnico: idUsuarioDestino,
          solicitudes: solicitudesOrdenadas,
        ),
      );

      state = state.copyWith(
        seleccionadas: {},
        ordenSeleccionadas: [],
        exitoMessage: 'Asignación confirmada correctamente.',
      );

      // Refresca contra API para que la solicitud recién asignada deje de
      // aparecer disponible y el técnico cambie inmediatamente a ocupado.
      await cargarDatos();

      state = state.copyWith(
        isAsignando: false,
        exitoMessage: 'Asignación confirmada correctamente.',
      );

      return true;
    } on SolicitudException catch (e) {
      state = state.copyWith(
        isAsignando: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isAsignando: false,
        errorMessage: 'Error inesperado al asignar ruta.',
      );
      return false;
    }
  }

  List<Solicitud> get solicitudesSeleccionadasOrdenadas {
    final porId = {
      for (final solicitud in state.solicitudes) solicitud.id: solicitud,
    };

    return state.ordenSeleccionadas
        .where(state.seleccionadas.contains)
        .map((id) => porId[id])
        .whereType<Solicitud>()
        .toList();
  }
}
