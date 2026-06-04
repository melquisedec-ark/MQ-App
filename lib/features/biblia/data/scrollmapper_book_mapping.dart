// =============================================================================
// scrollmapper_book_mapping.dart
// =============================================================================
// Mapeo de abreviaturas de libros en el dataset openbible.info (vía
// scrollmapper/bible_databases) a libro_id canónico de MQ-App (1-66).
//
// Este archivo es un **re-export** de la fuente de verdad única:
// `lib/dev/cross_refs_parser.dart`. Se conserva este wrapper por
// compatibilidad con imports que esperan la ruta
// `lib/features/biblia/data/scrollmapper_book_mapping.dart`.
//
// Dataset openbible: https://github.com/scrollmapper/bible_databases
// Formato abreviaturas: inglés estándar, ej. "Gen", "Exod", "1John", "Rev".
// Orden canónico: AT 1-39 (Génesis=1, Malaquías=39), NT 40-66
// (Mateo=40, Apocalipsis=66).
// =============================================================================

export 'package:mqapp/dev/cross_refs_parser.dart'
    show
        kScrollmapperToMappBookId,
        lookupScrollmapperBookId;
