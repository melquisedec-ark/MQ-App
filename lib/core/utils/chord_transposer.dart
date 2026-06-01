import '../chords/chord_parser.dart';
import '../constants/musical_constants.dart';

/// Transpone acordes en contenido ChordPro.
///
/// [content] - texto con formato ChordPro (ej: "[G]Dios es [C]amor")
/// [semitones] - número de semitonos a mover (positivo = subir, negativo = bajar)
///
/// Retorna el contenido con acordes transpuestos.
String transposeChordPro(String content, int semitones) {
  if (semitones == 0) return content;

  return content.replaceAllMapped(chordRegex, (match) {
    final chord = match.group(1)!;
    final transposed = _transposeChord(chord, semitones);
    return '[$transposed]';
  });
}

/// Transpone una nota individual aplicando el sufijo del acorde.
///
/// [chord] - raíz del acorde con posible sufijo (ej: "Am7", "G", "C#m")
/// También maneja acordes con bajo como "G/B" o "Am/C", transponiendo
/// tanto la raíz como la nota del bajo.
/// [semitones] - semitonos a mover
String _transposeChord(String chord, int semitones) {
  // Extraer raíz (primera letra mayúscula + posible # o b)
  final rootMatch = RegExp(r'^([A-G][#b]?)').firstMatch(chord);
  if (rootMatch == null) return chord;

  final root = rootMatch.group(1)!;
  String rest = chord.substring(root.length);

  // Detectar y extraer nota del bajo (ej: "/B", "/C#", "/Bb")
  String? bassNote;
  final bassMatch = RegExp(r'/([A-G][#b]?)$').firstMatch(rest);
  if (bassMatch != null) {
    bassNote = bassMatch.group(1)!;
    rest = rest.substring(0, rest.length - bassMatch.group(0)!.length);
  }

  // Transponer raíz
  final transposedRoot = _transposeRoot(root, semitones);
  String result = '$transposedRoot$rest';

  // Transponer bajo si existe
  if (bassNote != null) {
    final transposedBass = _transposeRoot(bassNote, semitones);
    result = '$result/$transposedBass';
  }

  return result;
}

/// Transpone la raíz del acorde en la escala cromática.
String _transposeRoot(String root, int semitones) {
  // Normalizar bemoles a sostenidos para búsqueda
  final normalizedRoot = _normalizeToSharp(root);
  final index = MusicalConstants.chromaticScale.indexOf(normalizedRoot);
  if (index == -1) return root;

  // Calcular nuevo índice con wrapping (escala circular)
  final newIndex = (index + semitones) % 12;
  final adjustedIndex = newIndex < 0 ? newIndex + 12 : newIndex;

  return MusicalConstants.chromaticScale[adjustedIndex];
}

/// Normaliza bemoles a sostenidos equivalentes.
String _normalizeToSharp(String root) {
  const flatToSharp = {
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };
  return flatToSharp[root] ?? root;
}
