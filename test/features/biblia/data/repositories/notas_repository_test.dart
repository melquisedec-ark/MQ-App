import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/nota.dart';

import '../../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  tearDownAll(() => cleanupBibleTestDatabases());

  group('NotasRepository', () {
    test('upsert crea una nota nueva', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final id = await bundle.notas.upsert(
          1, 4, 3, 16,
          'Para predicar sobre el amor de Dios',
          NotaColor.amarillo,
        );
        expect(id, isPositive);
        final nota = await bundle.notas.getNota(1, 4, 3, 16);
        expect(nota, isNotNull);
        expect(nota!.contenido, 'Para predicar sobre el amor de Dios');
        expect(nota.color, NotaColor.amarillo);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('upsert actualiza sin cambiar el id', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final id1 = await bundle.notas.upsert(
          1, 4, 3, 16, 'versión 1', NotaColor.amarillo,
        );
        final id2 = await bundle.notas.upsert(
          1, 4, 3, 16, 'versión 2', NotaColor.verde,
        );
        expect(
          id1,
          equals(id2),
          reason: 'El id debe permanecer estable entre upserts',
        );
        final nota = await bundle.notas.getNota(1, 4, 3, 16);
        expect(nota!.contenido, 'versión 2');
        expect(nota.color, NotaColor.verde);
        // Verificamos que solo haya 1 fila (no 2)
        final all = await bundle.notas.getAll();
        expect(all, hasLength(1));
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('getNota devuelve null si no existe', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final nota = await bundle.notas.getNota(1, 4, 3, 99);
        expect(nota, isNull);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('delete elimina por id', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final id = await bundle.notas.upsert(
          1, 4, 3, 16, 'texto', NotaColor.azul,
        );
        final removed = await bundle.notas.delete(id);
        expect(removed, 1);
        expect(await bundle.notas.getNota(1, 4, 3, 16), isNull);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('getAll filtra por color', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.notas.upsert(1, 4, 3, 16, 'a', NotaColor.amarillo);
        await bundle.notas.upsert(1, 4, 3, 17, 'b', NotaColor.verde);
        await bundle.notas.upsert(1, 4, 3, 18, 'c', NotaColor.amarillo);
        final amarillas = await bundle.notas.getAll(color: NotaColor.amarillo);
        expect(amarillas, hasLength(2));
        expect(amarillas.every((n) => n.color == NotaColor.amarillo), isTrue);
        final verdes = await bundle.notas.getAll(color: NotaColor.verde);
        expect(verdes, hasLength(1));
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
        // libro 4 es de v1; intentar crear nota con v=2, libro_id=4
        expect(
          () => bundle.notas.upsert(2, 4, 3, 16, 'x', NotaColor.ninguno),
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

    test('upsert actualiza fecha_modificacion', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.notas.upsert(1, 4, 3, 16, 'v1', NotaColor.ninguno);
        final n1 = await bundle.notas.getNota(1, 4, 3, 16);
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        await bundle.notas.upsert(1, 4, 3, 16, 'v2', NotaColor.ninguno);
        final n2 = await bundle.notas.getNota(1, 4, 3, 16);
        expect(
          n2!.fechaModificacion.isAfter(n1!.fechaModificacion),
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

    test('watchAll emite estado inicial y luego del upsert', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final emissions = <List<Nota>>[];
        final secondEmission = Completer<List<Nota>>();
        final sub = bundle.notas.watchAll().listen((value) {
          emissions.add(value);
          if (emissions.length == 2 && !secondEmission.isCompleted) {
            secondEmission.complete(value);
          }
        });

        while (emissions.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(emissions.first, isEmpty);

        await bundle.notas.upsert(1, 4, 3, 16, 'x', NotaColor.ninguno);
        final second = await secondEmission.future.timeout(
          const Duration(seconds: 2),
        );
        expect(second, hasLength(1));

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
