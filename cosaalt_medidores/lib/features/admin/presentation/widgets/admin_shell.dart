import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentRoute,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final String currentRoute;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, root) {
            final compactNav = root.maxWidth < 1120;
            final veryCompact = root.maxWidth < 760;
            final navWidth = veryCompact ? 64.0 : (compactNav ? 82.0 : 238.0);

            return Column(
              children: [
                Container(
                  height: 66,
                  color: const Color(0xFF006B3F),
                  padding: EdgeInsets.symmetric(horizontal: veryCompact ? 10 : 18),
                  child: Row(
                    children: [
                      // La identidad del modulo ocupa solo el espacio disponible.
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/logo_cosaalt.png',
                              height: 42,
                              width: 42,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.water_drop,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                            if (!veryCompact) ...[
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'COSAALT - Modulo Medidores',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // El bloque del usuario siempre queda anclado a la derecha.
                      if (!veryCompact) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF68D391), size: 18),
                              SizedBox(width: 7),
                              Text(
                                'Conectado',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF006B3F),
                        child: Text(_initials(user?.fullName ?? 'AD')),
                      ),
                      if (!veryCompact) ...[
                        const SizedBox(width: 9),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: compactNav ? 145 : 190),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Administrador',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(
                                'Administrador',
                                style: TextStyle(color: Color(0xFFD7EEE3), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                      PopupMenuButton<String>(
                        iconColor: Colors.white,
                        onSelected: (value) {
                          if (value == 'logout') {
                            ref.read(authControllerProvider.notifier).logout();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout),
                                SizedBox(width: 8),
                                Text('Cerrar sesion'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: navWidth,
                        color: Colors.white,
                        padding: EdgeInsets.fromLTRB(
                          compactNav ? 8 : 12,
                          18,
                          compactNav ? 8 : 12,
                          14,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                            _NavItem(
                              icon: Icons.dashboard_outlined,
                              label: 'Dashboard',
                              route: '/admin',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Divider()),
                            _SectionLabel('GESTION DE CAMBIOS', compact: compactNav),
                            _NavItem(
                              icon: Icons.assignment_outlined,
                              label: 'Solicitudes',
                              route: '/admin/solicitudes',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            _NavItem(
                              icon: Icons.route_outlined,
                              label: 'Recorridos',
                              route: '/admin/recorridos',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            _NavItem(
                              icon: Icons.sync_outlined,
                              label: 'Sincronizacion',
                              route: '/admin/sincronizacion',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            _NavItem(
                              icon: Icons.table_rows_outlined,
                              label: 'Planilla Digital',
                              route: '/admin/movimientos',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            _NavItem(
                              icon: Icons.bar_chart_outlined,
                              label: 'Reportes',
                              route: '/admin/reportes',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Divider()),
                            _SectionLabel('REVISION MECANICA', compact: compactNav),
                            _NavItem(
                              icon: Icons.fact_check_outlined,
                              label: 'Verificaciones',
                              route: '/admin/verificaciones',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            _NavItem(
                              icon: Icons.description_outlined,
                              label: 'Informes Tecnicos',
                              route: '/admin/informes',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Divider()),
                            _SectionLabel('CONFIGURACION', compact: compactNav),
                            _NavItem(
                              icon: Icons.people_outline,
                              label: 'Usuarios',
                              route: '/admin/usuarios',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            _NavItem(
                              icon: Icons.inventory_2_outlined,
                              label: 'Catalogos',
                              route: '/admin/catalogos',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                            _NavItem(
                              icon: Icons.rule_outlined,
                              label: 'Parametros Normativos',
                              route: '/admin/parametros',
                              currentRoute: currentRoute,
                              compact: compactNav,
                            ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(),
                            if (!compactNav)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Modulo de Administracion',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.fromLTRB(
                                compactNav ? 16 : 24,
                                16,
                                compactNav ? 16 : 24,
                                14,
                              ),
                              child: LayoutBuilder(
                                builder: (context, header) {
                                  final stack = header.maxWidth < 650 && actions.isNotEmpty;
                                  final titleBlock = Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: compactNav ? 22 : 25,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF17212B),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(color: Color(0xFF68737D)),
                                      ),
                                    ],
                                  );

                                  if (stack) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        titleBlock,
                                        const SizedBox(height: 12),
                                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: titleBlock),
                                      if (actions.isNotEmpty)
                                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(veryCompact ? 10 : (compactNav ? 16 : 24)),
                                child: child,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AD';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Tooltip(
        message: compact ? label : '',
        child: Material(
          color: selected ? const Color(0xFFE9F4EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => context.go(route),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: 12,
              ),
              child: compact
                  ? Center(
                      child: Icon(
                        icon,
                        size: 21,
                        color: selected
                            ? const Color(0xFF006B3F)
                            : const Color(0xFF46515C),
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: selected
                              ? const Color(0xFF006B3F)
                              : const Color(0xFF46515C),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected
                                  ? const Color(0xFF006B3F)
                                  : const Color(0xFF35404A),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.compact});
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return const SizedBox(height: 2);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 8, 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF8A949D),
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE4E0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminMessage extends StatelessWidget {
  const AdminMessage({super.key, this.error, this.success});

  final String? error;
  final String? success;

  @override
  Widget build(BuildContext context) {
    final text = error ?? success;
    if (text == null) return const SizedBox.shrink();
    final isError = error != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F1) : const Color(0xFFEAF7EF),
        border: Border.all(
          color: isError ? const Color(0xFFFFCACA) : const Color(0xFFBFE3CC),
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : AppColors.primaryGreen,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
