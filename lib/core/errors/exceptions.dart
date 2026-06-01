/// Excepción lanzada por los datasources locales (SQLite).
class DatabaseException implements Exception {
  final String message;
  final String? query;

  const DatabaseException(this.message, {this.query});

  @override
  String toString() =>
      'DatabaseException: $message${query != null ? ' [Query: $query]' : ''}';
}

/// Excepción lanzada por los datasources remotos (gRPC).
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException(this.message, {this.statusCode});

  @override
  String toString() =>
      'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Excepción lanzada cuando un recurso no se encuentra en el datasource.
class NotFoundException implements Exception {
  final String message;
  final String? entityType;

  const NotFoundException(this.message, {this.entityType});

  @override
  String toString() =>
      'NotFoundException: $message${entityType != null ? ' [Type: $entityType]' : ''}';
}

/// Excepción lanzada por argumentos inválidos en datasource.
class InvalidArgumentException implements Exception {
  final String message;

  const InvalidArgumentException(this.message);

  @override
  String toString() => 'InvalidArgumentException: $message';
}
