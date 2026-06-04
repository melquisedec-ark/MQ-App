-- =============================================================================
-- 004_cross_referencias.sql
-- =============================================================================
-- Migración 004: Tabla `cross_referencia` para el sistema de cross-references
-- bíblicas (Versículo X → Versículo Y, opcionalmente un rango).
--
-- Fuente de datos:
--   * Repo: https://github.com/scrollmapper/bible_databases
--   * Archivo: sources/extras/cross_references.txt
--   * Dataset: openbible.info/labs/cross-references/ (~340k referencias)
--   * Licencia datos: CC-BY 4.0 (requiere atribución al usar el dataset)
--   * Licencia código: MIT
--
-- Decisiones de diseño (resumen):
--   1. NO FK a `versiculo.id` — se permite que la referencia sea
--      "cross-versión" o apunte a un versículo aún no sembrado en
--      esta versión. Mismo patrón que `favorito_versiculo` y `nota`.
--   2. Soporte de rangos: `to_versiculo_inicio` / `to_versiculo_fin`
--      pueden ser iguales (versículo único) o diferentes (rango
--      tipo "1John.4.9-10" del dataset openbible).
--   3. Triggers BEFORE INSERT/UPDATE sobre ambas FKs (`from_libro_id`,
--      `to_libro_id`) para garantizar coherencia con `version_id`.
--      Mismo patrón que `favorito_versiculo_bi/bu` y `nota_bi/bu`.
--   4. Índices optimizados para las 2 queries principales del lector:
--        a) "refs que SALEN de un versículo" (FROM lookup)
--        b) "refs que LLEGAN a un versículo" (TO lookup, con rango)
--      El índice `idx_cross_ref_votos` soporta ORDER BY votos DESC
--      sin necesidad de re-ordenar en memoria.
--   5. `votos` (int, default 1) refleja la "fuerza" de la referencia en
--      el dataset openbible. Se usa para ordenar las refs más citadas
--      primero en la UI.
-- =============================================================================

PRAGMA foreign_keys = ON;

-- -----------------------------------------------------------------------------
-- Tabla: cross_referencia
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cross_referencia (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  version_id          INTEGER NOT NULL,
  from_libro_id       INTEGER NOT NULL,
  from_capitulo       INTEGER NOT NULL CHECK(from_capitulo > 0),
  from_versiculo      INTEGER NOT NULL CHECK(from_versiculo > 0),
  to_libro_id         INTEGER NOT NULL,
  to_capitulo         INTEGER NOT NULL CHECK(to_capitulo > 0),
  to_versiculo_inicio INTEGER NOT NULL CHECK(to_versiculo_inicio > 0),
  to_versiculo_fin    INTEGER NOT NULL CHECK(to_versiculo_fin >= to_versiculo_inicio),
  votos               INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (version_id)    REFERENCES version(id) ON DELETE CASCADE,
  FOREIGN KEY (from_libro_id) REFERENCES libro(id)   ON DELETE CASCADE,
  FOREIGN KEY (to_libro_id)   REFERENCES libro(id)   ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- Índices
-- -----------------------------------------------------------------------------
-- Lookup principal: refs que SALEN de un versículo (lo más usado en UI).
CREATE INDEX IF NOT EXISTS idx_cross_ref_from
  ON cross_referencia(version_id, from_libro_id, from_capitulo, from_versiculo);

-- Lookup secundario: refs que LLEGAN a un versículo o rango que lo contiene.
CREATE INDEX IF NOT EXISTS idx_cross_ref_to
  ON cross_referencia(version_id, to_libro_id, to_capitulo, to_versiculo_inicio);

-- Orden por relevancia (votos DESC) — soporta ORDER BY sin filesort.
CREATE INDEX IF NOT EXISTS idx_cross_ref_votos
  ON cross_referencia(version_id, votos DESC);

-- -----------------------------------------------------------------------------
-- Triggers: consistencia version_id ↔ from_libro_id / to_libro_id
-- -----------------------------------------------------------------------------
-- Sin estos triggers, el FK `FOREIGN KEY (from_libro_id) REFERENCES libro(id)`
-- solo valida que el id exista, NO que pertenezca al `version_id` declarado.
-- Esto replica el patrón de `favorito_versiculo` y `nota`.

CREATE TRIGGER IF NOT EXISTS cross_referencia_bi
BEFORE INSERT ON cross_referencia
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM libro
  WHERE libro.id = NEW.from_libro_id
    AND libro.version_id = NEW.version_id
)
BEGIN
  SELECT RAISE(ABORT, 'cross_referencia: from_libro_id no pertenece a version_id');
END;

CREATE TRIGGER IF NOT EXISTS cross_referencia_bi_to
BEFORE INSERT ON cross_referencia
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM libro
  WHERE libro.id = NEW.to_libro_id
    AND libro.version_id = NEW.version_id
)
BEGIN
  SELECT RAISE(ABORT, 'cross_referencia: to_libro_id no pertenece a version_id');
END;

CREATE TRIGGER IF NOT EXISTS cross_referencia_bu
BEFORE UPDATE ON cross_referencia
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM libro
  WHERE libro.id = NEW.from_libro_id
    AND libro.version_id = NEW.version_id
)
BEGIN
  SELECT RAISE(ABORT, 'cross_referencia: from_libro_id no pertenece a version_id');
END;

CREATE TRIGGER IF NOT EXISTS cross_referencia_bu_to
BEFORE UPDATE ON cross_referencia
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM libro
  WHERE libro.id = NEW.to_libro_id
    AND libro.version_id = NEW.version_id
)
BEGIN
  SELECT RAISE(ABORT, 'cross_referencia: to_libro_id no pertenece a version_id');
END;

-- -----------------------------------------------------------------------------
-- Registro de la migración 004
-- -----------------------------------------------------------------------------
INSERT OR IGNORE INTO schema_version (version, descripcion, fecha_aplicacion)
VALUES (
  4,
  'Cross-references bíblicas: tabla cross_referencia con 2 FKs a libro, '
  || '2 índices (FROM, TO) + 1 índice por votos, 4 triggers de validación '
  || 'version_id ↔ libro_id. Seed: ~340k refs de openbible.info (CC-BY 4.0).',
  strftime('%s', 'now')
);
