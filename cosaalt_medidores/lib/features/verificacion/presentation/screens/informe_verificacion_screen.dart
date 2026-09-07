import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/verificacion_ui.dart';

class InformeVerificacionScreen extends ConsumerStatefulWidget {
  const InformeVerificacionScreen({
    required this.id,
    super.key,
  });

  final int id;

  @override
  ConsumerState<InformeVerificacionScreen> createState() =>
      _InformeVerificacionScreenState();
}

class _InformeVerificacionScreenState
    extends ConsumerState<InformeVerificacionScreen> {
  final _observacionesCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();

  final Set<int> _pdfBusy = <int>{};

  DatosSocioMedidor? _datosSocio;
  bool _cargandoDatos = true;
  String? _errorDatos;

  @override
  void initState() {
    super.initState();

    Future.microtask(_cargarInicial);
  }

  Future<void> _cargarInicial() async {
    final notifier =
        ref.read(verificacionControllerProvider.notifier);

    await notifier.cargarVerificacion(
      widget.id,
    );

    await notifier.cargarInformes(
      widget.id,
    );

    try {
      final repo =
          ref.read(verificacionRepositoryProvider);

      final datos =
          await repo.obtenerDatosSocioMedidor(
        widget.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _datosSocio = datos;
        _errorDatos = null;
        _cargandoDatos = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorDatos = e.toString();
        _cargandoDatos = false;
      });
    }
  }

  @override
  void dispose() {
    _observacionesCtrl.dispose();
    _responsableCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(verificacionControllerProvider);

    final v =
        state.verificacionActual;

    final informes =
        state.informes;

    final proximaVersion =
        _obtenerProximaVersion(
      informes,
    );

    final nroPrevisto =
        _obtenerNumeroPrevisto(
      informes,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Informe Técnico',
        ),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () =>
              context.go(
            AppRoutes.mecanicoHome,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: ListView(
            padding: const EdgeInsets.all(
              16,
            ),
            children: [
              if (state.isLoading ||
                  _cargandoDatos)
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 12,
                  ),
                  child:
                      LinearProgressIndicator(),
                ),

              VerMessageBar(
                error:
                    state.errorMessage ??
                    _errorDatos,
                success:
                    state.successMessage,
              ),

              _buildEstado(
                context,
                v,
              ),

              if (v != null &&
                  v.finalizada)
                _buildVistaPrevia(
                  v,
                  _datosSocio,
                  nroPrevisto,
                  proximaVersion,
                ),

              if (informes.isNotEmpty)
                _buildVersiones(
                  context,
                  informes,
                ),

              if (v != null &&
                  v.finalizada)
                _buildNuevaEmision(
                  state.isAccion,
                  nroPrevisto,
                  proximaVersion,
                ),

              const SizedBox(
                height: 20,
              ),

              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      context.go(
                    AppRoutes.mecanicoHome,
                  ),
                  icon: const Icon(
                    Icons.home_outlined,
                  ),
                  label: const Text(
                    'Volver al inicio',
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstado(
    BuildContext context,
    VerificacionMecanico? v,
  ) {
    return VerSection(
      title: 'Estado del informe',
      child: v == null
          ? const Text(
              'No se encontró la verificación.',
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                VerDataRow(
                  label: 'Verificación',
                  value: '#${v.id}',
                ),

                VerDataRow(
                  label: 'Socio',
                  value:
                      v.nombreCliente ??
                      'Socio ${v.codCon}',
                ),

                VerDataRow(
                  label: 'Estado',
                  value: v.estado,
                ),

                VerDataRow(
                  label: 'Resultado',
                  value:
                      v.resultado ??
                      'Sin definir',
                ),

                const SizedBox(
                  height: 8,
                ),

                Row(
                  children: [
                    Icon(
                      v.finalizada
                          ? Icons
                              .check_circle_outline
                          : Icons.info_outline,
                      size: 18,
                      color: v.finalizada
                          ? const Color(
                              0xFF137A4A,
                            )
                          : const Color(
                              0xFF667085,
                            ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        v.finalizada
                            ? 'La verificación está finalizada. Revise los datos antes de emitir el informe técnico.'
                            : 'Debe finalizar la verificación antes de generar el informe técnico.',
                        style:
                            const TextStyle(
                          color:
                              Color(
                                0xFF667085,
                              ),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                if (!v.finalizada) ...[
                  const SizedBox(
                    height: 14,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        FilledButton.icon(
                      onPressed: () =>
                          context.go(
                        '${AppRoutes.mecanicoHome}/verificacion/${widget.id}/finalizar',
                      ),
                      icon:
                          const Icon(
                        Icons.task_alt,
                      ),
                      label:
                          const Text(
                        'Ir a finalizar',
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildVistaPrevia(
    VerificacionMecanico v,
    DatosSocioMedidor? datos,
    String nroPrevisto,
    int proximaVersion,
  ) {
    final ensayo =
        v.ensayo;

    final unidadVolumen =
        _texto(
      ensayo?.unidadVolumen,
      fallback: 'm³',
    );

    final unidadCaudal =
        _texto(
      ensayo?.unidadCaudal,
      fallback: 'm³/h',
    );

    final diferencia =
        ensayo?.volumenRegistrado != null &&
                ensayo?.volumenPatron != null
            ? ensayo!.volumenRegistrado! -
                ensayo.volumenPatron!
            : null;

    final errorConSigno =
        ensayo?.error;

    final errorAbsoluto =
        errorConSigno?.abs();

    return VerSection(
      title: 'Vista previa del informe',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color:
              const Color(
                0xFFF7FAF8,
              ),
          borderRadius:
              BorderRadius.circular(
                12,
              ),
          border: Border.all(
            color:
                const Color(
                  0xFFD8E4DD,
                ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'COSAALT R.L.',
              style: TextStyle(
                color:
                    Color(
                      0xFF006B45,
                    ),
                fontSize: 17,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            const Text(
              'INFORME TÉCNICO DE VERIFICACIÓN DE MEDIDOR',
              style: TextStyle(
                fontWeight:
                    FontWeight.w800,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            VerDataRow(
              label: 'Nro. previsto',
              value: nroPrevisto,
            ),

            VerDataRow(
              label: 'Próxima versión',
              value:
                  '$proximaVersion',
            ),

            const Divider(
              height: 30,
            ),

            /*
             * 1. DATOS DEL TÉCNICO Y SOCIO
             */
            const _PreviewTitle(
              number: '1',
              title:
                  'Datos del técnico y del socio',
            ),

            VerDataRow(
              label: 'Mecánico',
              value:
                  _texto(
                v.nombreMecanico,
              ),
            ),

            VerDataRow(
              label: 'Socio',
              value:
                  _texto(
                datos?.nombreCliente ??
                    v.nombreCliente,
              ),
            ),

            VerDataRow(
              label:
                  'Registro socio',
              value:
                  '${datos?.regSoc ?? v.codCon}',
            ),

            VerDataRow(
              label:
                  'Código / conexión',
              value:
                  datos?.codConexion
                          ?.toString() ??
                      'No registrado',
            ),

            VerDataRow(
              label: 'Dirección',
              value:
                  _texto(
                datos?.direccion,
              ),
            ),

            VerDataRow(
              label: 'Documento',
              value:
                  _texto(
                datos?.numeroDocumento,
              ),
            ),

            VerDataRow(
              label: 'RUC',
              value:
                  _texto(
                datos?.ruc,
              ),
            ),

            VerDataRow(
              label: 'Origen',
              value:
                  '${v.tipoOrigen} - ${v.idOrigen}',
            ),

            VerDataRow(
              label:
                  'Motivo / observación',
              value:
                  _texto(
                datos?.motivoObservacion,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            /*
             * 2. DATOS DEL MEDIDOR
             */
            const _PreviewTitle(
              number: '2',
              title:
                  'Datos del medidor',
            ),

            VerDataRow(
              label: 'Marca',
              value:
                  _texto(
                datos?.marcaMedidor,
              ),
            ),

            VerDataRow(
              label: 'Serie',
              value:
                  _texto(
                datos?.numeroMedidor,
              ),
            ),

            VerDataRow(
              label: 'Q3',
              value:
                  _texto(
                ensayo
                        ?.capacidadNominalQ3 ??
                    datos?.capacidadQ3,
              ),
            ),

            VerDataRow(
              label: 'Tipo',
              value:
                  _texto(
                datos?.tipoMedidor,
              ),
            ),

            VerDataRow(
              label: 'Clase',
              value:
                  _texto(
                datos?.claseMedidor,
              ),
            ),

            VerDataRow(
              label: 'Diámetro',
              value:
                  _texto(
                datos?.diametroMedidor,
              ),
            ),

            VerDataRow(
              label:
                  'Fecha conexión / registro',
              value:
                  datos?.fechaConexion ==
                          null
                      ? 'No registrado'
                      : verDate(
                          datos!
                              .fechaConexion!,
                        ),
            ),

            const SizedBox(
              height: 16,
            ),

            /*
             * 3. VERIFICACIÓN
             */
            const _PreviewTitle(
              number: '3',
              title: 'Verificación',
            ),

            VerDataRow(
              label:
                  'Fecha de verificación',
              value:
                  verDate(
                v.fechaVerificacion,
                time: true,
              ),
            ),

            VerDataRow(
              label:
                  'Lugar de verificación',
              value:
                  _texto(
                datos?.lugarVerificacion,
              ),
            ),

            VerDataRow(
              label:
                  'Tipo de ensayo',
              value:
                  _texto(
                ensayo?.tipoPrueba ??
                    datos?.tipoEnsayo,
              ),
            ),

            VerDataRow(
              label:
                  'Instrumento / banco',
              value:
                  _texto(
                ensayo?.instrumentoBanco,
              ),
            ),

            VerDataRow(
              label:
                  'Identificación del banco',
              value:
                  _texto(
                ensayo
                    ?.identificacionBanco,
              ),
            ),

            VerDataRow(
              label:
                  'Trazabilidad / calibración',
              value:
                  _texto(
                ensayo
                    ?.trazabilidadCalibracion,
              ),
            ),

            VerDataRow(
              label:
                  'Tipo de caudal',
              value:
                  _texto(
                ensayo?.tipoCaudal,
              ),
            ),

            VerDataRow(
              label: 'Caudal',
              value:
                  ensayo?.caudal ==
                          null
                      ? 'No registrado'
                      : '${_numero(ensayo!.caudal)} $unidadCaudal',
            ),

            const SizedBox(
              height: 16,
            ),

            /*
             * 4. PARTICIPANTES
             */
            const _PreviewTitle(
              number: '4',
              title: 'Participantes',
            ),

            if (v.participantes
                .isEmpty)
              const Text(
                'Sin participantes registrados.',
                style: TextStyle(
                  color:
                      Color(
                        0xFF667085,
                      ),
                ),
              )
            else
              ...v.participantes
                  .asMap()
                  .entries
                  .map(
                    (entry) {
                      final p =
                          entry.value;

                      return Container(
                        width:
                            double.infinity,
                        margin:
                            const EdgeInsets.only(
                              bottom: 8,
                            ),
                        padding:
                            const EdgeInsets.all(
                              10,
                            ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                                8,
                              ),
                          border:
                              Border.all(
                            color:
                                const Color(
                                  0xFFE3E9E6,
                                ),
                          ),
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Participante ${entry.key + 1}',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            VerDataRow(
                              label:
                                  'Nombre',
                              value:
                                  p.nombre,
                            ),

                            VerDataRow(
                              label:
                                  'Cargo',
                              value:
                                  _texto(
                                p.cargo,
                              ),
                            ),

                            VerDataRow(
                              label:
                                  'Tipo / rol',
                              value:
                                  _texto(
                                p.rol,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(
              height: 16,
            ),

            /*
             * 5. LECTURAS Y VOLÚMENES
             */
            const _PreviewTitle(
              number: '5',
              title:
                  'Lecturas y volúmenes',
            ),

            VerDataRow(
              label:
                  'Primera lectura',
              value:
                  ensayo?.lecturaInicial ==
                          null
                      ? 'No registrado'
                      : '${_numero(ensayo!.lecturaInicial)} $unidadVolumen',
            ),

            VerDataRow(
              label:
                  'Segunda lectura',
              value:
                  ensayo?.lecturaFinal ==
                          null
                      ? 'No registrado'
                      : '${_numero(ensayo!.lecturaFinal)} $unidadVolumen',
            ),

            VerDataRow(
              label:
                  'Volumen registrado',
              value:
                  ensayo
                              ?.volumenRegistrado ==
                          null
                      ? 'No registrado'
                      : '${_numero(ensayo!.volumenRegistrado)} $unidadVolumen',
            ),

            VerDataRow(
              label:
                  'Volumen patrón',
              value:
                  ensayo?.volumenPatron ==
                          null
                      ? 'No registrado'
                      : '${_numero(ensayo!.volumenPatron)} $unidadVolumen',
            ),

            VerDataRow(
              label: 'Diferencia',
              value:
                  diferencia == null
                      ? 'No registrado'
                      : '${_numero(diferencia)} $unidadVolumen',
            ),

            const SizedBox(
              height: 16,
            ),

            /*
             * 6. ERROR Y RESULTADO
             */
            const _PreviewTitle(
              number: '6',
              title:
                  'Error y resultado',
            ),

            VerDataRow(
              label:
                  'Error con signo',
              value:
                  _porcentajeSigno(
                errorConSigno,
              ),
            ),

            VerDataRow(
              label:
                  'Error absoluto',
              value:
                  errorAbsoluto ==
                          null
                      ? 'No registrado'
                      : '${errorAbsoluto.toStringAsFixed(2)} %',
            ),

            /*
             * M6/M8:
             * valores del snapshot normativo
             * guardado con el ensayo.
             */
            VerDataRow(
              label:
                  'Parámetro normativo',
              value:
                  _texto(
                ensayo
                    ?.parametroNormativoCodigoAplicado,
                fallback:
                    'Sin parámetro aplicable',
              ),
            ),

            VerDataRow(
              label:
                  'Límite permitido',
              value:
                  ensayo
                              ?.limiteNormativoAplicado ==
                          null
                      ? 'N/A'
                      : '${ensayo!.limiteNormativoAplicado!.toStringAsFixed(2)} %',
            ),

            VerDataRow(
              label: 'Resultado',
              value:
                  _texto(
                v.resultado,
                fallback:
                    'INDETERMINADO',
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            /*
             * 7. FUGAS
             */
            const _PreviewTitle(
              number: '7',
              title: 'Fugas',
            ),

            VerDataRow(
              label:
                  '¿Registra fuga?',
              value:
                  ensayo?.fugas == null
                      ? 'No registrado'
                      : ensayo!.fugas!
                          ? 'Sí'
                          : 'No',
            ),

            VerDataRow(
              label:
                  'Tipo de fuga',
              value:
                  ensayo?.fugas == true
                      ? _texto(
                          ensayo?.tipoFuga,
                        )
                      : 'No aplica',
            ),

            const SizedBox(
              height: 16,
            ),

            /*
             * 8. CONDICIONES Y OBSERVACIONES
             */
            const _PreviewTitle(
              number: '8',
              title:
                  'Condiciones y observaciones',
            ),

            VerDataRow(
              label: 'Condiciones',
              value:
                  _texto(
                ensayo?.condiciones,
              ),
            ),

            VerDataRow(
              label:
                  'Observaciones',
              value:
                  _texto(
                ensayo?.observaciones,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            /*
             * 9. RESPONSABLE
             */
            const _PreviewTitle(
              number: '9',
              title: 'Responsable',
            ),

            ValueListenableBuilder<
                TextEditingValue>(
              valueListenable:
                  _responsableCtrl,
              builder:
                  (
                    context,
                    value,
                    child,
                  ) {
                final responsable =
                    value.text.trim();

                return VerDataRow(
                  label:
                      'Responsable',
                  value:
                      responsable.isEmpty
                          ? 'Pendiente de ingresar'
                          : responsable,
                );
              },
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Firma del responsable: ______________________________',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                    10,
                  ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                      0xFFFFF9E8,
                    ),
                borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
              ),
              child:
                  const Text(
                'La vista previa utiliza los datos reales actualmente guardados para esta verificación. El PDF final se genera nuevamente desde el backend.',
                style:
                    TextStyle(
                  fontSize: 12.5,
                  color:
                      Color(
                        0xFF765F13,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersiones(
    BuildContext context,
    List<InformeVerificacion>
        informes,
  ) {
    return VerSection(
      title:
          'Versiones emitidas (${informes.length})',
      child: Column(
        children: [
          ...informes.map(
            (informe) =>
                _InformeRow(
              informe:
                  informe,
              busy:
                  _pdfBusy.contains(
                informe.id,
              ),
              onAbrir: () =>
                  _abrir(
                context,
                informe,
              ),
              onDescargar: () =>
                  _descargar(
                context,
                informe,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNuevaEmision(
    bool isAccion,
    String nroPrevisto,
    int proximaVersion,
  ) {
    return VerSection(
      title: 'Nueva emisión',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
                  12,
                ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                    0xFFF6F8FA,
                  ),
              borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
            ),
            child: Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Text(
                  'Informe: $nroPrevisto',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                Text(
                  'Versión: $proximaVersion',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const Text(
                  'Firma digital: No',
                  style:
                      TextStyle(
                    color:
                        Color(
                          0xFF667085,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          TextField(
            controller:
                _responsableCtrl,
            textCapitalization:
                TextCapitalization.words,
            decoration:
                const InputDecoration(
              labelText:
                  'Nombre del responsable *',
              hintText:
                  'Ej. Juan Pérez',
              helperText:
                  'Este nombre aparecerá en el informe como responsable.',
              prefixIcon:
                  Icon(
                    Icons.person_outline,
                  ),
              isDense: true,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                _observacionesCtrl,
            minLines: 2,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText:
                  'Observaciones de la emisión',
              hintText:
                  'Opcional',
              prefixIcon:
                  Icon(
                    Icons.notes_outlined,
                  ),
              alignLabelWithHint:
                  true,
              isDense: true,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
                  12,
                ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                    0xFFF0F7F3,
                  ),
              borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
              border:
                  Border.all(
                color:
                    const Color(
                      0xFFD4E7DC,
                    ),
              ),
            ),
            child:
                const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color:
                      Color(
                        0xFF137A4A,
                      ),
                ),

                SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    'Cada emisión crea una nueva versión. Las versiones anteriores no se eliminan ni reemplazan.',
                    style:
                        TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                FilledButton.icon(
              onPressed:
                  isAccion
                      ? null
                      : _generar,
              icon:
                  isAccion
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Icon(
                          Icons
                              .picture_as_pdf_outlined,
                        ),
              label: Text(
                isAccion
                    ? 'Generando...'
                    : 'Generar informe - versión $proximaVersion',
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _obtenerProximaVersion(
    List<InformeVerificacion>
        informes,
  ) {
    if (informes.isEmpty) {
      return 1;
    }

    var maxVersion = 0;

    for (final informe
        in informes) {
      if (informe.versionInforme >
          maxVersion) {
        maxVersion =
            informe.versionInforme;
      }
    }

    return maxVersion + 1;
  }

  /*
   * M8:
   *
   * Debe reproducir exactamente la misma regla
   * utilizada por SqlVerificacionRepository.
   *
   * v1:
   * INF-VER-2026-000002
   *
   * v2:
   * INF-VER-2026-000002-V2
   *
   * v3:
   * INF-VER-2026-000002-V3
   *
   * Esto permite conservar el índice SQL:
   *
   * UNIQUE (NroInforme)
   */
  String _obtenerNumeroPrevisto(
    List<InformeVerificacion>
        informes,
  ) {
    final year =
        DateTime.now().year;

    final nroBase =
        'INF-VER-$year-${widget.id.toString().padLeft(6, '0')}';

    final proximaVersion =
        _obtenerProximaVersion(
      informes,
    );

    if (proximaVersion <= 1) {
      return nroBase;
    }

    return '$nroBase-V$proximaVersion';
  }

  String _texto(
    String? value, {
    String fallback =
        'No registrado',
  }) {
    final clean =
        value?.trim();

    if (clean == null ||
        clean.isEmpty) {
      return fallback;
    }

    return clean;
  }

  String _numero(
    double? value, {
    int decimals = 4,
  }) {
    if (value == null) {
      return 'No registrado';
    }

    return value.toStringAsFixed(
      decimals,
    );
  }

  String _porcentajeSigno(
    double? value,
  ) {
    if (value == null) {
      return 'No registrado';
    }

    final prefix =
        value > 0 ? '+' : '';

    return '$prefix${value.toStringAsFixed(2)} %';
  }

  Future<void> _generar() async {
    final responsable =
        _responsableCtrl.text.trim();

    if (responsable.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Ingrese el nombre del responsable antes de generar el informe.',
          ),
        ),
      );

      return;
    }

    final state =
        ref.read(
      verificacionControllerProvider,
    );

    final v =
        state.verificacionActual;

    if (v == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró la verificación.',
          ),
        ),
      );

      return;
    }

    if (!v.finalizada) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'La verificación debe estar finalizada antes de emitir el informe.',
          ),
        ),
      );

      return;
    }

    final nroInforme =
        _obtenerNumeroPrevisto(
      state.informes,
    );

    final version =
        _obtenerProximaVersion(
      state.informes,
    );

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Generar informe técnico',
          ),
          content: Text(
            'Se generará:\n\n'
            '$nroInforme\n'
            'Versión $version\n\n'
            'Responsable: $responsable\n\n'
            'Las versiones anteriores se conservarán.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(false),
              child:
                  const Text(
                'Cancelar',
              ),
            ),

            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(true),
              icon:
                  const Icon(
                Icons
                    .picture_as_pdf_outlined,
              ),
              label:
                  const Text(
                'Generar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true ||
        !mounted) {
      return;
    }

    try {
      final notifier =
          ref.read(
        verificacionControllerProvider
            .notifier,
      );

      await notifier.generarInforme(
        widget.id,
        observaciones:
            _observacionesCtrl.text
                .trim(),
        nombreResponsable:
            responsable,
      );

      /*
       * Recargamos desde backend para que la UI
       * tome inmediatamente:
       *
       * - NroInforme real
       * - VersionInforme
       * - RutaPdf
       * - FechaEmision
       */
      await notifier.cargarInformes(
        widget.id,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  /*
   * M8:
   *
   * Abrir PDF utiliza un archivo temporal.
   *
   * El nombre incorpora tanto el NroInforme
   * como VersionInforme.
   *
   * Ejemplos:
   *
   * v1:
   * INF-VER-2026-000002_v1.pdf
   *
   * v2:
   * INF-VER-2026-000002-V2_v2.pdf
   */
  Future<void> _abrir(
    BuildContext context,
    InformeVerificacion informe,
  ) async {
    if (_pdfBusy.contains(
      informe.id,
    )) {
      return;
    }

    setState(() {
      _pdfBusy.add(
        informe.id,
      );
    });

    try {
      final repo =
          ref.read(
        verificacionRepositoryProvider,
      );

      final nombreVersionado =
          '${informe.nroInforme}_v${informe.versionInforme}';

      final path =
          await repo
              .prepararInformeTemporal(
        informe.id,
        nombreVersionado,
      );

      if (path.isEmpty) {
        return;
      }

      final result =
          await OpenFilex.open(
        path,
      );

      if (!context.mounted) {
        return;
      }

      if (result.type !=
          ResultType.done) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              result.message
                      .trim()
                      .isNotEmpty
                  ? result.message
                  : 'No se pudo abrir el PDF.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content:
                Text(
              e.toString(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pdfBusy.remove(
            informe.id,
          );
        });
      }
    }
  }

  /*
   * M8:
   *
   * Cada informe se descarga con nombre propio.
   *
   * v1:
   * INF-VER-2026-000002_v1.pdf
   *
   * v2:
   * INF-VER-2026-000002-V2_v2.pdf
   *
   * v3:
   * INF-VER-2026-000002-V3_v3.pdf
   */
  Future<void> _descargar(
    BuildContext context,
    InformeVerificacion informe,
  ) async {
    if (_pdfBusy.contains(
      informe.id,
    )) {
      return;
    }

    setState(() {
      _pdfBusy.add(
        informe.id,
      );
    });

    try {
      final repo =
          ref.read(
        verificacionRepositoryProvider,
      );

      final nombreVersionado =
          '${informe.nroInforme}_v${informe.versionInforme}';

      final path =
          await repo.descargarInforme(
        informe.id,
        nombreVersionado,
      );

      if (path.isNotEmpty &&
          context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'PDF guardado en:\n$path',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content:
                Text(
              e.toString(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pdfBusy.remove(
            informe.id,
          );
        });
      }
    }
  }
}

class _PreviewTitle
    extends StatelessWidget {
  const _PreviewTitle({
    required this.number,
    required this.title,
  });

  final String number;
  final String title;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                    0xFFE1F0E8,
                  ),
              borderRadius:
                  BorderRadius.circular(
                    6,
                  ),
            ),
            child: Text(
              number,
              style:
                  const TextStyle(
                color:
                    Color(
                      0xFF006B45,
                    ),
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 2,
              ),
              child: Text(
                title,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformeRow
    extends StatelessWidget {
  const _InformeRow({
    required this.informe,
    required this.busy,
    required this.onAbrir,
    required this.onDescargar,
  });

  final InformeVerificacion informe;
  final bool busy;
  final VoidCallback onAbrir;
  final VoidCallback onDescargar;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(
          12,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
                0xFFF6F8F7,
              ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          border:
              Border.all(
            color:
                const Color(
                  0xFFDDE4E0,
                ),
          ),
        ),
        child: LayoutBuilder(
          builder:
              (
                context,
                constraints,
              ) {
            final compact =
                constraints.maxWidth <
                    620;

            final info =
                Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons
                      .description_outlined,
                  color:
                      AppColors.darkBlue,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        informe.nroInforme,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        'Versión ${informe.versionInforme} · '
                        '${verDate(informe.fechaEmision, time: true)}',
                        style:
                            const TextStyle(
                          color:
                              Color(
                                0xFF667085,
                              ),
                          fontSize: 12,
                        ),
                      ),

                      if (informe
                              .observaciones !=
                          null &&
                          informe
                              .observaciones!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          informe
                              .observaciones!
                              .trim(),
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Color(
                                  0xFF667085,
                                ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final actions =
                Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment:
                  WrapCrossAlignment
                      .center,
              children: [
                VerStatusChip(
                  informe.firmado
                      ? 'Firmado'
                      : 'Pendiente firma',
                ),

                if (busy)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    tooltip:
                        'Abrir PDF',
                    onPressed:
                        onAbrir,
                    icon:
                        const Icon(
                      Icons
                          .open_in_new_outlined,
                    ),
                  ),

                  IconButton(
                    tooltip:
                        'Descargar PDF',
                    onPressed:
                        onDescargar,
                    icon:
                        const Icon(
                      Icons
                          .download_outlined,
                    ),
                  ),
                ],
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  info,

                  const SizedBox(
                    height: 10,
                  ),

                  Align(
                    alignment:
                        Alignment.centerRight,
                    child: actions,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: info,
                ),

                const SizedBox(
                  width: 12,
                ),

                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}