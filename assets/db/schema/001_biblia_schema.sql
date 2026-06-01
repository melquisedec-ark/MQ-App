-- =============================================================================
-- 001_biblia_schema.sql
-- =============================================================================
-- Esquema de base de datos para el módulo Biblia de MQ-App.
-- Motor: SQLite 3.39+ (requerido para FTS5 con tokenizador unicode61 y la
-- opción `remove_diacritics 2` aplicada correctamente).
--
-- Este archivo define SOLO el esquema (DDL). Los datos semilla (versículos de
-- RV1909 y RV1569) se aplican en archivos separados:
--   * 002_biblia_seed_rv1909_stub.sql  (versión RV1909, dominio público)
--   * 003_biblia_seed_rv1569_stub.sql  (versión RV1569, dominio público)
--
-- Decisiones de diseño (resumen; ver schema/README.md para detalle):
--   1. Normalización 3FN: version → libro → capitulo → versiculo.
--   2. FTS5 con contenido externo (`content='versiculo'`) para no duplicar el
--      texto en el índice, ahorrando ~10 MB en dos versiones.
--   3. Triggers obligatorios sobre `versiculo` para mantener el FTS sincronizado
--      (sin triggers, las búsquedas devuelven vacío).
--   4. UNIQUE(version_id, libro_id, capitulo, numero) en favoritos/notas para
--      garantizar "un favorito/nota por versículo" sin código adicional.
--   5. `schema_version` permite migraciones incrementales sin perder datos.
-- =============================================================================

-- Habilitar foreign keys (debe ir por conexión; se asegura también en Dart)
PRAGMA foreign_keys = ON;

-- -----------------------------------------------------------------------------
-- Tabla: version
-- Almacena las versiones de la Biblia soportadas (RV1909, RV1569, futuras).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS version (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre             TEXT    NOT NULL UNIQUE,  -- "Reina Valera 1909"
  abreviatura        TEXT    NOT NULL UNIQUE,  -- "RVR1909"
  idioma             TEXT    NOT NULL,          -- ISO 639-1: "es"
  descripcion        TEXT,                     -- Texto libre
  anio_publicacion   INTEGER,                  -- 1909, 1569, etc.
  es_dominio_publico INTEGER NOT NULL DEFAULT 1 CHECK(es_dominio_publico IN (0, 1)),
  activa             INTEGER NOT NULL DEFAULT 1 CHECK(activa IN (0, 1))
);

CREATE INDEX IF NOT EXISTS idx_version_activa ON version(activa);

-- -----------------------------------------------------------------------------
-- Tabla: libro
-- 66 libros canónicos. `numero` sigue el orden canónico estándar:
--   AT: 1..46  (Génesis = 1, Malaquías = 39)
--   NT: 47..66 (Mateo = 40, Apocalipsis = 66)
-- Se incluye `testamento` aunque sea derivable para acelerar filtros de UI.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS libro (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  version_id      INTEGER NOT NULL,
  nombre          TEXT    NOT NULL,  -- "Génesis", "Éxodo", "1 Juan"
  abreviatura     TEXT    NOT NULL,  -- "Gn", "Ex", "1Jn"
  testamento      TEXT    NOT NULL CHECK(testamento IN ('AT', 'NT')),
  numero          INTEGER NOT NULL CHECK(numero BETWEEN 1 AND 66),
  total_capitulos INTEGER NOT NULL CHECK(total_capitulos > 0),
  FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
  UNIQUE (version_id, numero)
);

CREATE INDEX IF NOT EXISTS idx_libro_version    ON libro(version_id);
CREATE INDEX IF NOT EXISTS idx_libro_testamento ON libro(testamento);

-- -----------------------------------------------------------------------------
-- Tabla: capitulo
-- `total_versiculos` se desnormaliza para mostrar "Salmos 119:176 (176 vers.)"
-- sin agregar JOIN en la UI.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS capitulo (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  libro_id        INTEGER NOT NULL,
  numero          INTEGER NOT NULL CHECK(numero > 0),
  total_versiculos INTEGER NOT NULL CHECK(total_versiculos >= 0),
  FOREIGN KEY (libro_id) REFERENCES libro(id) ON DELETE CASCADE,
  UNIQUE (libro_id, numero)
);

CREATE INDEX IF NOT EXISTS idx_capitulo_libro ON capitulo(libro_id);

-- -----------------------------------------------------------------------------
-- Tabla: versiculo
-- Tabla núcleo. ~31 102 versículos por versión → ~62 204 filas totales.
-- `texto` es la única columna pesada. Se usa COLLATE NOCASE a nivel de
-- conexión para ordenamientos sin distinguir mayúsculas.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS versiculo (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  capitulo_id INTEGER NOT NULL,
  numero      INTEGER NOT NULL CHECK(numero > 0),
  texto       TEXT    NOT NULL,
  FOREIGN KEY (capitulo_id) REFERENCES capitulo(id) ON DELETE CASCADE,
  UNIQUE (capitulo_id, numero)
);

CREATE INDEX IF NOT EXISTS idx_versiculo_capitulo ON versiculo(capitulo_id);

-- -----------------------------------------------------------------------------
-- Tabla virtual: versiculo_fts (FTS5)
-- Búsqueda full-text con normalización de diacríticos. El tokenizador
-- `unicode61` con `remove_diacritics 2`:
--   * "José"  == "jose"  (sin tildes)
--   * "María" == "maria" (sin tildes)
--   * "Niño"  == "nino"
-- Esto es crítico para usuarios hispanohablantes que tipean sin acentos en
-- dispositivos móviles.
--
-- `content='versiculo'` + `content_rowid='id'` = FTS5 con contenido externo.
-- El texto NO se duplica en la tabla FTS; el índice apunta a `versiculo.id`.
-- Esto ahorra ~10 MB totales en ambas versiones.
--
-- ⚠️  IMPORTANTE: Las tablas FTS5 con `content=` REQUIEREN triggers para
-- mantener el índice sincronizado. Sin los triggers de abajo, las búsquedas
-- devolverán 0 filas aunque `versiculo` tenga datos.
-- -----------------------------------------------------------------------------
CREATE VIRTUAL TABLE IF NOT EXISTS versiculo_fts USING fts5(
  texto,
  content='versiculo',
  content_rowid='id',
  tokenize='unicode61 remove_diacritics 2'
);

-- Triggers: sincronizan versiculo → versiculo_fts
CREATE TRIGGER IF NOT EXISTS versiculo_ai AFTER INSERT ON versiculo BEGIN
  INSERT INTO versiculo_fts(rowid, texto) VALUES (new.id, new.texto);
END;

CREATE TRIGGER IF NOT EXISTS versiculo_ad AFTER DELETE ON versiculo BEGIN
  INSERT INTO versiculo_fts(versiculo_fts, rowid, texto) VALUES('delete', old.id, old.texto);
END;

CREATE TRIGGER IF NOT EXISTS versiculo_au AFTER UPDATE ON versiculo BEGIN
  INSERT INTO versiculo_fts(versiculo_fts, rowid, texto) VALUES('delete', old.id, old.texto);
  INSERT INTO versiculo_fts(rowid, texto) VALUES (new.id, new.texto);
END;

-- -----------------------------------------------------------------------------
-- Tabla: favorito_versiculo
-- Un usuario puede marcar un versículo como favorito UNA VEZ por versión.
-- No referenciamos `versiculo.id` directamente para permitir favoritos
-- "fantasma" si una versión se actualiza (ej. cambio de versificación).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS favorito_versiculo (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  version_id    INTEGER NOT NULL,
  libro_id      INTEGER NOT NULL,
  capitulo      INTEGER NOT NULL CHECK(capitulo > 0),
  numero        INTEGER NOT NULL CHECK(numero > 0),
  fecha_agregado INTEGER NOT NULL,  -- unix timestamp (segundos)
  FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
  FOREIGN KEY (libro_id)   REFERENCES libro(id)   ON DELETE CASCADE,
  UNIQUE (version_id, libro_id, capitulo, numero)
);

CREATE INDEX IF NOT EXISTS idx_favorito_lookup ON favorito_versiculo(version_id, libro_id, capitulo, numero);
CREATE INDEX IF NOT EXISTS idx_favorito_fecha  ON favorito_versiculo(fecha_agregado DESC);

-- -----------------------------------------------------------------------------
-- Tabla: nota
-- Una nota por (versión, libro, capítulo, versículo). Color permitido:
-- amarillo / verde / azul / ninguno. Esto se valida con CHECK.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nota (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  version_id          INTEGER NOT NULL,
  libro_id            INTEGER NOT NULL,
  capitulo            INTEGER NOT NULL CHECK(capitulo > 0),
  numero              INTEGER NOT NULL CHECK(numero > 0),
  contenido           TEXT    NOT NULL,
  color               TEXT    NOT NULL CHECK(color IN ('amarillo', 'verde', 'azul', 'ninguno')),
  fecha_creacion      INTEGER NOT NULL,
  fecha_modificacion  INTEGER NOT NULL,
  FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
  FOREIGN KEY (libro_id)   REFERENCES libro(id)   ON DELETE CASCADE,
  UNIQUE (version_id, libro_id, capitulo, numero)
);

CREATE INDEX IF NOT EXISTS idx_nota_lookup ON nota(version_id, libro_id, capitulo, numero);
CREATE INDEX IF NOT EXISTS idx_nota_fecha_mod ON nota(fecha_modificacion DESC);

-- ============================================================
-- VALIDACIÓN: consistencia version_id ↔ libro_id
-- ============================================================
-- Un libro (libro.id) pertenece a UNA versión (version.id), ya que
-- `libro` tiene UNIQUE(version_id, numero). Sin embargo, el FK
-- `favorito_versiculo.libro_id → libro.id` solo verifica que el id
-- exista, NO que pertenezca a la misma versión declarada en la fila.
--
-- Esto permite datos corruptos del tipo:
--   INSERT INTO favorito_versiculo (version_id=1, libro_id=42, ...)
--   donde libro.id=42 pertenece a version_id=2.
--
-- Los triggers BEFORE INSERT/UPDATE de abajo rechazan cualquier
-- escritura donde (NEW.version_id, NEW.libro_id) no sea coherente
-- con la tabla `libro`. Mensajes en español para logs de usuario.
-- ============================================================

CREATE TRIGGER IF NOT EXISTS favorito_versiculo_bi
BEFORE INSERT ON favorito_versiculo
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM libro
  WHERE libro.id = NEW.libro_id
    AND libro.version_id = NEW.version_id
)
BEGIN
  SELECT RAISE(ABORT, 'favorito_versiculo: libro_id no pertenece a version_id');
END;

CREATE TRIGGER IF NOT EXISTS favorito_versiculo_bu
BEFORE UPDATE ON favorito_versiculo
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM libro
  WHERE libro.id = NEW.libro_id
    AND libro.version_id = NEW.version_id
)
BEGIN
  SELECT RAISE(ABORT, 'favorito_versiculo: libro_id no pertenece a version_id');
END;

CREATE TRIGGER IF NOT EXISTS nota_bi
BEFORE INSERT ON nota
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM libro
  WHERE libro.id = NEW.libro_id
    AND libro.version_id = NEW.version_id
)
BEGIN
  SELECT RAISE(ABORT, 'nota: libro_id no pertenece a version_id');
END;

CREATE TRIGGER IF NOT EXISTS nota_bu
BEFORE UPDATE ON nota
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM libro
  WHERE libro.id = NEW.libro_id
    AND libro.version_id = NEW.version_id
)
BEGIN
  SELECT RAISE(ABORT, 'nota: libro_id no pertenece a version_id');
END;

-- -----------------------------------------------------------------------------
-- Tabla: historial_versiculo
-- Append-only: registra cada versículo leído. Permite calcular:
--   * "última posición" por versión (ORDER BY fecha_lectura DESC LIMIT 1)
--   * streaks de lectura
--   * versículos más leídos (GROUP BY)
-- No confundir con `favorito_versiculo`: el historial es generado por el
-- sistema, los favoritos son curados por el usuario.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS historial_versiculo (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  version_id    INTEGER NOT NULL,
  libro_id      INTEGER NOT NULL,
  capitulo      INTEGER NOT NULL CHECK(capitulo > 0),
  numero        INTEGER NOT NULL CHECK(numero > 0),
  fecha_lectura INTEGER NOT NULL,  -- unix timestamp
  FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
  FOREIGN KEY (libro_id)   REFERENCES libro(id)   ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_historial_fecha    ON historial_versiculo(fecha_lectura DESC);
CREATE INDEX IF NOT EXISTS idx_historial_lookup   ON historial_versiculo(version_id, libro_id, capitulo, numero);

-- -----------------------------------------------------------------------------
-- Tabla: config (key-value store dentro del mismo SQLite)
-- Usada para preferencias simples que NO justifican SharedPreferences:
--   * Modo emisor (acordes / letra)
--   * Versión por defecto al abrir Biblia
--   * Tamaño de fuente del lector
-- Vivir en SQLite (mismo motor) simplifica backups, export/import y tests.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS config (
  clave              TEXT PRIMARY KEY,
  valor              TEXT NOT NULL,
  fecha_modificacion INTEGER NOT NULL
);

-- -----------------------------------------------------------------------------
-- Tabla: schema_version
-- Bitácora de migraciones aplicadas. sqflite expone `getVersion()` que se
-- puede mapear a esta tabla para auditoría. El "version" en la tabla es el
-- número de migración (1, 2, 3...), no la versión del schema_version.json.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schema_version (
  version         INTEGER PRIMARY KEY,
  descripcion     TEXT    NOT NULL,
  fecha_aplicacion INTEGER NOT NULL
);

-- -----------------------------------------------------------------------------
-- Registro inicial de la migración 001
-- -----------------------------------------------------------------------------
INSERT OR IGNORE INTO schema_version (version, descripcion, fecha_aplicacion)
VALUES (1, 'Esquema inicial: 6 tablas + FTS5 + config + schema_version', strftime('%s', 'now'));
