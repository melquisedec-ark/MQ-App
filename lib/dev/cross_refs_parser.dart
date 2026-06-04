// =============================================================================
// cross_refs_parser.dart
// =============================================================================
// Librería pura (sin side effects, sin `main()`) que parsea el dataset
// openbible de cross-references a objetos `ParsedRef`.
//
// Usado por:
//   * assets/db/tools/generate_cross_references_seed.dart  (script CLI)
//   * test/assets/db/tools/generate_cross_references_seed_test.dart
//
// Diseño:
//   * Top-level constants y funciones, sin estado mutable.
//   * Sin imports de dart:io ni dart:ffi — es 100% puro Dart testeable
//     en isolate sin bootstrapping de FFI.
// =============================================================================

/// Mapeo de abreviaturas del dataset scrollmapper/openbible a `libro_id`
/// de MQ-App (1-66).
///
/// 66 entradas (todos los libros canónicos protestantes). Las
/// abreviaturas que NO aparezcan se interpretarán como libros
/// apócrifos/typos y se omitirán silenciosamente.
const Map<String, int> kScrollmapperToMappBookId = {
  // Antiguo Testamento (1-39)
  'Gen': 1,
  'Exod': 2,
  'Lev': 3,
  'Num': 4,
  'Deut': 5,
  'Josh': 6,
  'Judg': 7,
  'Ruth': 8,
  '1Sam': 9,
  '2Sam': 10,
  '1Kgs': 11,
  '2Kgs': 12,
  '1Chr': 13,
  '2Chr': 14,
  'Ezra': 15,
  'Neh': 16,
  'Esth': 17,
  'Job': 18,
  'Ps': 19,
  'Prov': 20,
  'Eccl': 21,
  'Song': 22,
  'Isa': 23,
  'Jer': 24,
  'Lam': 25,
  'Ezek': 26,
  'Dan': 27,
  'Hos': 28,
  'Joel': 29,
  'Amos': 30,
  'Obad': 31,
  'Jonah': 32,
  'Mic': 33,
  'Nah': 34,
  'Hab': 35,
  'Zeph': 36,
  'Hag': 37,
  'Zech': 38,
  'Mal': 39,
  // Nuevo Testamento (40-66)
  'Matt': 40,
  'Mark': 41,
  'Luke': 42,
  'John': 43,
  'Acts': 44,
  'Rom': 45,
  '1Cor': 46,
  '2Cor': 47,
  'Gal': 48,
  'Eph': 49,
  'Phil': 50,
  'Col': 51,
  '1Thess': 52,
  '2Thess': 53,
  '1Tim': 54,
  '2Tim': 55,
  'Titus': 56,
  'Phlm': 57,
  'Heb': 58,
  'Jas': 59,
  '1Pet': 60,
  '2Pet': 61,
  '1John': 62,
  '2John': 63,
  '3John': 64,
  'Jude': 65,
  'Rev': 66,
};

/// Resuelve una abreviatura del dataset scrollmapper al `libro_id`
/// canónico de MQ-App. Devuelve `null` si no está en el mapa.
int? lookupScrollmapperBookId(String abbr) =>
    kScrollmapperToMappBookId[abbr];

/// Versículo (o rango de versículos) ya parseado.
class ParsedRef {
  final int fromLibroId;
  final int fromCapitulo;
  final int fromVersiculo;
  final int toLibroId;
  final int toCapitulo;
  final int toVersiculoInicio;
  final int toVersiculoFin;
  final int votos;

  const ParsedRef({
    required this.fromLibroId,
    required this.fromCapitulo,
    required this.fromVersiculo,
    required this.toLibroId,
    required this.toCapitulo,
    required this.toVersiculoInicio,
    required this.toVersiculoFin,
    required this.votos,
  });
}

/// Parsea una línea del dataset openbible.
///
/// Argumentos: las 3 columnas separadas por tab (fromRaw, toRaw, votesRaw).
///
/// Devuelve `null` si:
///   * El bookAbbr no está en el mapeo (libro apócrifo/typo).
///   * El formato no es parseable (capítulo o versículo no es int).
///   * El rango destino es inválido (`verseEnd < verseStart`).
///   * El origen no es un versículo único (debería no pasar en openbible,
///     pero defendámonos).
///   * Los votos son <= 0 o no parseables.
ParsedRef? parseRefLine(String fromRaw, String toRaw, String votesRaw) {
  final from = _parseVerseOrRange(fromRaw);
  if (from == null) return null;
  final to = _parseVerseOrRange(toRaw);
  if (to == null) return null;
  final fromLibro = lookupScrollmapperBookId(from.bookAbbr);
  if (fromLibro == null) return null;
  final toLibro = lookupScrollmapperBookId(to.bookAbbr);
  if (toLibro == null) return null;
  // from siempre es versículo único en openbible.
  if (from.verseEnd != from.verseStart) {
    return null;
  }
  if (to.verseEnd < to.verseStart) return null;
  final votos = int.tryParse(votesRaw.trim());
  if (votos == null || votos < 1) return null;
  return ParsedRef(
    fromLibroId: fromLibro,
    fromCapitulo: from.chapter,
    fromVersiculo: from.verseStart,
    toLibroId: toLibro,
    toCapitulo: to.chapter,
    toVersiculoInicio: to.verseStart,
    toVersiculoFin: to.verseEnd,
    votos: votos,
  );
}

class VerseParts {
  final String bookAbbr;
  final int chapter;
  final int verseStart;
  final int verseEnd;
  const VerseParts(this.bookAbbr, this.chapter, this.verseStart, this.verseEnd);
}

/// Parsea "Gen.1.1" → (Gen, 1, 1, 1) o "1John.4.9-10" → (1John, 4, 9, 10).
///
/// Devuelve `null` si el formato es inválido.
VerseParts? _parseVerseOrRange(String raw) {
  final parts = raw.trim().split('.');
  if (parts.length < 3) return null;
  final bookAbbr = parts[0];
  if (bookAbbr.isEmpty) return null;
  final chapter = int.tryParse(parts[1]);
  if (chapter == null) return null;
  final verseRaw = parts[2];
  if (verseRaw.isEmpty) return null;
  // Puede tener más puntos? El dataset openbile no, pero defendámonos.
  final verseParts = verseRaw.split('-');
  if (verseParts.isEmpty || verseParts.length > 2) return null;
  final verseStart = int.tryParse(verseParts[0]);
  if (verseStart == null) return null;
  final verseEnd = verseParts.length == 2
      ? (int.tryParse(verseParts[1]) ?? verseStart)
      : verseStart;
  return VerseParts(bookAbbr, chapter, verseStart, verseEnd);
}
