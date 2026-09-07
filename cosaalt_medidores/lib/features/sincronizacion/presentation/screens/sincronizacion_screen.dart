import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/sync_controller.dart';
import '../../../ejecucion_cambio/domain/entities/cambio_medidor.dart';

class SincronizacionScreen extends ConsumerWidget {
  const SincronizacionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () {
          ref.read(authControllerProvider.notifier).logout();
        },
      ),
      body: const SafeArea(child: SincronizacionView()),
    );
  }
}

/// Contenido reutilizable de sincronización. Se embebe tanto en la pantalla
/// standalone (/sincronizar) como en la pestaña "Sincronizar" de los
/// dashboards para que la barra de navegación inferior se mantenga visible.
class SincronizacionView extends ConsumerStatefulWidget {
  const SincronizacionView({super.key});

  @override
  ConsumerState<SincronizacionView> createState() => _SincronizacionViewState();
}

class _SincronizacionViewState extends ConsumerState<SincronizacionView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(syncControllerProvider.notifier).cargarPendientes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sincronización',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        _StatusCard(
          pendientes: syncState.pendientes,
          isSyncing: syncState.isSyncing,
          lastSyncTime: syncState.lastSyncTime,
          syncedCount: syncState.syncedCount,
          failedCount: syncState.failedCount,
          progress: syncState.progress,
          progressCurrent: syncState.progressCurrent,
          progressTotal: syncState.progressTotal,
          statusMessage: syncState.statusMessage,
        ),
        if (syncState.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.odecoRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.odecoRed.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              syncState.errorMessage!,
              style: const TextStyle(color: AppColors.odecoRed),
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: syncState.isSyncing || syncState.pendientes == 0
                ? null
                : () => ref.read(syncControllerProvider.notifier).sincronizar(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.darkBlue.withValues(
                alpha: 0.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: syncState.isSyncing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    syncState.pendientes == 0
                        ? 'No hay pendientes'
                        : 'SINCRONIZAR (${syncState.pendientes})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),

        if (syncState.draftsPendientes.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Trabajos guardados en el dispositivo',
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...syncState.draftsPendientes.map((draft) {
            final error = syncState.erroresPorLocalId[draft.localId];
            return _PendingDraftCard(
              draft: draft,
              error: error,
              onEdit: () => context.go('/trabajo/cambio/${draft.solicitudId}'),
            );
          }),
        ],
        if (syncState.syncedCount > 0 &&
            syncState.lastSyncTime != null &&
            !syncState.isSyncing) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${syncState.syncedCount} registro(s) sincronizado(s)',
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingDraftCard extends StatelessWidget {
  const _PendingDraftCard({
    required this.draft,
    required this.onEdit,
    this.error,
  });

  final CambioMedidorDraft draft;
  final String? error;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? AppColors.odecoRed.withValues(alpha: .35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${draft.tipoOrigen} · ${draft.solicitudId}',
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasError
                      ? AppColors.odecoRed.withValues(alpha: .10)
                      : AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hasError ? 'REQUIERE REVISIÓN' : 'PENDIENTE',
                  style: TextStyle(
                    color: hasError ? AppColors.odecoRed : AppColors.darkBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            draft.nombreSocio,
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Medidor nuevo: ${draft.numeroMedidorInstalado} · ${draft.marcaInstalado}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(
                color: AppColors.odecoRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(hasError ? 'CORREGIR TRABAJO' : 'EDITAR BORRADOR'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.pendientes,
    required this.isSyncing,
    required this.lastSyncTime,
    required this.syncedCount,
    required this.failedCount,
    required this.progress,
    required this.progressCurrent,
    required this.progressTotal,
    required this.statusMessage,
  });

  final int pendientes;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int syncedCount;
  final int failedCount;
  final double progress;
  final int progressCurrent;
  final int progressTotal;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            isSyncing ? Icons.sync : Icons.cloud_upload_outlined,
            size: 48,
            color: AppColors.darkBlue,
          ),
          const SizedBox(height: 12),
          Text(
            '$pendientes',
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w800,
              fontSize: 40,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'CAMBIOS PENDIENTES',
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (isSyncing) ...[
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: progressTotal > 0 ? progress : null,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.white,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 8),
            Text(
              progressTotal > 0
                  ? '${(progress * 100).round()}% · $progressCurrent de $progressTotal pasos'
                  : 'Conectando...',
              style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800),
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ],
          if (lastSyncTime != null) ...[
            const SizedBox(height: 10),
            Text(
              'Última sync: ${_formatFecha(lastSyncTime!)}',
              style: TextStyle(
                color: AppColors.darkBlue.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
          if (failedCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$failedCount trabajo(s) requieren revisión y permanecen guardados.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.odecoRed,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.day}/${fecha.month}/${fecha.year} $h:$m';
  }
}
