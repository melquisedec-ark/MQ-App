/// Segmento inmutable de texto ChordPro para renderizado con Wrap.
///
/// [chord] es el acorde sin corchetes, o null.
/// [text] es la letra asociada (puede ser vacía).
/// [isLineBreak] marca salto de línea poético preservado.
///
/// functional-style: clase sellada inmutable sin métodos mutantes.
class ChordSegment {
  final String? chord;
  final String text;
  final bool isLineBreak;

  const ChordSegment({
    this.chord,
    required this.text,
    this.isLineBreak = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordSegment &&
          chord == other.chord &&
          text == other.text &&
          isLineBreak == other.isLineBreak;

  @override
  int get hashCode => Object.hash(chord, text, isLineBreak);

  @override
  String toString() => isLineBreak
      ? 'ChordSegment(⏎)'
      : 'ChordSegment(${chord != null ? "[$chord]" : ""}$text)';
}
