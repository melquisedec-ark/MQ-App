import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/utils/chord_transposer.dart';

void main() {
  group('ChordTransposer - transposeChordPro', () {
    // ====================================================================
    // 1. Transposición de notas naturales (+1 semitono)
    // ====================================================================
    group('1. Notas naturales (+1 semitono)', () {
      test('C → C#', () {
        expect(transposeChordPro('[C]', 1), '[C#]');
      });

      test('D → D#', () {
        expect(transposeChordPro('[D]', 1), '[D#]');
      });

      test('E → F', () {
        expect(transposeChordPro('[E]', 1), '[F]');
      });

      test('G → G#', () {
        expect(transposeChordPro('[G]', 1), '[G#]');
      });

      test('A → A#', () {
        expect(transposeChordPro('[A]', 1), '[A#]');
      });

      test('B → C', () {
        expect(transposeChordPro('[B]', 1), '[C]');
      });
    });

    // ====================================================================
    // 2. Transposición de notas con sostenido (+1 semitono)
    // ====================================================================
    group('2. Notas con sostenido (+1 semitono)', () {
      test('C# → D', () {
        expect(transposeChordPro('[C#]', 1), '[D]');
      });

      test('D# → E', () {
        expect(transposeChordPro('[D#]', 1), '[E]');
      });

      test('F# → G', () {
        expect(transposeChordPro('[F#]', 1), '[G]');
      });

      test('G# → A', () {
        expect(transposeChordPro('[G#]', 1), '[A]');
      });

      test('A# → B', () {
        expect(transposeChordPro('[A#]', 1), '[B]');
      });
    });

    // ====================================================================
    // 3. Acordes menores
    // ====================================================================
    group('3. Acordes menores (+1 semitono)', () {
      test('Am → A#m', () {
        expect(transposeChordPro('[Am]', 1), '[A#m]');
      });

      test('Dm → D#m', () {
        expect(transposeChordPro('[Dm]', 1), '[D#m]');
      });

      test('Em → Fm', () {
        expect(transposeChordPro('[Em]', 1), '[Fm]');
      });
    });

    // ====================================================================
    // 4. Acordes con séptima
    // ====================================================================
    group('4. Acordes con séptima (+1 semitono)', () {
      test('G7 → G#7', () {
        expect(transposeChordPro('[G7]', 1), '[G#7]');
      });

      test('Cmaj7 → C#maj7', () {
        expect(transposeChordPro('[Cmaj7]', 1), '[C#maj7]');
      });

      test('Dm7 → D#m7', () {
        expect(transposeChordPro('[Dm7]', 1), '[D#m7]');
      });
    });

    // ====================================================================
    // 5. Acordes suspendidos
    // ====================================================================
    group('5. Acordes suspendidos (+1 semitono)', () {
      test('Csus4 → C#sus4', () {
        expect(transposeChordPro('[Csus4]', 1), '[C#sus4]');
      });

      test('Dsus2 → D#sus2', () {
        expect(transposeChordPro('[Dsus2]', 1), '[D#sus2]');
      });
    });

    // ====================================================================
    // 6. Acordes disminuidos y aumentados
    // ====================================================================
    group('6. Acordes disminuidos y aumentados (+1 semitono)', () {
      test('Bdim → Cdim', () {
        expect(transposeChordPro('[Bdim]', 1), '[Cdim]');
      });

      test('Caug → C#aug', () {
        expect(transposeChordPro('[Caug]', 1), '[C#aug]');
      });
    });

    // ====================================================================
    // 7. Acordes con bajo
    // ====================================================================
    group('7. Acordes con bajo (+1 semitono)', () {
      test('G/B → G#/C', () {
        expect(transposeChordPro('[G/B]', 1), '[G#/C]');
      });

      test('Am/C → A#m/C#', () {
        expect(transposeChordPro('[Am/C]', 1), '[A#m/C#]');
      });
    });

    // ====================================================================
    // 8. Líneas sin acordes
    // ====================================================================
    group('8. Líneas sin acordes', () {
      test('Texto plano permanece igual', () {
        const text = 'Esto es una línea sin acordes';
        expect(transposeChordPro(text, 1), text);
      });

      test('Texto con números y símbolos', () {
        const text = 'Verso 1: ¡Cantad al Señor!';
        expect(transposeChordPro(text, 1), text);
      });

      test('Texto multilínea sin acordes', () {
        const text = 'Línea uno\nLínea dos\nLínea tres';
        expect(transposeChordPro(text, 3), text);
      });
    });

    // ====================================================================
    // 9. Líneas mixtas (texto + acordes)
    // ====================================================================
    group('9. Líneas mixtas', () {
      test('Texto con acordes intercalados', () {
        const input = '[G]Dios es [C]amor';
        expect(transposeChordPro(input, 1), '[G#]Dios es [C#]amor');
      });

      test('Múltiples acordes sin texto entre ellos', () {
        const input = '[Am][G][F]';
        expect(transposeChordPro(input, 1), '[A#m][G#][F#]');
      });

      test('Acordes al inicio y final de línea', () {
        const input = '[C]Alabado sea el Señor[C]';
        expect(transposeChordPro(input, 2), '[D]Alabado sea el Señor[D]');
      });
    });

    // ====================================================================
    // 10. Transposición 0 (sin cambio)
    // ====================================================================
    group('10. Transposición 0', () {
      test('Nota natural sin cambio', () {
        expect(transposeChordPro('[C]', 0), '[C]');
      });

      test('Acorde menor sin cambio', () {
        expect(transposeChordPro('[Am7]', 0), '[Am7]');
      });

      test('Acorde con bajo sin cambio', () {
        expect(transposeChordPro('[G/B]', 0), '[G/B]');
      });

      test('Texto mixto sin cambio', () {
        const input = '[G]Dios es [C]amor';
        expect(transposeChordPro(input, 0), input);
      });
    });

    // ====================================================================
    // 11. Límites de transposición
    // ====================================================================
    group('11. Límites (+6 y -6 semitonos)', () {
      test('C +6 = F#', () {
        expect(transposeChordPro('[C]', 6), '[F#]');
      });

      test('C -6 = F#', () {
        expect(transposeChordPro('[C]', -6), '[F#]');
      });

      test('G +6 = C#', () {
        expect(transposeChordPro('[G]', 6), '[C#]');
      });

      test('G -6 = C#', () {
        expect(transposeChordPro('[G]', -6), '[C#]');
      });

      test('Am +6 = D#m', () {
        expect(transposeChordPro('[Am]', 6), '[D#m]');
      });

      test('Am -6 = D#m', () {
        expect(transposeChordPro('[Am]', -6), '[D#m]');
      });

      test('Bdim +6 = Fdim', () {
        expect(transposeChordPro('[Bdim]', 6), '[Fdim]');
      });

      test('C# +6 = G', () {
        expect(transposeChordPro('[C#]', 6), '[G]');
      });
    });

    // ====================================================================
    // 12. Caracteres especiales y casos borde
    // ====================================================================
    group('12. Caracteres especiales y casos borde', () {
      test('Contenido vacío retorna vacío', () {
        expect(transposeChordPro('', 5), '');
      });

      test('Solo corchetes vacíos no se modifican', () {
        expect(transposeChordPro('[]', 1), '[]');
      });

      test('Corchetes sin acorde válido no se modifican', () {
        expect(transposeChordPro('[H]', 1), '[H]');
      });

      test('Puntuación alrededor de acordes', () {
        const input = '¡[C]anto al Señor!';
        expect(transposeChordPro(input, 1), '¡[C#]anto al Señor!');
      });

      test('Múltiples espacios entre acordes', () {
        const input = '[C]    [G]';
        expect(transposeChordPro(input, 1), '[C#]    [G#]');
      });

      test('Notas con bemol se normalizan a sostenido', () {
        expect(transposeChordPro('[Db]', 1), '[D]');
      });

      test('Eb transpuesto +1 = E', () {
        expect(transposeChordPro('[Eb]', 1), '[E]');
      });

      test('Bb transpuesto +1 = B', () {
        expect(transposeChordPro('[Bb]', 1), '[B]');
      });

      test('Acorde con flat en el bajo', () {
        expect(transposeChordPro('[C/Bb]', 1), '[C#/B]');
      });
    });
  });
}
