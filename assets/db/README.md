# `assets/db/` — Bases de datos en tiempo de ejecución

Esta carpeta hospeda los archivos `.db` que se distribuyen como **assets de
Flutter** y se copian al almacenamiento del usuario en el primer arranque
(patrón `copyIfNeededAndOpenAssetDatabase` documentado por @curie en
`lib/core/database/database_helper.dart`).

## Contenido actual

| Archivo               | Tamaño     | Estado   | Descripción                                |
|-----------------------|------------|----------|--------------------------------------------|
| `himnario_id.db`      | ~1.7 MB    | Trackeado | HimnarioID 2.0 (existente, NO tocar)       |
| `himnario_id.db-shm`  | < 100 KB   | Ignorado  | WAL shared memory (runtime)                |
| `himnario_id.db-wal`  | < 200 KB   | Ignorado  | Write-Ahead Log (runtime)                  |
| `db_version.json`     | 15 B       | Trackeado | Versión del schema del himnario            |
| `schema/`             | -          | Trackeado | DDL + seeds (este PR)                      |
| `tools/`              | -          | Trackeado | Scripts generadores (este PR)              |

## Bases de datos a futuro (Fase 2)

- **`biblia.db`** — Biblia completa (RV1909 + RV1569, ~62 000 versículos).
  Tamaño estimado: **10-15 MB** sin comprimir, **~5 MB** con
  `gzip -9` para distribución. **No se commitea** (ver `.gitignore`).

## ¿Cómo se construyen?

```bash
# Fase 2 (script aún en stub):
dart run assets/db/tools/build_biblia_db.dart \
  --rv1909 ./tmp/rv1909.sql \
  --rv1569 ./tmp/rv1569.txt \
  --out    assets/db/biblia.db
```

El script:
1. Aplica el schema (`001_biblia_schema.sql`).
2. Inserta las 2 versiones RV1909/RV1569.
3. Puebla libros, capítulos y versículos desde las fuentes.
4. Ejecuta `VACUUM` + `ANALYZE` para optimizar el FTS5.
5. Empaqueta el resultado como asset.

## Distribución al usuario

1. `pubspec.yaml` declara `assets/db/biblia.db` (responsabilidad de @dev).
2. `DatabaseHelper.open()` (existente en `lib/core/database/`) compara
   `db_version.json` del asset vs. copia local.
3. Si difieren, copia el `.db` al app dir y reabre.
4. El usuario puede tener su propia DB con favoritos/notas **separados** de
   la distribución (ver `schema_version` y migraciones en
   `schema/README.md`).

## Tamaños esperados (referencia)

| DB              | Filas aprox.   | Crudo  | Comprimido | Notas                          |
|-----------------|----------------|--------|------------|--------------------------------|
| `himnario_id.db`| ~600 himnos    | 1.7 MB | -          | Ya distribuido                 |
| `biblia.db`     | 62 204 vers.   | 12 MB  | ~5 MB      | 2 versiones × 31 102 vers.     |
| SQLite + FTS5   | + ~3 MB índice | 15 MB  | ~6 MB      | El FTS5 externo no duplica     |

> Las cifras son estimaciones. El script de Fase 2 reportará tamaños reales.
