import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_admin_repository.dart';
import '../../domain/entities/admin_models.dart';
import 'admin_controller.dart';

class AdminSupervisionState {
  const AdminSupervisionState({
    this.dashboard,
    this.solicitudes,
    this.rutas,
    this.rutaSeleccionada,
    this.sincronizacion = const [],
    this.verificaciones,
    this.verificacionSeleccionada,
    this.movimientos,
    this.historicoCorporativo,
    this.estadisticas,
    this.isLoading = false,
    this.isExporting = false,
    this.errorMessage,
    this.successMessage,
  });

  final AdminDashboard? dashboard;
  final PagedData<AdminSolicitud>? solicitudes;
  final PagedData<AdminRuta>? rutas;
  final AdminRuta? rutaSeleccionada;
  final List<AdminSincronizacionTecnico> sincronizacion;
  final PagedData<AdminVerificacion>? verificaciones;
  final AdminVerificacionDetalle? verificacionSeleccionada;
  final PagedData<AdminMovimiento>? movimientos;
  final PagedData<AdminMovimientoCorporativo>? historicoCorporativo;
  final AdminEstadisticas? estadisticas;
  final bool isLoading, isExporting;
  final String? errorMessage, successMessage;

  AdminSupervisionState copyWith({
    AdminDashboard? dashboard,
    PagedData<AdminSolicitud>? solicitudes,
    PagedData<AdminRuta>? rutas,
    AdminRuta? rutaSeleccionada,
    bool clearRuta = false,
    List<AdminSincronizacionTecnico>? sincronizacion,
    PagedData<AdminVerificacion>? verificaciones,
    AdminVerificacionDetalle? verificacionSeleccionada,
    bool clearVerificacion = false,
    PagedData<AdminMovimiento>? movimientos,
    PagedData<AdminMovimientoCorporativo>? historicoCorporativo,
    AdminEstadisticas? estadisticas,
    bool? isLoading,
    bool? isExporting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) => AdminSupervisionState(
    dashboard: dashboard ?? this.dashboard,
    solicitudes: solicitudes ?? this.solicitudes,
    rutas: rutas ?? this.rutas,
    rutaSeleccionada: clearRuta ? null : (rutaSeleccionada ?? this.rutaSeleccionada),
    sincronizacion: sincronizacion ?? this.sincronizacion,
    verificaciones: verificaciones ?? this.verificaciones,
    verificacionSeleccionada: clearVerificacion ? null : (verificacionSeleccionada ?? this.verificacionSeleccionada),
    movimientos: movimientos ?? this.movimientos,
    historicoCorporativo: historicoCorporativo ?? this.historicoCorporativo,
    estadisticas: estadisticas ?? this.estadisticas,
    isLoading: isLoading ?? this.isLoading,
    isExporting: isExporting ?? this.isExporting,
    errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
  );
}

final adminSupervisionControllerProvider = NotifierProvider<AdminSupervisionController, AdminSupervisionState>(AdminSupervisionController.new);

class AdminSupervisionController extends Notifier<AdminSupervisionState> {
  @override
  AdminSupervisionState build() => const AdminSupervisionState();

  ApiAdminRepository get _repo => ref.read(adminRepositoryProvider);

  Future<void> cargarDashboard() async => _run(() async {
    state = state.copyWith(dashboard: await _repo.obtenerDashboard());
  });

  Future<void> cargarSolicitudes({DateTime? desde, DateTime? hasta, String? origen, String? estado, String? prioridad, int? tecnicoId, String? buscar, int page = 1, int pageSize = 25}) async => _run(() async {
    final data = await _repo.obtenerSolicitudesAdmin(desde: desde, hasta: hasta, origen: origen, estado: estado, prioridad: prioridad, tecnicoId: tecnicoId, buscar: buscar, page: page, pageSize: pageSize);
    state = state.copyWith(solicitudes: data);
  });

  Future<void> cargarRutas({DateTime? fecha, int? tecnicoId, String? estado, String? buscar, int page = 1, int pageSize = 20}) async => _run(() async {
    final data = await _repo.obtenerRutasAdmin(fecha: fecha, tecnicoId: tecnicoId, estado: estado, buscar: buscar, page: page, pageSize: pageSize);
    final selectedId = state.rutaSeleccionada?.idAsignacion;
    state = state.copyWith(rutas: data);
    if (data.items.isEmpty) {
      state = state.copyWith(clearRuta: true);
    } else if (selectedId == null || !data.items.any((r) => r.idAsignacion == selectedId)) {
      state = state.copyWith(rutaSeleccionada: data.items.first);
    }
  });

  Future<void> seleccionarRuta(int id) async => _run(() async {
    state = state.copyWith(rutaSeleccionada: await _repo.obtenerRutaAdmin(id));
  });

  Future<void> cargarSincronizacion({DateTime? fecha}) async => _run(() async {
    state = state.copyWith(sincronizacion: await _repo.obtenerSincronizacionAdmin(fecha: fecha));
  });

  Future<void> cargarVerificaciones({DateTime? desde, DateTime? hasta, int? mecanicoId, String? estado, String? resultado, String? buscar, bool? soloConInforme, int page = 1, int pageSize = 25}) async => _run(() async {
    final data = await _repo.obtenerVerificacionesAdmin(desde: desde, hasta: hasta, mecanicoId: mecanicoId, estado: estado, resultado: resultado, buscar: buscar, soloConInforme: soloConInforme, page: page, pageSize: pageSize);
    state = state.copyWith(verificaciones: data);
  });

  Future<void> seleccionarVerificacion(int id) async => _run(() async {
    state = state.copyWith(verificacionSeleccionada: await _repo.obtenerVerificacionDetalle(id));
  });

  Future<void> cargarMovimientos({DateTime? desde, DateTime? hasta, int? tecnicoId, int? motivoId, String? origen, String? marca, bool? sincronizado, String? buscar, int page = 1, int pageSize = 25}) async => _run(() async {
    final data = await _repo.obtenerMovimientos(desde: desde, hasta: hasta, tecnicoId: tecnicoId, motivoId: motivoId, origen: origen, marca: marca, sincronizado: sincronizado, buscar: buscar, page: page, pageSize: pageSize);
    state = state.copyWith(movimientos: data);
  });

  Future<void> cargarHistoricoCorporativo({int? codCon, bool? vigente, int? motivoId, String? marca, String? buscar, int page = 1, int pageSize = 25}) async => _run(() async {
    final data = await _repo.obtenerHistoricoCorporativo(codCon: codCon, vigente: vigente, motivoId: motivoId, marca: marca, buscar: buscar, page: page, pageSize: pageSize);
    state = state.copyWith(historicoCorporativo: data);
  });

  Future<void> cargarEstadisticas({DateTime? desde, DateTime? hasta, int? tecnicoId, int? mecanicoId, int? motivoId, String? origen, String? marca}) async => _run(() async {
    state = state.copyWith(estadisticas: await _repo.obtenerEstadisticas(desde: desde, hasta: hasta, tecnicoId: tecnicoId, mecanicoId: mecanicoId, motivoId: motivoId, origen: origen, marca: marca));
  });

  Future<String?> exportarVerificaciones({required bool pdf, DateTime? desde, DateTime? hasta, int? mecanicoId, String? estado, String? resultado, String? buscar, bool? soloConInforme}) async {
    state = state.copyWith(isExporting: true, clearMessages: true);
    try {
      final path = await _repo.exportarVerificaciones(pdf: pdf, desde: desde, hasta: hasta, mecanicoId: mecanicoId, estado: estado, resultado: resultado, buscar: buscar, soloConInforme: soloConInforme);
      if (path.isEmpty) {
        state = state.copyWith(isExporting: false);
        return null;
      }
      state = state.copyWith(isExporting: false, successMessage: 'Archivo guardado correctamente.');
      return path;
    } catch (e) {
      state = state.copyWith(isExporting: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<String?> descargarInforme(AdminInformeVerificacion informe) async {
    state = state.copyWith(isExporting: true, clearMessages: true);
    try {
      if (informe.rutaPdf == null || informe.rutaPdf!.trim().isEmpty) {
        throw const AdminApiException('El informe tecnico todavia no tiene un PDF generado.');
      }
      final path = await _repo.descargarInformeTecnico(informe.idInforme, informe.nroInforme);
      if (path.isEmpty) {
        state = state.copyWith(isExporting: false);
        return null;
      }
      state = state.copyWith(isExporting: false, successMessage: 'Informe guardado correctamente.');
      return path;
    } catch (e) {
      state = state.copyWith(isExporting: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<String?> exportarMovimientos({required bool pdf, DateTime? desde, DateTime? hasta, int? tecnicoId, int? motivoId, String? origen, String? marca, bool? sincronizado, String? buscar}) async {
    state = state.copyWith(isExporting: true, clearMessages: true);
    try {
      final path = await _repo.exportarMovimientos(pdf: pdf, desde: desde, hasta: hasta, tecnicoId: tecnicoId, motivoId: motivoId, origen: origen, marca: marca, sincronizado: sincronizado, buscar: buscar);
      if (path.isEmpty) {
        state = state.copyWith(isExporting: false);
        return null;
      }
      state = state.copyWith(isExporting: false, successMessage: 'Archivo guardado correctamente.');
      return path;
    } catch (e) {
      state = state.copyWith(isExporting: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<String?> exportarHistoricoCorporativo({required bool pdf, int? codCon, bool? vigente, int? motivoId, String? marca, String? buscar}) async {
    state = state.copyWith(isExporting: true, clearMessages: true);
    try {
      final path = await _repo.exportarHistoricoCorporativo(pdf: pdf, codCon: codCon, vigente: vigente, motivoId: motivoId, marca: marca, buscar: buscar);
      if (path.isEmpty) {
        state = state.copyWith(isExporting: false);
        return null;
      }
      state = state.copyWith(isExporting: false, successMessage: 'Archivo guardado correctamente.');
      return path;
    } catch (e) {
      state = state.copyWith(isExporting: false, errorMessage: e.toString());
      return null;
    }
  }

  void limpiarMensajes() => state = state.copyWith(clearMessages: true);

  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await action();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
