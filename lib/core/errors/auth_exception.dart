/// Excepción lanzada cuando ocurre un error de autenticación.
///
/// Puede ser por credenciales incompletas, incorrectas,
/// o cualquier otro error relacionado con el inicio de sesión.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
