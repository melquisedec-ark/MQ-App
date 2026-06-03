import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_libro_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_versiculo_provider.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/application/providers/historial_provider.dart';
import 'package:mqapp/features/biblia/application/providers/notas_provider.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_config_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:mqapp/features/biblia/presentation/screens/bible_reader_screen.dart';

import '../helpers/bible_db_test_helper.dart';

/// Helper: cuenta las filas de historial_versiculo.
Future<int> _countHistorialRows(Database db) async {
  final rows = await db.query('historial_versiculo');
  return rows.length;
}

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  group('B2: Bible reader respeta toggle autoHistorial', () {
    late Database db;
    late BibliaRepository bibliaRepo;
    late BibliaSearchRepository searchRepo;
    late FavoritosRepository favRepo;
    late NotasRepository notasRepo;
    late HistorialRepository histRepo;
    late BibliaConfigRepository configRepo;
    late BibleDatabaseHelper helper;

    setUp(() async {
      final bundle = await createBibleReposWithSeed();
      db = bundle.db;
      bibliaRepo = bundle.biblia;
      searchRepo = bundle.search;
      favRepo = bundle.favoritos;
      notasRepo = bundle.notas;
      histRepo = bundle.historial;
      helper = BibleDatabaseHelper.forTesting(db);
      configRepo = BibliaConfigRepository(helper);
    });

    tearDown(() async {
      await configRepo.dispose();
      await closeBibleRepos(
        db: db,
        favoritos: favRepo,
        notas: notasRepo,
        historial: histRepo,
      );
    });

    /// Construye el harness. El toggle se setea ANTES de crear el provider.
    /// Usamos el provider real (sin override) pero pre-sembramos el valor
    /// en BD para que el load async del notifier lo encuentre.
    Widget buildHarness({required bool autoHistorial}) {
      return ProviderScope(
        overrides: <Override>[
          bibleDatabaseHelperProvider.overrideWithValue(helper),
          bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
          favoritosRepositoryProvider.overrideWithValue(favRepo),
          notasRepositoryProvider.overrideWithValue(notasRepo),
          historialRepositoryProvider.overrideWithValue(histRepo),
          bibliaConfigRepositoryProvider.overrideWithValue(configRepo),
        ],
        child: MaterialApp(
          home: BibleReaderScreen(libroId: 1, capitulo: 1),
        ),
      );
    }

    /// Espera a que el `autoHistorialProvider` emita el [expected].
    ///
    /// Polling con [tester.pump] en lugar de timers para no contaminar
    /// el árbol con timers pendientes.
    Future<void> _waitForAutoHistorial(
      WidgetTester tester,
      ProviderContainer container,
      bool expected,
    ) async {
      // El provider se crea cuando se lee por primera vez.
      container.read(autoHistorialProvider);
      for (var i = 0; i < 30; i++) {
        if (container.read(autoHistorialProvider) == expected) return;
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets(
        'con auto_historial=true: navegar versículos registra en historial',
        (tester) async {
      await configRepo.setBool(BibliaConfigKeys.autoHistorial, true);

      await tester.pumpWidget(buildHarness(autoHistorial: true));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BibleReaderScreen)),
      );
      await _waitForAutoHistorial(tester, container, true);

      final baseline = await _countHistorialRows(db);

      container.read(currentVersiculoNumeroProvider.notifier).state = 2;
      await tester.pumpAndSettle();

      final after = await _countHistorialRows(db);
      expect(after, baseline + 1,
          reason: 'con toggle activo, cambiar versículo debe registrar');
    });

    testWidgets(
        'con auto_historial=false: navegar versículos NO registra',
        (tester) async {
      await configRepo.setBool(BibliaConfigKeys.autoHistorial, false);

      await tester.pumpWidget(buildHarness(autoHistorial: false));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BibleReaderScreen)),
      );
      await _waitForAutoHistorial(tester, container, false);

      final baseline = await _countHistorialRows(db);

      container.read(currentVersiculoNumeroProvider.notifier).state = 2;
      await tester.pumpAndSettle();
      container.read(currentVersiculoNumeroProvider.notifier).state = 3;
      await tester.pumpAndSettle();

      final after = await _countHistorialRows(db);
      expect(after, baseline,
          reason: 'B2: con toggle desactivado, ningún cambio debe registrar');
    });

    testWidgets(
        'cambiar toggle en runtime: vuelve a registrar al activarlo',
        (tester) async {
      await configRepo.setBool(BibliaConfigKeys.autoHistorial, false);

      await tester.pumpWidget(buildHarness(autoHistorial: false));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BibleReaderScreen)),
      );
      await _waitForAutoHistorial(tester, container, false);

      final baseline = await _countHistorialRows(db);

      // Cambio a v2 sin registrar (toggle off).
      container.read(currentVersiculoNumeroProvider.notifier).state = 2;
      await tester.pumpAndSettle();
      expect(await _countHistorialRows(db), baseline);

      // Cambio a v3 sin registrar (toggle off).
      container.read(currentVersiculoNumeroProvider.notifier).state = 3;
      await tester.pumpAndSettle();
      expect(await _countHistorialRows(db), baseline);

      // Activo el toggle.
      await container
          .read(autoHistorialProvider.notifier)
          .setEnabled(true);
      await _waitForAutoHistorial(tester, container, true);

      // Cambio a v4 → ahora debe registrar.
      container.read(currentVersiculoNumeroProvider.notifier).state = 4;
      await tester.pumpAndSettle();
      expect(await _countHistorialRows(db), baseline + 1,
          reason: 'tras activar toggle, debe volver a registrar');
    });
  });
}

/// Helper no usado (eliminado: ahora se hace polling en _waitForAutoHistorial).
