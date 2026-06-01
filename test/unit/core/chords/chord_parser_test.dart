import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/chords/chord_line.dart';
import 'package:himnario_id_2/core/chords/chord_parser.dart';
import 'package:himnario_id_2/core/chords/chord_segment.dart';

void main() {
  group('ChordParser - parseChordProLine', () {
    test('línea vacía retorna segmento vacío', () {
      final result = parseChordProLine('');
      expect(result, [const ChordLine(text: '')]);
    });

    test('línea sin acordes retorna un solo segmento', () {
      const text = 'Santo Dios';
      final result = parseChordProLine(text);
      expect(result, [ChordLine(chord: null, text: text)]);
    });

    test('texto sin acordes con múltiples palabras', () {
      const text = 'Esto es una línea sin acordes';
      final result = parseChordProLine(text);
      expect(result, [ChordLine(chord: null, text: text)]);
    });

    test('[C]Santo [G]Dios → 2 segmentos', () {
      final result = parseChordProLine('[C]Santo [G]Dios');
      expect(result.length, 2);
      expect(result[0], ChordLine(chord: 'C', text: 'Santo '));
      expect(result[1], ChordLine(chord: 'G', text: 'Dios'));
    });

    test('[C]Santo [G] → último segmento con texto vacío', () {
      final result = parseChordProLine('[C]Santo [G]');
      expect(result.length, 2);
      expect(result[0], ChordLine(chord: 'C', text: 'Santo '));
      expect(result[1], ChordLine(chord: 'G', text: ''));
    });

    test('[C]Santo → un solo segmento con acorde', () {
      final result = parseChordProLine('[C]Santo');
      expect(result.length, 1);
      expect(result[0], ChordLine(chord: 'C', text: 'Santo'));
    });

    test('[Am][G][F] → múltiples acordes adyacentes', () {
      final result = parseChordProLine('[Am][G][F]');
      expect(result.length, 3);
      expect(result[0], ChordLine(chord: 'Am', text: ''));
      expect(result[1], ChordLine(chord: 'G', text: ''));
      expect(result[2], ChordLine(chord: 'F', text: ''));
    });

    test('texto antes del primer acorde', () {
      final result = parseChordProLine('Intro [C]Santo');
      expect(result.length, 2);
      expect(result[0], ChordLine(text: 'Intro '));
      expect(result[1], ChordLine(chord: 'C', text: 'Santo'));
    });

    test('acorde con bajo G/B', () {
      final result = parseChordProLine('[G/B]Santo');
      expect(result.length, 1);
      expect(result[0], ChordLine(chord: 'G/B', text: 'Santo'));
    });

    test('acorde menor Am', () {
      final result = parseChordProLine('[Am]Santo');
      expect(result.length, 1);
      expect(result[0], ChordLine(chord: 'Am', text: 'Santo'));
    });

    test('acorde con séptima G7', () {
      final result = parseChordProLine('[G7]Santo');
      expect(result.length, 1);
      expect(result[0], ChordLine(chord: 'G7', text: 'Santo'));
    });
  });

  group('ChordParser - stripChords', () {
    test('elimina acordes de texto', () {
      expect(stripChords('[G]Dios es [C]amor'), 'Dios es amor');
    });

    test('texto sin acordes no se modifica', () {
      expect(stripChords('Dios es amor'), 'Dios es amor');
    });

    test('cadena vacía retorna vacío', () {
      expect(stripChords(''), '');
    });
  });

  group('ChordParser - chordRegex', () {
    test('captura acorde simple', () {
      final match = chordRegex.firstMatch('[G]');
      expect(match?.group(1), 'G');
    });

    test('captura acorde con sostenido', () {
      final match = chordRegex.firstMatch('[C#]');
      expect(match?.group(1), 'C#');
    });

    test('captura acorde con bemol', () {
      final match = chordRegex.firstMatch('[Bb]');
      expect(match?.group(1), 'Bb');
    });

    test('captura acorde con bajo', () {
      final match = chordRegex.firstMatch('[G/B]');
      expect(match?.group(1), 'G/B');
    });

    test('captura acorde menor con séptima', () {
      final match = chordRegex.firstMatch('[Dm7]');
      expect(match?.group(1), 'Dm7');
    });

    test('no captura corchetes vacíos', () {
      final match = chordRegex.firstMatch('[]');
      expect(match, isNull);
    });

    test('no captura acorde inválido H', () {
      final match = chordRegex.firstMatch('[H]');
      expect(match, isNull);
    });

    test('acorde con paréntesis [C#m7(b5)]', () {
      final match = chordRegex.firstMatch('[C#m7(b5)]');
      expect(match?.group(1), 'C#m7(b5)');
    });

    test('acorde con paréntesis y bajo [F#m7(b5)/B]', () {
      final match = chordRegex.firstMatch('[F#m7(b5)/B]');
      expect(match?.group(1), 'F#m7(b5)/B');
    });
  });

  group('ChordParser - parseChordProStanza', () {
    test('estrofa simple con 2 líneas', () {
      final result = parseChordProStanza('[C]Santo [G]Dios\n[Am]Señor');
      expect(result.length, 4);
      expect(result[0], const ChordSegment(chord: 'C', text: 'Santo '));
      expect(result[1], const ChordSegment(chord: 'G', text: 'Dios'));
      expect(result[2], const ChordSegment(text: '', isLineBreak: true));
      expect(result[3], const ChordSegment(chord: 'Am', text: 'Señor'));
    });

    test('texto vacío retorna lista vacía', () {
      final result = parseChordProStanza('');
      expect(result, isEmpty);
    });

    test('sin acordes multilínea', () {
      final result = parseChordProStanza('Santo\nDios');
      expect(result.length, 3);
      expect(result[0], const ChordSegment(text: 'Santo'));
      expect(result[1], const ChordSegment(text: '', isLineBreak: true));
      expect(result[2], const ChordSegment(text: 'Dios'));
    });

    test('trailing blank line ignorada — solo contenido', () {
      final result = parseChordProStanza('[C]Santo\n');
      expect(result.length, 1);
      expect(result[0], const ChordSegment(chord: 'C', text: 'Santo'));
    });

    test('múltiples trailing blank lines ignoradas — solo contenido', () {
      final result = parseChordProStanza('[C]Santo\n\n\n');
      expect(result.length, 1);
      expect(result[0], const ChordSegment(chord: 'C', text: 'Santo'));
    });

    test('leading blank line ignorada — solo contenido', () {
      final result = parseChordProStanza('\n[C]Santo');
      expect(result.length, 1);
      expect(result[0], const ChordSegment(chord: 'C', text: 'Santo'));
    });

    test('solo blanks retorna vacío', () {
      expect(parseChordProStanza('\n\n'), isEmpty);
    });

    test('triple blank line entre estrofas colapsa a doble', () {
      final result = parseChordProStanza('[C]Santo\n\n\n[G]Dios');
      expect(result.length, 4);
      expect(result[0], const ChordSegment(chord: 'C', text: 'Santo'));
      expect(result[1], const ChordSegment(text: '', isLineBreak: true));
      expect(result[2], const ChordSegment(text: '', isLineBreak: true));
      expect(result[3], const ChordSegment(chord: 'G', text: 'Dios'));
    });

    test('acorde con paréntesis parseChordProLine', () {
      final result = parseChordProLine('[C#m7(b5)]Santo');
      expect(result.first.chord, 'C#m7(b5)');
      expect(result.first.text, 'Santo');
    });
  });

  group('ChordSegment - modelo', () {
    test('== dos segmentos iguales', () {
      const a = ChordSegment(chord: 'C', text: 'Santo ');
      const b = ChordSegment(chord: 'C', text: 'Santo ');
      expect(a, equals(b));
    });

    test('== segmentos con chord diferente', () {
      const a = ChordSegment(chord: 'C', text: 'Santo ');
      const b = ChordSegment(chord: 'G', text: 'Santo ');
      expect(a, isNot(equals(b)));
    });

    test('== segmentos con text diferente', () {
      const a = ChordSegment(chord: 'C', text: 'Santo ');
      const b = ChordSegment(chord: 'C', text: 'Señor');
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistente con ==', () {
      const a = ChordSegment(chord: 'C', text: 'Santo ');
      const b = ChordSegment(chord: 'C', text: 'Santo ');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString línea break', () {
      const seg = ChordSegment(text: '', isLineBreak: true);
      expect(seg.toString(), 'ChordSegment(⏎)');
    });

    test('toString con acorde y texto', () {
      const seg = ChordSegment(chord: 'C', text: 'Santo ');
      expect(seg.toString(), 'ChordSegment([C]Santo )');
    });

    test('toString sin acorde ni texto', () {
      const seg = ChordSegment(text: '');
      expect(seg.toString(), 'ChordSegment()');
    });
  });

  group('ChordParser - expandToWordSegments', () {
    test('expande línea simple', () {
      final lines = parseChordProLine('[C]Santo [G]Dios');
      final result = expandToWordSegments(lines);
      expect(result.length, 2);
      expect(result[0], const ChordSegment(chord: 'C', text: 'Santo '));
      expect(result[1], const ChordSegment(chord: 'G', text: 'Dios'));
    });

    test('acorde sin texto se preserva', () {
      final lines = parseChordProLine('[C]Santo [G]');
      final result = expandToWordSegments(lines);
      expect(result.length, 2);
      expect(result[0], const ChordSegment(chord: 'C', text: 'Santo '));
      expect(result[1], const ChordSegment(chord: 'G', text: ''));
    });

    test('acordes adyacentes preservan segmentos vacíos', () {
      final lines = parseChordProLine('[Am][G][F]');
      final result = expandToWordSegments(lines);
      expect(result.length, 3);
      expect(result[0], const ChordSegment(chord: 'Am', text: ''));
      expect(result[1], const ChordSegment(chord: 'G', text: ''));
      expect(result[2], const ChordSegment(chord: 'F', text: ''));
    });

    test('texto antes del primer acorde se expande', () {
      final lines = parseChordProLine('Intro [C]Santo');
      final result = expandToWordSegments(lines);
      expect(result.length, 2);
      expect(result[0], const ChordSegment(chord: null, text: 'Intro '));
      expect(result[1], const ChordSegment(chord: 'C', text: 'Santo'));
    });

    test('línea sin acordes se expande palabra por palabra', () {
      final lines = parseChordProLine('Santo Dios es amor');
      final result = expandToWordSegments(lines);
      expect(result.length, 4);
      expect(result[0], const ChordSegment(chord: null, text: 'Santo '));
      expect(result[1], const ChordSegment(chord: null, text: 'Dios '));
      expect(result[2], const ChordSegment(chord: null, text: 'es '));
      expect(result[3], const ChordSegment(chord: null, text: 'amor'));
    });

    test('línea vacía produce segmento vacío', () {
      final lines = parseChordProLine('');
      final result = expandToWordSegments(lines);
      expect(result.length, 1);
      expect(result[0], const ChordSegment(text: ''));
    });
  });
}
