import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exception.dart';
import '../../../data/datasources/local/user_local_datasource.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../entities/usuario.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para iniciar sesión en el sistema.
///
/// Valida que las credenciales no estén vacías y delega la autenticación
/// al [UserRepository].
class LoginUseCase {
  final UserRepository _repository;

  LoginUseCase(this._repository);

  /// Ejecuta el inicio de sesión.
  ///
  /// [username] - nombre de usuario
  /// [password] - contraseña en texto plano
  ///
  /// Retorna [Usuario] si las credenciales son correctas, `null` en caso contrario.
  ///
  /// Lanza [AuthException] si las credenciales están incompletas.
  Future<Usuario?> execute(String username, String password) {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      throw const AuthException('Credenciales incompletas');
    }
    return _repository.login(username.trim(), password);
  }
}

/// Provider de [LoginUseCase].
///
/// Crea internamente las dependencias necesarias:
/// [UserLocalDataSource] y [UserRepositoryImpl].
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final dataSource = UserLocalDataSource();
  final repository = UserRepositoryImpl(dataSource);
  return LoginUseCase(repository);
});
