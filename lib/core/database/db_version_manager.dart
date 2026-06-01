import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Gestiona la versión de la base de datos pre-cargada en assets.
///
/// # Arquitectura de versionado
///
/// Hay DOS números de versión independientes:
///
/// 1. **SCHEMA_VERSION** (en [DatabaseHelper]): controla migraciones
///    estructurales (tablas, columnas, índices) mediante `onUpgrade()`.
///    Se incrementa cuando el equipo de desarrollo cambia el esquema SQL.
///
/// 2. **Asset version** (`assets/db/db_version.json`): controla el reemplazo
///    de la BD pre-cargada completa. Se incrementa cuando cambia el seed
///    data (himnos, estrofas, etc.) sin cambiar el esquema.
///
/// # Flujo de actualización
///
/// El chequeo rápido se realiza en `main.dart` mediante
/// `_quickCheckDbUpdate()` que compara versiones sin abrir la BD.
///
/// ```
/// _initDatabase()
///   ├─ ¿assetVersion > localVersion o BD no existe?
///   │   ├─ Sí: backup user data → copiar .db → restore → abrir BD
///   │   └─ No: abrir BD directamente
/// ```
///
/// El archivo `db_version_applied.txt` se guarda FUERA de la BD (en
/// el directorio de documentos de la app) para que persista cuando
/// la BD se reemplaza completamente.
class DbVersionManager {
  DbVersionManager._();

  /// Nombre del archivo que almacena la versión aplicada localmente.
  static const String _versionFileName = 'db_version_applied.txt';

  // ─── Asset (solo lectura) ───────────────────────────────────────

  /// Lee la versión de la BD desde `assets/db/db_version.json`.
  ///
  /// Formato esperado:
  /// ```json
  /// {"version": 3}
  /// ```
  ///
  /// Retorna `0` si el archivo no existe, está mal formado, o si
  /// la plataforma no soporta `rootBundle` (entornos de test).
  static Future<int> readAssetVersion() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/db/db_version.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return (data['version'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Lee los bytes del archivo de BD empaquetado en assets.
  ///
  /// Útil para copiar el archivo completo al sistema de archivos local.
  /// Retorna `Uint8List` vacío si el asset no existe.
  static Future<Uint8List> assetDbBytes() async {
    try {
      final byteData = await rootBundle.load('assets/db/himnario_id.db');
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
      final file = File('$dirPath/$_versionFileName');
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
  static Future<void> writeLocalVersion(String dirPath, int version) async {
    try {
      final file = File('$dirPath/$_versionFileName');
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
