import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_catalogos_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_parametros_screen.dart';
import '../../features/admin/presentation/screens/admin_movimientos_screen.dart';
import '../../features/admin/presentation/screens/admin_recorridos_screen.dart';
import '../../features/admin/presentation/screens/admin_reportes_screen.dart';
import '../../features/admin/presentation/screens/admin_sincronizacion_screen.dart';
import '../../features/admin/presentation/screens/admin_solicitudes_screen.dart';
import '../../features/admin/presentation/screens/admin_verificaciones_screen.dart';
import '../../features/admin/presentation/screens/admin_usuarios_screen.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/ejecucion_cambio/presentation/screens/cambio_medidor_screen.dart';
import '../../features/historial/presentation/screens/historial_screen.dart';
import '../../features/home/presentation/screens/asignador_dashboard_screen.dart';
import '../../features/home/presentation/screens/tecnico_dashboard_screen.dart';
import '../../features/monitoreo/presentation/screens/detalle_monitoreo_ruta_screen.dart';
import '../../features/monitoreo/presentation/screens/monitoreo_tecnicos_screen.dart';
import '../../features/recorrido/presentation/screens/detalle_recorrido_screen.dart';
import '../../features/recorrido/presentation/screens/paso1_seleccionar_screen.dart';
import '../../features/recorrido/presentation/screens/paso2_reordenar_screen.dart';
import '../../features/recorrido/presentation/screens/paso3_asignar_tecnico_screen.dart';
import '../../features/sincronizacion/presentation/screens/sincronizacion_screen.dart';
import '../../features/verificacion/presentation/screens/mecanico_home_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String asignadorHome = '/asignador';
  static const String tecnicoHome = '/tecnico';
  static const String adminHome = '/admin';
  static const String adminUsuarios = '/admin/usuarios';
  static const String adminCatalogos = '/admin/catalogos';
  static const String adminParametros = '/admin/parametros';
  static const String adminSolicitudes = '/admin/solicitudes';
  static const String adminRecorridos = '/admin/recorridos';
  static const String adminSincronizacion = '/admin/sincronizacion';
  static const String adminMovimientos = '/admin/movimientos';
  static const String adminReportes = '/admin/reportes';
  static const String adminVerificaciones = '/admin/verificaciones';
  static const String adminInformes = '/admin/informes';
  static const String mecanicoHome = '/mecanico';

  static const String cambioMedidor = '/trabajo/cambio/:solicitudId';
  static const String monitoreo = '/asignador/monitoreo';
  static const String monitoreoRuta = '/asignador/monitoreo/ruta/:id';
  static const String historial = '/historial';
  static const String miRecorrido = '/tecnico/mi-recorrido';
  static const String recorridoPaso1 = '/asignador/recorrido/paso1';
  static const String recorridoPaso2 = '/asignador/recorrido/paso2';
  static const String recorridoPaso3 = '/asignador/recorrido/paso3';
  static const String sincronizar = '/sincronizar';
}

String _homeForRole(UserRole role) => switch (role) {
  UserRole.asignador => AppRoutes.asignadorHome,
  UserRole.tecnico => AppRoutes.tecnicoHome,
  UserRole.administrador => AppRoutes.adminHome,
  UserRole.mecanico => AppRoutes.mecanicoHome,
};

int _tabInicial(GoRouterState state) {
  final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
  if (tab == null || tab < 0 || tab > 3) return 0;
  return tab;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final currentUser = ref.read(authControllerProvider).user;
      final location = state.matchedLocation;
      final isLoginRoute = location == AppRoutes.login;

      if (currentUser == null) {
        return isLoginRoute ? null : AppRoutes.login;
      }

      if (isLoginRoute) return _homeForRole(currentUser.role);

      switch (currentUser.role) {
        case UserRole.administrador:
          if (!location.startsWith('/admin')) return AppRoutes.adminHome;
          break;
        case UserRole.mecanico:
          if (!location.startsWith('/mecanico')) return AppRoutes.mecanicoHome;
          break;
        case UserRole.asignador:
          if (location.startsWith('/admin') ||
              location.startsWith('/mecanico') ||
              location.startsWith('/tecnico')) {
            return AppRoutes.asignadorHome;
          }
          break;
        case UserRole.tecnico:
          if (location.startsWith('/admin') ||
              location.startsWith('/mecanico') ||
              location.startsWith('/asignador')) {
            return AppRoutes.tecnicoHome;
          }
          break;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),

      GoRoute(path: AppRoutes.adminHome, builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: AppRoutes.adminUsuarios, builder: (context, state) => const AdminUsuariosScreen()),
      GoRoute(path: AppRoutes.adminCatalogos, builder: (context, state) => const AdminCatalogosScreen()),
      GoRoute(path: AppRoutes.adminParametros, builder: (context, state) => const AdminParametrosScreen()),
      GoRoute(path: AppRoutes.adminSolicitudes, builder: (context, state) => const AdminSolicitudesScreen()),
      GoRoute(path: AppRoutes.adminRecorridos, builder: (context, state) => const AdminRecorridosScreen()),
      GoRoute(path: AppRoutes.adminSincronizacion, builder: (context, state) => const AdminSincronizacionScreen()),
      GoRoute(path: AppRoutes.adminMovimientos, builder: (context, state) => const AdminMovimientosScreen()),
      GoRoute(path: AppRoutes.adminReportes, builder: (context, state) => const AdminReportesScreen()),
      GoRoute(path: AppRoutes.adminVerificaciones, builder: (context, state) => const AdminVerificacionesScreen()),
      GoRoute(path: AppRoutes.adminInformes, builder: (context, state) => const AdminInformesScreen()),
      GoRoute(path: AppRoutes.mecanicoHome, builder: (context, state) => const MecanicoHomeScreen()),

      GoRoute(
        path: AppRoutes.asignadorHome,
        builder: (context, state) => AsignadorDashboardScreen(initialTab: _tabInicial(state)),
      ),
      GoRoute(
        path: AppRoutes.tecnicoHome,
        builder: (context, state) => TecnicoDashboardScreen(initialTab: _tabInicial(state)),
      ),
      GoRoute(
        path: AppRoutes.cambioMedidor,
        builder: (context, state) {
          final solicitudId = state.pathParameters['solicitudId'];
          if (solicitudId == null || solicitudId.trim().isEmpty) {
            return const TecnicoDashboardScreen();
          }
          return CambioMedidorScreen(solicitudId: solicitudId.trim());
        },
      ),
      GoRoute(path: AppRoutes.monitoreo, builder: (context, state) => const MonitoreoTecnicosScreen()),
      GoRoute(
        path: AppRoutes.monitoreoRuta,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const AsignadorDashboardScreen();
          return DetalleMonitoreoRutaScreen(idAsignacion: id);
        },
      ),
      GoRoute(path: AppRoutes.historial, builder: (context, state) => const HistorialScreen()),
      GoRoute(path: AppRoutes.miRecorrido, builder: (context, state) => const DetalleRecorridoScreen()),
      GoRoute(path: AppRoutes.recorridoPaso1, builder: (context, state) => const Paso1SeleccionarSolicitudesScreen()),
      GoRoute(path: AppRoutes.recorridoPaso2, builder: (context, state) => const Paso2ReordenarScreen()),
      GoRoute(path: AppRoutes.recorridoPaso3, builder: (context, state) => const Paso3AsignarTecnicoScreen()),
      GoRoute(path: AppRoutes.sincronizar, builder: (context, state) => const SincronizacionScreen()),
    ],
  );

  ref.listen<AppUser?>(authControllerProvider.select((state) => state.user), (previous, next) {
    WidgetsBinding.instance.addPostFrameCallback((_) => router.refresh());
  });
  ref.onDispose(router.dispose);
  return router;
});
