import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/historial_item.dart';

void main() {
  group('HistorialItem', () {
    final fecha = DateTime.utc(2026, 6, 1, 9, 0, 0);
    final sample = HistorialItem(
      id: 1,
      versionId: 1,
      libroId: 4,
      libroNombre: 'Juan',
      libroAbreviatura: 'Jn',
      capitulo: 3,
      numero: 16,
      texto: 'Porque de tal manera amó Dios al mundo...',
      fechaLectura: fecha,
    );

    test('fromJoinedMap construye correctamente con todos los datos', () {
      final h = HistorialItem.fromJoinedMap({
        'id': 1,
        'version_id': 1,
        'libro_id': 4,
        'libro_nombre': 'Juan',
        'libro_abreviatura': 'Jn',
        'capitulo': 3,
        'numero': 16,
        'texto': 'Porque de tal manera amó Dios al mundo...',
        'fecha_lectura': fecha.millisecondsSinceEpoch ~/ 1000,
      });
      expect(h, equals(sample));
    });

    test('acepta texto null (versículo eliminado tras re-versificación)', () {
      final h = HistorialItem.fromJoinedMap({
        'id': 1,
        'version_id': 1,
        'libro_id': 4,
        'libro_nombre': 'Juan',
        'libro_abreviatura': 'Jn',
        'capitulo': 3,
        'numero': 16,
        'texto': null,
        'fecha_lectura': fecha.millisecondsSinceEpoch ~/ 1000,
      });
      expect(h.texto, isNull);
    });

    test('referencia retorna abreviatura + cap:num', () {
      expect(sample.referencia, 'Jn 3:16');
    });

    test('equality: misma data → iguales', () {
      final a = HistorialItem(
        id: 1, versionId: 1, libroId: 1, libroNombre: 'A',
        libroAbreviatura: 'A', capitulo: 1, numero: 1, texto: 't',
        fechaLectura: fecha,
      );
      final b = HistorialItem(
        id: 1, versionId: 1, libroId: 1, libroNombre: 'A',
        libroAbreviatura: 'A', capitulo: 1, numero: 1, texto: 't',
        fechaLectura: fecha,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
