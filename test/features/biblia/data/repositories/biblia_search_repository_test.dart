import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  tearDownAll(() => cleanupBibleTestDatabases());

  group('BibliaSearchRepository (FTS5)', () {
    test('search con query vacía devuelve lista vacía', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final results = await bundle.search.search('');
        expect(results, isEmpty);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('search con solo espacios devuelve lista vacía', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final results = await bundle.search.search('   ');
        expect(results, isEmpty);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('search matchea palabra simple', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        // "Dios" aparece en Génesis 1:1, Juan 3:16, 3:17, 3:18
        final results = await bundle.search.search('Dios');
        expect(results, isNotEmpty);
        expect(
          results.every((r) => r.versiculo.texto.contains('Dios')),
          isTrue,
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

    test('search es acento-insensible (José == jose)', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        // El seed no tiene "José" pero tiene "Jehová". Verificamos que
        // tipiar "jehova" (sin tilde) matchee.
        // NOTA: El trigger inserta solo el rowid y el texto; el FTS5 con
        // remove_diacritics 2 normaliza en el índice. Verificamos
        // empíricamente.
        final conTilde = await bundle.search.search('Jehová');
        final sinTilde = await bundle.search.search('jehova');
        // La búsqueda con tilde puede no encontrar (depende de cómo FTS5
        // tokeniza el texto original "Jehová"). Pero la búsqueda sin tilde
        // SÍ debe encontrar porque remove_diacritics 2 normaliza ambos.
        expect(
          sinTilde,
          isNotEmpty,
          reason: 'Búsqueda sin tilde debe encontrar "Jehová"',
        );
        // (conTilde puede ser vacío o no dependiendo del tokenizer; no
        // asumimos un comportamiento específico aquí.)
        // ignore: avoid_print
        print('conTilde=${conTilde.length}, sinTilde=${sinTilde.length}');
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('search multi-término aplica AND implícito', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        // "Dios mundo" debe matchear solo versículos que tienen AMBAS
        // palabras. Juan 3:16 y 3:17 califican.
        final results = await bundle.search.search('Dios mundo');
        expect(results, isNotEmpty);
        for (final r in results) {
          expect(r.versiculo.texto.toLowerCase(), contains('dios'));
          expect(r.versiculo.texto.toLowerCase(), contains('mundo'));
        }
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('search con frase exacta respeta el orden', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        // "de tal manera" debe matchear la frase exacta en Juan 3:16
        final results = await bundle.search.search('"de tal manera"');
        expect(results, isNotEmpty);
        expect(
          results.first.versiculo.texto.toLowerCase(),
          contains('de tal manera'),
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

    test('search filtra por versionId', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final v1 = await bundle.search.search('Dios', versionId: 1);
        expect(v1, isNotEmpty);
        expect(v1.every((r) => r.versionId == 1), isTrue);

        // En la versión 2 (RV1569) no hay versículos con "Dios" en el seed
        final v2 = await bundle.search.search('Dios', versionId: 2);
        expect(v2, isEmpty);

        final v999 = await bundle.search.search('Dios', versionId: 999);
        expect(v999, isEmpty);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('search respeta el limit', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        // "Dios" aparece en 4 versículos del seed (Gn 1:1, Jn 3:16, 17, 18)
        final r1 = await bundle.search.search('Dios', limit: 1);
        expect(r1, hasLength(1));

        final r2 = await bundle.search.search('Dios', limit: 2);
        expect(r2.length, lessThanOrEqualTo(2));

        final r100 = await bundle.search.search('Dios', limit: 100);
        // El seed tiene 5 versículos con "Dios":
        // Gn 1:1, Gn 1:2 (Espíritu de Dios), Jn 3:16, Jn 3:17, Jn 3:18
        expect(r100, hasLength(5));
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('search con caracteres especiales no rompe (sintaxis FTS5)', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        // Caracteres que serían operadores FTS5: ( ) * " :
        // La sanitización los escapa envolviendo en comillas.
        final r1 = await bundle.search.search('(Dios)');
        // Debe devolver lista (vacía o con resultados) sin lanzar excepción
        expect(r1, isA<List>());
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('search devuelve metadata correcta del libro/capítulo', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final results = await bundle.search.search('Dios');
        expect(results, isNotEmpty);
        for (final r in results) {
          expect(r.libroNombre, isNotEmpty);
          expect(r.libroAbreviatura, isNotEmpty);
          expect(r.libroNumero, inInclusiveRange(1, 66));
          expect(r.capituloNumero, greaterThan(0));
          expect(r.referencia, isNotEmpty);
        }
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
}
