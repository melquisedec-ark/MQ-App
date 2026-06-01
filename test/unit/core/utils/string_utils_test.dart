import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/utils/string_utils.dart';

void main() {
  group('StringUtils', () {
    // ==================================================================
    // normalizeForSort
    // ==================================================================
    group('normalizeForSort', () {
      test('elimina acentos: Álgebra → Algebra', () {
        expect(StringUtils.normalizeForSort('Álgebra'), 'Algebra');
      });

      test('elimina símbolos iniciales: (Salmo 23) → Salmo 23)', () {
        expect(StringUtils.normalizeForSort('(Salmo 23)'), 'Salmo 23)');
      });

      test('elimina signos de exclamación: ¡Aleluya! → Aleluya!', () {
        expect(StringUtils.normalizeForSort('¡Aleluya!'), 'Aleluya!');
      });

      test('elimina signos de interrogación: ¿Qué? → Que?', () {
        expect(StringUtils.normalizeForSort('¿Qué?'), 'Que?');
      });

      test('conserva caracteres válidos: "Himnario" → Himnario', () {
        expect(StringUtils.normalizeForSort('Himnario'), 'Himnario');
      });

      test('texto vacío retorna vacío', () {
        expect(StringUtils.normalizeForSort(''), '');
      });
    });

    // ==================================================================
    // compareForSort
    // ==================================================================
    group('compareForSort', () {
      test('compara ignorando acentos', () {
        // "Águila" normalizado es "Aguila", que va antes que "Burro"
        expect(StringUtils.compareForSort('Águila', 'Burro'), lessThan(0));
        // "Éxodo" y "Exodo" son iguales al normalizar
        expect(StringUtils.compareForSort('Éxodo', 'Exodo'), 0);
      });

      test('compara ignorando símbolos', () {
        // "(Salmo 1" normalizado es "Salmo 1)", que es ≠ "Salmo 1"
        // porque normalizeForSort solo quita símbolos al INICIO, no al final
        expect(StringUtils.compareForSort('(Salmo 1', 'Salmo 1'), 0);
        // "¿Qué?" normalizado es "Que?", va antes que "Re"
        expect(StringUtils.compareForSort('¿Qué?', 'Re'), lessThan(0));
      });
    });

    // ==================================================================
    // normalizeForSearch
    // ==================================================================
    group('normalizeForSearch', () {
      test('elimina acentos y pasa a minúsculas', () {
        expect(StringUtils.normalizeForSearch('Éxodo'), 'exodo');
        expect(StringUtils.normalizeForSearch('Ámazing'), 'amazing');
      });

      test('elimina puntuación', () {
        expect(StringUtils.normalizeForSearch('¡Aleluya!'), 'aleluya');
        expect(StringUtils.normalizeForSearch('¿Qué tal?'), 'que tal');
        expect(
          StringUtils.normalizeForSearch('Santa Biblia (Salmo 23)'),
          'santa biblia salmo 23',
        );
      });

      test('elimina marcadores ChordPro: [G]Dios es [C]amor', () {
        // normalizeForSearch llama a stripChords() primero,
        // convirtiendo "[G]Dios es [C]amor" → "dios es amor"
        expect(
          StringUtils.normalizeForSearch('[G]Dios es [C]amor'),
          'dios es amor',
        );
      });

      test('elimina acordes con bajo: [D/F#]Cuán precioso', () {
        expect(
          StringUtils.normalizeForSearch('[D/F#]Cuán precioso es el n[E]ombre de Jesú[A]s'),
          'cuan precioso es el nombre de jesus',
        );
      });

      test('colapsa espacios múltiples', () {
        expect(
          StringUtils.normalizeForSearch('Dios   es    amor'),
          'dios es amor',
        );
      });
    });
  });
}
