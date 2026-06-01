import '../../../core/errors/failures.dart';
import '../../../core/utils/chord_transposer.dart';

/// Caso de uso para transposición de acordes en contenido ChordPro.
///
/// Envuelve la función pura [transposeChordPro] del utils layer
/// con validaciones de dominio.
class TransposeChordsUseCase {
  /// Transpone los acordes en el contenido ChordPro.
  ///
  /// [content] - texto en formato ChordPro (ej: "[G]Dios es [C]amor")
  /// [semitones] - número de semitonos a mover (rango: -6 a +6)
  ///
  /// Retorna el contenido transpuesto.
  /// Lanza [InvalidArgumentFailure] si los semitonos están fuera de rango.
  String execute(String content, int semitones) {
    if (semitones < -6 || semitones > 6) {
      throw const InvalidArgumentFailure(
        'La transposición debe estar entre -6 y +6 semitonos',
      );
    }

    if (content.isEmpty) return content;

    return transposeChordPro(content, semitones);
  }
}
