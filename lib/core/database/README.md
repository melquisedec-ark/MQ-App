# `lib/core/database/` — Capa de persistencia SQLite

Este módulo encapsula **toda** la inicialización, migración y acceso a
las bases de datos SQLite embebidas (Himnario y Biblia).

## Stack

- **`sqflite_common_ffi`** — Backend FFI (dart:ffi) multiplataforma.
- **`sqlite3_flutter_libs`** — Bundle nativo de `libsqlite3` ≥ 3.46 para
  Android, iOS, macOS, Windows y Linux. Reemplaza la `libsqlite3` del
  sistema.
- **`sqflite_common`** — API agnóstica de plataforma (`Database`,
  `OpenDatabaseOptions`, `ConflictAlgorithm`).

`sqflite` (la implementación nativa Android/iOS) **sigue declarada** en
`pubspec.yaml` por compatibilidad transitiva, pero el código de este
módulo **no la usa** — todas las aperturas pasan por FFI.

## ¿Por qué FFI en TODAS las plataformas?

La Biblia (módulo `@arqui` / `@dev` en Fases previas) usa
`unicode61 remove_diacritics 2` en sus índices FTS5 para lograr búsqueda
**acento-insensible** (`José` == `jose`, `María` == `maria`).

Esa opción de tokenizador existe solo desde **SQLite 3.39.0** (junio 2022).
Sin embargo:

| SO               | Versión bundled           | Soporta 3.39+ |
|------------------|---------------------------|---------------|
| iOS 12–15        | libsqlite3 del sistema    | ❌ No        |
| iOS 16+          | libsqlite3 del sistema    | ✅ Sí (3.39) |
| Android < 14     | libsqlite3 del sistema    | ❌ No        |
| Android 14+      | libsqlite3 del sistema    | ✅ Sí (3.32+, 3.39+ en 14) |
| macOS / Win / Lx | varía (a veces 3.7+ OK)   | ⚠️ Incierto |

**Decisión arquitectónica** (registrada en `doc/PLAN_DE_DELEGACION.md`):
bundlear `libsqlite3` moderna vía `sqlite3_flutter_libs` y usar FFI en
**todas** las plataformas, unificando el código.

### Costo

- **+~2 MB** por binario de plataforma (iOS .ipa, Android .apk, etc.).
- Sin impacto funcional: el usuario final no nota la diferencia.

## Punto de entrada

`DatabaseHelper` es un **singleton** accesible vía
`DatabaseHelper.instance`. La primera llamada a `.database` dispara la
inicialización completa.

```dart
final db = await DatabaseHelper.instance.database;  // Database abierta
final rows = await db.query('Himno', limit: 10);
```

## Inicialización

1. **Primera instalación** (no existe `mqapp.db` local):
   - Se copia el asset `assets/db/mqapp.db` al directorio de documentos
     (`getApplicationDocumentsDirectory()`).
2. **Actualización de seed** (asset version > local version):
   - Backup de tablas de usuario (vía `UserDataBackup.exportUserData`).
   - Reemplazo completo del archivo `.db` desde assets.
   - Restauración de datos sobre la nueva BD
     (`UserDataBackup.importUserData`).
3. **Migraciones de esquema** (vía `onUpgrade` de sqflite):
   - Se ejecutan en orden secuencial por `SCHEMA_VERSION`.
   - Para la Biblia, las migraciones SQL viven en `assets/db/schema/`
     y se numeran `00X_descripcion.sql`.

## Versionado (dos dimensiones independientes)

| Concepto            | Dónde se define              | Para qué                          |
|---------------------|------------------------------|-----------------------------------|
| `SCHEMA_VERSION`    | `DatabaseHelper` (const 7)   | Migraciones estructurales         |
| `assets/db/db_version.json` | asset empaquetado     | Versión del seed data             |

Ambas se chequean en cada inicio; ver `DbVersionManager` para el flujo
detallado.

## Compatibilidad verificada

- `sqflite_common_ffi 2.3.7` + `sqlite3_flutter_libs 0.5.x` →
  libsqlite3 3.46+ en todas las plataformas.
- `flutter analyze`: 0 errores en este módulo.
- Test de humo: `test/unit/core/database/` cubre backup/restore y
  migraciones de esquema.

## Archivos del módulo

| Archivo                  | Propósito                                                       |
|--------------------------|-----------------------------------------------------------------|
| `database_helper.dart`   | Singleton de inicialización, migraciones y helpers de config.   |
| `db_version_manager.dart`| Lectura/escritura de la versión del asset vs. local.            |
| `user_data_backup.dart`  | Export/import de tablas de usuario (resiliencia ante updates).  |
| `schema.sql`             | DDL completo del Himnario (referencia histórica).               |
| `README.md`              | Este archivo.                                                   |

## Diagnóstico

Si la búsqueda acento-insensible falla en algún dispositivo:

1. Revisar logs: `SQLite version: X.Y.Z` debe ser ≥ 3.39.
2. Si el log dice `< 3.39`, falta `sqlite3_flutter_libs` en la build
   nativa (revisar `pubspec.yaml` y limpieza de caché de Gradle/CocoaPods).
3. Como defensa de profundidad, `_checkSqliteVersion` emite un
   `_log.warning(...)` cuando detecta versiones antiguas — la app
   sigue funcionando, pero las búsquedas sin tildes pueden no coincidir.

## Tests

```bash
flutter test test/unit/core/database/
```

Cubre:
- Apertura/cierre de BD.
- Migraciones de esquema (todas las versiones de `_onUpgrade`).
- Backup/restore de datos de usuario.
- Versión de SQLite detectada en runtime.
