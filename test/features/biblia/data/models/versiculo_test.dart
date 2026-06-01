import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/versiculo.dart';

void main() {
  group('Versiculo', () {
    const sample = Versiculo(
      id: 1,
      capituloId: 1,
      numero: 1,
      texto: 'En el principio creó Dios los cielos y la tierra.',
    );

    test('fromMap construye correctamente', () {
      final v = Versiculo.fromMap(const {
        'id': 1,
        'capitulo_id': 1,
        'numero': 1,
        'texto': 'En el principio creó Dios los cielos y la tierra.',
      });
      expect(v, equals(sample));
    });

    test('fromMap maneja texto largo con tildes y ñ', () {
      const largo = 'Porque de tal manera amó Dios al mundo, que ha dado '
          'a su Hijo unigénito, para que todo aquel que en él cree, no se '
          'pierda, mas tenga vida eterna.';
      final v = Versiculo.fromMap(const {
        'id': 2,
        'capitulo_id': 3,
        'numero': 16,
        'texto': largo,
      });
      expect(v.texto, largo);
    });

    test('toMap serializa a snake_case', () {
      final map = sample.toMap();
      expect(map['id'], 1);
      expect(map['capitulo_id'], 1);
      expect(map['numero'], 1);
      expect(map['texto'], sample.texto);
    });

    test('copyWith reemplaza solo los campos especificados', () {
      final v = sample.copyWith(numero: 2);
      expect(v.numero, 2);
      expect(v.capituloId, sample.capituloId);
      expect(v.texto, sample.texto);
    });

    test('equality: misma data → iguales', () {
      const a = Versiculo(
        id: 1, capituloId: 1, numero: 1, texto: 'texto',
      );
      const b = Versiculo(
        id: 1, capituloId: 1, numero: 1, texto: 'texto',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
