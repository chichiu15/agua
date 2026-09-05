import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../recorrido/presentation/controllers/detalle_recorrido_controller.dart';
import '../../data/repositories/api_sync_repository.dart';
import '../../data/services/sync_local_service.dart';

class SyncState {
  const SyncState({
    this.pendientes = 0,
    this.isSyncing = false,
    this.lastSyncTime,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    this.progressCurrent = 0,
    this.progressTotal = 0,
    this.statusMessage,
  });

  final int pendientes;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int syncedCount;
  final int failedCount;
  final String? errorMessage;
  final int progressCurrent;
  final int progressTotal;
  final String? statusMessage;

  double get progress => progressTotal <= 0
      ? 0
      : (progressCurrent / progressTotal).clamp(0.0, 1.0).toDouble();

  SyncState copyWith({
    int? pendientes,
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? syncedCount,
    int? failedCount,
    String? errorMessage,
    int? progressCurrent,
    int? progressTotal,
    String? statusMessage,
  }) {
    return SyncState(
      pendientes: pendientes ?? this.pendientes,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncedCount: syncedCount ?? this.syncedCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: errorMessage,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTotal: progressTotal ?? this.progressTotal,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

final syncLocalServiceProvider = Provider<SyncLocalService>((ref) => SyncLocalService());
final syncRepositoryProvider = Provider<ApiSyncRepository>((ref) => ApiSyncRepository());
final syncControllerProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);

class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() {
    Future.microtask(cargarPendientes);
    return const SyncState();
  }

  Future<void> cargarPendientes() async {
    final user = ref.read(authControllerProvider).user;
    final count = user == null
        ? 0
        : await ref.read(syncLocalServiceProvider).contarPendientes(idUsuarioApp: user.id);
    state = state.copyWith(pendientes: count);
  }

  Future<void> sincronizar() async {
    if (state.isSyncing) return;
    state = state.copyWith(
      isSyncing: true,
      errorMessage: null,
      syncedCount: 0,
      failedCount: 0,
      progressCurrent: 0,
      progressTotal: 0,
      statusMessage: 'Preparando sincronización...',
    );

    try {
      final localService = ref.read(syncLocalServiceProvider);
      final repository = ref.read(syncRepositoryProvider);
      final user = ref.read(authControllerProvider).user;
      if (user == null) {
        state = state.copyWith(isSyncing: false, errorMessage: 'La sesión ya no está disponible. Vuelva a iniciar sesión.');
        return;
      }
      final drafts = await localService.cargarDraftsPendientes(idUsuarioApp: user.id);
      if (drafts.isEmpty) {
        state = state.copyWith(isSyncing: false, pendientes: 0, syncedCount: 0, failedCount: 0);
        return;
      }

      final result = await repository.sincronizarBatch(
        drafts,
        onProgress: (current, total, message) {
          state = state.copyWith(
            progressCurrent: current,
            progressTotal: total,
            statusMessage: message,
          );
        },
      );
      for (final item in result.items.where((x) => x.ok)) {
        await localService.eliminarDraft(item.localId);
      }

      final pendientes = await localService.contarPendientes(idUsuarioApp: user.id);
      final errores = result.items.where((x) => !x.ok).toList();
      final detalleErrores = errores.take(3).map((x) => '${x.tipoOrigen}-${x.idOrigen}: ${x.error ?? 'requiere revisión'}').join('\n');

      state = state.copyWith(
        isSyncing: false,
        pendientes: pendientes,
        syncedCount: result.procesadosOk,
        failedCount: result.errores,
        lastSyncTime: result.procesadosOk > 0 ? DateTime.now() : state.lastSyncTime,
        errorMessage: errores.isEmpty
            ? null
            : 'Se sincronizaron ${result.procesadosOk} trabajo(s), pero ${result.errores} quedaron pendientes.\n$detalleErrores',
        statusMessage: errores.isEmpty
            ? 'Sincronización completada'
            : 'Sincronización terminada con pendientes',
      );

      await ref.read(detalleRecorridoControllerProvider.notifier).cargar();
    } on SyncException catch (e) {
      final currentUser = ref.read(authControllerProvider).user;
      final pending = currentUser == null
          ? 0
          : await ref.read(syncLocalServiceProvider).contarPendientes(idUsuarioApp: currentUser.id);
      state = state.copyWith(
        isSyncing: false,
        pendientes: pending,
        failedCount: pending,
        errorMessage: e.message,
      );
    } catch (_) {
      final currentUser = ref.read(authControllerProvider).user;
      final pending = currentUser == null
          ? 0
          : await ref.read(syncLocalServiceProvider).contarPendientes(idUsuarioApp: currentUser.id);
      state = state.copyWith(
        isSyncing: false,
        pendientes: pending,
        failedCount: pending,
        errorMessage: 'No se pudo completar la sincronización. Los trabajos siguen guardados en el dispositivo.',
      );
    }
  }
}
