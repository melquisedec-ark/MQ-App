# `assets/db/tools/` — Generadores de bases de datos

Esta carpeta contiene scripts que **generan los `.db`** a partir de
fuentes externas. Son offline-build tools: no se incluyen en el binario
de la app, solo se ejecutan en la máquina del desarrollador o en CI.

## Estado actual (Fase 2)

| Archivo                            | Estado    | Descripción                                  |
|------------------------------------|-----------|----------------------------------------------|
| `build_biblia_db.dart`             | ✅ Funcional | Genera `assets/db/biblia.db` desde fuentes upstream |
| `build_himnario_db.dart`           | Pendiente | Si se necesita regenerar el himnario        |
| `lib/books_canon.dart`             | ✅ Funcional | Metadatos canónicos de los 66 libros        |
| `source/rv1909/data.sql`           | ✅ Trackeado | Dump SQL de RV1909 (4.4 MB)                 |
| `source/rv1569/`                   | ⚠️ Placeholder | Fuente pendiente — ver `SOURCES.md`         |
| `SOURCES.md`                       | ✅ Completo | Documentación de fuentes y limitaciones     |

## Cómo ejecutar el build

```bash
# 1. Asegurarse de que las dependencias de Dart estén instaladas
dart pub get

# 2. Ejecutar el build (tarda ~9 s en un desktop Linux moderno)
dart run assets/db/tools/build_biblia_db.dart

# Flags opcionales:
#   --schema <path>     : ruta alternativa al schema (default: 001_biblia_schema.sql)
#   --rv1909  <path>    : ruta alternativa al data.sql RV1909
#   --out     <path>    : ruta del DB de salida (default: assets/db/biblia.db)
#   --keep-temp         : conserva el DB temporal para debugging
#   --skip-validate     : salta las 12 validaciones (NO recomendado)
```

Si `libsqlite3.so` no está en una ruta estándar, exportar la variable:

```bash
export LIBSQLITE3_PATH=/ruta/a/libsqlite3.so.0
dart run assets/db/tools/build_biblia_db.dart
```

## ¿Qué hace el script? (paso a paso)

```
┌──────────────────────────────────┐
│ 1. Aplica 001_biblia_schema.sql  │  (DDL puro: tablas + FTS5 + triggers)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 2. Inserta 2 versiones           │  (RVR1909, RVR1569)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 3. Inserta 132 libros (66 × 2)  │  (orden canónico 1-66 desde lib/books_canon.dart)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 4. Inserta 2 378 capítulos       │  (1 189 × 2, con total_versiculos=0 inicialmente)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 5. Parsea fuente RV1909          │  (regex + escape SQL en _parseRv1909Sql)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 6. Inserta 31 102 versículos × 2 │  (lotes de 1 000 con BEGIN/COMMIT)
│    RV1909: texto real            │
│    RV1569: texto = RV1909 (placeholder)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 7. Actualiza total_versiculos    │  (UPDATE por cada capítulo)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 8. Inserta config                │  (marcador RV1569 placeholder)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 9. ANALYZE                       │  (estadísticas para el query planner)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 10. Ejecuta 12 validaciones      │  (ver tabla abajo)
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│ 11. Copia el DB a la ruta final  │  (assets/db/biblia.db)
└──────────────────────────────────┘
```

## Validaciones (12 en total)

El script ejecuta 12 verificaciones y **falla** si alguna no pasa. Para
omitirlas (debugging), usar `--skip-validate`.

| # | Test | Esperado |
|---|------|----------|
| 1 | `COUNT(version) = 2` | 2 |
| 2 | `COUNT(libro) = 132` | 132 |
| 3 | `COUNT(capitulo) = 2 378` | 2 378 |
| 4 | `COUNT(versiculo) ≈ 62 204` | 62 204 (entre 62 000 y 62 500) |
| 5 | `LIKE %Dios% > 1 000` | ~7 666 |
| 6 | `FTS5 MATCH Dios* ≈ LIKE` | dentro de 5% |
| 7 | `FTS5 MATCH jose* > 100` | ~472 |
| 8 | `FTS5 insensibilidad tildes: josé* == jose*` | diferencia < 1% |
| 9 | `PRAGMA integrity_check` | `ok` |
| 10 | `PRAGMA foreign_key_check` | 0 violaciones |
| 11 | `RVR1909 = 31 102 versículos` | 31 102 |
| 12 | `RVR1569 = 31 102 versículos` | 31 102 |

## Salida esperada

```
✅ Schema aplicado (migración 001)
✅ Versiones insertadas: 2 (RV1909, RV1569)
✅ Libros insertados: 132
✅ Capítulos insertados: 2378
   ✓ 31102 versículos parseados
   ✓ RV1909: 31102 versículos insertados
   ✓ RV1569: 31102 versículos insertados (texto idéntico a RV1909)
✅ Versículos insertados: 62204
✅ Config insertada (marcador RV1569 placeholder)
✅ ANALYZE ejecutado
🔍 Ejecutando validaciones... (12/12 ✅)
📦 DB final copiado a: .../assets/db/biblia.db
📊 Tamaño: ~15 MB
⏱️  TOTAL: ~6 segundos
```

## Tiempo y tamaño de build (medidos)

- **Tiempo total:** ~6-9 s en desktop Linux x86_64 moderno.
- **Tamaño del DB:** ~15 MB (sin comprimir).
- **Tamaño .gz estimado:** ~5-6 MB (ver `dart compile js` o `gzip`).

## ¿Cómo añadir una nueva versión?

Ver `SOURCES.md` §4. Resumen:

1. Obtener fuente estructurada (JSON/SQL).
2. Normalizar al orden canónico (ver `lib/books_canon.dart`).
3. Modificar `_insertVersions()` en `build_biblia_db.dart`.
4. Añadir un parser (análogo a `_parseRv1909Sql`).
5. Re-correr el build.
6. Validar conteos.
7. Commit + actualizar `SOURCES.md`.

## Limitaciones conocidas

- **RV1569:** placeholder. El texto es idéntico a RV1909 hasta que se
  disponga de una fuente estructurada. Ver `SOURCES.md` §2.
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
