-- =============================================================================
-- 003_biblia_seed_rv1569_stub.sql
-- =============================================================================
-- STUB: Este archivo SOLO registra la versión RV1569 (la "Biblia del Oso").
-- Los versículos se insertarán en FASE 2 mediante el script:
--   assets/db/tools/build_biblia_db.dart
--
-- Fuente de datos (dominio público):
--   https://es.wikisource.org/wiki/Biblia_del_Oso
--
-- Notas históricas (útiles para la UI y para el campo `descripcion`):
--   * La "Biblia del Oso" es la primera traducción completa de la Biblia al
--     español, realizada por Casiodoro de Reina (1569) y revisada por Cipriano
--     de Valera (1602). Es la base de TODAS las Reinas Valeras posteriores.
--   * Está en dominio público en todo el mundo (450+ años de antigüedad).
--   * Contiene arcaísmos (ej. "Jehová" en lugar de "Yahvé", "absolutas
--     eternidades", "predestinó", etc.) que se preservan en este módulo
--     histórico.
-- =============================================================================

INSERT OR IGNORE INTO version (
  nombre, abreviatura, idioma, descripcion, anio_publicacion,
  es_dominio_publico, activa
) VALUES (
  'Reina Valera 1569',
  'RVR1569',
  'es',
  'Biblia del Oso de Casiodoro de Reina (1569). Primera traducción completa
de la Biblia al español. Dominio público mundial. Conserva arcaísmos del
español del siglo XVI.',
  1569,
  1,  -- es_dominio_publico
  1   -- activa
);

-- TODO(Fase 2): Insertar 66 libros, ~1 189 capítulos y ~31 102 versículos
--               a partir del texto scrapeado/parseado de Wikisource.
