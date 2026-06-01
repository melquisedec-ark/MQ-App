import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/capitulo.dart';

void main() {
  group('Capitulo', () {
    const sample = Capitulo(
      id: 1,
      libroId: 1,
      numero: 1,
      totalVersiculos: 31,
    );

    test('fromMap construye correctamente', () {
      final c = Capitulo.fromMap(const {
        'id': 1, 'libro_id': 1, 'numero': 1, 'total_versiculos': 31,
      });
      expect(c, equals(sample));
    });

    test('toMap serializa a snake_case', () {
      final map = sample.toMap();
      expect(map['id'], 1);
      expect(map['libro_id'], 1);
      expect(map['numero'], 1);
      expect(map['total_versiculos'], 31);
    });

    test('copyWith reemplaza solo los campos especificados', () {
      final c = sample.copyWith(numero: 2);
      expect(c.numero, 2);
      expect(c.libroId, sample.libroId);
    });

    test('equality: misma data → iguales', () {
      const a = Capitulo(id: 1, libroId: 1, numero: 1, totalVersiculos: 31);
      const b = Capitulo(id: 1, libroId: 1, numero: 1, totalVersiculos: 31);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
