-- =============================================================================
-- 002_biblia_seed_rv1909_stub.sql
-- =============================================================================
-- STUB: Este archivo SOLO registra la versión RV1909. Los ~31 102 versículos
-- se insertarán en FASE 2 mediante el script:
--   assets/db/tools/build_biblia_db.dart
-- que lee el repositorio fuente y genera el `biblia.db` final.
--
-- Fuente de datos (dominio público):
--   https://github.com/iglesianazaret/biblia-reina-valera-1909-base-datos-sql
--
-- Por qué no insertamos versículos aquí directamente:
--   * 31 102 filas × 2 versiones = 62 204 filas → ~30 MB de SQL plano
--   * El repositorio upstream puede cambiar; un script Dart reproducible es
--     más mantenible que un dump estático.
--   * Las foreign keys encadenadas (version → libro → capitulo → versiculo)
--     requieren transacciones que un .sql estático no puede garantizar
--     eficientemente con SQLite.
-- =============================================================================

INSERT OR IGNORE INTO version (
  nombre, abreviatura, idioma, descripcion, anio_publicacion,
  es_dominio_publico, activa
) VALUES (
  'Reina Valera 1909',
  'RVR1909',
  'es',
  'Revisión de 1909 de la Reina Valera. Basada en el texto de Cipriano de
Valera (1602) con revisiones posteriores. Dominio público en la mayoría de
jurisdicciones por antigüedad (>100 años desde publicación).',
  1909,
  1,  -- es_dominio_publico
  1   -- activa
);

-- TODO(Fase 2): Insertar 66 libros, ~1 189 capítulos y 31 102 versículos
--               a partir del dump SQL del repositorio upstream.
