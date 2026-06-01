import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/features/biblia/data/models/historial_item.dart';

import '../../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  tearDownAll(() => cleanupBibleTestDatabases());

  group('HistorialRepository', () {
    test('record inserta un item con timestamp', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final before = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        final id = await bundle.historial.record(1, 4, 3, 16);
        final after = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        expect(id, isPositive);
        final all = await bundle.historial.getAll();
        expect(all, hasLength(1));
        expect(all.first.id, id);
        // El timestamp debe estar entre before y after
        expect(
          all.first.fechaLectura.millisecondsSinceEpoch ~/ 1000,
          inInclusiveRange(before, after),
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

    test('getAll ordena por fecha_lectura DESC', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.historial.record(1, 4, 3, 16);
        await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
        await bundle.historial.record(1, 4, 3, 17);
        await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
        await bundle.historial.record(1, 4, 3, 18);
        final all = await bundle.historial.getAll();
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

    test('getAll incluye datos joined del libro y versículo', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.historial.record(1, 4, 3, 16);
        final all = await bundle.historial.getAll();
        expect(all, hasLength(1));
        expect(all.first.libroNombre, 'Juan');
        expect(all.first.libroAbreviatura, 'Jn');
        expect(all.first.texto, contains('Porque de tal manera amó Dios'));
        expect(all.first.referencia, 'Jn 3:16');
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('getAll filtra por versionId y respeta el limit', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.historial.record(1, 4, 3, 16);
        await bundle.historial.record(1, 4, 3, 17);
        // No intentamos a v2 porque el cap 3 de libro 5 está vacío
        // (y la FK se rompería).
        final v1 = await bundle.historial.getAll(versionId: 1);
        expect(v1, hasLength(2));
        final limited = await bundle.historial.getAll(limit: 1);
        expect(limited, hasLength(1));
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('remove elimina por id', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final id = await bundle.historial.record(1, 4, 3, 16);
        final removed = await bundle.historial.remove(id);
        expect(removed, 1);
        expect(await bundle.historial.getAll(), isEmpty);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('clear elimina todo el historial', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.historial.record(1, 4, 3, 16);
        await bundle.historial.record(1, 4, 3, 17);
        await bundle.historial.record(1, 4, 3, 18);
        final cleared = await bundle.historial.clear();
        expect(cleared, 3);
        expect(await bundle.historial.getAll(), isEmpty);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('record no es idempotente: cada llamada crea una fila', () async {
      // El historial es append-only por diseño (se quieren contar lecturas
      // individuales para stats de "más leídos").
      final bundle = await createBibleReposWithSeed();
      try {
        await bundle.historial.record(1, 4, 3, 16);
        await bundle.historial.record(1, 4, 3, 16);
        await bundle.historial.record(1, 4, 3, 16);
        final all = await bundle.historial.getAll();
        expect(all, hasLength(3));
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('watchAll emite estado inicial y luego del record', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final emissions = <List<HistorialItem>>[];
        final secondEmission = Completer<List<HistorialItem>>();
        final sub = bundle.historial.watchAll().listen((value) {
          emissions.add(value);
          if (emissions.length == 2 && !secondEmission.isCompleted) {
            secondEmission.complete(value);
          }
        });

        while (emissions.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(emissions.first, isEmpty);

        await bundle.historial.record(1, 4, 3, 16);
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
