import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/ejecucion_historial.dart';
import '../controllers/historial_controller.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  static String _formatoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} · $hora:$minuto';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CosaaltAppBar(
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      body: const SafeArea(child: HistorialView()),
    );
  }
}

/// Contenido reutilizable del historial. Se embebe tanto en la pantalla
/// standalone (/historial) como en la pestaña "Historial" de los dashboards
/// para que la barra de navegación inferior se mantenga visible.
class HistorialView extends ConsumerStatefulWidget {
  const HistorialView({super.key});

  @override
  ConsumerState<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends ConsumerState<HistorialView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(historialControllerProvider.notifier).cargar(),
    );
  }

  void _verFoto(BuildContext context, String rutaArchivo, String tipoFoto) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  '${ApiConfig.baseUrl}$rutaArchivo',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 56,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No se pudo cargar la foto ($tipoFoto)',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historialControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(historialControllerProvider.notifier).cargar(),
      child: _Contenido(state: state, onVerFoto: _verFoto),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.state, required this.onVerFoto});

  final HistorialState state;
  final void Function(BuildContext, String, String) onVerFoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.ejecuciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.ejecuciones.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              state.errorMessage!,
              style: const TextStyle(color: AppColors.odecoRed),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                ref.read(historialControllerProvider.notifier).cargar(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (state.ejecuciones.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.history, size: 64, color: AppColors.darkBlue),
          SizedBox(height: 12),
          Text(
            'Todavía no hay cambios de medidor registrados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.ejecuciones.length,
      itemBuilder: (context, index) {
        final e = state.ejecuciones[index];
        return _TarjetaHistorial(
          ejecucion: e,
          onVerFoto: (ruta, tipo) => onVerFoto(context, ruta, tipo),
        );
      },
    );
  }
}

class _TarjetaHistorial extends StatelessWidget {
  const _TarjetaHistorial({required this.ejecucion, required this.onVerFoto});

  final EjecucionHistorial ejecucion;
  final void Function(String rutaArchivo, String tipoFoto) onVerFoto;

  @override
  Widget build(BuildContext context) {
    final esOdeco = ejecucion.tipoOrigen == 'ODECO';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: esOdeco
                      ? AppColors.odecoRed.withValues(alpha: 0.1)
                      : AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ejecucion.tipoOrigen,
                  style: TextStyle(
                    color: esOdeco ? AppColors.odecoRed : AppColors.darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  HistorialScreen._formatoFecha(ejecucion.fechaHoraEjecucion),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '#${ejecucion.idEjecucion}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ejecucion.nombreCliente ?? 'Cliente sin nombre',
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (ejecucion.direccion != null) ...[
            const SizedBox(height: 2),
            Text(
              ejecucion.direccion!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.odecoRed.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${ejecucion.numeroMedidorRetirado} '
                  '${ejecucion.marcaRetirado == null ? '' : '(${ejecucion.marcaRetirado})'}'
                  ' · Lec: ${_formatoDecimal(ejecucion.lecturaRetiro)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.arrow_forward,
                size: 18,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${ejecucion.numeroMedidorInstalado} '
                  '${ejecucion.marcaInstalado == null ? '' : '(${ejecucion.marcaInstalado})'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (ejecucion.motivoDescripcion != null)
                _ChipInfo(
                  icon: Icons.settings,
                  label: ejecucion.motivoDescripcion!,
                ),
              if (ejecucion.nombreTecnico != null)
                _ChipInfo(
                  icon: Icons.person_outline,
                  label: ejecucion.nombreTecnico!,
                ),
              if (ejecucion.codCon != null)
                _ChipInfo(
                  icon: Icons.badge_outlined,
                  label: 'N° ${ejecucion.codCon}',
                ),
            ],
          ),
          if (ejecucion.evidencias.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'FOTOS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final evidencia in ejecucion.evidencias) ...[
                  _MiniaturaFoto(
                    rutaArchivo: evidencia.rutaArchivo,
                    etiqueta: evidencia.tipoFoto == 'MedidorRetirado'
                        ? 'Retirado'
                        : 'Nuevo',
                    onTap: () =>
                        onVerFoto(evidencia.rutaArchivo, evidencia.tipoFoto),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatoDecimal(double valor) =>
      valor == valor.roundToDouble() ? valor.toStringAsFixed(0) : '$valor';
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.darkBlue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniaturaFoto extends StatelessWidget {
  const _MiniaturaFoto({
    required this.rutaArchivo,
    required this.etiqueta,
    required this.onTap,
  });

  final String rutaArchivo;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              '${ApiConfig.baseUrl}$rutaArchivo',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 84,
                  height: 84,
                  color: AppColors.lightBlue,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: 84,
                height: 84,
                color: AppColors.border,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            etiqueta,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
