import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/nota.dart';

void main() {
  group('Nota', () {
    final fechaCre = DateTime.utc(2026, 6, 1, 12, 0, 0);
    final fechaMod = DateTime.utc(2026, 6, 2, 8, 0, 0);
    final sample = Nota(
      id: 1,
      versionId: 1,
      libroId: 4,
      capitulo: 3,
      numero: 16,
      contenido: 'Para predicar sobre el amor de Dios',
      color: NotaColor.amarillo,
      fechaCreacion: fechaCre,
      fechaModificacion: fechaMod,
    );

    group('fromMap', () {
      test('construye correctamente con color válido', () {
        final n = Nota.fromMap({
          'id': 1,
          'version_id': 1,
          'libro_id': 4,
          'capitulo': 3,
          'numero': 16,
          'contenido': 'Para predicar sobre el amor de Dios',
          'color': 'amarillo',
          'fecha_creacion': fechaCre.millisecondsSinceEpoch ~/ 1000,
          'fecha_modificacion': fechaMod.millisecondsSinceEpoch ~/ 1000,
        });
        expect(n, equals(sample));
      });

      test('acepta los 4 colores válidos', () {
        for (final c in ['amarillo', 'verde', 'azul', 'ninguno']) {
          final n = Nota.fromMap({
            'id': 1, 'version_id': 1, 'libro_id': 1, 'capitulo': 1,
            'numero': 1, 'contenido': 'x', 'color': c,
            'fecha_creacion': 0, 'fecha_modificacion': 0,
          });
          expect(n.color.value, c);
        }
      });

      test('lanza FormatException con color inválido', () {
        expect(
          () => Nota.fromMap({
            'id': 1, 'version_id': 1, 'libro_id': 1, 'capitulo': 1,
            'numero': 1, 'contenido': 'x', 'color': 'rojo',
            'fecha_creacion': 0, 'fecha_modificacion': 0,
          }),
          throwsFormatException,
        );
      });

      test('acepta fechas en epoch 0 (caso borde)', () {
        final n = Nota.fromMap({
          'id': 1, 'version_id': 1, 'libro_id': 1, 'capitulo': 1,
          'numero': 1, 'contenido': 'x', 'color': 'ninguno',
          'fecha_creacion': 0, 'fecha_modificacion': 0,
        });
        expect(n.fechaCreacion.millisecondsSinceEpoch, 0);
        expect(n.fechaModificacion.millisecondsSinceEpoch, 0);
      });
    });

    group('toMap', () {
      test('serializa a snake_case', () {
        final map = sample.toMap();
        expect(map['id'], 1);
        expect(map['version_id'], 1);
        expect(map['libro_id'], 4);
        expect(map['capitulo'], 3);
        expect(map['numero'], 16);
        expect(map['contenido'], 'Para predicar sobre el amor de Dios');
        expect(map['color'], 'amarillo');
        expect(
          map['fecha_creacion'],
          fechaCre.millisecondsSinceEpoch ~/ 1000,
        );
        expect(
          map['fecha_modificacion'],
          fechaMod.millisecondsSinceEpoch ~/ 1000,
        );
      });
    });

    test('copyWith reemplaza solo los campos especificados', () {
      final c = sample.copyWith(color: NotaColor.verde);
      expect(c.color, NotaColor.verde);
      expect(c.contenido, sample.contenido);
    });

    test('equality: misma data → iguales', () {
      final a = Nota(
        id: 1, versionId: 1, libroId: 1, capitulo: 1, numero: 1,
        contenido: 'x', color: NotaColor.azul,
        fechaCreacion: fechaCre, fechaModificacion: fechaMod,
      );
      final b = Nota(
        id: 1, versionId: 1, libroId: 1, capitulo: 1, numero: 1,
        contenido: 'x', color: NotaColor.azul,
        fechaCreacion: fechaCre, fechaModificacion: fechaMod,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
