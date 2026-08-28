import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/ejecucion_cambio/presentation/screens/cambio_medidor_screen.dart';
import '../../features/home/presentation/screens/asignador_dashboard_screen.dart';
import '../../features/home/presentation/screens/tecnico_dashboard_screen.dart';
import '../../features/historial/presentation/screens/historial_screen.dart';
import '../../features/monitoreo/presentation/screens/detalle_monitoreo_ruta_screen.dart';
import '../../features/monitoreo/presentation/screens/monitoreo_tecnicos_screen.dart';
import '../../features/recorrido/presentation/screens/detalle_recorrido_screen.dart';
import '../../features/recorrido/presentation/screens/paso1_seleccionar_screen.dart';
import '../../features/recorrido/presentation/screens/paso2_reordenar_screen.dart';
import '../../features/recorrido/presentation/screens/paso3_asignar_tecnico_screen.dart';
import '../../features/sincronizacion/presentation/screens/sincronizacion_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';

  static const String asignadorHome = '/asignador';
  static const String tecnicoHome = '/tecnico';

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

      // ============================================================
      // USUARIO NO AUTENTICADO
      // ============================================================

      if (currentUser == null) {
        return isLoginRoute ? null : AppRoutes.login;
      }

      // ============================================================
      // USUARIO AUTENTICADO QUE SIGUE EN LOGIN
      // ============================================================

      if (isLoginRoute) {
        return switch (currentUser.role) {
          UserRole.asignador => AppRoutes.asignadorHome,
          UserRole.tecnico => AppRoutes.tecnicoHome,
        };
      }

      // ============================================================
      // PROTECCIÓN DE RUTAS DEL ASIGNADOR
      // ============================================================

      if (location.startsWith(AppRoutes.asignadorHome) &&
          currentUser.role != UserRole.asignador) {
        return AppRoutes.tecnicoHome;
      }

      // ============================================================
      // PROTECCIÓN DE RUTAS DEL TÉCNICO
      // ============================================================

      if (location.startsWith(AppRoutes.tecnicoHome) &&
          currentUser.role != UserRole.tecnico) {
        return AppRoutes.asignadorHome;
      }

      return null;
    },

    routes: [
      // ============================================================
      // LOGIN
      // ============================================================

      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          return const LoginScreen();
        },
      ),

      // ============================================================
      // DASHBOARD ASIGNADOR
      // ============================================================
      GoRoute(
        path: AppRoutes.asignadorHome,
        builder: (context, state) {
          return AsignadorDashboardScreen(initialTab: _tabInicial(state));
        },
      ),

      // ============================================================
      // DASHBOARD TÉCNICO
      // ============================================================
      GoRoute(
        path: AppRoutes.tecnicoHome,
        builder: (context, state) {
          return TecnicoDashboardScreen(initialTab: _tabInicial(state));
        },
      ),

      // ============================================================
      // CAMBIO DE MEDIDOR
      // ============================================================
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

      // ============================================================
      // MONITOREO
      // ============================================================
      GoRoute(
        path: AppRoutes.monitoreo,
        builder: (context, state) {
          return const MonitoreoTecnicosScreen();
        },
      ),

      GoRoute(
        path: AppRoutes.monitoreoRuta,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          if (id == null) {
            return const AsignadorDashboardScreen();
          }

          return DetalleMonitoreoRutaScreen(idAsignacion: id);
        },
      ),

      // ============================================================
      // HISTORIAL
      // ============================================================
      GoRoute(
        path: AppRoutes.historial,
        builder: (context, state) {
          return const HistorialScreen();
        },
      ),

      GoRoute(
        path: AppRoutes.miRecorrido,
        builder: (context, state) {
          return const DetalleRecorridoScreen();
        },
      ),

      // ============================================================
      // RECORRIDOS
      // ============================================================
      GoRoute(
        path: AppRoutes.recorridoPaso1,
        builder: (context, state) {
          return const Paso1SeleccionarSolicitudesScreen();
        },
      ),

      GoRoute(
        path: AppRoutes.recorridoPaso2,
        builder: (context, state) {
          return const Paso2ReordenarScreen();
        },
      ),

      GoRoute(
        path: AppRoutes.recorridoPaso3,
        builder: (context, state) {
          return const Paso3AsignarTecnicoScreen();
        },
      ),

      // ============================================================
      // SINCRONIZACIÓN
      // ============================================================
      GoRoute(
        path: AppRoutes.sincronizar,
        builder: (context, state) {
          return const SincronizacionScreen();
        },
      ),
    ],
  );

  // ==============================================================
  // CAMBIOS DE AUTENTICACIÓN
  //
  // IMPORTANTE:
  //
  // No refrescamos GoRouter en el mismo instante en que Riverpod
  // está notificando el cambio de estado.
  //
  // LoginScreen también observa authControllerProvider y se marca
  // para reconstrucción. Si GoRouter modifica el Navigator durante
  // ese mismo ciclo pueden aparecer:
  //
  //   _dependents.isEmpty
  //   Tried to build dirty widget in the wrong build scope
  //   Duplicate GlobalKeys detected in widget tree
  //
  // Por eso esperamos al siguiente frame.
  // ==============================================================

  ref.listen<AppUser?>(authControllerProvider.select((state) => state.user), (
    previous,
    next,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.refresh();
    });
  });

  ref.onDispose(router.dispose);

  return router;
});
