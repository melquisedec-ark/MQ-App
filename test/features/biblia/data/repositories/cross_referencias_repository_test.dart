import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  tearDownAll(() => cleanupBibleTestDatabases());

  group('CrossReferenciasRepository', () {
    group('getByFromVerse', () {
      test('retorna refs ordenadas por libro/capítulo/versículo destino', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Juan 3:16 tiene 3 refs: Gn 22:12-14 (libro#1), Jn 3:17 (libro#43), 1Jn 4:9-10 (libro#62)
          final refs = await bundle.crossRefs.getByFromVerse(
            versionId: 1,
            libroId: 4, // Juan
            capitulo: 3,
            versiculo: 16,
          );
          expect(refs, hasLength(3));
          // Verificar orden canónico: Gn → Jn → 1Jn
          expect(refs[0].toLibroId, 1);  // Génesis
          expect(refs[1].toLibroId, 4);  // Juan
          expect(refs[2].toLibroId, 6);  // 1 Juan
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

    // C6: batch query para evitar N+1 al renderizar chapter view.
    group('getCountsByFromVerseBatch', () {
      test('retorna Map con counts por versículo en el capítulo', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Juan cap 3: solo el versículo 16 tiene refs (3 en el seed).
          final map = await bundle.crossRefs.getCountsByFromVerseBatch(
            versionId: 1,
            libroId: 4, // Juan
            capitulo: 3,
          );
          expect(map, isA<Map<int, int>>());
          // Solo aparece el versículo 16 (con count 3). El 17 y 18 no
          // tienen refs salientes en el seed, no aparecen en el Map.
          expect(map.length, 1);
          expect(map[16], 3);
          expect(map.containsKey(17), isFalse);
          expect(map.containsKey(18), isFalse);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('versículos sin refs no aparecen en el Map', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Génesis cap 1: versículo 1 tiene 2 refs; versículo 2 no tiene
          // refs salientes (es destino, no origen).
          final map = await bundle.crossRefs.getCountsByFromVerseBatch(
            versionId: 1,
            libroId: 1,
            capitulo: 1,
          );
          expect(map.containsKey(1), isTrue);
          expect(map[1], 2);
          expect(map.containsKey(2), isFalse);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('capítulo sin refs retorna Map vacío', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Génesis cap 2: ninguna ref sale de aquí en el seed.
          final map = await bundle.crossRefs.getCountsByFromVerseBatch(
            versionId: 1,
            libroId: 1,
            capitulo: 2,
          );
          expect(map, isEmpty);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('respeta versionId (no cuenta refs de otra versión)', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Las refs del seed son de version_id=1; en version=2 no hay.
          final map = await bundle.crossRefs.getCountsByFromVerseBatch(
            versionId: 2,
            libroId: 4,
            capitulo: 3,
          );
          expect(map, isEmpty);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('con seed vacío (sin refs), retorna Map vacío', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final map = await bundle.crossRefs.getCountsByFromVerseBatch(
            versionId: 1,
            libroId: 1,
            capitulo: 1,
          );
          expect(map, isEmpty);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('Génesis 1:1 con 2 refs y Salmos 23:1 con 1 ref en sus caps',
          () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Cap 1 de Génesis: versículo 1 tiene 2 refs.
          final gen1 = await bundle.crossRefs.getCountsByFromVerseBatch(
            versionId: 1,
            libroId: 1,
            capitulo: 1,
          );
          expect(gen1[1], 2);

          // Cap 23 de Salmos: versículo 1 tiene 1 ref.
          final sal23 = await bundle.crossRefs.getCountsByFromVerseBatch(
            versionId: 1,
            libroId: 3,
            capitulo: 23,
          );
          expect(sal23[1], 1);
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
            ''', [999, 1, 1, 1, 1, 1, 1, 1, 1],),
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
            ''', [2, 4, 3, 16, 1, 1, 1, 1, 1],),
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
            ''', [1, 1, 1, 1, 1, 1, 5, 3, 1],),
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

    // Feature #2: preview del texto del versículo destino.
    group('getByFromVerseWithPreview', () {
      test('retorna refs con preview_texto cuando el versículo existe',
          () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Génesis 1:1 → Génesis 1:2 (versículo 2 existe en el seed).
          final refs = await bundle.crossRefs.getByFromVerseWithPreview(
            versionId: 1,
            libroId: 1,
            capitulo: 1,
            versiculo: 1,
          );
          expect(refs, hasLength(2));
          // La primera ref va a Génesis 1:2 → debe tener preview.
          final refGn12 =
              refs.firstWhere((r) => r.toCapitulo == 1 && r.toVersiculoInicio == 2);
          expect(refGn12.previewTexto, isNotNull);
          expect(
            refGn12.previewTexto!,
            contains('Y la tierra estaba desordenada'),
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

      test('preview_texto es null cuando el versículo destino no existe',
          () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          // Juan 3:16 → 3 refs. La preview query usa LEFT JOIN a todo,
          // así que todas las refs se incluyen.
          final refs = await bundle.crossRefs.getByFromVerseWithPreview(
            versionId: 1,
            libroId: 4,
            capitulo: 3,
            versiculo: 16,
          );
          expect(refs, hasLength(3));
          // La ref a Génesis 22:12: cap 22 no existe en seed → preview null.
          final refGn22 =
              refs.firstWhere((r) => r.toLibroId == 1 && r.toCapitulo == 22);
          expect(refGn22.previewTexto, isNull);
          // La ref a Juan 3:17 SÍ existe → preview no null.
          final refJn317 =
              refs.firstWhere((r) => r.toLibroId == 4 && r.toCapitulo == 3);
          expect(refJn317.previewTexto, isNotNull);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('retorna lista vacía si no hay refs', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          final refs = await bundle.crossRefs.getByFromVerseWithPreview(
            versionId: 1,
            libroId: 4,
            capitulo: 3,
            versiculo: 17,
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

      test('ordena por libro/capítulo/versículo destino igual que getByFromVerse', () async {
        final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
        try {
          final refs = await bundle.crossRefs.getByFromVerseWithPreview(
            versionId: 1,
            libroId: 4,
            capitulo: 3,
            versiculo: 16,
          );
          expect(refs, hasLength(3));
          // Orden canónico: Gn → Jn → 1Jn
          expect(refs[0].toLibroId, 1);  // Génesis
          expect(refs[1].toLibroId, 4);  // Juan
          expect(refs[2].toLibroId, 6);  // 1 Juan
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
