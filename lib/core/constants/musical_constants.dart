/// Constantes musicales utilizadas para la transposición de acordes.
///
/// Círculo cromático completo con 12 notas (escala temperada).
/// Se usa para desplazar los acordes en el sistema de transposición.
class MusicalConstants {
  MusicalConstants._();

  /// Arreglo circular de notas en orden cromático ascendente.
  /// Cada nota representa un semitono.
  static const List<String> chromaticScale = [
    'C', // 0
    'C#', // 1
    'D', // 2
    'D#', // 3
    'E', // 4
    'F', // 5
    'F#', // 6
    'G', // 7
    'G#', // 8
    'A', // 9
    'A#', // 10
    'B', // 11
  ];

  /// Notas equivalentes en notación bemol (para mostrar al usuario)
  static const Map<String, String> sharpToFlat = {
    'C#': 'Db',
    'D#': 'Eb',
    'F#': 'Gb',
    'G#': 'Ab',
    'A#': 'Bb',
  };

  /// Número máximo de semitonos para transposición permitida
  static const int maxTranspositionSemitones = 6;

  /// Número mínimo de semitonos para transposición permitida
  static const int minTranspositionSemitones = -6;

  /// Acordes mayores para validación
  static const List<String> majorChords = [
    'C',
    'C#',
    'Db',
    'D',
    'D#',
    'Eb',
    'E',
    'F',
    'F#',
    'Gb',
    'G',
    'G#',
    'Ab',
    'A',
    'A#',
    'Bb',
    'B',
  ];

  /// Prefijos de acordes (menores, séptima, etc.)
  static const List<String> chordSuffixes = [
    '',
    'm',
    '7',
    'm7',
    'Maj7',
    'maj7',
    'dim',
    'dim7',
    'aug',
    'sus',
    'sus2',
    'sus4',
    'add9',
    '9',
    '11',
    '13',
    '6',
    'm6',
    '7sus4',
    '7b5',
    '7#5',
    'm7b5',
    '°',
    'ø',
  ];
}
