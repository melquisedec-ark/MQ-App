import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/chord_transposer.dart';

/// Provider que almacena el valor actual de transposición en semitonos.
/// Rango válido: -6 a +6.
final transposeValueProvider = StateProvider<int>((ref) => 0);

/// Provider que expone el contenido ChordPro transpuesto.
///
/// Toma el contenido original y el valor de transposición actual,
/// y retorna el texto con acordes transpuestos usando [ChordTransposer].
final transposedChordsProvider =
    Provider.family<String, String>((ref, content) {
  final semitones = ref.watch(transposeValueProvider);
  if (semitones == 0) return content;
  return transposeChordPro(content, semitones);
});

/// Provider para la tonalidad actual (nota base).
final currentKeyProvider = StateProvider<String>((ref) => 'C');

/// Provider que retorna la tonalidad transpuesta según el valor actual.
final transposedKeyProvider = Provider<String>((ref) {
  final originalKey = ref.watch(currentKeyProvider);
  final semitones = ref.watch(transposeValueProvider);
  if (semitones == 0) return originalKey;

  // Transponer la nota clave usando las constantes musicales
  final index = _chromaticScale.indexOf(_normalizeToSharp(originalKey));
  if (index == -1) return originalKey;

  final newIndex = (index + semitones) % 12;
  final adjustedIndex = newIndex < 0 ? newIndex + 12 : newIndex;
  return _chromaticScale[adjustedIndex];
});

/// Escala cromática (copia local para este provider).
const List<String> _chromaticScale = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

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
