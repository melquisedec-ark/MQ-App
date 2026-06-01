import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/biblia_version.dart';

void main() {
  group('BibliaVersion', () {
    const sample = BibliaVersion(
      id: 1,
      nombre: 'Reina Valera 1909',
      abreviatura: 'RVR1909',
      idioma: 'es',
      descripcion: 'Versión de dominio público',
      anioPublicacion: 1909,
      esDominioPublico: true,
      activa: true,
    );

    group('fromMap', () {
      test('construye correctamente desde un map completo', () {
        final v = BibliaVersion.fromMap(const {
          'id': 1,
          'nombre': 'Reina Valera 1909',
          'abreviatura': 'RVR1909',
          'idioma': 'es',
          'descripcion': 'Versión de dominio público',
          'anio_publicacion': 1909,
          'es_dominio_publico': 1,
          'activa': 1,
        });
        expect(v, equals(sample));
      });

      test('acepta descripcion y anio_publicacion null', () {
        final v = BibliaVersion.fromMap(const {
          'id': 2,
          'nombre': 'Reina Valera 1569',
          'abreviatura': 'RVR1569',
          'idioma': 'es',
          'descripcion': null,
          'anio_publicacion': null,
          'es_dominio_publico': 1,
          'activa': 1,
        });
        expect(v.descripcion, isNull);
        expect(v.anioPublicacion, isNull);
      });

      test('interpreta es_dominio_publico=0 como false', () {
        final v = BibliaVersion.fromMap(const {
          'id': 3,
          'nombre': 'NVI',
          'abreviatura': 'NVI',
          'idioma': 'es',
          'descripcion': null,
          'anio_publicacion': 1999,
          'es_dominio_publico': 0,
          'activa': 1,
        });
        expect(v.esDominioPublico, isFalse);
      });

      test('interpreta activa=0 como false', () {
        final v = BibliaVersion.fromMap(const {
          'id': 4,
          'nombre': 'LBLA',
          'abreviatura': 'LBLA',
          'idioma': 'es',
          'descripcion': null,
          'anio_publicacion': 1960,
          'es_dominio_publico': 0,
          'activa': 0,
        });
        expect(v.activa, isFalse);
      });

      test('tolerante a es_dominio_publico / activa null (default true)', () {
        final v = BibliaVersion.fromMap(const {
          'id': 5,
          'nombre': 'Test',
          'abreviatura': 'TST',
          'idioma': 'es',
          'descripcion': null,
          'anio_publicacion': null,
          // Sin es_dominio_publico ni activa
        });
        expect(v.esDominioPublico, isTrue);
        expect(v.activa, isTrue);
      });
    });

    group('toMap', () {
      test('serializa a snake_case y 1/0 para booleans', () {
        final map = sample.toMap();
        expect(map['id'], 1);
        expect(map['nombre'], 'Reina Valera 1909');
        expect(map['abreviatura'], 'RVR1909');
        expect(map['idioma'], 'es');
        expect(map['descripcion'], 'Versión de dominio público');
        expect(map['anio_publicacion'], 1909);
        expect(map['es_dominio_publico'], 1);
        expect(map['activa'], 1);
      });

      test('false booleans serializan como 0', () {
        final v = sample.copyWith(esDominioPublico: false, activa: false);
        final map = v.toMap();
        expect(map['es_dominio_publico'], 0);
        expect(map['activa'], 0);
      });
    });

    group('copyWith', () {
      test('reemplaza solo los campos especificados', () {
        final v2 = sample.copyWith(nombre: 'RV1909 (otra)');
        expect(v2.nombre, 'RV1909 (otra)');
        expect(v2.id, sample.id);
        expect(v2.abreviatura, sample.abreviatura);
        expect(v2.esDominioPublico, sample.esDominioPublico);
      });

      test('devuelve una instancia igual si no se cambia nada', () {
        final v2 = sample.copyWith();
        expect(v2, equals(sample));
      });
    });

    group('equality', () {
      test('dos instancias con los mismos campos son iguales', () {
        const a = BibliaVersion(
          id: 1, nombre: 'A', abreviatura: 'A', idioma: 'es',
        );
        const b = BibliaVersion(
          id: 1, nombre: 'A', abreviatura: 'A', idioma: 'es',
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('dos instancias con diferentes campos NO son iguales', () {
        const a = BibliaVersion(
          id: 1, nombre: 'A', abreviatura: 'A', idioma: 'es',
        );
        const b = BibliaVersion(
          id: 2, nombre: 'A', abreviatura: 'A', idioma: 'es',
        );
        expect(a, isNot(equals(b)));
      });
    });
  });
}
