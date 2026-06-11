import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/dev/cross_refs_parser.dart';

void main() {
  group('lookupScrollmapperBookId', () {
    test('resuelve las 66 abreviaturas a libro_id 1-66', () {
      // Cada libro canónico debe resolverse a su id (1-66) sin colisiones.
      final resolved = <int, String>{};
      for (final entry in kScrollmapperToMappBookId.entries) {
        expect(lookupScrollmapperBookId(entry.key), entry.value,
            reason: '${entry.key} debe mapear a ${entry.value}',);
        resolved[entry.value] = entry.key;
      }
      expect(resolved.length, 66, reason: 'Debe haber 66 entradas únicas');
    });

    test('devuelve null para abreviatura desconocida (Tob apócrifo)', () {
      expect(lookupScrollmapperBookId('Tob'), isNull);
    });

    test('devuelve null para typo / cadena vacía', () {
      expect(lookupScrollmapperBookId(''), isNull);
      expect(lookupScrollmapperBookId('Genesis'), isNull); // english largo
      expect(lookupScrollmapperBookId('GEN'), isNull); // case-sensitive
    });

    test('libro_id=1 = Génesis; libro_id=66 = Apocalipsis', () {
      expect(lookupScrollmapperBookId('Gen'), 1);
      expect(lookupScrollmapperBookId('Rev'), 66);
    });
  });

  group('parseRefLine', () {
    test('parsea versículo único destino (Gen.1.1 → Gen.1.2)', () {
      final r = parseRefLine('Gen.1.1', 'Gen.1.2', '1');
      expect(r, isNotNull);
      expect(r!.fromLibroId, 1);
      expect(r.fromCapitulo, 1);
      expect(r.fromVersiculo, 1);
      expect(r.toLibroId, 1);
      expect(r.toCapitulo, 1);
      expect(r.toVersiculoInicio, 2);
      expect(r.toVersiculoFin, 2);
      expect(r.votos, 1);
    });

    test('parsea rango destino (1John.4.9 → 1John.4.9-10)', () {
      final r = parseRefLine('1John.4.9', '1John.4.9-10', '3');
      expect(r, isNotNull);
      expect(r!.fromLibroId, 62); // 1 Juan canónico
      expect(r.toVersiculoInicio, 9);
      expect(r.toVersiculoFin, 10);
      expect(r.votos, 3);
    });

    test('parsea cross-libro (John.3.16 → Gen.22.12, 5 votos)', () {
      final r = parseRefLine('John.3.16', 'Gen.22.12', '5');
      expect(r, isNotNull);
      expect(r!.fromLibroId, 43); // John
      expect(r.fromCapitulo, 3);
      expect(r.fromVersiculo, 16);
      expect(r.toLibroId, 1); // Gen
      expect(r.toCapitulo, 22);
      expect(r.toVersiculoInicio, 12);
      expect(r.toVersiculoFin, 12);
      expect(r.votos, 5);
    });

    test('skip si bookAbbr origen no está en el mapeo (apócrifo)', () {
      // Tobit es deuterocanónico, no está en MQ-App.
      final r = parseRefLine('Tob.1.1', 'Tob.1.2', '1');
      expect(r, isNull);
    });

    test('skip si bookAbbr destino no está en el mapeo', () {
      final r = parseRefLine('Gen.1.1', 'Tob.1.2', '1');
      expect(r, isNull);
    });

    test('skip si el rango destino es inválido (verseEnd < verseStart)', () {
      // El parseo defensivo: si el dataset tiene un typo como "Gen.1.5-3"
      // (5 al 3), el parser lo deja pasar pero parseRefLine lo descarta.
      // NOTA: el parser interno interpreta "5-3" como versículo 5 (start
      // parsea, end falla → fallback a start). Para forzar el descarte,
      // pasamos un rango explícitamente inválido con formato no-estándar.
      // Probamos con un caso que sí genera verseEnd < verseStart:
      // Si el input es "Gen.1.10-5", _parseVerseOrRange da verseEnd=5
      // (porque el fallback aplica), lo cual NO es inválido para el
      // check del parser. Por lo tanto, este caso actualmente NO se skipea.
      // Documentamos el comportamiento real:
      final r = parseRefLine('Gen.1.1', 'Gen.1.10-5', '1');
      // Comportamiento: el rango "10-5" se interpreta como start=10,
      // end=5 (fallback en int.tryParse falla, usa start=10). Pero como
      // 5 < 10, parseRefLine lo descarta por el check `to.verseEnd <
      // to.verseStart` → true → devuelve null.
      expect(r, isNull,
          reason: 'El check to.verseEnd < to.verseStart filtra este caso',);
    });

    test('skip si votos no es un entero', () {
      final r = parseRefLine('Gen.1.1', 'Gen.1.2', 'notanumber');
      expect(r, isNull);
    });

    test('skip si votos <= 0', () {
      expect(parseRefLine('Gen.1.1', 'Gen.1.2', '0'), isNull);
      expect(parseRefLine('Gen.1.1', 'Gen.1.2', '-5'), isNull);
    });

    test('skip si el formato de origen no es parseable (sin puntos)', () {
      expect(parseRefLine('Gen11', 'Gen.1.2', '1'), isNull);
    });

    test('skip si el capítulo no es entero', () {
      expect(parseRefLine('Gen.X.1', 'Gen.1.2', '1'), isNull);
    });

    test('skip si el versículo no es entero', () {
      expect(parseRefLine('Gen.1.X', 'Gen.1.2', '1'), isNull);
    });

    test('tolera espacios extra en los argumentos (trim interno)', () {
      // El parser hace `raw.trim()` antes de split.
      final r = parseRefLine(' Gen.1.1 ', ' Gen.1.2 ', ' 1 ');
      expect(r, isNotNull);
      expect(r!.fromLibroId, 1);
      expect(r.toLibroId, 1);
    });

    test('origen con rango no es válido (openbible solo usa versículo único)',
        () {
      final r = parseRefLine('Gen.1.1-2', 'Gen.1.3', '1');
      expect(r, isNull,
          reason: 'El from debe ser versículo único (no rango)',);
    });
  });
}
