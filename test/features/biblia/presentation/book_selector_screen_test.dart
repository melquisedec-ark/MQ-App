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
import 'package:mqapp/features/biblia/presentation/screens/book_selector_screen.dart';
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
  required List<FavoritoVersiculo> favoritos,
  required List<Nota> notas,
  required List<HistorialItem> historial,
  String initialLocation = '/biblia',
}) {
  return ProviderScope(
    overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(helper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      favoritosStreamProvider.overrideWith((_) async* {
        yield favoritos;
      }),
      notasStreamProvider.overrideWith((_) async* {
        yield notas;
      }),
      historialStreamProvider.overrideWith((_) async* {
        yield historial;
      }),
      // Forzar phone mode para tests (lista simple, no grid desktop)
      deviceModeProvider.overrideWith((ref) {
        final notifier = DualModeNotifier();
        notifier.setMode(DeviceMode.phone);
        return notifier;
      }),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: initialLocation,
        routes: <RouteBase>[
          GoRoute(
            path: '/biblia',
            builder: (_, __) => const BookSelectorScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'libro/:libroId',
                name: 'biblia_libro',
                builder: (_, __) => const Scaffold(
                  body: Text('chapter-grid-stub'),
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

  Widget buildHarness({
    List<FavoritoVersiculo>? favoritos,
    List<Nota>? notas,
    List<HistorialItem>? historial,
  }) =>
      _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        helper: helper,
        favoritos: favoritos ?? const <FavoritoVersiculo>[],
        notas: notas ?? const <Nota>[],
        historial: historial ?? const <HistorialItem>[],
      );

  testWidgets('muestra 5 tabs: AT, NT, Favoritos, Notas, Historial',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('AT'), findsOneWidget);
    expect(find.text('NT'), findsOneWidget);
    expect(find.text('⭐ Favoritos'), findsOneWidget);
    expect(find.text('📝 Notas'), findsOneWidget);
    expect(find.text('🕐 Historial'), findsOneWidget);
  });

  testWidgets('tab AT muestra Génesis como primer libro', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // El tab AT es el default
    expect(find.text('Génesis'), findsOneWidget);
    expect(find.textContaining('50 capítulos'), findsWidgets);
  });

  testWidgets('tab Favoritos muestra empty state', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('⭐ Favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes favoritos'), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });

  testWidgets('tab Favoritos muestra favoritos cuando hay', (tester) async {
    final fav = FavoritoVersiculo(
      id: 1,
      versionId: 1,
      libroId: 1,
      capitulo: 1,
      numero: 1,
      fechaAgregado: DateTime.now(),
    );
    await tester.pumpWidget(buildHarness(favoritos: [fav]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('⭐ Favoritos'));
    await tester.pumpAndSettle();

    // La referencia Génesis 1:1 debería aparecer
    expect(find.textContaining('Gn 1:1'), findsOneWidget);
  });

  testWidgets('tab Notas muestra empty state', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('📝 Notas'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes notas'), findsOneWidget);
  });

  testWidgets('tab Historial muestra empty state', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('🕐 Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Tu historial está vacío'), findsOneWidget);
  });
}
