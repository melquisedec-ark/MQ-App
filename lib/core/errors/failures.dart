/// Clase base para todos los Failure de la aplicación.
/// Representa un error manejable a nivel de dominio/aplicación.
sealed class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? ' ($code)' : ''}';
}

/// Error relacionado con la base de datos local.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Error relacionado con comunicación de red.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Error cuando un recurso no es encontrado.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Error por argumentos inválidos.
class InvalidArgumentFailure extends Failure {
  const InvalidArgumentFailure(super.message, {super.code});
}

/// Error de autenticación/permisos.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message, {super.code});
}

/// Error relacionado con reproducción de audio.
class AudioFailure extends Failure {
  const AudioFailure(super.message, {super.code});
}
