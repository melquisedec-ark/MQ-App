import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/cross_referencias_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_libro_provider.dart';
import 'package:mqapp/features/biblia/data/repositories/cross_referencias_repository.dart';

import '../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  tearDownAll(() => cleanupBibleTestDatabases());

  group('CrossRefQuery', () {
    test('equality: misma cuádrupla → iguales', () {
      const a = CrossRefQuery(libroId: 1, capitulo: 1, versiculo: 1);
      const b = CrossRefQuery(libroId: 1, capitulo: 1, versiculo: 1);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality: cambia versiculo → diferentes', () {
      const a = CrossRefQuery(libroId: 1, capitulo: 1, versiculo: 1);
      const b = CrossRefQuery(libroId: 1, capitulo: 1, versiculo: 2);
      expect(a, isNot(equals(b)));
    });

    test('inequality: cambia libro → diferentes', () {
      const a = CrossRefQuery(libroId: 1, capitulo: 1, versiculo: 1);
      const b = CrossRefQuery(libroId: 2, capitulo: 1, versiculo: 1);
      expect(a, isNot(equals(b)));
    });
  });

  group('crossReferenciasProvider', () {
    test('retorna refs para una query válida (Juan 3:16)', () async {
      final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
      try {
        final providerContainer = ProviderContainer(
          overrides: [
            bibleDatabaseHelperProvider.overrideWithValue(
              BibleDatabaseHelper.forTesting(bundle.db),
            ),
          ],
        );
        addTearDown(providerContainer.dispose);

        // Asegurar version_id=1
        final versionId = providerContainer.read(currentVersionIdProvider);

        const query = CrossRefQuery(
          libroId: 4, // Juan
          capitulo: 3,
          versiculo: 16,
        );
        final refs =
            await providerContainer.read(crossReferenciasProvider(query).future);
        expect(refs, hasLength(3));
        // Orden canónico: Gn(1) → Jn(43) → 1Jn(62)
        expect(refs[0].toLibroId, 1);
        expect(refs[2].toLibroId, 6);
        expect(versionId, 1); // sanity
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('retorna lista vacía para versículo sin refs', () async {
      final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
      try {
        final providerContainer = ProviderContainer(
          overrides: [
            bibleDatabaseHelperProvider.overrideWithValue(
              BibleDatabaseHelper.forTesting(bundle.db),
            ),
          ],
        );
        addTearDown(providerContainer.dispose);

        const query = CrossRefQuery(
          libroId: 4, // Juan
          capitulo: 3,
          versiculo: 99, // no existe en el seed
        );
        final refs =
            await providerContainer.read(crossReferenciasProvider(query).future);
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

    test('se invalida al cambiar currentVersionIdProvider', () async {
      final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
      try {
        final providerContainer = ProviderContainer(
          overrides: [
            bibleDatabaseHelperProvider.overrideWithValue(
              BibleDatabaseHelper.forTesting(bundle.db),
            ),
          ],
        );
        addTearDown(providerContainer.dispose);

        const query = CrossRefQuery(
          libroId: 4, capitulo: 3, versiculo: 16,
        );

        // Primera lectura: v1, debe tener 3 refs.
        final first = await providerContainer
            .read(crossReferenciasProvider(query).future);
        expect(first, hasLength(3));

        // Cambiar version_id. Como no hay refs para v2, debe re-emitir [].
        providerContainer.read(currentVersionIdProvider.notifier).state = 2;

        // Leer de nuevo: invalidation por cambio de versionId debe
        // haber disparado una nueva query (v2, sin refs).
        final second = await providerContainer
            .read(crossReferenciasProvider(query).future);
        expect(second, isEmpty);
      } finally {
        await closeBibleRepos(
          db: bundle.db,
          favoritos: bundle.favoritos,
          notas: bundle.notas,
          historial: bundle.historial,
        );
      }
    });

    test('autoDispose: dos consumers con misma query comparten cache',
        () async {
      // Aunque autoDispose libera cuando no hay listeners, mientras hay
      // >=1 listener activo, dos consumidores con la misma query deben
      // recibir los mismos datos (cache hit).
      final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
      try {
        final providerContainer = ProviderContainer(
          overrides: [
            bibleDatabaseHelperProvider.overrideWithValue(
              BibleDatabaseHelper.forTesting(bundle.db),
            ),
          ],
        );
        addTearDown(providerContainer.dispose);

        const query = CrossRefQuery(
          libroId: 4, capitulo: 3, versiculo: 16,
        );

        final a = await providerContainer
            .read(crossReferenciasProvider(query).future);
        final b = await providerContainer
            .read(crossReferenciasProvider(query).future);
        expect(a, hasLength(3));
        expect(b, hasLength(3));
        // Mismas refs (mismo id)
        expect(a.map((r) => r.id).toList(), b.map((r) => r.id).toList());
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

  group('crossReferenciasCountProvider', () {
    test('retorna 3 para Juan 3:16', () async {
      final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
      try {
        final providerContainer = ProviderContainer(
          overrides: [
            bibleDatabaseHelperProvider.overrideWithValue(
              BibleDatabaseHelper.forTesting(bundle.db),
            ),
          ],
        );
        addTearDown(providerContainer.dispose);

        const query = CrossRefQuery(
          libroId: 4, capitulo: 3, versiculo: 16,
        );
        final n = await providerContainer
            .read(crossReferenciasCountProvider(query).future);
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

    test('retorna 0 para versículo sin refs', () async {
      final bundle = await createBibleReposWithSeed(includeCrossRefs: true);
      try {
        final providerContainer = ProviderContainer(
          overrides: [
            bibleDatabaseHelperProvider.overrideWithValue(
              BibleDatabaseHelper.forTesting(bundle.db),
            ),
          ],
        );
        addTearDown(providerContainer.dispose);

        const query = CrossRefQuery(
          libroId: 4, capitulo: 3, versiculo: 99,
        );
        final n = await providerContainer
            .read(crossReferenciasCountProvider(query).future);
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

  group('crossReferenciasRepositoryProvider', () {
    test('devuelve un CrossReferenciasRepository usando el helper', () async {
      final bundle = await createBibleReposWithSeed();
      try {
        final providerContainer = ProviderContainer(
          overrides: [
            bibleDatabaseHelperProvider.overrideWithValue(
              BibleDatabaseHelper.forTesting(bundle.db),
            ),
          ],
        );
        addTearDown(providerContainer.dispose);

        final repo = providerContainer.read(
          crossReferenciasRepositoryProvider,
        );
        expect(repo, isA<CrossReferenciasRepository>());
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
