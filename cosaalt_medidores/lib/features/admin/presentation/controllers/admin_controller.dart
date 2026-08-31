import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_admin_repository.dart';
import '../../domain/entities/admin_models.dart';

class AdminState {
  const AdminState({
    this.usuarios = const [],
    this.roles = const [],
    this.funcionarios = const [],
    this.motivos = const [],
    this.marcas = const [],
    this.parametros = const [],
    this.parametroVigente,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<AdminUsuario> usuarios;
  final List<AdminRol> roles;
  final List<AdminFuncionario> funcionarios;
  final List<MotivoCatalogo> motivos;
  final List<MarcaCatalogo> marcas;
  final List<ParametroNormativo> parametros;
  final ParametroNormativo? parametroVigente;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  AdminState copyWith({
    List<AdminUsuario>? usuarios,
    List<AdminRol>? roles,
    List<AdminFuncionario>? funcionarios,
    List<MotivoCatalogo>? motivos,
    List<MarcaCatalogo>? marcas,
    List<ParametroNormativo>? parametros,
    ParametroNormativo? parametroVigente,
    bool clearParametroVigente = false,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) => AdminState(
    usuarios: usuarios ?? this.usuarios,
    roles: roles ?? this.roles,
    funcionarios: funcionarios ?? this.funcionarios,
    motivos: motivos ?? this.motivos,
    marcas: marcas ?? this.marcas,
    parametros: parametros ?? this.parametros,
    parametroVigente: clearParametroVigente ? null : (parametroVigente ?? this.parametroVigente),
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
  );
}

final adminRepositoryProvider = Provider<ApiAdminRepository>((ref) => ApiAdminRepository());
final adminControllerProvider = NotifierProvider<AdminController, AdminState>(AdminController.new);

class AdminController extends Notifier<AdminState> {
  @override
  AdminState build() => const AdminState();

  Future<void> cargarInicio() async {
    if (state.usuarios.isNotEmpty && state.parametros.isNotEmpty) return;
    await cargarTodo();
  }

  Future<void> cargarTodo() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final values = await Future.wait([
        repo.obtenerUsuarios(),
        repo.obtenerRoles(),
        repo.obtenerFuncionarios(),
        repo.obtenerMotivos(),
        repo.obtenerMarcas(),
        repo.obtenerParametros(),
      ]);
      state = state.copyWith(
        usuarios: values[0] as List<AdminUsuario>,
        roles: values[1] as List<AdminRol>,
        funcionarios: values[2] as List<AdminFuncionario>,
        motivos: values[3] as List<MotivoCatalogo>,
        marcas: values[4] as List<MarcaCatalogo>,
        parametros: values[5] as List<ParametroNormativo>,
        isLoading: false,
        clearMessages: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString(), clearParametroVigente: true);
    }
  }

  Future<void> cargarUsuarios() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final values = await Future.wait([repo.obtenerUsuarios(), repo.obtenerRoles(), repo.obtenerFuncionarios()]);
      state = state.copyWith(
        usuarios: values[0] as List<AdminUsuario>,
        roles: values[1] as List<AdminRol>,
        funcionarios: values[2] as List<AdminFuncionario>,
        isLoading: false,
        clearMessages: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> guardarUsuario({int? id, required GuardarUsuario usuario}) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (id == null) {
        await repo.crearUsuario(usuario);
      } else {
        await repo.actualizarUsuario(id, usuario);
      }
      final usuarios = await repo.obtenerUsuarios();
      state = state.copyWith(
        usuarios: usuarios,
        isSaving: false,
        successMessage: id == null ? 'Usuario creado correctamente.' : 'Usuario actualizado correctamente.',
        clearMessages: true,
      );
      // copyWith clearMessages would clear success, so assign explicitly afterwards.
      state = AdminState(
        usuarios: state.usuarios, roles: state.roles, funcionarios: state.funcionarios,
        motivos: state.motivos, marcas: state.marcas, parametros: state.parametros,
        parametroVigente: state.parametroVigente, isLoading: false, isSaving: false,
        successMessage: id == null ? 'Usuario creado correctamente.' : 'Usuario actualizado correctamente.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> cambiarEstadoUsuario(AdminUsuario usuario, bool activo) async {
    await guardarUsuario(
      id: usuario.id,
      usuario: GuardarUsuario(
        codFunCorporativo: usuario.codFunCorporativo,
        nombreUsuario: usuario.nombreUsuario,
        contrasena: null,
        idRol: usuario.idRol,
        activo: activo,
      ),
    );
  }

  Future<void> cargarCatalogos() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final values = await Future.wait([repo.obtenerMotivos(), repo.obtenerMarcas()]);
      state = state.copyWith(
        motivos: values[0] as List<MotivoCatalogo>,
        marcas: values[1] as List<MarcaCatalogo>,
        isLoading: false,
        clearMessages: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> cargarParametros() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final parametros = await ref.read(adminRepositoryProvider).obtenerParametros();
      state = state.copyWith(parametros: parametros, isLoading: false, clearMessages: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> guardarParametro({int? id, required GuardarParametroNormativo parametro}) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (id == null) {
        await repo.crearParametro(parametro);
      } else {
        await repo.actualizarParametro(id, parametro);
      }
      final parametros = await repo.obtenerParametros();
      state = AdminState(
        usuarios: state.usuarios, roles: state.roles, funcionarios: state.funcionarios,
        motivos: state.motivos, marcas: state.marcas, parametros: parametros,
        parametroVigente: state.parametroVigente, isLoading: false, isSaving: false,
        successMessage: id == null ? 'Parametro creado correctamente.' : 'Parametro actualizado correctamente.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> cambiarEstadoParametro(ParametroNormativo parametro, bool activo) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.cambiarEstadoParametro(parametro.id, activo);
      final parametros = await repo.obtenerParametros();
      state = AdminState(
        usuarios: state.usuarios, roles: state.roles, funcionarios: state.funcionarios,
        motivos: state.motivos, marcas: state.marcas, parametros: parametros,
        parametroVigente: state.parametroVigente, isLoading: false, isSaving: false,
        successMessage: activo ? 'Parametro activado.' : 'Parametro desactivado.',
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> probarVigente(double caudal) async {
    state = state.copyWith(isSaving: true, clearMessages: true, clearParametroVigente: true);
    try {
      final item = await ref.read(adminRepositoryProvider).obtenerParametroVigente(caudal);
      state = state.copyWith(parametroVigente: item, isSaving: false, clearMessages: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString(), clearParametroVigente: true);
    }
  }
}
