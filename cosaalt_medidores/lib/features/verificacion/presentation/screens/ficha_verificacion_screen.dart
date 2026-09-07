import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/verificacion_mecanico.dart';
import '../controllers/verificacion_controller.dart';
import '../widgets/mecanico_shell.dart';
import '../widgets/verificacion_ui.dart';

class FichaVerificacionScreen extends ConsumerStatefulWidget {
  const FichaVerificacionScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<FichaVerificacionScreen> createState() =>
      _FichaVerificacionScreenState();
}

class _FichaVerificacionScreenState
    extends ConsumerState<FichaVerificacionScreen> {
  static const String _noRegistrado = 'No registrado';

  /// M4:
  /// Los únicos tipos permitidos por el reparto.
  static const List<String> _tiposParticipante = [
    'Personal COSAALT',
    'Técnico verificador',
    'Representante del usuario',
    'Otro',
  ];

  final List<ParticipanteVerificacion> _participantes = [];

  @override
  void initState() {
    super.initState();

    Future.microtask(_cargarVerificacion);
  }

  Future<void> _cargarVerificacion() async {
    final controller = ref.read(verificacionControllerProvider.notifier);

    await controller.cargarVerificacion(widget.id);

    if (!mounted) return;

    final state = ref.read(verificacionControllerProvider);

    final participantes =
        state.participantesBorrador ??
        state.verificacionActual?.participantes ??
        const <ParticipanteVerificacion>[];

    setState(() {
      _participantes
        ..clear()
        ..addAll(participantes);
    });
  }

  String? _normalizarTipo(String? value) {
    final limpio = value?.trim();

    if (limpio == null || limpio.isEmpty) {
      return null;
    }

    for (final tipo in _tiposParticipante) {
      if (tipo.toLowerCase() == limpio.toLowerCase()) {
        return tipo;
      }
    }

    /*
     * Puede existir información antigua creada cuando
     * "Rol" todavía era un campo de texto libre.
     *
     * No eliminamos el participante.
     * Al editarlo, se seleccionará "Otro".
     */
    return 'Otro';
  }

  Future<ParticipanteVerificacion?> _mostrarEditorParticipante({
    ParticipanteVerificacion? participante,
  }) async {
    final nombreController = TextEditingController(
      text: participante?.nombre ?? '',
    );

    final cargoController = TextEditingController(
      text: participante?.cargo ?? '',
    );

    String? tipoSeleccionado = _normalizarTipo(participante?.rol);

    String? errorNombre;
    String? errorTipo;

    final resultado = await showDialog<ParticipanteVerificacion>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                participante == null
                    ? 'Agregar participante'
                    : 'Editar participante',
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nombre y apellido *',
                          border: const OutlineInputBorder(),
                          errorText: errorNombre,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: cargoController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Cargo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        key: ValueKey(tipoSeleccionado),
                        initialValue: tipoSeleccionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Tipo de participante *',
                          border: const OutlineInputBorder(),
                          errorText: errorTipo,
                        ),
                        items: _tiposParticipante
                            .map(
                              (tipo) => DropdownMenuItem<String>(
                                value: tipo,
                                child: Text(tipo),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            tipoSeleccionado = value;
                            errorTipo = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                  onPressed: () {
                    final nombre = nombreController.text.trim();
                    final cargo = cargoController.text.trim();

                    var valido = true;

                    if (nombre.isEmpty) {
                      valido = false;
                      errorNombre = 'Ingrese el nombre del participante.';
                    } else {
                      errorNombre = null;
                    }

                    if (tipoSeleccionado == null) {
                      valido = false;
                      errorTipo = 'Seleccione el tipo de participante.';
                    } else {
                      errorTipo = null;
                    }

                    if (!valido) {
                      setModalState(() {});
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      ParticipanteVerificacion(
                        id: participante?.id,
                        nombre: nombre,
                        cargo: cargo.isEmpty ? null : cargo,
                        rol: tipoSeleccionado,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    cargoController.dispose();

    return resultado;
  }

  Future<void> _agregarParticipante() async {
    final nuevo = await _mostrarEditorParticipante();

    if (!mounted || nuevo == null) return;

    setState(() {
      _participantes.add(nuevo);
    });
  }

  Future<void> _editarParticipante(int index) async {
    if (index < 0 || index >= _participantes.length) {
      return;
    }

    final editado = await _mostrarEditorParticipante(
      participante: _participantes[index],
    );

    if (!mounted || editado == null) return;

    setState(() {
      _participantes[index] = editado;
    });
  }

  Future<void> _eliminarParticipante(int index) async {
    if (index < 0 || index >= _participantes.length) {
      return;
    }

    final participante = _participantes[index];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar participante'),
          content: Text(
            '¿Desea eliminar a "${participante.nombre}" de la verificación?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    setState(() {
      _participantes.removeAt(index);
    });
  }

  Future<bool> _guardarParticipantes() async {
    /*
     * Validación defensiva.
     * Normalmente estos errores no aparecerán porque
     * el formulario de agregar/editar ya valida.
     */
    for (var i = 0; i < _participantes.length; i++) {
      final participante = _participantes[i];

      if (participante.nombre.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El participante ${i + 1} no tiene nombre.'),
            ),
          );
        }
        return false;
      }

      if (_normalizarTipo(participante.rol) == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seleccione el tipo del participante ${i + 1}.'),
            ),
          );
        }
        return false;
      }
    }

    final participantesLimpios = _participantes.map((p) {
      final cargo = p.cargo?.trim();

      return ParticipanteVerificacion(
        id: p.id,
        nombre: p.nombre.trim(),
        cargo: cargo == null || cargo.isEmpty ? null : cargo,
        rol: _normalizarTipo(p.rol),
      );
    }).toList();

    final error = await ref
        .read(verificacionControllerProvider.notifier)
        .guardarParticipantes(widget.id, participantesLimpios);

    if (!mounted) return error == null;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return false;
    }

    /*
     * Volvemos a tomar la lista entregada por
     * el backend. De esta forma también tenemos
     * los IdParticipante generados por SQL Server.
     */
    final actualizada = ref
        .read(verificacionControllerProvider)
        .verificacionActual;

    if (actualizada != null) {
      setState(() {
        _participantes
          ..clear()
          ..addAll(actualizada.participantes);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Participantes guardados correctamente.')),
    );

    return true;
  }

  Future<void> _guardarYContinuar() async {
    /*
     * IMPORTANTE:
     *
     * Antes la pantalla navegaba al ensayo aunque
     * guardarParticipantes hubiera fallado.
     *
     * Ahora solamente avanzamos cuando el backend
     * confirmó el guardado.
     */
    final guardado = await _guardarParticipantes();

    if (!mounted || !guardado) return;

    context.go('${AppRoutes.mecanicoHome}/verificacion/${widget.id}/ensayo');
  }

  String _valor(String? value) {
    final limpio = value?.trim();

    return limpio == null || limpio.isEmpty ? _noRegistrado : limpio;
  }

  String _entero(int? value) {
    return value == null ? _noRegistrado : '$value';
  }

  String _fecha(DateTime? value, {bool time = false}) {
    if (value == null || value.millisecondsSinceEpoch == 0) {
      return _noRegistrado;
    }

    String two(int v) => v.toString().padLeft(2, '0');

    final fecha = '${two(value.day)}/${two(value.month)}/${value.year}';

    if (!time) return fecha;

    return '$fecha ${two(value.hour)}:${two(value.minute)}';
  }

  String _documento(DatosSocioMedidor? datos) {
    final partes = [datos?.tipDocumento, datos?.numeroDocumento]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return partes.isEmpty ? _noRegistrado : partes.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificacionControllerProvider);

    final verificacion = state.verificacionActual;

    final datos = state.datosSocio;

    return Scaffold(
      appBar: MecanicoPageAppBar(
        title: const Text('Ficha de Verificación'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go(AppRoutes.mecanicoHome);
            }
          },
        ),
      ),
      body: state.isLoading && verificacion == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VerMessageBar(
                  error: state.errorMessage,
                  success: state.successMessage,
                ),

                /*
                 * M3
                 * -------------------------------------------------
                 * Se mantiene completa la ficha base que ya
                 * corregimos anteriormente.
                 */
                VerSection(
                  title: 'Ficha base de verificación',
                  child: verificacion == null
                      ? const Text('No se encontró la verificación.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _valor(
                                      datos?.nombreCliente ??
                                          verificacion.nombreCliente,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                VerStatusChip(verificacion.estado),
                              ],
                            ),

                            const Divider(height: 18),

                            VerDataRow(
                              label: 'Usuario / mecánico',
                              value: _valor(verificacion.nombreMecanico),
                            ),

                            VerDataRow(
                              label: 'Código / conexión',
                              value: _entero(datos?.codConexion),
                            ),

                            VerDataRow(
                              label: 'Registro del socio',
                              value: _entero(
                                datos?.regSoc ?? verificacion.codCon,
                              ),
                            ),

                            VerDataRow(
                              label: 'Dirección',
                              value: _valor(datos?.direccion),
                            ),

                            VerDataRow(
                              label: 'Documento',
                              value: _documento(datos),
                            ),

                            VerDataRow(label: 'RUC', value: _valor(datos?.ruc)),

                            const Divider(height: 18),

                            VerDataRow(
                              label: 'Marca',
                              value: _valor(datos?.marcaMedidor),
                            ),

                            VerDataRow(
                              label: 'Serie',
                              value: _valor(
                                datos?.numeroMedidor ?? verificacion.idMedidor,
                              ),
                            ),

                            VerDataRow(
                              label: 'Capacidad nominal Q3',
                              value: _valor(datos?.capacidadQ3),
                            ),

                            VerDataRow(
                              label: 'Tipo',
                              value: _valor(datos?.tipoMedidor),
                            ),

                            VerDataRow(
                              label: 'Clase',
                              value: _valor(datos?.claseMedidor),
                            ),

                            VerDataRow(
                              label: 'Diámetro',
                              value: _valor(datos?.diametroMedidor),
                            ),

                            VerDataRow(
                              label: 'Fecha conexión / registro',
                              value: _fecha(datos?.fechaConexion),
                            ),

                            const Divider(height: 18),

                            VerDataRow(
                              label: 'Fecha de verificación',
                              value: _fecha(
                                verificacion.fechaVerificacion,
                                time: true,
                              ),
                            ),

                            VerDataRow(
                              label: 'Lugar de verificación',
                              value: _valor(datos?.lugarVerificacion),
                            ),

                            VerDataRow(
                              label: 'Tipo de ensayo',
                              value: _valor(
                                datos?.tipoEnsayo ??
                                    verificacion.ensayo?.tipoPrueba,
                              ),
                            ),

                            VerDataRow(
                              label: 'Motivo / observación',
                              value: _valor(datos?.motivoObservacion),
                            ),

                            VerDataRow(
                              label: 'Origen',
                              value:
                                  '${verificacion.tipoOrigen} - ${verificacion.idOrigen}',
                            ),

                            if (verificacion.resultado != null) ...[
                              const SizedBox(height: 6),
                              VerDataRow(
                                label: 'Resultado',
                                value: _valor(verificacion.resultado),
                              ),
                            ],
                          ],
                        ),
                ),

                /*
                 * M4
                 * -------------------------------------------------
                 * Participantes.
                 */
                if (!(verificacion?.finalizada ?? false))
                  VerSection(
                    title: 'Participantes',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registre las personas presentes durante la verificación.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 12),

                        if (_participantes.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9F8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD9E2E7),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  size: 38,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No hay participantes registrados.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...List.generate(_participantes.length, (index) {
                            final participante = _participantes[index];

                            return _ParticipanteCard(
                              participante: participante,
                              numero: index + 1,
                              onEditar: () => _editarParticipante(index),
                              onEliminar: () => _eliminarParticipante(index),
                            );
                          }),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: state.isAccion
                                ? null
                                : _agregarParticipante,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar participante'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: state.isAccion
                                ? null
                                : () async {
                                    await _guardarParticipantes();
                                  },
                            icon: state.isAccion
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              state.isAccion
                                  ? 'Guardando...'
                                  : 'Guardar participantes',
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: state.isAccion
                                ? null
                                : _guardarYContinuar,
                            icon: const Icon(Icons.science_outlined),
                            label: const Text('Continuar al ensayo'),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go(
                          '${AppRoutes.mecanicoHome}/verificacion/${widget.id}/informe',
                        ),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Ver informe'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ParticipanteCard extends StatelessWidget {
  const _ParticipanteCard({
    required this.participante,
    required this.numero,
    required this.onEditar,
    required this.onEliminar,
  });

  final ParticipanteVerificacion participante;
  final int numero;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  String _dato(String? value) {
    final limpio = value?.trim();

    return limpio == null || limpio.isEmpty ? 'No registrado' : limpio;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD9E2E7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE9F4EE),
                  child: Text(
                    '$numero',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    participante.nombre,
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _ParticipanteDato(
              icon: Icons.badge_outlined,
              label: 'Cargo',
              value: _dato(participante.cargo),
            ),

            const SizedBox(height: 5),

            _ParticipanteDato(
              icon: Icons.groups_outlined,
              label: 'Tipo de participante',
              value: _dato(participante.rol),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),

                const SizedBox(width: 6),

                TextButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.odecoRed,
                  ),
                  label: const Text(
                    'Eliminar',
                    style: TextStyle(color: AppColors.odecoRed),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipanteDato extends StatelessWidget {
  const _ParticipanteDato({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(
                context,
              ).style.copyWith(fontSize: 13, color: const Color(0xFF374151)),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
