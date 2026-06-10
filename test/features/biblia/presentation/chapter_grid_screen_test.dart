import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/application/providers/historial_provider.dart';
import 'package:mqapp/features/biblia/application/providers/notas_provider.dart';
import 'package:mqapp/features/biblia/data/models/favorito_versiculo.dart';
import 'package:mqapp/features/biblia/data/models/historial_item.dart';
import 'package:mqapp/features/biblia/data/models/nota.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:mqapp/features/biblia/presentation/screens/chapter_grid_screen.dart';
import 'package:mqapp/presentation/dual_mode_wrapper/dual_mode_providers.dart';
import 'package:mqapp/presentation/dual_mode_wrapper/device_mode.dart';

import '../helpers/bible_db_test_helper.dart';

Widget _buildHarness({
  required BibliaRepository bibliaRepo,
  required FavoritosRepository favRepo,
  required NotasRepository notasRepo,
  required HistorialRepository histRepo,
  required BibliaSearchRepository searchRepo,
  required BibleDatabaseHelper helper,
  int libroId = 1, // Génesis (50 capítulos)
}) {
  return ProviderScope(
    overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(helper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      favoritosStreamProvider.overrideWith((_) async* {
        yield const <FavoritoVersiculo>[];
      }),
      notasStreamProvider.overrideWith((_) async* {
        yield const <Nota>[];
      }),
      historialStreamProvider.overrideWith((_) async* {
        yield const <HistorialItem>[];
      }),
      deviceModeProvider.overrideWith((ref) {
        final notifier = DualModeNotifier();
        notifier.setMode(DeviceMode.phone);
        return notifier;
      }),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/biblia/libro/$libroId',
        routes: <RouteBase>[
          GoRoute(
            path: '/biblia/libro/:libroId',
            builder: (_, state) {
              final id = int.parse(state.pathParameters['libroId']!);
              return ChapterGridScreen(libroId: id);
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'capitulo/:capitulo',
                name: 'biblia_reader',
                builder: (_, __) => const Scaffold(
                  body: Text('reader-stub'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
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
  late BibliaSearchRepository searchRepo;
  late BibleDatabaseHelper helper;

  setUp(() async {
    final bundle = await createBibleReposWithSeed();
    db = bundle.db;
    bibliaRepo = bundle.biblia;
    favRepo = bundle.favoritos;
    notasRepo = bundle.notas;
    histRepo = bundle.historial;
    searchRepo = bundle.search;
    helper = BibleDatabaseHelper.forTesting(db);
  });

  tearDown(() async {
    await closeBibleRepos(
      db: db,
      favoritos: favRepo,
      notas: notasRepo,
      historial: histRepo,
    );
  });

  Widget buildHarness({int libroId = 1}) => _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        helper: helper,
        libroId: libroId,
      );

  testWidgets('muestra grid con capítulos para Génesis', (tester) async {
    await tester.pumpWidget(buildHarness(libroId: 1));
    await tester.pumpAndSettle();

    // El título del AppBar debe ser "Génesis"
    expect(find.text('Génesis'), findsOneWidget);
    // El subtítulo "Selecciona un capítulo" está visible
    expect(find.text('Selecciona un capítulo'), findsOneWidget);
    // Los capítulos del seed son 1 y 2 (total 2 caps en el seed)
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('muestra Juan en el AppBar', (tester) async {
    await tester.pumpWidget(buildHarness(libroId: 4));
    await tester.pumpAndSettle();

    expect(find.text('Juan'), findsOneWidget);
    // El capítulo 3 de Juan está seed
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('muestra botón "Capítulo aleatorio"', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('Capítulo aleatorio'), findsOneWidget);
  });
}
