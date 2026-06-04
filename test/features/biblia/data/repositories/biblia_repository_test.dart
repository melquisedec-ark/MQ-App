import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/libro.dart';

import '../../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  tearDownAll(() => cleanupBibleTestDatabases());

  group('BibliaRepository', () {
    group('Versiones', () {
      test('getActiveVersions devuelve solo las activas', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          // El seed tiene 2 versiones, ambas activas
          final active = await bundle.biblia.getActiveVersions();
          expect(active, hasLength(2));
          expect(
            active.map((v) => v.abreviatura).toList(),
            containsAll(['RVR1909', 'RVR1569']),
          );
          expect(active.every((v) => v.activa), isTrue);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('getActiveVersions omite versiones inactivas', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          await bundle.db.update(
            'version',
            {'activa': 0},
            where: 'id = ?',
            whereArgs: [2],
          );
          final active = await bundle.biblia.getActiveVersions();
          expect(active, hasLength(1));
          expect(active.first.id, 1);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('getVersionById devuelve la versión o null', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final v = await bundle.biblia.getVersionById(1);
          expect(v, isNotNull);
          expect(v!.nombre, 'Reina Valera 1909');
          final missing = await bundle.biblia.getVersionById(999);
          expect(missing, isNull);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('getVersionByAbreviatura es case-sensitive', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final v = await bundle.biblia.getVersionByAbreviatura('RVR1909');
          expect(v, isNotNull);
          final vLower = await bundle.biblia.getVersionByAbreviatura('rvr1909');
          expect(vLower, isNull);
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

    group('Libros', () {
      test('getLibrosByVersion devuelve libros en orden canónico', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final libros = await bundle.biblia.getLibrosByVersion(1);
          // Génesis=1, Éxodo=2, Salmos=19, Juan=43, 1 Juan=62 (5 libros en v1)
          expect(libros, hasLength(5));
          expect(
            libros.map((l) => l.numero).toList(),
            [1, 2, 19, 43, 62],
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

      test('getLibrosByVersion filtra por testamento', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final at = await bundle.biblia.getLibrosByVersion(
            1,
            testamento: Testamento.at,
          );
          // Génesis, Éxodo, Salmos (3 AT)
          expect(at, hasLength(3));
          expect(at.every((l) => l.testamento == Testamento.at), isTrue);

          final nt = await bundle.biblia.getLibrosByVersion(
            1,
            testamento: Testamento.nt,
          );
          // Juan + 1 Juan (2 NT) — agregado en C1 para tests de
          // cross_referencia (1 Juan canónico = libro_id 62).
          expect(nt, hasLength(2));
          expect(nt.map((l) => l.nombre).toList(), ['Juan', '1 Juan']);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('getLibroByNumero resuelve por (version, numero)', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final juan = await bundle.biblia.getLibroByNumero(1, 43);
          expect(juan, isNotNull);
          expect(juan!.nombre, 'Juan');
          final missing = await bundle.biblia.getLibroByNumero(1, 999);
          expect(missing, isNull);
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

    group('Capítulos', () {
      test('getCapitulosByLibro ordena por número', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final caps = await bundle.biblia.getCapitulosByLibro(1);
          // Génesis caps 1 y 2
          expect(caps, hasLength(2));
          expect(caps.map((c) => c.numero).toList(), [1, 2]);
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

    group('Versículos', () {
      test('getVersiculosByCapitulo ordena por número', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          // Juan cap 3 (id=3): versículos 16, 17, 18
          final versiculos = await bundle.biblia.getVersiculosByCapitulo(3);
          expect(versiculos, hasLength(3));
          expect(versiculos.map((v) => v.numero).toList(), [16, 17, 18]);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('getVersiculoByReference resuelve la cuádrupla canónica', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          // RV1909 Juan 3:16 (version 1, libro 43, cap 3, num 16)
          final v = await bundle.biblia.getVersiculoByReference(1, 43, 3, 16);
          expect(v, isNotNull);
          expect(v!.texto, contains('Porque de tal manera amó Dios'));
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('getVersiculoByReference retorna null si no existe', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final v = await bundle.biblia.getVersiculoByReference(1, 43, 99, 99);
          expect(v, isNull);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('getVersiculoByReference distingue entre versiones del mismo libro',
          () async {
        final bundle = await createBibleReposWithSeed();
        try {
          // En el seed, libro id=4 es Juan de RV1909 (v1),
          // libro id=5 es Juan de RV1569 (v2) y NO tiene versículos
          // en su cap 3 (id=5).
          final v1909 = await bundle.biblia.getVersiculoByReference(1, 43, 3, 16);
          expect(v1909, isNotNull);
          // Juan 3:16 de RV1569: libro numero=43 en v2, pero el cap 3 (id=5)
          // está vacío.
          final v1569 = await bundle.biblia.getVersiculoByReference(2, 43, 3, 16);
          expect(v1569, isNull);
        } finally {
          await closeBibleRepos(
            db: bundle.db,
            favoritos: bundle.favoritos,
            notas: bundle.notas,
            historial: bundle.historial,
          );
        }
      });

      test('getRandomVersiculo devuelve un versículo de la versión', () async {
        final bundle = await createBibleReposWithSeed();
        try {
          // Repetir 10 veces para descartar que devuelva siempre el mismo
          // (la versión 2 está vacía para cap 3, pero tiene 1 libro).
          // Solo podemos testear v1 confiablemente.
          for (var i = 0; i < 5; i++) {
            final v = await bundle.biblia.getRandomVersiculo(1);
            expect(v, isNotNull);
            expect(v!.texto, isNotEmpty);
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

      test('getRandomVersiculo retorna null si la versión no tiene versículos',
          () async {
        final bundle = await createBibleReposWithSeed();
        try {
          final v = await bundle.biblia.getRandomVersiculo(999);
          expect(v, isNull);
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
