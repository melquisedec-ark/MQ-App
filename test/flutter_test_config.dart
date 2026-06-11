import 'dart:async';

import 'test_helpers/test_environment.dart';

/// Configuración global para todos los tests de Flutter.
///
/// Flutter carga automáticamente este archivo antes de ejecutar cada suite
/// de tests. Inicializamos sqflite_ffi con el override de libsqlite3.so.0
/// para Linux, evitando el error "Failed to load dynamic library" que
/// ocurre en CI (GitHub Actions) donde no existe el symlink libsqlite3.so.
///
/// Ref: https://docs.flutter.dev/testing/overview#test-configuration
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  initTestEnvironment();
  await testMain();
}
