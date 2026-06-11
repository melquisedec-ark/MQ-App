import '../../../core/errors/auth_exception.dart';
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


