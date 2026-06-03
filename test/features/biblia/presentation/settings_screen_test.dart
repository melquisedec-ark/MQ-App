import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/application/providers/historial_provider.dart';
import 'package:mqapp/features/biblia/application/providers/notas_provider.dart';
import 'package:mqapp/features/biblia/data/models/biblia_version.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_config_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:mqapp/features/biblia/presentation/screens/settings_screen.dart';

import '../helpers/bible_db_test_helper.dart';

/// Construye un `MaterialApp` con el SettingsScreen y un `ProviderScope`
/// que override los providers que necesitan BD.
Widget _buildHarness({
  required BibliaRepository bibliaRepo,
  required FavoritosRepository favRepo,
  required NotasRepository notasRepo,
  required HistorialRepository histRepo,
  required BibleDatabaseHelper helper,
  required BibliaConfigRepository configRepo,
  List<BibliaVersion> versions = const [
    BibliaVersion(
      id: 1,
      nombre: 'Reina Valera 1909',
      abreviatura: 'RVR1909',
      idioma: 'es',
    ),
    BibliaVersion(
      id: 2,
      nombre: 'Reina Valera 1569',
      abreviatura: 'RVR1569',
      idioma: 'es',
    ),
  ],
}) {
  return ProviderScope(
    overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(helper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      bibliaConfigRepositoryProvider.overrideWithValue(configRepo),
      activeBibliaVersionsProvider.overrideWith((_) async => versions),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  late Database db;
  late BibliaRepository bibliaRepo;
  late FavoritosRepository favRepo;
  late NotasRepository notasRepo;
  late HistorialRepository histRepo;
  late BibliaConfigRepository configRepo;
  late BibleDatabaseHelper helper;

  setUp(() async {
    final bundle = await createBibleReposWithSeed();
    db = bundle.db;
    bibliaRepo = bundle.biblia;
    favRepo = bundle.favoritos;
    notasRepo = bundle.notas;
    histRepo = bundle.historial;
    helper = BibleDatabaseHelper.forTesting(db);
    configRepo = BibliaConfigRepository(helper);
  });

  tearDown(() async {
    await closeBibleRepos(
      db: db,
      favoritos: favRepo,
      notas: notasRepo,
      historial: histRepo,
    );
    await configRepo.dispose();
  });

  testWidgets('renders all four sections and defaults', (tester) async {
    // Set a tall surface so all 4 sections are visible without scrolling.
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        helper: helper,
        configRepo: configRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Sections visible
    expect(find.text('BIBLIA'), findsOneWidget);
    expect(find.text('EMISOR'), findsOneWidget);
    expect(find.text('APARIENCIA'), findsOneWidget);
    expect(find.text('ACERCA DE'), findsOneWidget);

    // Specific labels
    expect(find.text('Versión por defecto'), findsOneWidget);
    expect(find.text('Registrar historial'), findsOneWidget);
    expect(find.text('Color de nota por defecto'), findsOneWidget);
    expect(find.text('Modo de vista del emisor'), findsOneWidget);
    expect(find.text('Tema de la aplicación'), findsOneWidget);
    expect(find.text('Acerca de MQ-App'), findsOneWidget);
  });

  testWidgets('toggling auto-historial persists to config table',
      (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        helper: helper,
        configRepo: configRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Initial: default is true. Tap to turn off.
    final switchFinder = find.byType(Switch).first;
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify persisted
    final stored = await configRepo.getBool(
      BibliaConfigKeys.autoHistorial,
      defaultValue: true,
    );
    expect(stored, isFalse,
        reason: 'auto_historial debería haberse guardado como false');
  });

  testWidgets('changing emitter view mode persists to config table',
      (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        helper: helper,
        configRepo: configRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Default is "compact". Tap "Preview" segment.
    final previewSegment = find.text('Preview');
    expect(previewSegment, findsOneWidget);
    await tester.tap(previewSegment);
    await tester.pumpAndSettle();

    final stored = await configRepo.get(
      BibliaConfigKeys.emitterViewModeDefault,
      defaultValue: 'compact',
    );
    expect(stored, equals('preview'));
  });
}
