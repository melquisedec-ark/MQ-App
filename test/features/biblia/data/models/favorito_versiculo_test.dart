import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/favorito_versiculo.dart';

void main() {
  group('FavoritoVersiculo', () {
    final fecha = DateTime.utc(2026, 6, 1, 12, 30, 45);
    final sample = FavoritoVersiculo(
      id: 1,
      versionId: 1,
      libroId: 4,
      capitulo: 3,
      numero: 16,
      fechaAgregado: fecha,
    );

    test('fromMap convierte unix seconds a DateTime UTC', () {
      final unix = fecha.millisecondsSinceEpoch ~/ 1000;
      final f = FavoritoVersiculo.fromMap({
        'id': 1,
        'version_id': 1,
        'libro_id': 4,
        'capitulo': 3,
        'numero': 16,
        'fecha_agregado': unix,
      });
      expect(f, equals(sample));
      expect(f.fechaAgregado.isUtc, isTrue);
    });

    test('toMap convierte DateTime UTC a unix seconds', () {
      final map = sample.toMap();
      expect(map['id'], 1);
      expect(map['version_id'], 1);
      expect(map['libro_id'], 4);
      expect(map['capitulo'], 3);
      expect(map['numero'], 16);
      expect(
        map['fecha_agregado'],
        fecha.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('roundtrip: fromMap(toMap(x)) preserva los datos', () {
      final map = sample.toMap();
      final restored = FavoritoVersiculo.fromMap(map);
      expect(restored, equals(sample));
    });

    test('copyWith reemplaza solo los campos especificados', () {
      final c = sample.copyWith(numero: 17);
      expect(c.numero, 17);
      expect(c.capitulo, sample.capitulo);
      expect(c.fechaAgregado, sample.fechaAgregado);
    });

    test('equality: misma data → iguales', () {
      final a = FavoritoVersiculo(
        id: 1, versionId: 1, libroId: 1, capitulo: 1, numero: 1,
        fechaAgregado: fecha,
      );
      final b = FavoritoVersiculo(
        id: 1, versionId: 1, libroId: 1, capitulo: 1, numero: 1,
        fechaAgregado: fecha,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
