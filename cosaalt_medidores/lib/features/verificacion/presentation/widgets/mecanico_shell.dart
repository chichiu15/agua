import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Marco persistente para las pantallas internas del módulo Mecánico.
///
/// Mantiene visibles el encabezado institucional y la navegación inferior
/// mientras cambia únicamente el contenido central.
class MecanicoDetailShell extends ConsumerWidget {
  const MecanicoDetailShell({
    required this.child,
    super.key,
  });

  final Widget child;

  static const String _mecanicoHome = '/mecanico';

  void _irATab(BuildContext context, int index) {
    switch (index) {
      case 1:
        context.go('$_mecanicoHome?tab=1');
        return;
      case 2:
        context.go('$_mecanicoHome?tab=2');
        return;
      default:
        context.go(_mecanicoHome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CosaaltAppBar(
        automaticallyImplyLeading: false,
        onLogout: () {
          ref.read(authControllerProvider.notifier).logout();
        },
      ),
      body: child,
      bottomNavigationBar: MecanicoBottomNav(
        currentIndex: 0,
        onTap: (index) => _irATab(context, index),
      ),
    );
  }
}

/// Navegación inferior compartida por el inicio y las pantallas internas
/// del módulo Mecánico. Tener una sola definición evita que el footer cambie
/// visualmente entre pantallas.
class MecanicoBottomNav extends StatelessWidget {
  const MecanicoBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex.clamp(0, 2).toInt(),
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: AppColors.darkBlue,
      backgroundColor: Colors.white,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Solicitudes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Historial',
        ),
      ],
    );
  }
}


/// Barra de título interna para las pantallas que viven dentro del shell
/// persistente del módulo Mecánico.
///
/// A diferencia del encabezado institucional, esta barra es neutra: evita
/// mostrar dos encabezados verdes y conserva las acciones propias de cada
/// pantalla (volver, actualizar, etc.).
class MecanicoPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MecanicoPageAppBar({
    required this.title,
    this.leading,
    this.actions,
    super.key,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: AppColors.darkBlue,
      titleTextStyle: const TextStyle(
        color: AppColors.darkBlue,
        fontWeight: FontWeight.w800,
        fontSize: 19,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkBlue),
      leading: leading,
      title: title,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1),
      ),
    );
  }
}
