import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/application/providers/historial_provider.dart';
import 'package:mqapp/features/biblia/application/providers/notas_provider.dart';
import 'package:mqapp/features/biblia/application/providers/random_versiculo_provider.dart';
import 'package:mqapp/features/biblia/data/models/biblia_version.dart';
import 'package:mqapp/features/biblia/data/models/favorito_versiculo.dart';
import 'package:mqapp/features/biblia/data/models/historial_item.dart';
import 'package:mqapp/features/biblia/data/models/nota.dart';
import 'package:mqapp/features/biblia/data/models/versiculo_contexto.dart';
import 'package:mqapp/features/biblia/data/models/versiculo.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:mqapp/features/biblia/presentation/screens/home_screen.dart';
import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common/sqflite.dart';

import '../helpers/bible_db_test_helper.dart';

/// Crea un `Widget` con un `GoRouter` mínimo + `ProviderScope` con overrides
/// para que el HomeScreen pueda renderizar sin tocar la BD real.
Widget _buildTestHarness({
  required BibliaRepository bibliaRepo,
  required FavoritosRepository favRepo,
  required NotasRepository notasRepo,
  required HistorialRepository histRepo,
  required BibliaSearchRepository searchRepo,
  required VersiculoContexto? randomVerse,
  required List<BibliaVersion> versions,
  required List<FavoritoVersiculo> favoritos,
  required List<Nota> notas,
  required List<HistorialItem> historial,
  required BibleDatabaseHelper dbHelper,
  String initialLocation = '/',
}) {
  return ProviderScope(
    overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(dbHelper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      activeBibliaVersionsProvider.overrideWith((_) async => versions),
      randomVersiculoProvider.overrideWith((_) async => randomVerse),
      // Streams: los devolvemos pre-poblados como valor inicial.
      favoritosStreamProvider.overrideWith((_) async* {
        yield favoritos;
      }),
      notasStreamProvider.overrideWith((_) async* {
        yield notas;
      }),
      historialStreamProvider.overrideWith((_) async* {
        yield historial;
      }),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: initialLocation,
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (_, __) => const HomeScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'config',
                name: 'config',
                builder: (_, __) =>
                    const Scaffold(body: Text('config-screen-stub')),
              ),
              GoRoute(
                path: 'connect',
                name: 'connect',
                builder: (_, __) =>
                    const Scaffold(body: Text('connect-screen-stub')),
              ),
              GoRoute(
                path: 'biblia',
                name: 'biblia',
                builder: (_, __) =>
                    const Scaffold(body: Text('biblia-screen-stub')),
              ),
              GoRoute(
                path: 'himnario',
                name: 'himnario',
                builder: (_, __) =>
                    const Scaffold(body: Text('himnario-screen-stub')),
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

  const bibliaVersion = BibliaVersion(
    id: 1,
    nombre: 'Reina Valera 1909',
    abreviatura: 'RVR1909',
    idioma: 'es',
  );

  const randomVerse = VersiculoContexto(
    versiculo: Versiculo(
      id: 1,
      capituloId: 1,
      numero: 1,
      texto: 'En el principio creó Dios los cielos y la tierra.',
    ),
    versionId: 1,
    libroNombre: 'Génesis',
    libroAbreviatura: 'Gn',
    libroNumero: 1,
    capituloNumero: 1,
  );

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

  Widget buildHarness() => _buildTestHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        randomVerse: randomVerse,
        versions: const [bibliaVersion],
        favoritos: const <FavoritoVersiculo>[],
        notas: const <Nota>[],
        historial: const <HistorialItem>[],
        dbHelper: helper,
      );

  testWidgets('muestra estado vacío cuando el versículo es null',
      (tester) async {
    await tester.pumpWidget(_buildTestHarness(
      bibliaRepo: bibliaRepo,
      favRepo: favRepo,
      notasRepo: notasRepo,
      histRepo: histRepo,
      searchRepo: searchRepo,
      randomVerse: null,
      versions: const [bibliaVersion],
      favoritos: const <FavoritoVersiculo>[],
      notas: const <Nota>[],
      historial: const <HistorialItem>[],
      dbHelper: helper,
    ),);
    await tester.pumpAndSettle();

    // El versículo card muestra el estado vacío
    expect(
      find.textContaining('No hay versículos disponibles'),
      findsOneWidget,
    );
    // Pero los 2 cards principales siguen visibles
    expect(find.text('BIBLIA'), findsOneWidget);
    expect(find.text('HIMNARIO'), findsOneWidget);
  });

  testWidgets('tap en card BIBLIA navega a /biblia', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('BIBLIA'));
    await tester.pumpAndSettle();

    expect(find.text('biblia-screen-stub'), findsOneWidget);
  });
}
