/// Modelo de datos inmutable que representa un segmento de línea con acorde.
///
/// Cada segmento contiene un [chord] opcional (el acorde en formato ChordPro,
/// sin corchetes) y el [text] que le sigue. Cuando [chord] es `null`, el
/// segmento es solo texto sin acorde asociado.
///
/// Ejemplo:
/// ```dart
/// ChordLine(chord: 'C', text: 'Santo ')  // "[C]Santo "
/// ChordLine(chord: null, text: 'Santo ')  // "Santo " (sin acorde)
/// ```
class ChordLine {
  /// El acorde (sin corchetes), o `null` si el segmento no tiene acorde.
  final String? chord;

  /// El texto que sigue al acorde (puede ser vacío).
  final String text;

  const ChordLine({this.chord, required this.text});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordLine && chord == other.chord && text == other.text;

  @override
  int get hashCode => Object.hash(chord, text);

  @override
  String toString() => 'ChordLine(${chord != null ? "[$chord]" : ""}$text)';
}
