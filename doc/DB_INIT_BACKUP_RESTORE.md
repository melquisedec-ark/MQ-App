# Inicialización de Base de Datos — Backup + Replace + Restore

> **Estado**: Implementado desde v2.1.3
> **Archivo**: `lib/core/database/database_helper.dart` — `_initDatabase()`

## Arquitectura

La inicialización de la BD sigue un flujo lineal y predecible, sin merges ni lógica condicional compleja:

```
_initDatabase()
  ├── Debug mode (desktop, !Android, !iOS)
  │   └── Usa BD directamente desde `assets/db/himnario_id.db`
  │
  └── Release mode (Android, iOS, Windows, macOS, Linux)
      ├── ¿BD local NO existe?
      │   └── Copiar BD del asset → abrir
      │
      ├── ¿assetVersion > localVersion?
      │   ├── 1. Backup datos de usuario
      │   ├── 2. Cerrar BD actual
      │   ├── 3. Eliminar BD local
      │   ├── 4. Copiar BD del asset
      │   ├── 5. Abrir BD nueva (raw)
      │   ├── 6. PRAGMA user_version = SCHEMA_VERSION
      │   ├── 7. Restaurar datos de usuario
      │   └── 8. Cerrar BD raw
      │
      └── Abrir BD con `_openDatabasePlatform()`
          └── Escribir localVersion
```

## Tablas respaldadas y restauradas

| Tabla | FK a | Estrategia restore |
|-------|------|--------------------|
| `Configuracion` | — | `ConflictAlgorithm.replace` |
| `Usuario` | — | `ConflictAlgorithm.ignore` |
| `Fondo_Pantalla` | — | `ConflictAlgorithm.ignore` |
| `Arreglo_Musical` | `usuario_id`, `version_pais_id` | `ConflictAlgorithm.ignore` |
| `Estrofa_Arreglo` | `arreglo_musical_id` | `ConflictAlgorithm.ignore` |
| `Historial_Reproduccion` | `himno_id`, `version_pais_id` | `ConflictAlgorithm.ignore` |

### Detalle importante sobre FK

Durante el restore se desactivan temporalmente las FK (`PRAGMA foreign_keys = OFF`) para evitar errores de orden. Se reactivan al finalizar.

Las tablas de seed data (`Himno`, `Version_Pais`, `Estrofa`, `Pais`, `Categoria`, `Himno_Categoria`, `Himno_Busqueda`) NO se respaldan porque vienen completas en el asset.

## Funciones

### `_backupUserData(String dbPath)`

Abre la BD local en modo raw (sin gestión de versiones) y extrae todas las tablas de usuario en un `Map<String, List<Map<String, dynamic>>>`.

### `_restoreUserData(Database db, Map backup)`

Inserta los datos respaldados en la BD nueva en el orden correcto (respetando FK). Usa `ignore` para evitar duplicados si el registro ya existe (ej: mismo usuario).

### `_copyAssetDb(File destFile)`

Lee los bytes de `assets/db/himnario_id.db` via `rootBundle.load()` y los escribe al sistema de archivos local. Si el asset está vacío (no existe en el bundle), no copia nada y la BD se crea con el schema fresco via `onCreate`.

## PRAGMA user_version

La BD del asset se abre con `_openDatabaseRaw()` (sin gestión de versiones de sqflite). Se ejecuta `PRAGMA user_version = 7` (el valor de `SCHEMA_VERSION`) para que en el próximo `_openDatabasePlatform()` sqflite detecte que la versión coincide y no ejecute `onCreate` ni `onUpgrade`.

## Manejo de errores

Si el backup o restore falla, la app continúa con la BD nueva **sin datos de usuario**. Esto es intencional: es preferible perder configuraciones a tener una BD corrupta con datos inconsistentes (como ocurría con el merge).

## Historial

| Versión | Sistema | Problema |
|---------|---------|----------|
| ≤ v2.0.4 | Replace directo (sin backup) | Se perdían arreglos musicales al actualizar |
| v2.1.0 – v2.1.2 | Merge incremental | Bugs de corrupción (himno 290, Version_Pais huérfanos) |
| **v2.1.3+** | **Backup + Replace + Restore** | **Estable. Sin bugs conocidos.** |
