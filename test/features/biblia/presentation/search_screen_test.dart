import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/cross_referencias_provider.dart';
import 'package:mqapp/features/biblia/application/providers/derived_providers.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/application/providers/historial_provider.dart';
import 'package:mqapp/features/biblia/application/providers/notas_provider.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/cross_referencias_repository.dart';
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
  required CrossReferenciasRepository crossRefsRepo,
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
      crossReferenciasRepositoryProvider.overrideWithValue(crossRefsRepo),
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
  late CrossReferenciasRepository crossRefsRepo;
  late BibleDatabaseHelper helper;

  setUp(() async {
    final bundle = await createBibleReposWithSeed();
    db = bundle.db;
    bibliaRepo = bundle.biblia;
    favRepo = bundle.favoritos;
    notasRepo = bundle.notas;
    histRepo = bundle.historial;
    searchRepo = bundle.search;
    crossRefsRepo = bundle.crossRefs;
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
        crossRefsRepo: crossRefsRepo,
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

    // Buscar "Dios" (aparece en Génesis 1:1, 1:2 y Juan 3:16, 3:17, 3:18)
    await tester.enterText(find.byType(TextField), 'Dios');
    // Esperar el debounce (300ms) + la búsqueda
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Debe mostrar el contador de resultados.
    expect(find.textContaining('resultado'), findsOneWidget);
    // Y al menos un hit visible (el ListView es lazy, así que solo
    // los primeros items están en el árbol. En el seed, "Gn 1:1"
    // siempre es uno de los primeros).
    expect(find.text('Gn 1:1'), findsOneWidget);
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

  // ─────────────────────────────────────────────────────────────
  // C9: tab de Referencias
  // ─────────────────────────────────────────────────────────────

  testWidgets('TabBar muestra "Versículos" y "Referencias"', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Ambos tabs visibles.
    expect(find.text('Versículos'), findsOneWidget);
    expect(find.text('Referencias'), findsOneWidget);
  });

  testWidgets('Tab Referencias: query vacío muestra hint', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Tap en la tab Referencias.
    await tester.tap(find.text('Referencias'));
    await tester.pumpAndSettle();

    // El hint específico de referencias es visible.
    expect(
      find.textContaining('Escribe una referencia destino'),
      findsOneWidget,
    );
  });

  testWidgets('Tab Referencias: Génesis 22:12 retorna versículos que la citan',
      (tester) async {
    // Sembrar cross-refs: Juan 3:16 → Génesis 22:12-14 (5 votos).
    await seedCrossReferenciasTestDb(db);

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Tap en la tab Referencias.
    await tester.tap(find.text('Referencias'));
    await tester.pumpAndSettle();

    // Buscar el destino "Génesis 22:12".
    await tester.enterText(find.byType(TextField), 'Génesis 22:12');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Debug
    final allText = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .where((t) => t != null)
        .toList();
    debugPrint('Text widgets: $allText');

    // El resultado debe mostrar que Juan 3:16 cita Génesis 22:12.
    expect(find.text('Jn 3:16'), findsOneWidget);
    // Y el header "1 versículo cita a Génesis 22:12" (1 sola ref en el seed).
    expect(
      find.textContaining('cita a Génesis 22:12'),
      findsOneWidget,
    );
  });

  testWidgets('Tab Referencias: formato inválido muestra error',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Tap en la tab Referencias.
    await tester.tap(find.text('Referencias'));
    await tester.pumpAndSettle();

    // Formato inválido (sin ":versiculo").
    await tester.enterText(find.byType(TextField), 'juan');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // El hint de formato inválido es visible.
    expect(
      find.textContaining('Formato inválido'),
      findsOneWidget,
    );
  });
}
