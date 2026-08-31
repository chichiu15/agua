import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_models.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_shell.dart';

class AdminParametrosScreen extends ConsumerStatefulWidget {
  const AdminParametrosScreen({super.key});
  @override ConsumerState<AdminParametrosScreen> createState() => _AdminParametrosScreenState();
}

class _AdminParametrosScreenState extends ConsumerState<AdminParametrosScreen> {
  final _caudalCtrl = TextEditingController(text: '120');

  @override void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminControllerProvider.notifier).cargarParametros());
  }

  @override void dispose() { _caudalCtrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    return AdminShell(
      title: 'Parametros Normativos',
      subtitle: 'Configura los limites de error y rangos de caudal utilizados en la verificacion metrologica.',
      currentRoute: '/admin/parametros',
      actions: [FilledButton.icon(onPressed: state.isSaving ? null : () => _abrirFormulario(context, null), icon: const Icon(Icons.add), label: const Text('Nuevo parametro'))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AdminMessage(error: state.errorMessage, success: state.successMessage),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF0F5FF), border: Border.all(color: const Color(0xFFC9DAFF)), borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [Icon(Icons.info_outline, color: Color(0xFF1677FF)), SizedBox(width: 10), Expanded(child: Text('Estos parametros se utilizan para determinar automaticamente si el resultado de una verificacion se encuentra dentro del limite permitido.'))]),
        ),
        const SizedBox(height: 16),
        if (state.isLoading) const LinearProgressIndicator(),
        AdminCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F6F4)),
              columns: const [
                DataColumn(label: Text('Codigo')),
                DataColumn(label: Text('Descripcion')),
                DataColumn(label: Text('Error max. %')),
                DataColumn(label: Text('Caudal min')),
                DataColumn(label: Text('Caudal max')),
                DataColumn(label: Text('Vigencia inicio')),
                DataColumn(label: Text('Vigencia fin')),
                DataColumn(label: Text('Activo')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: state.parametros.map((p) => DataRow(cells: [
                DataCell(Text(p.codigo, style: const TextStyle(fontWeight: FontWeight.w800))),
                DataCell(SizedBox(width: 220, child: Text(p.descripcion ?? '-', overflow: TextOverflow.ellipsis))),
                DataCell(Text('${_num(p.errorMaxPermitido)} %')),
                DataCell(Text(p.caudalMin == null ? '-' : _num(p.caudalMin!))),
                DataCell(Text(p.caudalMax == null ? '-' : _num(p.caudalMax!))),
                DataCell(Text(_date(p.vigenciaInicio))),
                DataCell(Text(_date(p.vigenciaFin))),
                DataCell(Switch(value: p.activo, onChanged: state.isSaving ? null : (v) => ref.read(adminControllerProvider.notifier).cambiarEstadoParametro(p, v))),
                DataCell(IconButton(tooltip: 'Editar', onPressed: state.isSaving ? null : () => _abrirFormulario(context, p), icon: const Icon(Icons.edit_outlined))),
              ])).toList(),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AdminCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final form = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consultar parametro aplicable',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ingrese un caudal para consultar que parametro vigente corresponde a ese rango.',
                    style: TextStyle(color: Color(0xFF68737D)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
                        child: TextField(
                          controller: _caudalCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Caudal del ensayo',
                            suffixText: 'L/h',
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: state.isSaving
                            ? null
                            : () {
                                final value = double.tryParse(
                                  _caudalCtrl.text.trim().replaceAll(',', '.'),
                                );
                                if (value == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ingrese un caudal valido.'),
                                    ),
                                  );
                                  return;
                                }
                                ref
                                    .read(adminControllerProvider.notifier)
                                    .probarVigente(value);
                              },
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Consultar'),
                      ),
                    ],
                  ),
                ],
              );
              final result = _ResultadoVigente(item: state.parametroVigente);

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    const SizedBox(height: 18),
                    result,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: 24),
                  Expanded(child: result),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _abrirFormulario(BuildContext context, ParametroNormativo? item) async {
    final formKey = GlobalKey<FormState>();
    final codigo = TextEditingController(text: item?.codigo ?? '');
    final descripcion = TextEditingController(text: item?.descripcion ?? '');
    final error = TextEditingController(text: item == null ? '' : _num(item.errorMaxPermitido));
    final min = TextEditingController(text: item?.caudalMin == null ? '' : _num(item!.caudalMin!));
    final max = TextEditingController(text: item?.caudalMax == null ? '' : _num(item!.caudalMax!));
    DateTime? inicio = item?.vigenciaInicio;
    DateTime? fin = item?.vigenciaFin;
    bool activo = item?.activo ?? true;

    final accepted = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(item == null ? 'Nuevo parametro normativo' : 'Editar parametro normativo'),
          content: SizedBox(
            width: 650,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: codigo, decoration: const InputDecoration(labelText: 'Codigo *', hintText: 'Ej. NB-ISO4064-Q2'), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio.' : null),
                const SizedBox(height: 12),
                TextFormField(controller: descripcion, decoration: const InputDecoration(labelText: 'Descripcion')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: error, decoration: const InputDecoration(labelText: 'Error maximo permitido *', suffixText: '%'), validator: _decimalRequired)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: min, decoration: const InputDecoration(labelText: 'Caudal minimo', suffixText: 'L/h'), validator: _decimalOptional)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: max, decoration: const InputDecoration(labelText: 'Caudal maximo', suffixText: 'L/h'), validator: _decimalOptional)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _DateField(label: 'Vigencia inicio (opcional)', value: inicio, onTap: () async { final d = await _pickDate(context, inicio); if (d != null) setLocalState(() => inicio = d); }, onClear: () => setLocalState(() => inicio = null))),
                  const SizedBox(width: 12),
                  Expanded(child: _DateField(label: 'Vigencia fin (opcional)', value: fin, onTap: () async { final d = await _pickDate(context, fin); if (d != null) setLocalState(() => fin = d); }, onClear: () => setLocalState(() => fin = null))),
                ]),
                const SizedBox(height: 4),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Parametro activo'), subtitle: const Text('Solo los activos pueden ser seleccionados por la validacion mecanica.'), value: activo, onChanged: (v) => setLocalState(() => activo = v)),
              ])),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () { if (formKey.currentState?.validate() == true) Navigator.pop(dialogContext, true); }, child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (accepted == true && mounted) {
      final errorValue = _parse(error.text)!;
      final minValue = _parse(min.text);
      final maxValue = _parse(max.text);
      if (minValue != null && maxValue != null && minValue > maxValue) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El caudal minimo no puede ser mayor al maximo.')));
      } else if (inicio != null && fin != null && inicio!.isAfter(fin!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La vigencia inicial no puede ser posterior a la final.')));
      } else {
        await ref.read(adminControllerProvider.notifier).guardarParametro(
          id: item?.id,
          parametro: GuardarParametroNormativo(
            codigo: codigo.text.trim(), descripcion: descripcion.text.trim().isEmpty ? null : descripcion.text.trim(),
            errorMaxPermitido: errorValue, caudalMin: minValue, caudalMax: maxValue,
            vigenciaInicio: inicio, vigenciaFin: fin, activo: activo,
          ),
        );
      }
    }
    codigo.dispose(); descripcion.dispose(); error.dispose(); min.dispose(); max.dispose();
  }

  static String? _decimalRequired(String? value) => _parse(value ?? '') == null ? 'Ingrese un numero valido.' : null;
  static String? _decimalOptional(String? value) => value == null || value.trim().isEmpty || _parse(value) != null ? null : 'Numero invalido.';
  static double? _parse(String value) => value.trim().isEmpty ? null : double.tryParse(value.trim().replaceAll(',', '.'));
  static String _num(double value) => value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  static String _date(DateTime? value) => value == null ? '-' : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  static Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) => showDatePicker(context: context, initialDate: initial ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
}

class _ResultadoVigente extends StatelessWidget {
  const _ResultadoVigente({required this.item}); final ParametroNormativo? item;
  @override Widget build(BuildContext context) {
    if (item == null) return Container(height: 126, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF7F9F8), borderRadius: BorderRadius.circular(10)), child: const Text('Ejecute una prueba para ver la regla seleccionada.', style: TextStyle(color: Colors.grey)));
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFEAF7EF), border: Border.all(color: const Color(0xFFBFE3CC)), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.check_circle, color: Color(0xFF0A7A45)), SizedBox(width: 8), Text('Regla vigente encontrada', style: TextStyle(fontWeight: FontWeight.w800))]),
        const SizedBox(height: 8),
        Text(item!.codigo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text('Error maximo: ${item!.errorMaxPermitido}%'),
        Text('Rango: ${item!.caudalMin ?? '-'} - ${item!.caudalMax ?? '-'} L/h'),
      ]),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, this.onClear});
  final String label; final DateTime? value; final VoidCallback onTap; final VoidCallback? onClear;
  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [if (onClear != null && value != null) IconButton(onPressed: onClear, icon: const Icon(Icons.clear, size: 18)), const Icon(Icons.calendar_today_outlined, size: 18), const SizedBox(width: 10)])),
      child: Text(value == null ? 'Sin fecha' : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'),
    ),
  );
}
