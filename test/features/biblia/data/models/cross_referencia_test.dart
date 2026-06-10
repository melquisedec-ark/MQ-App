import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/cross_referencia.dart';

void main() {
  group('CrossReferencia', () {
    // Muestra base: Juan 3:16 → Génesis 22:12-14 (rango destino)
    final sampleRango = CrossReferencia(
      id: 1,
      versionId: 1,
      fromLibroId: 43,
      fromCapitulo: 3,
      fromVersiculo: 16,
      toLibroId: 1,
      toCapitulo: 22,
      toVersiculoInicio: 12,
      toVersiculoFin: 14,
      votos: 5,
    );

    // Muestra 2: versículo único destino
    final sampleUnico = CrossReferencia(
      id: 2,
      versionId: 1,
      fromLibroId: 43,
      fromCapitulo: 3,
      fromVersiculo: 16,
      toLibroId: 43,
      toCapitulo: 3,
      toVersiculoInicio: 17,
      toVersiculoFin: 17,
      votos: 2,
    );

    group('fromMap', () {
      test('construye correctamente un versículo único destino', () {
        final m = CrossReferencia.fromMap({
          'id': 2,
          'version_id': 1,
          'from_libro_id': 43,
          'from_capitulo': 3,
          'from_versiculo': 16,
          'to_libro_id': 43,
          'to_capitulo': 3,
          'to_versiculo_inicio': 17,
          'to_versiculo_fin': 17,
          'votos': 2,
        });
        expect(m, equals(sampleUnico));
      });

      test('construye correctamente un rango destino (inicio < fin)', () {
        final m = CrossReferencia.fromMap({
          'id': 1,
          'version_id': 1,
          'from_libro_id': 43,
          'from_capitulo': 3,
          'from_versiculo': 16,
          'to_libro_id': 1,
          'to_capitulo': 22,
          'to_versiculo_inicio': 12,
          'to_versiculo_fin': 14,
          'votos': 5,
        });
        expect(m, equals(sampleRango));
      });

      test('usa default 1 cuando votos es null en el map', () {
        final m = CrossReferencia.fromMap({
          'id': 3,
          'version_id': 1,
          'from_libro_id': 1,
          'from_capitulo': 1,
          'from_versiculo': 1,
          'to_libro_id': 1,
          'to_capitulo': 1,
          'to_versiculo_inicio': 2,
          'to_versiculo_fin': 2,
          'votos': null,
        });
        expect(m.votos, 1);
      });
    });

    group('toMap', () {
      test('serializa a snake_case preservando todos los campos', () {
        final map = sampleRango.toMap();
        expect(map['id'], 1);
        expect(map['version_id'], 1);
        expect(map['from_libro_id'], 43);
        expect(map['from_capitulo'], 3);
        expect(map['from_versiculo'], 16);
        expect(map['to_libro_id'], 1);
        expect(map['to_capitulo'], 22);
        expect(map['to_versiculo_inicio'], 12);
        expect(map['to_versiculo_fin'], 14);
        expect(map['votos'], 5);
      });

      test('roundtrip fromMap(toMap(x)) preserva los datos (rango)', () {
        final map = sampleRango.toMap();
        final restored = CrossReferencia.fromMap(map);
        expect(restored, equals(sampleRango));
      });

      test('roundtrip fromMap(toMap(x)) preserva los datos (versículo único)',
          () {
        final map = sampleUnico.toMap();
        final restored = CrossReferencia.fromMap(map);
        expect(restored, equals(sampleUnico));
      });
    });

    group('esRango', () {
      test('devuelve true si toVersiculoInicio != toVersiculoFin', () {
        expect(sampleRango.esRango, isTrue);
      });

      test('devuelve false si toVersiculoInicio == toVersiculoFin', () {
        expect(sampleUnico.esRango, isFalse);
      });
    });

    group('copyWith', () {
      test('reemplaza solo votos (único campo modificable)', () {
        final c = sampleRango.copyWith(votos: 10);
        expect(c.votos, 10);
        // Todos los demás campos idénticos
        expect(c.id, sampleRango.id);
        expect(c.versionId, sampleRango.versionId);
        expect(c.fromLibroId, sampleRango.fromLibroId);
        expect(c.fromCapitulo, sampleRango.fromCapitulo);
        expect(c.fromVersiculo, sampleRango.fromVersiculo);
        expect(c.toLibroId, sampleRango.toLibroId);
        expect(c.toCapitulo, sampleRango.toCapitulo);
        expect(c.toVersiculoInicio, sampleRango.toVersiculoInicio);
        expect(c.toVersiculoFin, sampleRango.toVersiculoFin);
        expect(c.esRango, sampleRango.esRango);
      });

      test('sin argumentos, devuelve instancia equivalente', () {
        final c = sampleRango.copyWith();
        expect(c, equals(sampleRango));
      });
    });

    test('equality: misma data → iguales (incluye votos)', () {
      final a = CrossReferencia(
        id: 1, versionId: 1,
        fromLibroId: 43, fromCapitulo: 3, fromVersiculo: 16,
        toLibroId: 1, toCapitulo: 22,
        toVersiculoInicio: 12, toVersiculoFin: 14,
        votos: 5,
      );
      final b = CrossReferencia(
        id: 1, versionId: 1,
        fromLibroId: 43, fromCapitulo: 3, fromVersiculo: 16,
        toLibroId: 1, toCapitulo: 22,
        toVersiculoInicio: 12, toVersiculoFin: 14,
        votos: 5,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality: votos diferentes → diferentes', () {
      final a = sampleRango;
      final b = sampleRango.copyWith(votos: 99);
      expect(a, isNot(equals(b)));
    });
  });

  // Feature #2: CrossReferenciaConPreview
  group('CrossReferenciaConPreview', () {
    test('fromMap con preview_texto parsea correctamente', () {
      final m = CrossReferenciaConPreview.fromMap({
        'id': 1,
        'version_id': 1,
        'from_libro_id': 43,
        'from_capitulo': 3,
        'from_versiculo': 16,
        'to_libro_id': 1,
        'to_capitulo': 22,
        'to_versiculo_inicio': 12,
        'to_versiculo_fin': 14,
        'votos': 5,
        'preview_texto':
            'Por tanto, el Señor mismo os dará señal: He aquí que la '
            'virgen concebirá, y dará a luz un hijo, y llamará su nombre '
            'Emanuel',
      });
      expect(m.id, 1);
      expect(m.toLibroId, 1);
      expect(m.votos, 5);
      // Preview completo (sin truncar).
      expect(m.previewTexto, isNotNull);
      expect(m.previewTexto, contains('Emanuel'));
      expect(m.previewTexto!.length, greaterThan(55));
    });

    test('fromMap sin preview_texto: preview es null', () {
      final m = CrossReferenciaConPreview.fromMap({
        'id': 2,
        'version_id': 1,
        'from_libro_id': 43,
        'from_capitulo': 3,
        'from_versiculo': 16,
        'to_libro_id': 1,
        'to_capitulo': 22,
        'to_versiculo_inicio': 12,
        'to_versiculo_fin': 14,
        'votos': 5,
        'preview_texto': null,
      });
      expect(m.previewTexto, isNull);
    });

    test('preview texto corto se guarda completo', () {
      final m = CrossReferenciaConPreview.fromMap({
        'id': 3,
        'version_id': 1,
        'from_libro_id': 1,
        'from_capitulo': 1,
        'from_versiculo': 1,
        'to_libro_id': 1,
        'to_capitulo': 1,
        'to_versiculo_inicio': 2,
        'to_versiculo_fin': 2,
        'votos': 1,
        'preview_texto': 'Texto corto',
      });
      expect(m.previewTexto, 'Texto corto');
    });

    test('hereda propiedades de CrossReferencia (esRango)', () {
      final m = CrossReferenciaConPreview.fromMap({
        'id': 4,
        'version_id': 1,
        'from_libro_id': 43,
        'from_capitulo': 3,
        'from_versiculo': 16,
        'to_libro_id': 1,
        'to_capitulo': 22,
        'to_versiculo_inicio': 12,
        'to_versiculo_fin': 14,
        'votos': 5,
        'preview_texto': 'Preview',
      });
      expect(m.esRango, isTrue);
      expect(m.toVersiculoInicio, 12);
      expect(m.toVersiculoFin, 14);
    });

    test('equality incluye previewTexto', () {
      final a = CrossReferenciaConPreview(
        id: 1, versionId: 1,
        fromLibroId: 1, fromCapitulo: 1, fromVersiculo: 1,
        toLibroId: 1, toCapitulo: 1,
        toVersiculoInicio: 2, toVersiculoFin: 2,
        votos: 1,
        previewTexto: 'Preview A',
      );
      final b = CrossReferenciaConPreview(
        id: 1, versionId: 1,
        fromLibroId: 1, fromCapitulo: 1, fromVersiculo: 1,
        toLibroId: 1, toCapitulo: 1,
        toVersiculoInicio: 2, toVersiculoFin: 2,
        votos: 1,
        previewTexto: 'Preview A',
      );
      expect(a, equals(b));

      final c = CrossReferenciaConPreview(
        id: 1, versionId: 1,
        fromLibroId: 1, fromCapitulo: 1, fromVersiculo: 1,
        toLibroId: 1, toCapitulo: 1,
        toVersiculoInicio: 2, toVersiculoFin: 2,
        votos: 1,
        previewTexto: 'Preview B',
      );
      expect(a, isNot(equals(c)));
    });
  });
}
