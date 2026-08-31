import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ejecucion_cambio/domain/entities/cambio_medidor.dart';
import '../../data/repositories/api_sync_repository.dart';
import '../../data/services/sync_local_service.dart';

class SyncState {
  const SyncState({
    this.pendientes = 0,
    this.isSyncing = false,
    this.lastSyncTime,
    this.syncedCount = 0,
    this.errorMessage,
  });

  final int pendientes;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int syncedCount;
  final String? errorMessage;

  SyncState copyWith({
    int? pendientes,
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? syncedCount,
    String? errorMessage,
  }) {
    return SyncState(
      pendientes: pendientes ?? this.pendientes,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncedCount: syncedCount ?? this.syncedCount,
      errorMessage: errorMessage,
    );
  }
}

final syncLocalServiceProvider = Provider<SyncLocalService>((ref) {
  return SyncLocalService();
});

final syncRepositoryProvider = Provider<ApiSyncRepository>((ref) {
  return ApiSyncRepository();
});

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  Future<void> cargarPendientes() async {
    final count = await ref.read(syncLocalServiceProvider).contarPendientes();
    state = state.copyWith(pendientes: count);
  }

  Future<void> sincronizar() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, errorMessage: null, syncedCount: 0);

    try {
      final localService = ref.read(syncLocalServiceProvider);
      final repository = ref.read(syncRepositoryProvider);

      final drafts = await localService.cargarDraftsPendientes();
      if (drafts.isEmpty) {
        state = state.copyWith(isSyncing: false, pendientes: 0, syncedCount: 0);
        return;
      }

      final procesados = await repository.sincronizarBatch(drafts);

      for (final draft in drafts) {
        await localService.eliminarDraft(draft.localId);
      }

      state = state.copyWith(
        isSyncing: false,
        pendientes: 0,
        syncedCount: procesados,
        lastSyncTime: DateTime.now(),
      );
    } on SyncException catch (e) {
      final pending = await ref
          .read(syncLocalServiceProvider)
          .contarPendientes();
      state = state.copyWith(
        isSyncing: false,
        pendientes: pending,
        errorMessage: e.message,
      );
    } catch (e) {
      final pending = await ref
          .read(syncLocalServiceProvider)
          .contarPendientes();
      state = state.copyWith(
        isSyncing: false,
        pendientes: pending,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }
}
