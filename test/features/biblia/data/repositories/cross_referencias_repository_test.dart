import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  tearDownAll(() => cleanupBibleTestDatabases());

  group('CrossReferenciasRepository', () {
    group('getByFromVerse', () {
      test('retorna refs ordenadas por votos DESC', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Juan 3:16 tiene 3 refs en el seed con votos 5, 3, 2
          final refs = await bundle.crossRefs.getByFromVerse(
            versionId: 1,
            libroId: 4, // Juan
            capitulo: 3,
            versiculo: 16,
          );
          expect(refs, hasLength(3));
          // Verificar orden: 5 → 3 → 2
          expect(refs[0].votos, 5);
          expect(refs[1].votos, 3);
          expect(refs[2].votos, 2);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('retorna lista vacía si no hay refs (versículo sin refs)', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          final refs = await bundle.crossRefs.getByFromVerse(
            versionId: 1,
            libroId: 4, // Juan
            capitulo: 3,
            versiculo: 17, // sólo es destino, no origen
          );
          expect(refs, isEmpty);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('respeta versionId (no retorna refs de otra versión)', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // El seed tiene refs solo en version_id=1; pedimos en version=2
          // → debe devolver lista vacía.
          final refs = await bundle.crossRefs.getByFromVerse(
            versionId: 2, // no existe en seed
            libroId: 4,
            capitulo: 3,
            versiculo: 16,
          );
          expect(refs, isEmpty);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('con seed vacío, retorna lista vacía', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final refs = await bundle.crossRefs.getByFromVerse(
            versionId: 1,
            libroId: 1,
            capitulo: 1,
            versiculo: 1,
          );
          expect(refs, isEmpty);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });
    });

    group('getByToVerse', () {
      test('retorna refs que apuntan a un versículo único', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Génesis 22:12 está dentro del rango Gén 22:12-14 (1 ref)
          final refs = await bundle.crossRefs.getByToVerse(
            versionId: 1,
            libroId: 1,
            capitulo: 22,
            versiculo: 12,
          );
          expect(refs, hasLength(1));
          expect(refs.first.esRango, isTrue);
          expect(refs.first.toVersiculoInicio, 12);
          expect(refs.first.toVersiculoFin, 14);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('retorna refs cuyo rango destino contiene el versículo', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Génesis 22:13 cae en 22:12-14 (mismo ref que arriba)
          final refs = await bundle.crossRefs.getByToVerse(
            versionId: 1,
            libroId: 1,
            capitulo: 22,
            versiculo: 13,
          );
          expect(refs, hasLength(1));
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('NO retorna refs cuyo rango destino no contiene el versículo',
          () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Génesis 22:15 está FUERA del rango 22:12-14 → no debe aparecer
          final refs = await bundle.crossRefs.getByToVerse(
            versionId: 1,
            libroId: 1,
            capitulo: 22,
            versiculo: 15,
          );
          expect(refs, isEmpty);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('retorna lista vacía si el versículo no es destino de nada',
          () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          final refs = await bundle.crossRefs.getByToVerse(
            versionId: 1,
            libroId: 1, // Génesis
            capitulo: 1, // cap 1 (no es destino de ninguna ref en el seed)
            versiculo: 1,
          );
          expect(refs, isEmpty);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });
    });

    group('countByFromVerse', () {
      test('retorna 3 para Juan 3:16 (3 refs en el seed)', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          final n = await bundle.crossRefs.countByFromVerse(
            versionId: 1,
            libroId: 4,
            capitulo: 3,
            versiculo: 16,
          );
          expect(n, 3);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('retorna 0 si no hay refs', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          final n = await bundle.crossRefs.countByFromVerse(
            versionId: 1,
            libroId: 4,
            capitulo: 3,
            versiculo: 17,
          );
          expect(n, 0);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });
    });

    group('countByToVerse', () {
      test('retorna 1 para Génesis 22:12 (cae en rango 12-14)', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          final n = await bundle.crossRefs.countByToVerse(
            versionId: 1,
            libroId: 1,
            capitulo: 22,
            versiculo: 12,
          );
          expect(n, 1);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('retorna 1 para Génesis 22:13 (también cae en rango 12-14)',
          () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          final n = await bundle.crossRefs.countByToVerse(
            versionId: 1,
            libroId: 1,
            capitulo: 22,
            versiculo: 13,
          );
          expect(n, 1);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });
    });

    group('Integridad referencial (triggers)', () {
      test('insertar con version_id inexistente falla con error de trigger',
          () async {
        final bundle = await createBibleReposWithSeed();
        try {
          await expectLater(
            bundle.db.rawInsert('''
              INSERT INTO cross_referencia
                (version_id, from_libro_id, from_capitulo, from_versiculo,
                 to_libro_id, to_capitulo, to_versiculo_inicio, to_versiculo_fin, votos)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', [999, 1, 1, 1, 1, 1, 1, 1, 1]),
            throwsA(isA<dynamic>()),
          );
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('insertar con from_libro_id de otra versión falla', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          // libro_id=4 es Juan de v1; intentar usar con version_id=2
          await expectLater(
            bundle.db.rawInsert('''
              INSERT INTO cross_referencia
                (version_id, from_libro_id, from_capitulo, from_versiculo,
                 to_libro_id, to_capitulo, to_versiculo_inicio, to_versiculo_fin, votos)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', [2, 4, 3, 16, 1, 1, 1, 1, 1]),
            throwsA(isA<dynamic>()),
          );
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('CHECK rechaza to_versiculo_fin < to_versiculo_inicio', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          await expectLater(
            bundle.db.rawInsert('''
              INSERT INTO cross_referencia
                (version_id, from_libro_id, from_capitulo, from_versiculo,
                 to_libro_id, to_capitulo, to_versiculo_inicio, to_versiculo_fin, votos)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', [1, 1, 1, 1, 1, 1, 5, 3, 1]),
            throwsA(isA<dynamic>()),
          );
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });
    });
  });
}
