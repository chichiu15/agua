import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/admin_controller.dart';
import '../widgets/admin_shell.dart';

class AdminCatalogosScreen extends ConsumerStatefulWidget {
  const AdminCatalogosScreen({super.key});

  @override
  ConsumerState<AdminCatalogosScreen> createState() => _AdminCatalogosScreenState();
}

class _AdminCatalogosScreenState extends ConsumerState<AdminCatalogosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminControllerProvider.notifier).cargarCatalogos());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    return AdminShell(
      title: 'Catalogos Operativos',
      subtitle: 'R3-R4 - Consulta de motivos de cambio y marcas oficiales de COSAALT.',
      currentRoute: '/admin/catalogos',
      actions: [
        OutlinedButton.icon(
          onPressed: state.isLoading
              ? null
              : () => ref.read(adminControllerProvider.notifier).cargarCatalogos(),
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminMessage(error: state.errorMessage, success: state.successMessage),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              border: Border.all(color: const Color(0xFFBFE3CC)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: Color(0xFF006B3F)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estos catalogos pertenecen a COSAALT y se leen desde el esquema dbo. '
                    'Desde esta aplicacion NO se crean, editan ni eliminan motivos o marcas. '
                    'Esto mantiene una sola fuente de verdad.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoading) const LinearProgressIndicator(),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final motivos = _CatalogPanel(
                icon: Icons.build_circle_outlined,
                title: 'Motivos de cambio',
                source: 'dbo.MotivosCambioMedidor',
                emptyText: 'No se encontraron motivos activos.',
                rows: state.motivos
                    .map((m) => _CatalogRow(code: m.id.toString(), name: m.descripcion))
                    .toList(),
                isLoading: state.isLoading,
              );
              final marcas = _CatalogPanel(
                icon: Icons.speed_outlined,
                title: 'Marcas de medidor',
                source: 'dbo.Marcas',
                emptyText: 'No se encontraron marcas.',
                rows: state.marcas
                    .map(
                      (m) => _CatalogRow(
                        code: m.id.toString(),
                        name: m.nombre,
                        extra: m.alias,
                      ),
                    )
                    .toList(),
                isLoading: state.isLoading,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    motivos,
                    const SizedBox(height: 16),
                    marcas,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: motivos),
                  const SizedBox(width: 16),
                  Expanded(child: marcas),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CatalogPanel extends StatelessWidget {
  const _CatalogPanel({
    required this.icon,
    required this.title,
    required this.source,
    required this.emptyText,
    required this.rows,
    required this.isLoading,
  });

  final IconData icon;
  final String title;
  final String source;
  final String emptyText;
  final List<Widget> rows;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF006B3F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(source, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 24),
          if (rows.isEmpty && !isLoading) Text(emptyText),
          ...rows,
        ],
      ),
    );
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({required this.code, required this.name, this.extra});

  final String code;
  final String name;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        border: Border.all(color: const Color(0xFFE3E8E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '#$code',
              style: const TextStyle(
                color: Color(0xFF006B3F),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              softWrap: true,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (extra != null && extra!.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                extra!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
