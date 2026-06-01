# `assets/db/schema/` — Diseño del schema de la Biblia

Este directorio contiene el DDL puro (sin datos) de la base de datos del
módulo Biblia. Los archivos se numeran para forzar el orden de aplicación:

| Archivo                              | Propósito                                                  |
|--------------------------------------|------------------------------------------------------------|
| `001_biblia_schema.sql`              | DDL: 6 tablas + FTS5 + triggers + índices                  |
| `002_biblia_seed_rv1909_stub.sql`    | Seed: 1 INSERT en `version` (RV1909)                       |
| `003_biblia_seed_rv1569_stub.sql`    | Seed: 1 INSERT en `version` (RV1569)                       |
| (futuros `004_…`, `005_…`)           | Migraciones: añadir tablas, columnas, índices, etc.       |

## Decisiones de diseño

### 1. Por qué FTS5 con `unicode61 remove_diacritics 2`

FTS5 es el motor de búsqueda full-text **nativo de SQLite 3.9+** y no añade
dependencias externas. La opción `remove_diacritics 2` aplicada al
tokenizador `unicode61` (estándar de SQLite 3.39+) logra:

- Búsqueda **insensible a tildes**: `José` == `jose`, `María` == `maria`,
  `Niño` == `nino`.
- Es crítico en móvil: el teclado en pantalla omite tildes en la mayoría
  de los casos.
- El FTS5 se declara **external-content** (`content='versiculo'`,
  `content_rowid='id'`): el texto no se duplica en el índice, ahorrando
  ~10 MB totales entre ambas versiones.

⚠️  **Triggers obligatorios**: las tablas FTS5 con `content=` requieren
triggers `AFTER INSERT/UPDATE/DELETE` en la tabla fuente para mantenerse
sincronizadas. El schema los incluye (`versiculo_ai`, `versiculo_ad`,
`versiculo_au`). **No los elimines** o las búsquedas devolverán 0 filas.

### 2. Por qué `UNIQUE` en favoritos y notas

- `favorito_versiculo`: `UNIQUE(version_id, libro_id, capitulo, numero)`
  garantiza que un versículo no se marque dos veces en la misma versión.
- `nota`: misma unicidad, pero además permite "una sola nota por versículo"
  (modelo simple; se puede extender a tabla `nota_revisiones` en el futuro).

El `UNIQUE` se aplica al INSERT inicial, evitando lógica de
"¿ya existe?" en Dart. **El precio**: si en el futuro queremos múltiples
notas por versículo, se necesitará una migración. Ver sección "Migraciones"
abajo.

### 3. Por qué separar `historial_versiculo` de `favorito_versiculo`

- `favorito_versiculo` está **curado por el usuario** (acción explícita).
- `historial_versiculo` es **generado por el sistema** (cada vez que se
  lee un versículo, se inserta una fila).

Mezclarlos generaría:
- Polución al listar "favoritos" (incluiría todo lo leído).
- Imposibilidad de distinguir "el usuario quiere ver esto de nuevo" vs
  "el sistema sabe que leyó esto".

Adicionalmente, `historial_versiculo` es **append-only** y se puede podar
periódicamente (ej. mantener últimos 12 meses) sin tocar favoritos.

### 4. Por qué una tabla `config` en vez de `SharedPreferences`

- **Consistencia de plataforma**: HimnarioID 2.0 ya usa SQLite para
  preferencias (ver `lib/core/database/`). Usar el mismo motor evita
  divergencia entre `shared_preferences` (Android/iOS nativos) y
  `path_provider` (desktop).
- **Backup único**: una sola carpeta a copiar para restaurar TODO el
  estado del usuario.
- **Atomicidad**: las preferencias de la Biblia y del Himnario pueden
  transaccionar juntas (ej. "cambiar a modo emisor" afecta a ambos).
- **Migración trivial**: añadir un nuevo `clave` es solo `INSERT`.

### 5. Estrategia de migraciones (`schema_version`)

El patrón sigue las convenciones de `sqflite_common_ffi` y de herramientas
como `sqflite_migration`:

1. Cada archivo nuevo se numera secuencialmente:
   `004_agregar_xxx.sql`, `005_…`, etc.
2. Al aplicar, se inicia transacción, se ejecuta el DDL, se hace `INSERT`
   en `schema_version`, se hace `COMMIT`.
3. El cliente Dart (`DatabaseHelper`) consulta
   `SELECT MAX(version) FROM schema_version` para saber qué migraciones
   ya se aplicaron y aplica las faltantes en orden.
4. El campo `descripcion` permite auditar cambios en producción.

#### Ejemplo de migración futura (referencia, no aplicada)

```sql
-- 004_agregar_tabla_plan_lectura.sql
CREATE TABLE plan_lectura (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre      TEXT NOT NULL,
  duracion_dias INTEGER NOT NULL,
  fecha_inicio INTEGER NOT NULL
);
INSERT INTO schema_version (version, descripcion, fecha_aplicacion)
VALUES (4, 'Agregar tabla plan_lectura para retos de lectura',
        strftime('%s', 'now'));
```

### 6. Por qué `version_idioma` y `anio_publicacion` no tienen CHECK

- `idioma` se valida con código Dart (lista blanca de ISO 639-1: "es",
  "en", "pt", etc.). No es necesario CHECK en SQL: el código es la única
  fuente de verdad.
- `anio_publicacion` puede ser NULL (versiones en proceso).

### 7. Por qué triggers de validación `version_id ↔ libro_id`

`libro` tiene `UNIQUE(version_id, numero)`, lo que significa que un
`libro.id` pertenece a **una sola** versión. Sin embargo, las FKs de
`favorito_versiculo` y `nota` (`FOREIGN KEY (libro_id) REFERENCES libro(id)`)
solo verifican que el `libro_id` exista, **no** que pertenezca al mismo
`version_id` declarado en la fila. Esto permitía insertar favoritos o
notas con un `libro_id` "robado" de otra versión (datos inconsistentes).

Los triggers `BEFORE INSERT/UPDATE` (`favorito_versiculo_bi/bu`,
`nota_bi/bu`) rechazan cualquier escritura donde `libro_id` no
pertenezca al `version_id` de la fila, lanzando `RAISE(ABORT)` con
mensaje en español. Validación a nivel de esquema, no de aplicación:
la regla de integridad se cumple **incluso** si el cliente Dart
tiene un bug.

## Cardinalidad esperada (para dimensionar)

| Tabla                | Filas por versión | Total 2 ver. |
|----------------------|-------------------|--------------|
| `version`            | 1                 | 2            |
| `libro`              | 66                | 132          |
| `capitulo`           | 1 189             | 2 378        |
| `versiculo`          | 31 102            | 62 204       |
| `favorito_versiculo` | n/a (usuario)     | variable     |
| `nota`               | n/a (usuario)     | variable     |
| `historial_versiculo`| n/a (append-only) | crece con uso |
| `versiculo_fts`      | (índice, no filas) | externo      |

## Compatibilidad SQLite

- Requerido: **SQLite 3.39+** (FTS5 + `remove_diacritics 2` con valores
  extendidos).
- Probado contra: `sqflite_common_ffi 2.3.7` (ya en `pubspec.yaml`).
- En Android: `sqflite` usa la libsqlite del sistema, típicamente 3.32+.
  Verificar versión mínima en runtime con `sqlite_version()` antes de
  aplicar el schema (a coordinar con @dev).
