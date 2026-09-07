import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/api_verificacion_repository.dart';
import '../../domain/entities/verificacion_mecanico.dart';

class VerificacionState {
  const VerificacionState({
    this.dashboard,
    this.solicitudes = const [],
    this.verificacionActual,
    this.datosSocio,
    this.participantesBorrador,
    this.informes = const [],
    this.informeRecienGenerado,
    this.historial,
    this.isLoading = false,
    this.isAccion = false,
    this.errorMessage,
    this.successMessage,
  });

  final MecanicoDashboard? dashboard;
  final List<SolicitudVerificacion> solicitudes;
  final VerificacionMecanico? verificacionActual;
  final DatosSocioMedidor? datosSocio;
  final List<ParticipanteVerificacion>? participantesBorrador;
  final List<InformeVerificacion> informes;
  final InformeVerificacion? informeRecienGenerado;
  final HistorialVerificacionResponse? historial;
  final bool isLoading;
  final bool isAccion;
  final String? errorMessage;
  final String? successMessage;

  VerificacionState copyWith({
    MecanicoDashboard? dashboard,
    List<SolicitudVerificacion>? solicitudes,
    VerificacionMecanico? verificacionActual,
    DatosSocioMedidor? datosSocio,
    List<ParticipanteVerificacion>? participantesBorrador,
    List<InformeVerificacion>? informes,
    InformeVerificacion? informeRecienGenerado,
    HistorialVerificacionResponse? historial,
    bool? isLoading,
    bool? isAccion,
    String? errorMessage,
    String? successMessage,
    bool limpiarVerificacion = false,
    bool limpiarMensajes = false,
  }) => VerificacionState(
    dashboard: dashboard ?? this.dashboard,
    solicitudes: solicitudes ?? this.solicitudes,
    verificacionActual: limpiarVerificacion
        ? null
        : (verificacionActual ?? this.verificacionActual),
    datosSocio: limpiarVerificacion ? null : (datosSocio ?? this.datosSocio),
    participantesBorrador: limpiarVerificacion
        ? null
        : (participantesBorrador ?? this.participantesBorrador),
    informes: informes ?? this.informes,
    informeRecienGenerado:
        informeRecienGenerado ?? this.informeRecienGenerado,
    historial: historial ?? this.historial,
    isLoading: isLoading ?? this.isLoading,
    isAccion: isAccion ?? this.isAccion,
    errorMessage: limpiarMensajes ? null : (errorMessage ?? this.errorMessage),
    successMessage:
        limpiarMensajes ? null : (successMessage ?? this.successMessage),
  );
}

final verificacionRepositoryProvider = Provider<ApiVerificacionRepository>(
  (ref) => ApiVerificacionRepository(),
);

final verificacionControllerProvider =
    NotifierProvider<VerificacionController, VerificacionState>(
      VerificacionController.new,
    );

class VerificacionController extends Notifier<VerificacionState> {
  int _historialRequestId = 0;

  @override
  VerificacionState build() => const VerificacionState();

  ApiVerificacionRepository get _repo =>
      ref.read(verificacionRepositoryProvider);

  int? get _idMecanico => ref.read(authControllerProvider).user?.id;

  void limpiarMensajes() => state = state.copyWith(limpiarMensajes: true);

  String _error(
    Object error, {
    required String fallback,
  }) => mensajeVerificacionError(error, fallback: fallback);

  void guardarParticipantesBorrador(
    List<ParticipanteVerificacion> participantes,
  ) {
    String? nulo(String? value) {
      final s = value?.trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final limpios = participantes
        .where((p) => p.nombre.trim().isNotEmpty)
        .map(
          (p) => ParticipanteVerificacion(
            nombre: p.nombre.trim(),
            cargo: nulo(p.cargo),
            rol: nulo(p.rol),
          ),
        )
        .toList();

    state = state.copyWith(
      participantesBorrador: limpios,
      successMessage: limpios.isEmpty
          ? null
          : 'Participantes guardados: ${limpios.length}.',
    );
  }

  void setVerificacion(VerificacionMecanico v) =>
      state = state.copyWith(verificacionActual: v);

  Future<String?> guardarParticipantes(
    int idVerificacion,
    List<ParticipanteVerificacion> participantes,
  ) async {
    try {
      state = state.copyWith(isAccion: true, limpiarMensajes: true);

      final actualizada = await _repo.guardarParticipantes(
        idVerificacion,
        participantes,
      );

      state = state.copyWith(
        verificacionActual: actualizada,
        participantesBorrador: null,
        isAccion: false,
        successMessage: 'Participantes guardados correctamente.',
      );

      return null;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudieron guardar los participantes.',
      );

      state = state.copyWith(
        isAccion: false,
        errorMessage: mensaje,
      );

      return mensaje;
    }
  }

  Future<String?> cargarDashboard() async {
    final id = _idMecanico;
    if (id == null) {
      return 'No se identificó al mecánico que inició sesión.';
    }

    try {
      state = state.copyWith(isLoading: true, limpiarMensajes: true);

      final dashboard = await _repo.obtenerDashboard(id);

      state = state.copyWith(
        dashboard: dashboard,
        isLoading: false,
      );

      return null;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudo cargar el inicio del mecánico.',
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: mensaje,
      );

      return mensaje;
    }
  }

  Future<String?> cargarSolicitudes() async {
    try {
      state = state.copyWith(isLoading: true, limpiarMensajes: true);

      final solicitudes = await _repo.obtenerSolicitudes();

      state = state.copyWith(
        solicitudes: solicitudes,
        isLoading: false,
      );

      return null;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudieron cargar las solicitudes.',
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: mensaje,
      );

      return mensaje;
    }
  }

  Future<String?> tomarVerificacion({
    required String tipoOrigen,
    required String idOrigen,
    required int codCon,
    String? idMedidor,
  }) async {
    final id = _idMecanico;
    if (id == null) {
      return 'No se identificó al mecánico que inició sesión.';
    }

    try {
      state = state.copyWith(isAccion: true, limpiarMensajes: true);

      final idVerificacion = await _repo.tomarVerificacion(
        tipoOrigen: tipoOrigen,
        idOrigen: idOrigen,
        codCon: codCon,
        idUsuarioMecanico: id,
        idMedidor: idMedidor,
      );

      await cargarSolicitudes();
      await _cargarVerificacion(idVerificacion);

      state = state.copyWith(
        isAccion: false,
        successMessage: 'Verificación tomada correctamente.',
      );

      return null;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudo tomar la solicitud.',
      );

      state = state.copyWith(
        isAccion: false,
        errorMessage: mensaje,
      );

      return mensaje;
    }
  }

  Future<String?> _cargarVerificacion(int id) async {
    try {
      final verificacion = await _repo.obtenerVerificacion(id);

      DatosSocioMedidor? datos;
      try {
        datos = await _repo.obtenerDatosSocioMedidor(id);
      } catch (_) {
        // La ficha principal puede seguir mostrándose aunque los datos
        // institucionales no estén disponibles temporalmente.
      }

      state = state.copyWith(
        verificacionActual: verificacion,
        datosSocio: datos,
      );

      return null;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudo cargar la verificación.',
      );

      state = state.copyWith(errorMessage: mensaje);
      return mensaje;
    }
  }

  Future<String?> cargarVerificacion(int id) async {
    try {
      state = state.copyWith(isLoading: true, limpiarMensajes: true);

      final error = await _cargarVerificacion(id);

      state = state.copyWith(isLoading: false);
      return error;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudo cargar la verificación.',
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: mensaje,
      );

      return mensaje;
    }
  }

  Future<CalculoEnsayo?> calcularEnsayo(
    Map<String, dynamic> request,
  ) async {
    try {
      final calculo = await _repo.calcularEnsayo(request);

      if (calculo.resultado == 'INDETERMINADO' &&
          calculo.parametroNormativo == null) {
        state = state.copyWith(
          errorMessage:
              'No existe parámetro normativo para este caudal. El resultado queda INDETERMINADO.',
        );
      }

      return calculo;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudo calcular el ensayo.',
      );

      state = state.copyWith(errorMessage: mensaje);
      return null;
    }
  }

  Future<EnsayoGuardadoResultado?> guardarEnsayo(
    int idVerificacion,
    Map<String, dynamic> request,
  ) async {
    try {
      state = state.copyWith(isAccion: true, limpiarMensajes: true);

      final result = await _repo.guardarEnsayo(
        idVerificacion,
        request,
      );

      await _cargarVerificacion(idVerificacion);

      state = state.copyWith(
        isAccion: false,
        successMessage: result.mensaje,
      );

      return result;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudo guardar el ensayo.',
      );

      state = state.copyWith(
        isAccion: false,
        errorMessage: mensaje,
      );

      return null;
    }
  }

  Future<bool> finalizar(int idVerificacion) async {
    try {
      state = state.copyWith(isAccion: true, limpiarMensajes: true);

      final verificacion = await _repo.finalizar(idVerificacion);

      state = state.copyWith(
        isAccion: false,
        verificacionActual: verificacion,
        successMessage: 'Verificación finalizada correctamente.',
      );

      return true;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudo finalizar la verificación.',
      );

      state = state.copyWith(
        isAccion: false,
        errorMessage: mensaje,
      );

      return false;
    }
  }

  Future<String?> cargarInformes(int idVerificacion) async {
    try {
      final informes = await _repo.obtenerInformes(idVerificacion);

      state = state.copyWith(
        informes: informes,
        informeRecienGenerado: informes.isEmpty ? null : informes.first,
      );

      return null;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudieron cargar los informes.',
      );

      state = state.copyWith(errorMessage: mensaje);
      return mensaje;
    }
  }

  Future<InformeVerificacion?> generarInforme(
    int idVerificacion, {
    String? observaciones,
    String? nombreResponsable,
    String? cargoResponsable,
    String? nombreDestinatario,
    String? cargoDestinatario,
    String? referencia,
    String? lugarVerificacion,
    String? tipoEnsayoTexto,
    String? descripcionTecnica,
    String? conclusionAdicional,
    String? recomendacion,
  }) async {
    try {
      state = state.copyWith(isAccion: true, limpiarMensajes: true);

      final informe = await _repo.generarInforme(
        idVerificacion,
        observaciones: observaciones,
        nombreResponsable: nombreResponsable,
        cargoResponsable: cargoResponsable,
        nombreDestinatario: nombreDestinatario,
        cargoDestinatario: cargoDestinatario,
        referencia: referencia,
        lugarVerificacion: lugarVerificacion,
        tipoEnsayoTexto: tipoEnsayoTexto,
        descripcionTecnica: descripcionTecnica,
        conclusionAdicional: conclusionAdicional,
        recomendacion: recomendacion,
      );

      await cargarInformes(idVerificacion);

      state = state.copyWith(
        isAccion: false,
        informeRecienGenerado: informe,
        successMessage: 'Informe generado correctamente.',
      );

      return informe;
    } catch (e) {
      final mensaje = _error(
        e,
        fallback: 'No se pudo generar el informe.',
      );

      state = state.copyWith(
        isAccion: false,
        errorMessage: mensaje,
      );

      return null;
    }
  }

  Future<String?> cargarHistorial({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    String? resultado,
    String? buscar,
    int page = 1,
    int pageSize = 20,
  }) async {
    final id = _idMecanico;
    if (id == null) {
      return 'No se identificó al mecánico que inició sesión.';
    }

    // M9: evita que una búsqueda anterior, más lenta, reemplace
    // los resultados de una búsqueda más reciente.
    final requestId = ++_historialRequestId;

    try {
      state = state.copyWith(
        isLoading: true,
        limpiarMensajes: true,
      );

      final historial = await _repo.obtenerHistorial(
        id,
        desde: desde,
        hasta: hasta,
        estado: estado,
        resultado: resultado,
        buscar: buscar,
        page: page,
        pageSize: pageSize,
      );

      if (requestId != _historialRequestId) {
        return null;
      }

      state = state.copyWith(
        historial: historial,
        isLoading: false,
      );

      return null;
    } catch (e) {
      if (requestId != _historialRequestId) {
        return null;
      }

      final mensaje = _error(
        e,
        fallback: 'No se pudo cargar el historial.',
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: mensaje,
      );

      return mensaje;
    }
  }
}
