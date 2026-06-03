# `assets/db/tools/` — Generadores de bases de datos

Esta carpeta contiene scripts que **generan los `.db`** a partir de
fuentes externas. Son offline-build tools: no se incluyen en el binario
de la app, solo se ejecutan en la máquina del desarrollador o en CI.

## Estado actual (v1.0.1)

| Archivo                            | Estado    | Descripción                                  |
|------------------------------------|-----------|----------------------------------------------|
| `build_biblia_db.dart`             | ✅ Funcional | Genera `assets/db/biblia.db` desde fuentes upstream |
| `build_himnario_db.dart`           | Pendiente | Si se necesita regenerar el himnario        |
| `lib/books_canon.dart`             | ✅ Funcional | Metadatos canónicos de los 66 libros        |
| `source/rv1909/data.sql`           | ✅ Trackeado | Dump SQL de RV1909 (4.4 MB)                 |
| `SOURCES.md`                       | ✅ Completo | Documentación de fuentes y limitaciones     |

> ℹ️ **v1.0.1**: RV1569 placeholder fue eliminada (decisión D1). El schema
> sigue siendo multi-versión (tabla `version` + FKs CASCADE), listo para
> re-insertar versiones futuras. Ver `SOURCES.md` §4.

## Cómo ejecutar el build

```bash
# 1. Asegurarse de que las dependencias de Dart estén instaladas
dart pub get

# 2. Ejecutar el build (tarda ~5 s en un desktop Linux moderno)
dart run assets/db/tools/build_biblia_db.dart

#  Flags opcionales:
#   --schema <path>     : ruta alternativa al schema (default: 001_biblia_schema.sql)
#   --rv1909  <path>    : ruta alternativa al data.sql RV1909
#   --out     <path>    : ruta del DB de salida (default: assets/db/biblia.db)
#   --keep-temp         : conserva el DB temporal para debugging
#   --skip-validate     : salta las 11 validaciones (NO recomendado)
```

Si `libsqlite3.so` no está en una ruta estándar, exportar la variable:

```bash
export LIBSQLITE3_PATH=/ruta/a/libsqlite3.so.0
dart run assets/db/tools/build_biblia_db.dart
```

## ¿Qué hace el script? (paso a paso, v1.0.1)

```
┌──────────────────────────────────┐
│ 1. Aplica 001_biblia_schema.sql  │  (DDL puro: tablas + FTS5 + triggers)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 2. Inserta 1 versión             │  (RVR1909)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 3. Inserta 66 libros             │  (orden canónico 1-66 desde lib/books_canon.dart)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 4. Inserta 1 189 capítulos       │  (con total_versiculos=0 inicialmente)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 5. Parsea fuente RV1909          │  (regex + escape SQL en _parseRv1909Sql)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 6. Inserta 31 102 versículos     │  (lotes de 1 000 con BEGIN/COMMIT)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 7. Actualiza total_versiculos    │  (UPDATE por cada capítulo)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 8. Inserta config                │  (build_timestamp, build_script_version,
│                                  │   rv1909_verses)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 9. ANALYZE                       │  (estadísticas para el query planner)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 10. Ejecuta 11 validaciones      │  (ver tabla abajo)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 11. Copia el DB a la ruta final  │  (assets/db/biblia.db)
└──────────────────────────────────┘
```

## Validaciones (11 en total, v1.0.1)

El script ejecuta 11 verificaciones y **falla** si alguna no pasa. Para
omitirlas (debugging), usar `--skip-validate`.

| # | Test | Esperado |
|---|------|----------|
| 1 | `COUNT(version) = 1` | 1 |
| 2 | `COUNT(libro) = 66` | 66 |
| 3 | `COUNT(capitulo) = 1 189` | 1 189 |
| 4 | `COUNT(versiculo) ≈ 31 102` | 31 102 (entre 31 000 y 31 200) |
| 5 | `LIKE %Dios% > 1 000` | ~3 833 |
| 6 | `FTS5 MATCH Dios* ≈ LIKE` | dentro de 5% |
| 7 | `FTS5 MATCH jose* > 100` | ~236 |
| 8 | `FTS5 insensibilidad tildes: josé* == jose*` | diferencia < 1% |
| 9 | `PRAGMA integrity_check` | `ok` |
| 10 | `PRAGMA foreign_key_check` | 0 violaciones |
| 11 | `RVR1909 = 31 102 versículos` | 31 102 |

## Salida esperada

```
✅ Schema aplicado (migración 001)
✅ Versiones insertadas: 1 (RV1909)
✅ Libros insertados: 66
✅ Capítulos insertados: 1189
   ✓ 31102 versículos parseados
   ✓ RV1909: 31102 versículos insertados
✅ Versículos insertados: 31102
✅ Config insertada
✅ ANALYZE ejecutado
🔍 Ejecutando validaciones... (11/11 ✅)
📦 DB final copiado a: .../assets/db/biblia.db
📊 Tamaño: ~7.5 MB
⏱️  TOTAL: ~4 segundos
```

## Tiempo y tamaño de build (medidos, v1.0.1)

- **Tiempo total:** ~4-5 s en desktop Linux x86_64 moderno.
- **Tamaño del DB:** ~7.45 MB (sin comprimir).
- **Tamaño .gz estimado:** ~3-4 MB (ver `dart compile js` o `gzip`).
- **Reducción vs v1.0.0:** 15.19 MB → 7.45 MB (**-51%**).

## ¿Cómo añadir una nueva versión?

Ver `SOURCES.md` §4. Resumen:

1. Obtener fuente estructurada (JSON/SQL).
2. Normalizar al orden canónico (ver `lib/books_canon.dart`).
3. Modificar `_insertVersions()` y `_insertVerses()` en `build_biblia_db.dart`.
4. Añadir un parser (análogo a `_parseRv1909Sql`).
5. Re-correr el build.
6. Validar conteos.
7. Commit + actualizar `SOURCES.md`.

## Limitaciones conocidas

- **Sin deuterocanónicos:** no se incluyen Tobit, Judith, Sabiduría,
  Eclesiástico, Baruc, 1-2 Macabeos (presentes en Biblias católicas
  pero no en el canon protestante que sigue la tradición Reina Valera).
  Para añadirlos: nueva tabla `deuterocanonico` o ampliar `libro` con
  un campo `es_deuterocanonico INTEGER`.
- **Sin Strong's numbers:** el texto no incluye números Strong para
  concordancias. Si se necesitan, son una capa adicional (no
  contemplada en el schema actual).

## Patrón de consumo en runtime (responsabilidad de @dev + @curie)

El DB generado se **embebe como asset** y se copia al primer arranque:

```dart
// (pseudocódigo basado en lib/core/database/bible_database_helper.dart existente)
final dbPath = p.join(appDir.path, 'biblia.db');
final exists = File(dbPath).existsSync();
if (!exists) {
  final bytes = await rootBundle.load('assets/db/biblia.db');
  await File(dbPath).writeAsBytes(bytes.buffer.asUint8List());
}
final db = await openDatabase(dbPath);
```

Esto significa que **el `.db` de runtime es writable** (favoritos, notas,
historial), pero las **lecturas masivas** (texto bíblico, búsqueda FTS5)
siempre vienen del snapshot del asset. En la práctica, las escrituras se
limitan a ~1 KB/día por usuario, así que el DB nunca crece demasiado.
