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
import 'package:mqapp/features/biblia/application/providers/reader_providers.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/models/nota.dart';
import 'package:mqapp/features/biblia/presentation/widgets/verse_card.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:mqapp/features/biblia/presentation/screens/bible_reader_screen.dart';
import 'package:mqapp/presentation/views_projection/providers/connection_providers.dart';

import '../helpers/bible_db_test_helper.dart';

Widget _buildHarness({
  required BibliaRepository bibliaRepo,
  required FavoritosRepository favRepo,
  required NotasRepository notasRepo,
  required HistorialRepository histRepo,
  required BibliaSearchRepository searchRepo,
  required BibleDatabaseHelper helper,
  int libroId = 1,
  int capitulo = 1,
  bool isConnected = false,
  BibleReaderViewMode initialViewMode = BibleReaderViewMode.chapter,
}) {
  return ProviderScope(
    overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(helper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      favoritosStreamProvider.overrideWith((_) => favRepo.watchAll()),
      notasStreamProvider.overrideWith((_) => notasRepo.watchAll()),
      historialStreamProvider.overrideWith((_) => histRepo.watchAll()),
      // Override directo: no requiere instanciar ConnectionNotifier
      // (que abriría sockets reales en el constructor de GrpcControlDataSource).
      isConnectedProvider.overrideWith((_) => isConnected),
      readerViewModeProvider.overrideWith(
        (ref) {
          final notifier = ReaderViewModeNotifier(ref);
          // Override sincrónico: no depende de async setViewMode
          notifier.state = initialViewMode;
          return notifier;
        },
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/biblia/libro/$libroId/capitulo/$capitulo',
        routes: <RouteBase>[
          GoRoute(
            path: '/biblia',
            builder: (_, __) => const Scaffold(
              body: Text('biblia-stub'),
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'libro/:libroId',
                builder: (_, state) {
                  final id = int.parse(state.pathParameters['libroId']!);
                  return Scaffold(body: Text('libro-$id'));
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'capitulo/:capitulo',
                    name: 'biblia_reader',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['libroId']!);
                      final cap = int.parse(state.pathParameters['capitulo']!);
                      return BibleReaderScreen(libroId: id, capitulo: cap);
                    },
                  ),
                ],
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

  Widget buildHarness({int libroId = 1, int capitulo = 1, bool isConnected = false, BibleReaderViewMode initialViewMode = BibleReaderViewMode.chapter}) =>
      _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        helper: helper,
        libroId: libroId,
        capitulo: capitulo,
        isConnected: isConnected,
        initialViewMode: initialViewMode,
      );

  /// Escribe un valor en la tabla `config`. Necesario para tests que
  /// necesitan que el `ReaderViewModeNotifier` cargue el modo desde BD
  /// (su `_loadFromDb` async sobrescribe el `state` inicial del override).
  Future<void> setConfig(String clave, String valor) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await db.insert(
      'config',
      {
        'clave': clave,
        'valor': valor,
        'fecha_modificacion': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  testWidgets('muestra el título del libro y el versículo inicial',
      (tester) async {
    await tester.pumpWidget(buildHarness(libroId: 1, capitulo: 1));
    await tester.pumpAndSettle();

    // AppBar muestra "Génesis 1"
    expect(find.text('Génesis 1'), findsOneWidget);
    // Texto del versículo 1 de Génesis 1 (seed) visible en modo capítulo
    expect(
      find.textContaining('En el principio creó Dios'),
      findsOneWidget,
    );
  });

  testWidgets('avanza al siguiente versículo al pulsar la flecha derecha',
      (tester) async {
    await tester.pumpWidget(buildHarness(libroId: 1, capitulo: 1, initialViewMode: BibleReaderViewMode.verse));
    await tester.pumpAndSettle();

    // Verificar que el versículo inicial es el 1
    expect(find.textContaining('En el principio creó Dios'), findsOneWidget);

    // Pulsar el botón "Versículo siguiente" (chevron_right)
    final nextBtn = find.byTooltip('Versículo siguiente');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Ahora debe verse el versículo 2
    expect(
      find.textContaining('Y la tierra estaba desordenada'),
      findsOneWidget,
    );
  });

  testWidgets('favorito alterna desde el icono ⭐ inline en chapter view',
      (tester) async {
    // Pre-poblar config con view_mode=chapter (default).
    // (El toggle ya no está en AppBar, está en bottom bar - A1+A2.)
    await tester.pumpWidget(buildHarness(libroId: 1, capitulo: 1));
    await tester.pumpAndSettle();

    // En chapter view, el icon ⭐ aparece en cada VerseCard.
    // Inicialmente NO debe haber ningún star_rounded (sin favoritos).
    expect(find.byIcon(Icons.star_rounded), findsNothing);

    // Agregamos un favorito en BD y verificamos que aparece el star.
    await favRepo.add(1, 1, 1, 1);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    // Verificar en BD
    final favoritos = await favRepo.getAll(versionId: 1);
    expect(favoritos.length, 1);
    expect(favoritos.first.numero, 1);
  });

  testWidgets('toggle de modo lectura ahora está en el bottom bar, no en AppBar',
      (tester) async {
    await tester.pumpWidget(buildHarness(libroId: 1, capitulo: 1));
    await tester.pumpAndSettle();

    // A1+A2: el toggle NO debe estar en el AppBar.
    // El bottom bar tiene "Vista por versículo" como tooltip
    // (estamos en chapter, el botón dice a dónde switch).
    expect(find.byTooltip('Vista por versículo'), findsOneWidget);
    // El AppBar NO debe contener un IconButton con el icono de toggle.
    final appBar = find.byType(AppBar);
    final toggleIconInAppBar = find.descendant(
      of: appBar,
      matching: find.byIcon(Icons.view_agenda_outlined),
    );
    expect(toggleIconInAppBar, findsNothing);
  });

  testWidgets('abre el modal de notas en verse mode con long-press',
      (tester) async {
    // En verse mode, el menú de long-press tiene "Agregar nota".
    // (El botón inline en bottom bar fue removido en A4+D1.)
    await setConfig('biblia.reader_view_mode', 'verse');
    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ));
    await tester.pumpAndSettle();

    // Long-press sobre el texto del versículo (que es el que tiene
    // el GestureDetector con onLongPress en verse mode).
    await tester.longPress(find.text('En el principio creó Dios los cielos y la tierra.'));
    await tester.pumpAndSettle();

    // El modal debe mostrar el título "Agregar nota" o "Editar nota".
    final hasAddNote = find.text('Agregar nota').evaluate().isNotEmpty;
    final hasEditNote = find.text('Editar nota').evaluate().isNotEmpty;
    expect(hasAddNote || hasEditNote, isTrue);
  });

  testWidgets('oculta el botón ENVIAR cuando no hay display conectado',
      (tester) async {
    await tester.pumpWidget(buildHarness(libroId: 1, capitulo: 1));
    await tester.pumpAndSettle();

    // Sin conexión, el botón ENVIAR no debe renderizarse.
    expect(find.text('ENVIAR'), findsNothing);
    expect(find.byIcon(Icons.cast_rounded), findsNothing);
  });

  testWidgets('muestra el botón ENVIAR cuando hay display',
      (tester) async {
    await tester.pumpWidget(
      buildHarness(libroId: 1, capitulo: 1, isConnected: true),
    );
    await tester.pumpAndSettle();

    // Con conexión, el botón ENVIAR aparece en la AppBar.
    expect(find.text('ENVIAR'), findsOneWidget);
    expect(find.byIcon(Icons.cast_rounded), findsOneWidget);
  });

  // B1: preview de nota inline en verse mode.
  testWidgets('verse mode muestra preview de nota cuando existe',
      (tester) async {
    // Pre-poblar config con view_mode=verse (el _loadFromDb async del
    // notifier sobrescribe el state inicial del override; sin esto el
    // test termina corriendo en chapter mode por default).
    await setConfig('biblia.reader_view_mode', 'verse');

    // Sembrar una nota en Génesis 1:1.
    await notasRepo.upsert(
      1, // versionId
      1, // libroId
      1, // capitulo
      1, // versiculo numero
      'Mi nota sobre la creación',
      NotaColor.amarillo,
    );

    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ));
    await tester.pumpAndSettle();

    // El texto de la nota debe ser visible en el preview inline.
    expect(find.text('Mi nota sobre la creación'), findsOneWidget);
  });

  testWidgets('verse mode sin nota NO muestra preview', (tester) async {
    await setConfig('biblia.reader_view_mode', 'verse');
    // Sin notas sembradas.
    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ));
    await tester.pumpAndSettle();

    // El badge "Tiene nota" no debe aparecer.
    expect(find.text('Tiene nota'), findsNothing);
  });

  testWidgets('tap en preview de nota abre modal Editar nota',
      (tester) async {
    await setConfig('biblia.reader_view_mode', 'verse');
    await notasRepo.upsert(
      1,
      1,
      1,
      1,
      'Nota a editar',
      NotaColor.verde,
    );

    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ));
    await tester.pumpAndSettle();

    // Tap en el _NotaPreview widget usando la key.
    final preview = find.byKey(ValueKey('nota_preview_1'));
    expect(preview, findsOneWidget);
    await tester.tap(preview);
    // El padre tiene onDoubleTap, hay que esperar el delay de gesture arena.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // El modal se abre con título "Editar nota" (porque ya existe).
    expect(find.text('Editar nota'), findsOneWidget);
  });
}
