import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/asignador_dashboard_screen.dart';
import '../../features/home/presentation/screens/tecnico_dashboard_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String asignadorHome = '/asignador';
  static const String tecnicoHome = '/tecnico';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(
    authControllerProvider.select((state) => state.user),
  );

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // No hay usuario autenticado.
      if (currentUser == null) {
        if (isLoginRoute) {
          return null;
        }

        return AppRoutes.login;
      }

      // Ya inició sesión y todavía está en Login.
      if (isLoginRoute) {
        switch (currentUser.role) {
          case UserRole.asignador:
            return AppRoutes.asignadorHome;

          case UserRole.tecnico:
            return AppRoutes.tecnicoHome;
        }
      }

      // Evita que un técnico entre al módulo del asignador.
      if (state.matchedLocation.startsWith(AppRoutes.asignadorHome) &&
          currentUser.role != UserRole.asignador) {
        return AppRoutes.tecnicoHome;
      }

      // Evita que un asignador entre al módulo del técnico.
      if (state.matchedLocation.startsWith(AppRoutes.tecnicoHome) &&
          currentUser.role != UserRole.tecnico) {
        return AppRoutes.asignadorHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.asignadorHome,
        builder: (context, state) {
          return const AsignadorDashboardScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.tecnicoHome,
        builder: (context, state) {
          return const TecnicoDashboardScreen();
        },
      ),
    ],
  );
});
