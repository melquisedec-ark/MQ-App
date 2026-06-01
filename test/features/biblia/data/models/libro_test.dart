import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/libro.dart';

void main() {
  group('Libro', () {
    const sample = Libro(
      id: 1,
      versionId: 1,
      nombre: 'Génesis',
      abreviatura: 'Gn',
      testamento: Testamento.at,
      numero: 1,
      totalCapitulos: 50,
    );

    group('fromMap', () {
      test('construye correctamente desde un map completo', () {
        final l = Libro.fromMap(const {
          'id': 1,
          'version_id': 1,
          'nombre': 'Génesis',
          'abreviatura': 'Gn',
          'testamento': 'AT',
          'numero': 1,
          'total_capitulos': 50,
        });
        expect(l, equals(sample));
      });

      test('acepta testamento=NT', () {
        final l = Libro.fromMap(const {
          'id': 66,
          'version_id': 1,
          'nombre': 'Apocalipsis',
          'abreviatura': 'Ap',
          'testamento': 'NT',
          'numero': 66,
          'total_capitulos': 22,
        });
        expect(l.testamento, Testamento.nt);
      });

      test('lanza FormatException con testamento inválido', () {
        expect(
          () => Libro.fromMap(const {
            'id': 1,
            'version_id': 1,
            'nombre': 'X',
            'abreviatura': 'X',
            'testamento': 'INVALID',
            'numero': 1,
            'total_capitulos': 1,
          }),
          throwsFormatException,
        );
      });
    });

    group('Testamento enum', () {
      test('value retorna AT/NT para SQL', () {
        expect(Testamento.at.value, 'AT');
        expect(Testamento.nt.value, 'NT');
      });

      test('label retorna nombres legibles', () {
        expect(Testamento.at.label, 'Antiguo Testamento');
        expect(Testamento.nt.label, 'Nuevo Testamento');
      });

      test('fromString acepta mayúsculas y minúsculas', () {
        expect(TestamentoX.fromString('AT'), Testamento.at);
        expect(TestamentoX.fromString('at'), Testamento.at);
        expect(TestamentoX.fromString('NT'), Testamento.nt);
        expect(TestamentoX.fromString('nt'), Testamento.nt);
      });

      test('fromString retorna null para valores inválidos', () {
        expect(TestamentoX.fromString('XX'), isNull);
        expect(TestamentoX.fromString(null), isNull);
      });
    });

    group('toMap', () {
      test('serializa a snake_case', () {
        final map = sample.toMap();
        expect(map['id'], 1);
        expect(map['version_id'], 1);
        expect(map['nombre'], 'Génesis');
        expect(map['abreviatura'], 'Gn');
        expect(map['testamento'], 'AT');
        expect(map['numero'], 1);
        expect(map['total_capitulos'], 50);
      });
    });

    group('copyWith', () {
      test('reemplaza solo los campos especificados', () {
        final l2 = sample.copyWith(nombre: 'Genesis (otra)');
        expect(l2.nombre, 'Genesis (otra)');
        expect(l2.id, sample.id);
        expect(l2.testamento, sample.testamento);
      });
    });

    group('equality', () {
      test('dos instancias con los mismos campos son iguales', () {
        const a = Libro(
          id: 1, versionId: 1, nombre: 'A', abreviatura: 'A',
          testamento: Testamento.at, numero: 1, totalCapitulos: 1,
        );
        const b = Libro(
          id: 1, versionId: 1, nombre: 'A', abreviatura: 'A',
          testamento: Testamento.at, numero: 1, totalCapitulos: 1,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}
