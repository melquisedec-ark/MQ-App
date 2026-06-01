# Schema de `biblia.db` — MQ-App

> **Propósito:** Documentar el schema del módulo Biblia para los developers
> que implementarán el patrón Repository en la Fase 2.
> **Archivo fuente:** `assets/db/schema/001_biblia_schema.sql` (300 líneas, DDL puro)
> **Motor:** SQLite 3.39+ (FFI bundleado, ver `lib/core/database/README.md`)
> **Cardinalidad esperada:** 62 204 versículos (31 102 × 2 versiones)

---

## Visión general

La DB del módulo Biblia tiene **9 tablas físicas + 1 virtual (FTS5)**:

| # | Tabla                | Tipo     | Propósito                                  |
|---|----------------------|----------|--------------------------------------------|
| 1 | `version`            | Catálogo | Versiones bíblicas (RV1909, RV1569)        |
| 2 | `libro`              | Catálogo | 66 libros canónicos por versión            |
| 3 | `capitulo`           | Catálogo | Capítulos por libro                        |
| 4 | `versiculo`          | Núcleo   | Texto bíblico (~62 K filas)                |
| 5 | `versiculo_fts`      | Virtual  | Índice full-text con acento-insensibilidad |
| 6 | `favorito_versiculo` | Usuario  | Versículos marcados por el usuario         |
| 7 | `nota`               | Usuario  | Notas personales (1 por versículo)         |
| 8 | `historial_versiculo`| Sistema  | Bitácora append-only de lecturas           |
| 9 | `config`             | Sistema  | Preferencias key-value                     |
| 10| `schema_version`     | Sistema  | Bitácora de migraciones aplicadas          |

---

## Diagrama Entidad-Relación (ASCII)

```
                              ┌─────────────┐
                              │  version    │
                              │─────────────│
                              │ id PK       │
                              │ nombre      │ (UNIQUE)
                              │ abreviatura │ (UNIQUE)
                              │ idioma      │
                              │ anio_pub    │
                              │ activa      │
                              └──────┬──────┘
                                     │ 1
                                     │
                                     │ N
                              ┌──────┴──────┐
                              │   libro     │
                              │─────────────│
                              │ id PK       │
                              │ version_id  │──> version.id (FK, CASCADE)
                              │ nombre      │
                              │ abreviatura │
                              │ testamento  │ (CHECK 'AT'|'NT')
                              │ numero      │ (1..66)
                              │ total_cap   │ UNIQUE(version_id, numero)
                              └──────┬──────┘
                                     │ 1
                                     │
                                     │ N
                              ┌──────┴──────┐
                              │  capitulo   │
                              │─────────────│
                              │ id PK       │
                              │ libro_id FK │──> libro.id (CASCADE)
                              │ numero      │ UNIQUE(libro_id, numero)
                              │ total_vers  │
                              └──────┬──────┘
                                     │ 1
                                     │
                                     │ N
                              ┌──────┴──────┐         ┌─────────────────┐
                              │ versiculo   │────────>│ versiculo_fts   │
                              │─────────────│ content │ (FTS5, external)│
                              │ id PK       │         │ tokenize=       │
                              │ cap_id FK   │         │  unicode61      │
                              │ numero      │         │  remove_diacr.2 │
                              │ texto       │         └─────────────────┘
                              │ UNIQUE(cap, │
                              │        num) │
                              └─────────────┘
                                     ▲
                                     │ (referenciado lógicamente, no FK)
                                     │
        ┌────────────────────┬───────┴────────┬──────────────────────┐
        │                    │                │                      │
┌───────┴──────────┐ ┌──────┴─────────┐ ┌────┴──────────────┐ ┌────┴────────────┐
│ favorito_versic. │ │     nota       │ │ historial_versic. │ │     config      │
│──────────────────│ │────────────────│ │───────────────────│ │─────────────────│
│ id PK            │ │ id PK          │ │ id PK             │ │ clave PK        │
│ version_id FK    │ │ version_id FK  │ │ version_id FK     │ │ valor           │
│ libro_id   FK    │ │ libro_id   FK  │ │ libro_id   FK     │ │ fecha_mod       │
│ capitulo         │ │ capitulo       │ │ capitulo          │ └─────────────────┘
│ numero           │ │ numero         │ │ numero            │
│ fecha_agregado   │ │ contenido      │ │ fecha_lectura     │ ┌─────────────────┐
│ UNIQUE(v,l,c,n)  │ │ color CHECK    │ │ (append-only)     │ │ schema_version  │
└──────────────────┘ │ fecha_creac    │ └───────────────────┘ │─────────────────│
                     │ fecha_mod      │                       │ version PK      │
                     │ UNIQUE(v,l,c,n)│                       │ descripcion     │
                     └────────────────┘                       │ fecha_aplicacion│
                                                               └─────────────────┘
```

> ⚠️ Las tablas de usuario (`favorito_versiculo`, `nota`, `historial_versiculo`)
> referencian `libro.id` y `version.id` pero **no** `versiculo.id` directamente.
> Esto permite "favoritos fantasma" si una versión se re-versifica (decisión
> documentada en `assets/db/schema/README.md`).

---

## Detalle de tablas

### `version` — Catálogo de versiones bíblicas

```sql
id                 INTEGER PRIMARY KEY AUTOINCREMENT
nombre             TEXT    NOT NULL UNIQUE       -- "Reina Valera 1909"
abreviatura        TEXT    NOT NULL UNIQUE       -- "RVR1909"
idioma             TEXT    NOT NULL              -- ISO 639-1: "es"
descripcion        TEXT                          -- texto libre
anio_publicacion   INTEGER                       -- 1909, 1569
es_dominio_publico INTEGER NOT NULL DEFAULT 1 CHECK(0|1)
activa             INTEGER NOT NULL DEFAULT 1 CHECK(0|1)
```

**Propósito:** Identificar las versiones bíblicas soportadas. Solo se cargan
las activas al inicio (`SELECT * FROM version WHERE activa=1`).

### `libro` — 66 libros canónicos

```sql
id              INTEGER PRIMARY KEY AUTOINCREMENT
version_id      INTEGER NOT NULL → version.id (CASCADE)
nombre          TEXT    NOT NULL                -- "Génesis"
abreviatura     TEXT    NOT NULL                -- "Gn"
testamento      TEXT    NOT NULL CHECK('AT'|'NT')
numero          INTEGER NOT NULL CHECK(1..66)
total_capitulos INTEGER NOT NULL CHECK(>0)
UNIQUE(version_id, numero)
```

**Propósito:** Listar libros para navegación. `numero` permite orden canónico
sin `ORDER BY nombre` (que es locale-dependiente).

### `capitulo` — Capítulos por libro

```sql
id              INTEGER PRIMARY KEY AUTOINCREMENT
libro_id        INTEGER NOT NULL → libro.id (CASCADE)
numero          INTEGER NOT NULL CHECK(>0)
total_versiculos INTEGER NOT NULL CHECK(>=0)
UNIQUE(libro_id, numero)
```

**Propósito:** Mostrar grids de capítulos. `total_versiculos` se
desnormaliza para evitar `COUNT(*)` en la UI ("Salmos 119:176 vers.").

### `versiculo` — Texto bíblico (núcleo)

```sql
id          INTEGER PRIMARY KEY AUTOINCREMENT
capitulo_id INTEGER NOT NULL → capitulo.id (CASCADE)
numero      INTEGER NOT NULL CHECK(>0)
texto       TEXT    NOT NULL
UNIQUE(capitulo_id, numero)
```

**Propósito:** Almacenar el texto sagrado. ~31 102 filas por versión, ~4 KB
totales por versículo promedio. La columna más "cara" de toda la DB.

### `versiculo_fts` — Índice full-text (virtual)

```sql
CREATE VIRTUAL TABLE versiculo_fts USING fts5(
  texto,
  content='versiculo',
  content_rowid='id',
  tokenize='unicode61 remove_diacritics 2'
);
```

**Propósito:** Búsqueda acento-insensible ultrarrápida. El contenido NO se
duplica: el FTS apunta a `versiculo.id` por rowid. Los 3 triggers
`versiculo_ai/ad/au` mantienen la sincronía.

**Ejemplo de query:**

```sql
-- Buscar versículos con "amor" (también matchea "Amor", "AMOR", y tildes)
SELECT v.id, v.texto
FROM versiculo_fts fts
JOIN versiculo v ON v.id = fts.rowid
WHERE versiculo_fts MATCH 'amor'
ORDER BY rank
LIMIT 50;

-- Búsqueda multi-término (AND implícito con espacios)
SELECT v.id, v.texto
FROM versiculo_fts fts
JOIN versiculo v ON v.id = fts.rowid
WHERE versiculo_fts MATCH 'Dios amor'
LIMIT 50;

-- Frase exacta
SELECT v.id, v.texto
FROM versiculo_fts fts
JOIN versiculo v ON v.id = fts.rowid
WHERE versiculo_fts MATCH '"camino verdad vida"'
LIMIT 50;
```

### `favorito_versiculo` — Marcados del usuario

```sql
id            INTEGER PRIMARY KEY AUTOINCREMENT
version_id    INTEGER NOT NULL → version.id (CASCADE)
libro_id      INTEGER NOT NULL → libro.id   (CASCADE)
capitulo      INTEGER NOT NULL CHECK(>0)
numero        INTEGER NOT NULL CHECK(>0)
fecha_agregado INTEGER NOT NULL  -- unix timestamp
UNIQUE(version_id, libro_id, capitulo, numero)
```

**Propósito:** Marcar versículos. La unicidad evita duplicados sin código.
Trigger `favorito_versiculo_bi/bu` valida coherencia version-libro.

### `nota` — Notas personales

```sql
id                  INTEGER PRIMARY KEY AUTOINCREMENT
version_id          INTEGER NOT NULL → version.id
libro_id            INTEGER NOT NULL → libro.id
capitulo            INTEGER NOT NULL CHECK(>0)
numero              INTEGER NOT NULL CHECK(>0)
contenido           TEXT    NOT NULL
color               TEXT    NOT NULL CHECK('amarillo'|'verde'|'azul'|'ninguno')
fecha_creacion      INTEGER NOT NULL
fecha_modificacion  INTEGER NOT NULL
UNIQUE(version_id, libro_id, capitulo, numero)
```

**Propósito:** Una nota por versículo con color semaforizado (GTD-style).

### `historial_versiculo` — Bitácora append-only

```sql
id            INTEGER PRIMARY KEY AUTOINCREMENT
version_id    INTEGER NOT NULL → version.id
libro_id      INTEGER NOT NULL → libro.id
capitulo      INTEGER NOT NULL CHECK(>0)
numero        INTEGER NOT NULL CHECK(>0)
fecha_lectura INTEGER NOT NULL  -- unix timestamp
```

**Propósito:** Generado por el sistema cada vez que se lee un versículo.
Permite "última posición", streaks, versículos más leídos. Se puede podar.

### `config` — Preferencias key-value

```sql
clave              TEXT PRIMARY KEY
valor              TEXT NOT NULL
fecha_modificacion INTEGER NOT NULL
```

**Propósito:** Preferencias en SQLite (no `SharedPreferences`) para
consistencia multiplataforma. Claves: `modo_emisor`, `version_default`,
`font_size`, etc.

### `schema_version` — Bitácora de migraciones

```sql
version         INTEGER PRIMARY KEY
descripcion     TEXT    NOT NULL
fecha_aplicacion INTEGER NOT NULL
```

**Propósito:** Auditoría de migraciones. El cliente Dart consulta
`SELECT MAX(version)` para saber qué migración aplicar.

---

## Triggers (7 totales)

### 3 de sincronización FTS5 (en `versiculo`)

| Trigger             | Evento   | Acción                                              |
|---------------------|----------|-----------------------------------------------------|
| `versiculo_ai`      | AFTER INSERT | INSERT en `versiculo_fts(rowid, texto)`        |
| `versiculo_ad`      | AFTER DELETE | INSERT en `versiculo_fts('delete', old.id, ...)` |
| `versiculo_au`      | AFTER UPDATE | DELETE old + INSERT new en `versiculo_fts`     |

**Por qué son obligatorios:** las FTS5 con `content=` NO se sincronizan
automáticamente. Sin estos triggers, las búsquedas devuelven 0 filas aunque
`versiculo` tenga datos. Documentado en el header del SQL.

### 4 de validación `version_id ↔ libro_id` (en `favorito_versiculo` y `nota`)

| Trigger                    | Evento          | Validación                                       |
|----------------------------|-----------------|--------------------------------------------------|
| `favorito_versiculo_bi`    | BEFORE INSERT   | `libro.version_id = NEW.version_id`             |
| `favorito_versiculo_bu`    | BEFORE UPDATE   | idem                                             |
| `nota_bi`                  | BEFORE INSERT   | idem                                             |
| `nota_bu`                  | BEFORE UPDATE   | idem                                             |

**Qué previenen:** inserts/update con un `libro_id` "robado" de otra versión.
Ejemplo bloqueado:

```sql
-- libro 42 pertenece a version 2 (RV1569)
INSERT INTO favorito_versiculo (version_id=1, libro_id=42, ...)
-- ERROR: favorito_versiculo: libro_id no pertenece a version_id
```

---

## Índices (12 totales)

| Índice                          | Tabla                  | Optimiza query                                       |
|---------------------------------|------------------------|------------------------------------------------------|
| `idx_version_activa`            | `version`              | `WHERE activa=1`                                     |
| `idx_libro_version`             | `libro`                | `WHERE version_id=?`                                 |
| `idx_libro_testamento`          | `libro`                | `WHERE testamento='AT'` (filtro AT/NT)               |
| `idx_capitulo_libro`            | `capitulo`             | `WHERE libro_id=?`                                   |
| `idx_versiculo_capitulo`        | `versiculo`            | `WHERE capitulo_id=?` (lectura de capítulo)          |
| `idx_favorito_lookup`           | `favorito_versiculo`   | `WHERE version_id=? AND libro_id=?`                  |
| `idx_favorito_fecha`            | `favorito_versiculo`   | `ORDER BY fecha_agregado DESC` (lista cronológica)  |
| `idx_nota_lookup`               | `nota`                 | `WHERE version_id=? AND libro_id=?`                  |
| `idx_nota_fecha_mod`            | `nota`                 | `ORDER BY fecha_modificacion DESC`                   |
| `idx_historial_fecha`           | `historial_versiculo`  | `ORDER BY fecha_lectura DESC LIMIT 1` (última pos.)  |
| `idx_historial_lookup`          | `historial_versiculo`  | `WHERE version_id=? AND libro_id=?`                  |
| FTS5 interno                    | `versiculo_fts`        | `MATCH '...'` (búsqueda full-text)                  |

---

## Estrategia de migraciones

Cada archivo se numera secuencialmente (`001_…`, `002_…`, etc.). Al aplicar:

1. Iniciar transacción (`BEGIN`).
2. Ejecutar el DDL del archivo.
3. `INSERT INTO schema_version (version, descripcion, fecha_aplicacion)`.
4. `COMMIT`.

El cliente Dart (`DatabaseHelper`) lee `SELECT MAX(version) FROM
schema_version` y aplica las migraciones faltantes en orden. Ejemplo de
migración futura (referencia, no aplicada):

```sql
-- 004_agregar_tabla_plan_lectura.sql
CREATE TABLE plan_lectura (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre        TEXT NOT NULL,
  duracion_dias INTEGER NOT NULL,
  fecha_inicio  INTEGER NOT NULL
);
INSERT INTO schema_version (version, descripcion, fecha_aplicacion)
VALUES (4, 'Agregar plan_lectura para retos', strftime('%s', 'now'));
```

---

## Patrones de query comunes

### Q1 — Listar libros del AT de la versión RV1909

```sql
SELECT id, nombre, abreviatura, total_capitulos
FROM libro
WHERE version_id = 1 AND testamento = 'AT'
ORDER BY numero;
```

### Q2 — Leer capítulo completo (ej. Juan 3)

```sql
SELECT v.id, v.numero, v.texto
FROM versiculo v
JOIN capitulo c ON c.id = v.capitulo_id
JOIN libro l ON l.id = c.libro_id
WHERE l.abreviatura = 'Jn' AND c.numero = 3
ORDER BY v.numero;
```

### Q3 — Versículo aleatorio (home)

```sql
SELECT v.id, v.texto, l.nombre, c.numero, v.numero
FROM versiculo v
JOIN capitulo c ON c.id = v.capitulo_id
JOIN libro l ON l.id = c.libro_id
WHERE l.version_id = 1
ORDER BY RANDOM()
LIMIT 1;
```

### Q4 — Búsqueda FTS5 con join a libro/capítulo

```sql
SELECT l.nombre AS libro, c.numero AS cap, v.numero AS vers, v.texto
FROM versiculo_fts fts
JOIN versiculo v ON v.id = fts.rowid
JOIN capitulo c ON c.id = v.capitulo_id
JOIN libro l ON l.id = c.libro_id
WHERE versiculo_fts MATCH 'amor'
ORDER BY rank
LIMIT 20;
```

### Q5 — Versículos favoritos del usuario

```sql
SELECT fv.capitulo, fv.numero, l.nombre, l.abreviatura
FROM favorito_versiculo fv
JOIN libro l ON l.id = fv.libro_id
WHERE fv.version_id = 1
ORDER BY fv.fecha_agregado DESC;
```

### Q6 — Última posición leída (resume)

```sql
SELECT l.abreviatura, c.numero, v.numero
FROM historial_versiculo h
JOIN libro l ON l.id = h.libro_id
WHERE h.version_id = 1
ORDER BY h.fecha_lectura DESC
LIMIT 1;
```

### Q7 — Total de notas por color

```sql
SELECT color, COUNT(*) AS total
FROM nota
WHERE version_id = 1
GROUP BY color;
```

### Q8 — Capítulos con más notas (top 5)

```sql
SELECT l.nombre, n.capitulo, COUNT(*) AS notas_count
FROM nota n
JOIN libro l ON l.id = n.libro_id
WHERE n.version_id = 1
GROUP BY l.id, n.capitulo
ORDER BY notas_count DESC
LIMIT 5;
```

---

## Tamaño estimado

| Recurso                         | Tamaño             |
|---------------------------------|--------------------|
| Texto bíblico crudo (2 ver.)    | ~15-17 MB          |
| DB compactada con FTS5 incluido | **5-7 MB**         |
| APK con DB bundleada (debug)    | 164 MB (sin split) |
| APK release split-per-abi       | ~25-30 MB / ABI    |

Cálculo: ~31 102 versículos × ~250 bytes/texto = ~7.5 MB por versión; el
FTS5 external content añade solo el índice invertido (~1-2 MB total).
Compresión nativa SQLite (`VACUUM` + `PRAGMA page_size`) reduce ~60%.

---

## Referencias

- **DDL fuente:** `assets/db/schema/001_biblia_schema.sql` (300 líneas)
- **Decisiones de diseño:** `assets/db/schema/README.md`
- **Distribución y build:** `assets/db/README.md`
- **Stack FFI en Dart:** `lib/core/database/README.md`
- **Reporte de Fase 1:** [`PHASE_1_REPORT.md`](PHASE_1_REPORT.md)
- **Decisión FTS5:** [`ARCHITECTURE_DECISIONS.md`](ARCHITECTURE_DECISIONS.md) §3
- **Decisión multi-DB:** [`ARCHITECTURE_DECISIONS.md`](ARCHITECTURE_DECISIONS.md) §5

---

*Documento creado por @documentador el 1 de junio de 2026*
*Para preguntas, contactar a @back (diseño) o @dev (implementación Fase 2)*
