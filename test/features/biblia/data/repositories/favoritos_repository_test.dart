import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/favorito_versiculo.dart';

import '../../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  tearDownAll(() => cleanupBibleTestDatabases());

  group('FavoritosRepository', () {
    test('add inserta un favorito', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final inserted = await bundle.favoritos.add(1, 4, 3, 16);
        expect(inserted, isTrue);
        final isFav = await bundle.favoritos.isFavorito(1, 4, 3, 16);
        expect(isFav, isTrue);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('add es idempotente (segunda llamada devuelve false)', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final first = await bundle.favoritos.add(1, 4, 3, 16);
        expect(first, isTrue);
        final second = await bundle.favoritos.add(1, 4, 3, 16);
        expect(second, isFalse);
        final count = await bundle.favoritos.getAll();
        expect(count, hasLength(1));
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('remove elimina por la cuádrupla', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.favoritos.add(1, 4, 3, 16);
        final removed = await bundle.favoritos.remove(1, 4, 3, 16);
        expect(removed, 1);
        expect(await bundle.favoritos.isFavorito(1, 4, 3, 16), isFalse);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('remove es idempotente (segunda llamada devuelve 0)', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.favoritos.add(1, 4, 3, 16);
        final r1 = await bundle.favoritos.remove(1, 4, 3, 16);
        expect(r1, 1);
        final r2 = await bundle.favoritos.remove(1, 4, 3, 16);
        expect(r2, 0);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('isFavorito devuelve false si no existe', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        expect(
          await bundle.favoritos.isFavorito(1, 4, 3, 99),
          isFalse,
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

    test('getAll ordena por fecha_agregado DESC', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.favoritos.add(1, 4, 3, 16);
        await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
        await bundle.favoritos.add(1, 4, 3, 17);
        await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
        await bundle.favoritos.add(1, 4, 3, 18);
        final all = await bundle.favoritos.getAll();
        expect(all, hasLength(3));
        // El más reciente (18) debe estar primero
        expect(all.first.numero, 18);
        expect(all.last.numero, 16);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('getAll filtra por versionId', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.favoritos.add(1, 4, 3, 16);
        // Intentar agregar a libro 5 (RV1569) con la mismísima (v=2, l=5, c=3, n=16)
        await bundle.favoritos.add(2, 5, 3, 16);
        final v1 = await bundle.favoritos.getAll(versionId: 1);
        expect(v1, hasLength(1));
        expect(v1.first.versionId, 1);
        final v2 = await bundle.favoritos.getAll(versionId: 2);
        expect(v2, hasLength(1));
        expect(v2.first.versionId, 2);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('trigger rechaza libro de otra versión', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        // Intentar agregar a libro 4 (RV1909) usando version 2
        // El trigger favorito_versiculo_bi debe rechazar.
        expect(
          () => bundle.favoritos.add(2, 4, 3, 16),
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

    test('watchAll emite estado inicial y luego del add', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        // Para un stream broadcast, suscribimos una vez y acumulamos.
        final emissions = <List<FavoritoVersiculo>>[];
        final secondEmission = Completer<List<FavoritoVersiculo>>();
        final sub = bundle.favoritos.watchAll().listen((value) {
          emissions.add(value);
          if (emissions.length == 2 && !secondEmission.isCompleted) {
            secondEmission.complete(value);
          }
        });

        // Espera a la primera emisión (estado inicial vacío).
        while (emissions.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(emissions.first, isEmpty);

        // Add → debe disparar segunda emisión.
        await bundle.favoritos.add(1, 4, 3, 16);
        final second = await secondEmission.future.timeout(
          const Duration(seconds: 2),
        );
        expect(second, hasLength(1));
        expect(second.first.numero, 16);

        await sub.cancel();
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
