import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../recorrido/domain/entities/solicitud.dart';
import '../../data/repositories/ejecucion_repository_impl.dart';
import '../../data/services/evidencia_local_service.dart';
import '../../domain/entities/cambio_medidor.dart';
import '../../domain/repositories/ejecucion_repository.dart';

class CambioMedidorState {
  const CambioMedidorState({
    this.solicitud,
    this.motivos = const [],
    this.fotoRetirado,
    this.fotoNuevo,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.archivoLocal,
  });

  final Solicitud? solicitud;
  final List<MotivoCambio> motivos;
  final String? fotoRetirado;
  final String? fotoNuevo;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final String? archivoLocal;

  CambioMedidorState copyWith({
    Solicitud? solicitud,
    List<MotivoCambio>? motivos,
    String? fotoRetirado,
    String? fotoNuevo,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    String? archivoLocal,
    bool clearFotoRetirado = false,
    bool clearFotoNuevo = false,
  }) {
    return CambioMedidorState(
      solicitud: solicitud ?? this.solicitud,
      motivos: motivos ?? this.motivos,
      fotoRetirado:
          clearFotoRetirado ? null : (fotoRetirado ?? this.fotoRetirado),
      fotoNuevo: clearFotoNuevo ? null : (fotoNuevo ?? this.fotoNuevo),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      archivoLocal: archivoLocal ?? this.archivoLocal,
    );
  }
}

final ejecucionRepositoryProvider = Provider<EjecucionRepository>((ref) {
  return EjecucionRepositoryImpl();
});

final evidenciaLocalServiceProvider = Provider<EvidenciaLocalService>((ref) {
  return EvidenciaLocalService();
});

final cambioMedidorControllerProvider =
    NotifierProvider<CambioMedidorController, CambioMedidorState>(
  CambioMedidorController.new,
);

class CambioMedidorController extends Notifier<CambioMedidorState> {
  @override
  CambioMedidorState build() => const CambioMedidorState();

  Future<void> cargar(String solicitudId) async {
    state = const CambioMedidorState(isLoading: true);

    try {
      final repository = ref.read(ejecucionRepositoryProvider);
      final results = await Future.wait([
        repository.obtenerSolicitud(solicitudId),
        repository.obtenerMotivos(),
      ]);

      state = CambioMedidorState(
        solicitud: results[0] as Solicitud,
        motivos: results[1] as List<MotivoCambio>,
      );
    } on EjecucionException catch (e) {
      state = CambioMedidorState(errorMessage: e.message);
    } catch (e) {
      state = CambioMedidorState(
        errorMessage: 'Error inesperado al cargar el formulario: $e',
      );
    }
  }

  Future<void> tomarFotoRetirado() async {
    final solicitud = state.solicitud;
    if (solicitud == null) return;

    try {
      final path = await ref.read(evidenciaLocalServiceProvider).capturarYComprimir(
            solicitudId: solicitud.id,
            tipoFoto: 'medidor_retirado',
          );
      if (path != null) state = state.copyWith(fotoRetirado: path);
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudo guardar la foto: $e');
    }
  }

  Future<void> tomarFotoNuevo() async {
    final solicitud = state.solicitud;
    if (solicitud == null) return;

    try {
      final path = await ref.read(evidenciaLocalServiceProvider).capturarYComprimir(
            solicitudId: solicitud.id,
            tipoFoto: 'medidor_nuevo',
          );
      if (path != null) state = state.copyWith(fotoNuevo: path);
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudo guardar la foto: $e');
    }
  }

  Future<bool> guardarLocal({
    required String lecturaRetiroTexto,
    required int? idMotivo,
    required String numeroNuevo,
    required String marcaNueva,
    required String estadoNuevo,
    required String observaciones,
  }) async {
    final solicitud = state.solicitud;
    final user = ref.read(authControllerProvider).user;

    if (solicitud == null || user == null) {
      state = state.copyWith(errorMessage: 'Faltan datos de sesión o solicitud.');
      return false;
    }

    final lectura = double.tryParse(lecturaRetiroTexto.replaceAll(',', '.'));

    if (solicitud.numeroMedidor == null || solicitud.numeroMedidor!.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'La solicitud no tiene un medidor activo asociado.',
      );
      return false;
    }
    if (lectura == null || lectura < 0) {
      state = state.copyWith(errorMessage: 'Ingrese una lectura de retiro válida.');
      return false;
    }
    if (idMotivo == null) {
      state = state.copyWith(errorMessage: 'Seleccione el motivo del cambio.');
      return false;
    }
    if (numeroNuevo.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Ingrese el número del medidor instalado.');
      return false;
    }
    if (numeroNuevo.trim().toLowerCase() == solicitud.numeroMedidor!.trim().toLowerCase()) {
      state = state.copyWith(
        errorMessage: 'El medidor nuevo debe ser distinto al retirado.',
      );
      return false;
    }
    if (marcaNueva.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Ingrese la marca del medidor instalado.');
      return false;
    }
    if (state.fotoRetirado == null || state.fotoNuevo == null) {
      state = state.copyWith(
        errorMessage: 'Debe registrar las dos fotografías de respaldo.',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final idOrigen = solicitud.folioOdeco?.toString() ??
          solicitud.id.replaceFirst('LEC-', '');
      final now = DateTime.now();
      final localId = '${solicitud.id}_${now.microsecondsSinceEpoch}'
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      final draft = CambioMedidorDraft(
        localId: localId,
        solicitudId: solicitud.id,
        tipoOrigen: solicitud.tipoOrigen,
        idOrigen: idOrigen,
        idUsuarioApp: user.id,
        fechaHoraEjecucion: now,
        registroSocio: solicitud.registroSocio,
        nombreSocio: solicitud.nombreCliente,
        direccion: solicitud.direccion,
        numeroMedidorRetirado: solicitud.numeroMedidor!,
        marcaRetirado: solicitud.marcaMedidor,
        lecturaRetiro: lectura,
        idMotivo: idMotivo,
        numeroMedidorInstalado: numeroNuevo.trim(),
        marcaInstalado: marcaNueva.trim(),
        estadoMedidorInstalado: estadoNuevo,
        observaciones: observaciones.trim().isEmpty ? null : observaciones.trim(),
        fotoMedidorRetirado: state.fotoRetirado!,
        fotoMedidorNuevo: state.fotoNuevo!,
        latitud: solicitud.latitud,
        longitud: solicitud.longitud,
      );

      final path = await ref.read(ejecucionRepositoryProvider).guardarLocal(draft);

      state = state.copyWith(
        isSaving: false,
        archivoLocal: path,
        successMessage:
            'Datos guardados localmente. Quedaron pendientes de sincronización.',
      );
      return true;
    } on EjecucionException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No se pudo guardar localmente: $e',
      );
      return false;
    }
  }
}
