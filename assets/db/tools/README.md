# `assets/db/tools/` — Generadores de bases de datos

Esta carpeta contiene scripts que **generan los `.db`** a partir de
fuentes externas. Son offline-build tools: no se incluyen en el binario
de la app, solo se ejecutan en la máquina del desarrollador o en CI.

## Estado actual (Fase 1)

| Archivo                      | Estado    | Descripción                          |
|------------------------------|-----------|--------------------------------------|
| `build_biblia_db.dart`       | STUB      | Validación de args, mensaje de plan  |
| `build_himnario_db.dart`     | Pendiente | Si se necesita regenerar el himnario |

## Plan de Fase 2: `build_biblia_db.dart`

Pipeline completo (referencia para la implementación futura):

```
┌──────────────────┐    ┌──────────────────┐
│ Upstream RV1909  │    │ Upstream RV1569  │
│ (SQL dump)       │    │ (Wikisource txt) │
└────────┬─────────┘    └────────┬─────────┘
         │                       │
         ▼                       ▼
   ┌──────────────────────────────────┐
   │  Normalización:                  │
   │  * Quitar CRLF                   │
   │  * Normalizar Unicode (NFC)      │
   │  * Eliminar numerales prefijados │
   │  * Validar ids canónicos         │
   └──────────────┬───────────────────┘
                  ▼
   ┌──────────────────────────────────┐
   │  Aplicar 001_biblia_schema.sql   │
   │  Aplicar 002_biblia_seed_*.sql   │
   │  Aplicar 003_biblia_seed_*.sql   │
   │  BEGIN; ... COMMIT; por cada     │
   │  bloque de 5 000 versículos      │
   └──────────────┬───────────────────┘
                  ▼
   ┌──────────────────────────────────┐
   │  VACUUM + ANALYZE                │
   │  Calcular CRC32                  │
   │  Reportar tamaño final           │
   └──────────────┬───────────────────┘
                  ▼
            assets/db/biblia.db
```

## Uso (Fase 2)

```bash
# 1. Descargar fuentes
git clone https://github.com/iglesianazaret/biblia-reina-valera-1909-base-datos-sql.git ./tmp/rv1909
curl -L "https://es.wikisource.org/wiki/Biblia_del_Oso" -o ./tmp/rv1569.html

# 2. Generar
dart run assets/db/tools/build_biblia_db.dart \
  --rv1909 ./tmp/rv1909/biblia.sql \
  --rv1569 ./tmp/rv1569.txt \
  --out    assets/db/biblia.db

# 3. Verificar integridad
sqlite3 assets/db/biblia.db "PRAGMA integrity_check;"
sqlite3 assets/db/biblia.db "SELECT COUNT(*) FROM versiculo;"
# Esperado: 62 204
```

## Patrón de consumo en runtime (responsabilidad de @dev + @curie)

El DB generado se **embebe como asset** y se copia al primer arranque:

```dart
// (pseudocódigo basado en lib/core/database/database_helper.dart existente)
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

## Tamaños objetivo

| Etapa                | Tamaño esperado |
|----------------------|-----------------|
| `biblia.db` (crudo)  | 10-15 MB        |
| `biblia.db` (.gz)    | ~5 MB           |
| App bundle total     | +5 MB (a verificar con @dev si es aceptable) |
