import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Gestor de versión del asset `assets/db/biblia.db`.
///
/// ## Arquitectura de versionado
///
/// Hay DOS números de versión independientes:
///
/// 1. **SCHEMA_VERSION** (en [BibleDatabaseHelper]): controla migraciones
///    estructurales (tablas, columnas, índices) mediante `onUpgrade()`.
///    Se incrementa cuando el equipo de desarrollo cambia el esquema SQL.
///
/// 2. **Asset version** (`assets/db/biblia_version.json`): controla el
///    reemplazo de la BD pre-cargada completa. Se incrementa cuando cambia
///    el seed data (nuevos versículos, corrección de texto, etc.) sin
///    cambiar el esquema.
///
/// ## Formato esperado
///
/// ```json
/// {"version": 1}
/// ```
///
/// Si el archivo no existe, está mal formado, o la plataforma no soporta
/// `rootBundle` (tests), se retorna `0` y la app continúa con la BD local
/// existente (o vacía en primera instalación).
class BibleSchemaVersion {
  BibleSchemaVersion._();

  /// Nombre del archivo que almacena la versión aplicada localmente.
  /// Se guarda FUERA de la BD (en el directorio de documentos) para que
  /// persista cuando la BD se reemplaza completamente.
  static const String _localVersionFileName = 'biblia_version_applied.txt';

  /// Ruta del archivo JSON de versión dentro de los assets.
  static const String _assetVersionPath = 'assets/db/biblia_version.json';

  /// Ruta del archivo de BD dentro de los assets.
  static const String _assetDbPath = 'assets/db/biblia.db';

  // ─── Asset (solo lectura) ───────────────────────────────────────

  /// Lee la versión de la BD desde `assets/db/biblia_version.json`.
  ///
  /// Retorna `0` si el archivo no existe, está mal formado, o si la
  /// plataforma no soporta `rootBundle` (entornos de test).
  static Future<int> readAssetVersion() async {
    try {
      final jsonStr =
          await rootBundle.loadString(_assetVersionPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return (data['version'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Lee los bytes del archivo de BD empaquetado en assets.
  ///
  /// Retorna `Uint8List` vacío si el asset no existe (ej. aún no fue
  /// generado por @back, o en entornos de test).
  static Future<Uint8List> assetDbBytes() async {
    try {
      final byteData = await rootBundle.load(_assetDbPath);
      return byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } catch (_) {
      return Uint8List(0);
    }
  }

  // ─── Local (lectura/escritura) ──────────────────────────────────

  /// Lee la versión aplicada localmente desde el archivo marker.
  ///
  /// [dirPath] es la ruta del directorio de documentos de la app
  /// (obtenido con `getApplicationDocumentsDirectory()`).
  ///
  /// Retorna `0` si el archivo no existe (primera ejecución).
  static Future<int> readLocalVersion(String dirPath) async {
    try {
      final file = File('$dirPath/$_localVersionFileName');
      if (!await file.exists()) return 0;
      final content = await file.readAsString();
      return int.tryParse(content.trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Persiste la versión aplicada localmente.
  ///
  /// [dirPath] es la ruta del directorio de documentos de la app.
  /// Debe llamarse DESPUÉS de copiar exitosamente la BD desde assets.
  static Future<void> writeLocalVersion(
    String dirPath,
    int version,
  ) async {
    try {
      final file = File('$dirPath/$_localVersionFileName');
      await file.writeAsString(version.toString());
    } catch (_) {
      // Fallo silencioso — en el próximo inicio se reintentará la copia.
    }
  }

  // ─── Comparación ────────────────────────────────────────────────

  /// Determina si la BD local necesita ser reemplazada por el asset.
  ///
  /// Retorna `true` cuando `assetVersion > localVersion`.
  /// Si ambas son 0 (sin versiones), retorna `false`.
  static bool needsUpdate(int assetVersion, int localVersion) {
    return assetVersion > localVersion;
  }
}
