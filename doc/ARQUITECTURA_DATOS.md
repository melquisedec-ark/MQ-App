# Arquitectura de Versionado de Base de Datos

> **Archivos clave**:
> - `lib/core/database/database_helper.dart` — `SCHEMA_VERSION`, `_initDatabase()`
> - `lib/core/database/db_version_manager.dart` — `DbVersionManager`

## Dos números de versión independientes

Existen DOS sistemas de versionado que NO deben confundirse:

```
┌─────────────────────────────────────────────────────┐
│                   SCHEMA_VERSION                     │
│  (en DatabaseHelper)                                 │
│                                                      │
│  Propósito: Migraciones de esquema SQL               │
│  (tablas, columnas, índices, vistas)                 │
│                                                      │
│  Flujo: sqflite.onUpgrade(oldVersion, newVersion)    │
│                                                      │
│  Actual: 7                                           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                   db_version.json                    │
│  (assets/db/db_version.json)                         │
│                                                      │
│  Propósito: Control de actualizaciones de seed data  │
│  (himnos, estrofas, configuraciones por defecto)     │
│                                                      │
│  Flujo: assetVersion > localVersion → reemplazar BD  │
│                                                      │
│  Actual: 3 (desde v2.1.3)                            │
└─────────────────────────────────────────────────────┘
```

## SCHEMA_VERSION

Controla la estructura de la BD. Se incrementa cuando se agregan, modifican o eliminan tablas/columnas.

Se almacena en el `PRAGMA user_version` de SQLite. sqflite lo lee automáticamente al abrir la BD y ejecuta `onUpgrade()` si el número en disco es menor al de la app.

### Historial

| Versión | Cambio |
|---------|--------|
| 1 | Schema inicial |
| 2 | Columnas `username`/`password_hash` en `Usuario` + tabla `Fondo_Pantalla` |
| 3 | Normalización de países (columna `pais_id` en `Version_Pais`, tabla `Pais`) |
| 4 | Tabla `Himno_Busqueda` |
| 5 | Columna `evento` en `Himno` |
| 6 | Eliminar `video` del CHECK de `Fondo_Pantalla.tipo` |
| 7 | Forzar reindex de búsqueda (stripChords) |

## db_version (asset version)

Controla el reemplazo de la BD pre-cargada. Se incrementa cuando cambian los datos semilla (nuevos himnos, estrofas corregidas, configs por defecto).

Se almacena en:
- **Asset**: `assets/db/db_version.json` (solo lectura, empaquetado en la app)
- **Local**: `db_version_applied.txt` en el directorio de documentos de la app

### Flujo de actualización

```dart
final assetVersion = await DbVersionManager.readAssetVersion();  // del JSON
final localVersion = await DbVersionManager.readLocalVersion();   // del .txt

if (assetVersion > localVersion) {
  // Backup → Reemplazar BD → Restore
}
```

### Historial

| db_version | App | Cambio |
|------------|-----|--------|
| 1 | v2.1.0 – v2.1.2 | Seed data inicial (con sistema de merge) |
| 2 | v2.1.2 | Config defaults de glassmorphism |
| **3** | **v2.1.3+** | **Seed data actual + backup/restore** |

## ¿Cuándo incrementar cada uno?

### Incrementar SCHEMA_VERSION cuando:
- Agregas una tabla nueva
- Agregas/eliminas/renombras una columna
- Cambias un índice
- Cambias una vista
- Cambias un CHECK constraint

### Incrementar db_version cuando:
- Cambias el contenido de `assets/db/himnario_id.db` (nuevos himnos, estrofas corregidas)
- Agregas configuraciones por defecto en la tabla `Configuracion`
- Quieres forzar un reemplazo completo de la BD para todos los usuarios

### Regla general

> Si el cambio requiere migración de datos (transformar datos existentes), usa SCHEMA_VERSION.
> Si el cambio es solo de contenido (nuevos himnos, configs default), usa db_version.

## El archivo `db_version_applied.txt`

Se guarda FUERA de la BD (en el directorio de documentos de la app) para que persista cuando la BD se reemplaza completamente.

- Si no existe → `readLocalVersion()` retorna `0`
- Si existe → lee el contenido como entero
- Contenido no numérico → retorna `0`

## Modo Debug (desktop)

En debug mode (desktop, no Android/iOS), la app usa directamente el archivo `assets/db/himnario_id.db` del proyecto. No hay copia ni reemplazo. Esto permite editar la BD y ver cambios sin reinstalar.

## Tablas de la BD

### Seed data (viene del asset, se reemplaza completamente)
- `Himno` — Catálogo de himnos
- `Version_Pais` — Versiones por país
- `Estrofa` — Letra y estructura
- `Pais` — Países
- `Categoria` — Categorías
- `Himno_Categoria` — Asignación himno↔categoría
- `Himno_Busqueda` — Índice de búsqueda pre-computado

### Datos de usuario (se respaldan y restauran)
- `Usuario` — Usuarios del sistema
- `Arreglo_Musical` — Arreglos personalizados
- `Estrofa_Arreglo` — Estrofas de arreglos
- `Configuracion` — Preferencias (clave/valor)
- `Fondo_Pantalla` — Fondos personalizados
- `Historial_Reproduccion` — Historial de himnos vistos
- `Pista_Audio` — Pistas de audio (NO respaldada actualmente)
