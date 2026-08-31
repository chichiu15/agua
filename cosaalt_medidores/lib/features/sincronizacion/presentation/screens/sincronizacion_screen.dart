import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/sync_controller.dart';

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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.pendientes,
    required this.isSyncing,
    required this.lastSyncTime,
    required this.syncedCount,
  });

  final int pendientes;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int syncedCount;

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
