import 'dart:ffi';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

/// Inicializa el entorno de tests para todas las plataformas.
///
/// ## Por qué existe este helper
///
/// En Linux, el sistema tiene `libsqlite3.so.0` pero NO `libsqlite3.so`
/// (sin symlink sin sufijo de versión). El paquete `sqflite_common_ffi`
/// usa `sqlite3` que por defecto busca el primer nombre, lo cual falla
/// con `Failed to load dynamic library 'libsqlite3.so'`.
///
/// El patrón probado en `test/features/biblia/helpers/bible_db_test_helper.dart`
/// (y que pasa 132/132 tests de Biblia) es:
/// 1. Sobrescribir el `OpenLibrary` para Linux con un callback top-level
///    que carga `libsqlite3.so.0` directamente.
/// 2. Usar `createDatabaseFactoryFfi(noIsolate: true)` para que el FFI
///    corra en el isolate principal y no requiera serializar el callback.
///
/// Este helper centraliza ese patrón para que las pruebas heredadas de
/// HimnarioID 2.0 (integration tests, user_data_backup tests, etc.) puedan
/// aprovecharlo sin duplicar código.
///
/// ## Uso
///
/// ```dart
/// import '../test_helpers/test_environment.dart';
///
/// void main() {
///   setUpAll(() {
///     initTestEnvironment();
///   });
/// }
/// ```
bool _testEnvInit = false;

/// Inicializa sqflite_ffi con el override de libsqlite3 para Linux.
///
/// Es seguro llamarlo múltiples veces (idempotente): solo se ejecuta
/// la primera vez.
void initTestEnvironment() {
  if (_testEnvInit) return;
  _testEnvInit = true;

  if (Platform.isLinux) {
    open.overrideFor(
      OperatingSystem.linux,
      _openLibsqliteLinux,
    );
  }
  databaseFactory = createDatabaseFactoryFfi(noIsolate: true);
}

/// Top-level `OpenLibrary` para Linux.
///
/// DEBE ser top-level (no closure) porque `sqlite3` la invoca en el
/// isolate de FFI y las closures locales no se pueden serializar.
DynamicLibrary _openLibsqliteLinux() {
  return DynamicLibrary.open('libsqlite3.so.0');
}
