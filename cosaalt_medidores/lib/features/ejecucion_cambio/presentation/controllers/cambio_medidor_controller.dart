import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../recorrido/domain/entities/solicitud.dart';
import '../../../recorrido/presentation/controllers/detalle_recorrido_controller.dart';
import '../../../sincronizacion/presentation/controllers/sync_controller.dart';
import '../../data/repositories/ejecucion_repository_impl.dart';
import '../../data/services/evidencia_local_service.dart';
import '../../domain/entities/cambio_medidor.dart';
import '../../domain/repositories/ejecucion_repository.dart';

class CambioMedidorState {
  const CambioMedidorState({
    this.solicitud,
    this.motivos = const [],
    this.medidoresDisponibles = const [],
    this.fotoRetirado,
    this.fotoNuevo,
    this.isLoading = false,
    this.isSearchingMeters = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.archivoLocal,
  });

  final Solicitud? solicitud;
  final List<MotivoCambio> motivos;
  final List<MedidorDisponible> medidoresDisponibles;
  final String? fotoRetirado;
  final String? fotoNuevo;
  final bool isLoading;
  final bool isSearchingMeters;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final String? archivoLocal;

  CambioMedidorState copyWith({
    Solicitud? solicitud,
    List<MotivoCambio>? motivos,
    List<MedidorDisponible>? medidoresDisponibles,
    String? fotoRetirado,
    String? fotoNuevo,
    bool? isLoading,
    bool? isSearchingMeters,
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
      medidoresDisponibles: medidoresDisponibles ?? this.medidoresDisponibles,
      fotoRetirado: clearFotoRetirado ? null : (fotoRetirado ?? this.fotoRetirado),
      fotoNuevo: clearFotoNuevo ? null : (fotoNuevo ?? this.fotoNuevo),
      isLoading: isLoading ?? this.isLoading,
      isSearchingMeters: isSearchingMeters ?? this.isSearchingMeters,
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
  int _busquedaVersion = 0;

  @override
  CambioMedidorState build() => const CambioMedidorState();

  Future<void> cargar(String solicitudId) async {
    state = const CambioMedidorState(isLoading: true);

    try {
      final repository = ref.read(ejecucionRepositoryProvider);
      final results = await Future.wait([
        repository.obtenerSolicitud(solicitudId),
        repository.obtenerMotivos(),
        repository.obtenerMedidoresDisponibles(),
      ]);

      state = CambioMedidorState(
        solicitud: results[0] as Solicitud,
        motivos: results[1] as List<MotivoCambio>,
        medidoresDisponibles: _ordenarMedidores(results[2] as List<MedidorDisponible>),
      );
    } on EjecucionException catch (e) {
      state = CambioMedidorState(errorMessage: e.message);
    } catch (_) {
      state = const CambioMedidorState(
        errorMessage: 'No se pudo cargar el formulario de cambio. Revise la conexión y vuelva a intentar.',
      );
    }
  }

  Future<void> buscarMedidoresDisponibles(String texto) async {
    final version = ++_busquedaVersion;
    state = state.copyWith(isSearchingMeters: true, errorMessage: null);
    try {
      final items = await ref
          .read(ejecucionRepositoryProvider)
          .obtenerMedidoresDisponibles(buscar: texto);
      if (version != _busquedaVersion) return;
      state = state.copyWith(
        medidoresDisponibles: _ordenarMedidores(items),
        isSearchingMeters: false,
        errorMessage: items.isEmpty
            ? 'No se encontraron medidores libres con ese criterio.'
            : null,
      );
    } on EjecucionException catch (e) {
      if (version != _busquedaVersion) return;
      state = state.copyWith(isSearchingMeters: false, errorMessage: e.message);
    } catch (_) {
      if (version != _busquedaVersion) return;
      state = state.copyWith(
        isSearchingMeters: false,
        errorMessage: 'No se pudo consultar medidores disponibles.',
      );
    }
  }

  Future<void> tomarFotoRetirado() async {
    if (kIsWeb) return _mensajeSoloDispositivo();
    final solicitud = state.solicitud;
    if (solicitud == null) return;

    try {
      final path = await ref.read(evidenciaLocalServiceProvider).capturarYComprimir(
        solicitudId: solicitud.id,
        tipoFoto: 'medidor_retirado',
      );
      if (path != null) state = state.copyWith(fotoRetirado: path, errorMessage: null);
    } catch (_) {
      state = state.copyWith(errorMessage: 'No se pudo capturar o guardar la fotografía del medidor retirado.');
    }
  }

  Future<void> tomarFotoNuevo() async {
    if (kIsWeb) return _mensajeSoloDispositivo();
    final solicitud = state.solicitud;
    if (solicitud == null) return;

    try {
      final path = await ref.read(evidenciaLocalServiceProvider).capturarYComprimir(
        solicitudId: solicitud.id,
        tipoFoto: 'medidor_nuevo',
      );
      if (path != null) state = state.copyWith(fotoNuevo: path, errorMessage: null);
    } catch (_) {
      state = state.copyWith(errorMessage: 'No se pudo capturar o guardar la fotografía del medidor instalado.');
    }
  }

  void _mensajeSoloDispositivo() {
    state = state.copyWith(
      errorMessage: 'La captura y el guardado local están disponibles en Android y Windows, no en navegador web.',
    );
  }

  Future<bool> guardarLocal({
    required String lecturaRetiroTexto,
    required int? idMotivo,
    required MedidorDisponible? medidorInstalado,
    required String observaciones,
  }) async {
    final solicitud = state.solicitud;
    final user = ref.read(authControllerProvider).user;

    if (kIsWeb) {
      _mensajeSoloDispositivo();
      return false;
    }
    if (solicitud == null || user == null) {
      state = state.copyWith(errorMessage: 'Faltan datos de sesión o solicitud.');
      return false;
    }

    final lectura = double.tryParse(lecturaRetiroTexto.replaceAll(',', '.'));
    if (solicitud.numeroMedidor == null || solicitud.numeroMedidor!.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'La solicitud no tiene un medidor activo asociado.');
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
    if (medidorInstalado == null) {
      state = state.copyWith(errorMessage: 'Seleccione un medidor institucional disponible.');
      return false;
    }
    if (!medidorInstalado.estaLibre || !medidorInstalado.estaPerfecto) {
      state = state.copyWith(errorMessage: 'El medidor seleccionado no figura como LIBRE y PERFECTO. Actualice la búsqueda.');
      return false;
    }
    if (medidorInstalado.serie.trim().toLowerCase() == solicitud.numeroMedidor!.trim().toLowerCase()) {
      state = state.copyWith(errorMessage: 'El medidor instalado debe ser distinto al retirado.');
      return false;
    }
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);

    try {
      final idOrigen = solicitud.folioOdeco?.toString() ?? solicitud.id.replaceFirst('LEC-', '');
      final now = DateTime.now();
      final localId = '${solicitud.id}_${now.microsecondsSinceEpoch}'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final ubicacion = await _capturarUbicacionActual();

      final draft = CambioMedidorDraft(
        localId: localId,
        solicitudId: solicitud.id,
        tipoOrigen: solicitud.tipoOrigen,
        idOrigen: idOrigen,
        idUsuarioApp: user.id,
        fechaHoraEjecucion: now,
        codCon: solicitud.codCon,
        nombreSocio: solicitud.nombreCliente,
        direccion: solicitud.direccion,
        numeroMedidorRetirado: solicitud.numeroMedidor!,
        marcaRetirado: solicitud.marcaMedidor,
        lecturaRetiro: lectura,
        idMotivo: idMotivo,
        codMedidorInstalado: medidorInstalado.codMedidor,
        numeroMedidorInstalado: medidorInstalado.serie,
        marcaInstalado: medidorInstalado.marca,
        observaciones: observaciones.trim().isEmpty ? null : observaciones.trim(),
        fotoMedidorRetirado: state.fotoRetirado,
        fotoMedidorNuevo: state.fotoNuevo,
        latitud: ubicacion.$1 ?? solicitud.latitud,
        longitud: ubicacion.$2 ?? solicitud.longitud,
      );

      final path = await ref.read(ejecucionRepositoryProvider).guardarLocal(draft);

      // Si se está corrigiendo un trabajo que quedó pendiente por conflicto de
      // sincronización, conservamos únicamente la versión local más reciente.
      final localService = ref.read(syncLocalServiceProvider);
      final anteriores = await localService.cargarDraftsPendientes(idUsuarioApp: user.id);
      for (final anterior in anteriores) {
        if (anterior.solicitudId == solicitud.id && anterior.localId != draft.localId) {
          await localService.eliminarDraft(anterior.localId);
        }
      }

      await ref.read(syncControllerProvider.notifier).cargarPendientes();
      await ref.read(detalleRecorridoControllerProvider.notifier).cargar();

      state = state.copyWith(
        isSaving: false,
        archivoLocal: path,
        successMessage: 'Trabajo guardado en el dispositivo. Queda pendiente de sincronización con el servidor.',
      );
      return true;
    } on EjecucionException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No se pudo guardar el trabajo localmente.',
      );
      return false;
    }
  }

  List<MedidorDisponible> _ordenarMedidores(List<MedidorDisponible> items) {
    final ordenados = [...items];
    ordenados.sort((a, b) {
      final porSerie = a.serie.toLowerCase().compareTo(b.serie.toLowerCase());
      if (porSerie != 0) return porSerie;
      final porMarca = a.marca.toLowerCase().compareTo(b.marca.toLowerCase());
      return porMarca != 0 ? porMarca : a.codMedidor.compareTo(b.codMedidor);
    });
    return ordenados;
  }

  Future<(double?, double?)> _capturarUbicacionActual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return (null, null);
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return (null, null);
      }
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return (posicion.latitude, posicion.longitude);
    } catch (_) {
      // La falta de GPS no debe impedir el trabajo offline; en ese caso se
      // conserva la coordenada de la solicitud descargada.
      return (null, null);
    }
  }
}
