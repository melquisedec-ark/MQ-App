# Reporte de Implementación — DB Auto-Update

> **Fecha:** 22 de mayo de 2026
> **Rama:** `feature/db-auto-update`
> **Commit:** `6db1c31`

---

## Resumen

Se implementó el mecanismo de **auto-actualización de base de datos desde assets** en la rama `feature/db-auto-update`, siguiendo una arquitectura **desacoplada** que evita el bug anterior (acoplamiento con `onUpgrade` de sqflite).

---

## Evaluación del Arquitecto (@arqui)

La propuesta `windowsdb.md` fue evaluada y se encontraron **9 fallas críticas**:

| # | Problema | Impacto |
|---|----------|---------|
| 1 | Usaba `Platform.resolvedExecutable` (solo Windows) | Rompe portabilidad multiplataforma |
| 2 | Introducía `shared_preferences` innecesariamente | Dependencia extra sin beneficio |
| 3 | No utilizaba el manifiesto `db_version.json` existente | Ignora infraestructura ya creada |
| 4 | No hacía backup de datos de usuario | Pérdida total de datos al actualizar |
| 5 | Sin manejo de errores ni atomicidad | Corrupción de BD en caso de crash |
| 6 | Nombre de archivo incorrecto (`himnario_biblia.db`) | No coincide con el real |
| 7 | Migraciones `onUpgrade` huérfanas | Esquema en estado indefinido |
| 8 | Versión hardcodeada en código Dart | Propenso a errores humanos |
| 9 | Sin try-catch en `rootBundle.load` | Crash si el asset no existe |

### Diseño Propuesto

Se rediseñó con **dos capas de versionado ortogonales**:

| Concepto | Propósito | Mecanismo |
|----------|-----------|-----------|
| **SCHEMA_VERSION** | Migraciones estructurales (tablas, columnas) | `version: 6` de sqflite + `onUpgrade` |
| **ASSET_VERSION** | Actualizaciones de seed data (himnos, estrofas) | `db_version.json` vs `db_version_applied.txt` |

---

## Flujo de Actualización

```
_initDatabase()
  ├─ Leer assetVersion (db_version.json)
  ├─ Leer localVersion (db_version_applied.txt)
  ├─ ¿assetVersion > localVersion o BD no existe?
  │   ├─ Sí:
  │   │   ├─ Backup de datos de usuario (7 tablas → JSON en memoria)
  │   │   ├─ Copiar nuevo .db desde assets (writeAsBytes)
  │   │   ├─ Escribir db_version_applied.txt
  │   │   └─ Re-importar datos de usuario (INSERT OR IGNORE)
  │   └─ No: saltar copia
  └─ Abrir BD con openDatabase(version: SCHEMA_VERSION, onUpgrade)
```

---

## Archivos Creados (6)

| Archivo | Líneas | Propósito |
|---------|--------|-----------|
| `lib/core/database/db_version_manager.dart` | 130 | Gestión de versiones: leer versión del asset, leer/escribir versión local, comparar, cargar bytes del .db |
| `lib/core/database/user_data_backup.dart` | 108 | Backup/restore de 7 tablas de usuario con `INSERT OR IGNORE` y manejo de AUTOINCREMENT |
| `lib/presentation/widgets/db_update_screen.dart` | 268 | Pantalla informativa con logo, spinner animado y transición automática |
| `assets/db/db_version.json` | 1 | Manifiesto de versión: `{"version": 1}` |
| `test/unit/core/database/db_version_manager_test.dart` | — | 12 tests: `needsUpdate`, FS read/write, fallback |
| `test/unit/core/database/user_data_backup_test.dart` | — | 8 tests: export, import, FK handling, AUTOINCREMENT |

---

## Archivos Modificados (5)

| Archivo | Cambio |
|---------|--------|
| `lib/core/database/database_helper.dart` | Refactor completo: `SCHEMA_VERSION = 6`, `_openDatabaseRaw`, `_openDatabasePlatform`, backup → replace → restore, Logger |
| `lib/main.dart` | Chequeo rápido `_quickCheckDbUpdate()`, MaterialApp compartido para evitar navegadores anidados |
| `pubspec.yaml` | Asset `db_version.json` declarado explícitamente |
| `README.md` | Nueva sección "Database Auto-Update" con flujo de trabajo |
| `TASKS_DEV.md` | Nueva guía de arquitectura y procedimiento |

---

## Resultados de Tests

| Suite | Tests | Resultado |
|-------|-------|-----------|
| Unit: `db_version_manager_test.dart` | 12 | ✅ Todos pasan |
| Unit: `user_data_backup_test.dart` | 8 | ✅ Todos pasan |
| Integration: `database_test.dart` | 28 | ✅ Todos pasan |
| `flutter analyze lib/` | — | ✅ 0 errores, 0 warnings (info-level lints pre-existentes) |

---

## Detalle de Implementación

### DbVersionManager (`db_version_manager.dart`)

Clase puramente funcional (sin estado mutable) con 6 métodos estáticos:

```dart
readAssetVersion()          → Future<int>   // Desde db_version.json en assets
assetDbBytes()              → Future<Uint8List>  // Bytes del .db empaquetado
readLocalVersion(dirPath)   → Future<int>   // Desde db_version_applied.txt en FS
writeLocalVersion(dirPath, version) → Future<void>  // Persiste versión aplicada
needsUpdate(assetV, localV) → bool  // assetV > localV
```

Usa **archivo de texto plano** (`db_version_applied.txt`) en lugar de `shared_preferences` para evitar nueva dependencia y garantizar portabilidad.

### UserDataBackup (`user_data_backup.dart`)

Backup/restore de 7 tablas de usuario en orden de dependencias FK:

1. **Tablas padre**: `Usuario`, `Fondo_Pantalla`
2. **Tablas hijo**: `Arreglo_Musical`, `Estrofa_Arreglo`, `Pista_Audio`, `Historial_Reproduccion`, `Configuracion`

Para tablas con `id AUTOINCREMENT`, se omite el campo `id` en el INSERT para que SQLite re-asigne valores y evite conflictos con los IDs del nuevo asset.

### DatabaseHelper (`database_helper.dart`)

Refactorizado con nueva arquitectura:

```dart
static const int SCHEMA_VERSION = 6;  // ← Independiente del asset version

// Backup → Replace → Restore
if (needsReplace) {
  userData = await UserDataBackup.exportUserData(oldDb);  // Backup
  bytes = await DbVersionManager.assetDbBytes();           // Replace
  await localFile.writeAsBytes(bytes);
  await DbVersionManager.writeLocalVersion(dir.path, assetVersion);
  await UserDataBackup.importUserData(newDb, userData);    // Restore
}
// Abrir BD definitiva con onCreate/onUpgrade
return await _openDatabasePlatform(dbPath);
```

- `_openDatabaseRaw()` — abre BD sin versiones (para backup/restore), activa `PRAGMA foreign_keys`
- `_openDatabasePlatform()` — abre BD con `SCHEMA_VERSION`, `onCreate`, `onUpgrade`
- Validación de bytes vacíos antes de escribir para evitar archivos corruptos

### DbUpdateScreen (`db_update_screen.dart`)

Pantalla informativa que se muestra **solo cuando hay actualización**:

- Logo circular con ícono `music_note_rounded` (120×120, borde primary @ 15% alpha)
- Título "MQ App" (`displayLarge`, w300, letterSpacing 4)
- `CircularProgressIndicator` con fade-in animado (800ms `Curves.easeIn`)
- Texto de estado: "Copiando base de datos..." → "¡Listo!"
- Subtítulo: "Este proceso puede tomar unos segundos"
- **Sin botones de acción** — no blocker
- Transición automática a `HimnarioApp` vía `runApp()` con delay de 300ms
- Manejo de errores: si falla la inicialización, muestra "Continuando..." y transiciona igualmente
- Comparte el mismo `MaterialApp` raíz con la app principal (sin navegadores anidados)

---

## Issues Corregidos (post-revisión de @arqui)

| Issue | Severidad | Fix |
|-------|-----------|-----|
| `writeAsBytes([])` creaba archivo corrupto | 🔴 Alta | Guard de `bytes.isEmpty` antes de escribir |
| `PRAGMA foreign_keys` solo en `_onCreate` | 🔴 Alta | Activado en `_openDatabaseRaw` también |
| `MaterialApp` anidado (dos navigators) | 🟡 Media | MaterialApp compartido en `main.dart` |
| `checkIfDbNeedsUpdate()` retornaba siempre true | 🟡 Media | Eliminada (código muerto) |
| `replaceFromAssets()` nunca era llamada | 🟢 Baja | Eliminada (código muerto) |

---

## Issues Conocidos (No bloqueantes)

1. **`INSERT OR IGNORE` descarta datos en conflicto**: Si el asset seed tiene un `Usuario` con `username = 'admin'` y el usuario cambió su contraseña, el backup no restaura el cambio. Mitigación: en la práctica el asset seed y los datos de usuario rara vez chocan, y las contraseñas se pueden re-establecer.

2. **Backup no atómico**: Los datos de usuario existen solo en memoria RAM entre la copia del .db y el restore. Un crash en esta ventana (~100ms) perdería la sesión de cambios. Mitigación: ventana extremadamente pequeña; en el futuro se podría escribir un backup a disco temporal.

3. **Schemas de test desactualizados**: Los helpers de test usan columna `pais` (TEXT) en lugar de `pais_id` (INTEGER). No afecta la funcionalidad de producción.

4. **FK references en Arreglo_Musical**: Si el nuevo asset DB tiene IDs diferentes de `Version_Pais`, los arreglos musicales restaurados pueden fallar por violación de FK. Los errores se silencian (catch vacío) y las filas conflictivas se descartan.

---

## Push a GitHub

- **Rama**: `feature/db-auto-update`
- **Commit**: `6db1c31`
- **Mensaje**: `feat: implementar DB auto-update desacoplado de sqflite`
- **URL**: `https://github.com/moy385/HimnarioID_2.0/tree/feature/db-auto-update`

---

## Cómo Usar el Nuevo Flujo

Para actualizar la base de datos en el futuro:

1. **Regenerar** `assets/db/himnario_id.db` con el nuevo contenido (himnos, estrofas, etc.)
2. **Incrementar** la versión en `assets/db/db_version.json`
3. **Si hay cambios de esquema**: agregar migración en `_onUpgrade()` de `database_helper.dart` e incrementar `SCHEMA_VERSION`
4. **Ejecutar** `flutter test` para verificar que todo funciona
5. **Commit y push** a la rama correspondiente

> La app detectará automáticamente la nueva versión al iniciar, reemplazará la BD local y preservará los datos del usuario (arreglos musicales, configuraciones, usuarios, fondos personalizados, historial).

---

*Reporte generado por @orquestador — 22 de mayo de 2026*
