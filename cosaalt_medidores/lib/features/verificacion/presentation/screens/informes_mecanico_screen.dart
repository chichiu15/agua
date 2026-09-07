import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/mecanico_shell.dart';

class InformesMecanicoScreen
    extends ConsumerStatefulWidget {
  const InformesMecanicoScreen({
    super.key,
  });

  @override
  ConsumerState<InformesMecanicoScreen>
      createState() =>
          _InformesMecanicoScreenState();
}

class _InformesMecanicoScreenState
    extends ConsumerState<InformesMecanicoScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_cargar);
  }

  Future<void> _cargar() async {
    /*
     * Reutilizamos el historial existente.
     *
     * No creamos un endpoint nuevo solamente
     * para M1.
     *
     * Pedimos las verificaciones completadas
     * del mecánico conectado y posteriormente
     * mostramos únicamente aquellas que
     * realmente tienen un informe generado.
     */
    await ref
        .read(
          verificacionControllerProvider.notifier,
        )
        .cargarHistorial(
          estado: 'Completada',
          page: 1,
          pageSize: 200,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(verificacionControllerProvider);

    final historial =
        state.historial?.items ??
            const <HistorialVerificacionItem>[];

    final informes = historial
        .where(
          (item) => item.tieneInforme,
        )
        .toList();

    return Scaffold(
      appBar: MecanicoPageAppBar(
        title: const Text(
          'Informes de verificación',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                state.isLoading ? null : _cargar,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Informes emitidos',
              style: TextStyle(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Informes generados por tus verificaciones completadas.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            if (state.errorMessage != null)
              Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        Colors.red.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style:
                            const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (state.isLoading &&
                state.historial == null)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(32),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (informes.isEmpty)
              _SinInformes(
                onActualizar: _cargar,
              )
            else ...[
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 18,
                    color:
                        AppColors.darkBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${informes.length} informe(s)',
                    style:
                        const TextStyle(
                      color:
                          AppColors.darkBlue,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ...informes.map(
                (item) => _InformeCard(
                  item: item,
                  onTap: () =>
                      _abrirInforme(item),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _abrirInforme(
    HistorialVerificacionItem item,
  ) async {
    await context.push<void>(
      '${AppRoutes.mecanicoHome}/verificacion/${item.idVerificacion}/informe',
    );

    if (mounted) {
      await _cargar();
    }
  }
}

class _InformeCard extends StatelessWidget {
  const _InformeCard({
    required this.item,
    required this.onTap,
  });

  final HistorialVerificacionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nombreSocio =
        item.nombreCliente?.trim();

    final numeroInforme =
        item.nroInforme?.trim();

    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFD9E2E7),
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        BoxDecoration(
                      color: const Color(
                        0xFFEDF4FF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .description_outlined,
                      color:
                          AppColors.darkBlue,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          numeroInforme !=
                                      null &&
                                  numeroInforme
                                      .isNotEmpty
                              ? numeroInforme
                              : 'Informe de verificación',
                          style:
                              const TextStyle(
                            color: AppColors
                                .darkBlue,
                            fontWeight:
                                FontWeight
                                    .w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          'Verificación #${item.idVerificacion}',
                          style:
                              const TextStyle(
                            color: AppColors
                                .textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                    color:
                        Color(0xFF8A949D),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _DatoInforme(
                icon:
                    Icons.person_outline,
                texto: nombreSocio != null &&
                        nombreSocio.isNotEmpty
                    ? nombreSocio
                    : 'Socio ${item.codCon}',
              ),

              _DatoInforme(
                icon: Icons.link,
                texto:
                    'Conexión ${item.codCon}',
              ),

              if (item.numeroMedidor !=
                      null &&
                  item.numeroMedidor!
                      .trim()
                      .isNotEmpty)
                _DatoInforme(
                  icon:
                      Icons.speed_outlined,
                  texto:
                      'Medidor ${item.marcaMedidor ?? ''} ${item.numeroMedidor}'
                          .trim(),
                ),

              _DatoInforme(
                icon:
                    Icons.check_circle_outline,
                texto:
                    'Resultado: ${item.resultado ?? "Sin definir"}',
              ),

              const SizedBox(height: 6),

              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(
                    Icons
                        .visibility_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Ver informe',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoInforme extends StatelessWidget {
  const _DatoInforme({
    required this.icon,
    required this.texto,
  });

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              texto,
              style:
                  const TextStyle(
                color: Color(0xFF374151),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinInformes extends StatelessWidget {
  const _SinInformes({
    required this.onActualizar,
  });

  final Future<void> Function() onActualizar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F9F8),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFD9E2E7),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 48,
            color:
                AppColors.textSecondary,
          ),

          const SizedBox(height: 12),

          const Text(
            'No hay informes generados',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight:
                  FontWeight.w800,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Cuando una verificación tenga un informe emitido aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: onActualizar,
            icon:
                const Icon(Icons.refresh),
            label:
                const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}