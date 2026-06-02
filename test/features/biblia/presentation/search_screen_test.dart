import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_libro_provider.dart';
import 'package:mqapp/features/biblia/application/providers/derived_providers.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/application/providers/historial_provider.dart';
import 'package:mqapp/features/biblia/application/providers/notas_provider.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:mqapp/features/biblia/presentation/screens/search_screen.dart';

import '../helpers/bible_db_test_helper.dart';

Widget _buildHarness({
  required BibliaRepository bibliaRepo,
  required FavoritosRepository favRepo,
  required NotasRepository notasRepo,
  required HistorialRepository histRepo,
  required BibliaSearchRepository searchRepo,
  required BibleDatabaseHelper helper,
}) {
  return ProviderScope(
    overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(helper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      bibliaSearchRepositoryProvider.overrideWithValue(searchRepo),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/biblia/search',
        routes: <RouteBase>[
          GoRoute(
            path: '/biblia',
            builder: (_, __) => const Scaffold(
              body: Text('biblia-stub'),
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'search',
                name: 'biblia_search',
                builder: (_, __) => const SearchScreen(),
              ),
              GoRoute(
                path: 'libro/:libroId/capitulo/:capitulo',
                name: 'biblia_reader',
                builder: (_, state) {
                  final id = int.parse(state.pathParameters['libroId']!);
                  final cap = int.parse(state.pathParameters['capitulo']!);
                  return Scaffold(body: Text('reader-$id-$cap'));
                },
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

  Widget buildHarness() => _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        helper: helper,
      );

  testWidgets('muestra hint inicial cuando el query está vacío',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(
      find.text('Escribe palabras para buscar versículos'),
      findsOneWidget,
    );
  });

  testWidgets('muestra resultados al buscar un término existente',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Buscar "Dios" (aparece en Juan 3:16 y 3:17 del seed)
    await tester.enterText(find.byType(TextField), 'Dios');
    // Esperar el debounce (300ms) + la búsqueda
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Debe mostrar el contador de resultados
    expect(find.textContaining('resultado'), findsOneWidget);
    // Y la referencia del primer hit
    expect(find.text('Jn 3:16'), findsOneWidget);
  });

  testWidgets('muestra empty state cuando no hay resultados',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Buscar algo que no existe en el seed
    await tester.enterText(find.byType(TextField), 'xyzzyx');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(
      find.text('No se encontraron versículos para "xyzzyx"'),
      findsOneWidget,
    );
  });
}
