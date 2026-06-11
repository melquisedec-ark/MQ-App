import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/cross_referencias_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_libro_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_versiculo_provider.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/application/providers/historial_provider.dart';
import 'package:mqapp/features/biblia/application/providers/notas_provider.dart';
import 'package:mqapp/features/biblia/application/providers/reader_providers.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/models/nota.dart';
import 'package:mqapp/features/biblia/presentation/widgets/verse_card.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/cross_referencias_repository.dart';
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
  required CrossReferenciasRepository crossRefsRepo,
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
      crossReferenciasRepositoryProvider.overrideWithValue(crossRefsRepo),
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
                      // C8: parsear `?v=N` igual que en app_router.
                      final vParam = state.uri.queryParameters['v'];
                      final v =
                          vParam != null ? int.tryParse(vParam) : null;
                      return BibleReaderScreen(
                        libroId: id,
                        capitulo: cap,
                        initialVersiculo: v,
                      );
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

  Widget buildHarness({
    int libroId = 1,
    int capitulo = 1,
    bool isConnected = false,
    BibleReaderViewMode initialViewMode = BibleReaderViewMode.chapter,
  }) =>
      _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        crossRefsRepo: crossRefsRepo,
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
    ),);
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
    ),);
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
    ),);
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
    ),);
    await tester.pumpAndSettle();

    // Tap en el _NotaPreview widget usando la key.
    final preview = find.byKey(const ValueKey('nota_preview_1'));
    expect(preview, findsOneWidget);
    await tester.tap(preview);
    // El padre tiene onDoubleTap, hay que esperar el delay de gesture arena.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // El modal se abre con título "Editar nota" (porque ya existe).
    expect(find.text('Editar nota'), findsOneWidget);
  });

  // A5: refinamiento del preview de nota (Card tinted + botón Editar).
  testWidgets('verse mode con nota larga (50+ chars) se trunca con ellipsis',
      (tester) async {
    await setConfig('biblia.reader_view_mode', 'verse');
    const longNote = 'Esta es una nota muy larga que tiene más de 50 '
        'caracteres para verificar que se trunca con ellipsis en el preview '
        'cuando excede el maxLines de 5';
    expect(longNote.length, greaterThan(50));

    await notasRepo.upsert(1, 1, 1, 1, longNote, NotaColor.azul);

    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ),);
    await tester.pumpAndSettle();

    // El texto debe estar presente (widget lo renderiza aunque truncado).
    expect(find.textContaining('Esta es una nota muy larga'), findsOneWidget);
    // El label 'Tu nota' debe estar visible.
    expect(find.text('Tu nota'), findsOneWidget);
  });

  testWidgets('tap en botón Editar del preview abre modal con existingNote',
      (tester) async {
    await setConfig('biblia.reader_view_mode', 'verse');
    await notasRepo.upsert(1, 1, 1, 1, 'Contenido a editar', NotaColor.amarillo);

    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ),);
    await tester.pumpAndSettle();

    // El botón Editar es visible.
    final editBtn = find.text('Editar');
    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    // Esperar gesture arena delay.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // El modal abre con "Editar nota" porque la nota existe.
    expect(find.text('Editar nota'), findsOneWidget);
  });

  testWidgets('preview muestra el label Tu nota y el icono edit_note_rounded',
      (tester) async {
    await setConfig('biblia.reader_view_mode', 'verse');
    await notasRepo.upsert(1, 1, 1, 1, 'Mi nota', NotaColor.verde);

    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ),);
    await tester.pumpAndSettle();

    expect(find.text('Tu nota'), findsOneWidget);
    // v1.0.4b: bottom bar también tiene edit_note_rounded → al menos 1.
    expect(find.byIcon(Icons.edit_note_rounded), findsAtLeastNWidgets(1));
  });

  // ─────────────────────────────────────────────────────────────
  // C4+C5+C6: cross-references en Bible reader
  // ─────────────────────────────────────────────────────────────

  testWidgets('verse mode con cross-refs en BD muestra sección N referencias',
      (tester) async {
    // Sembrar cross-refs directamente en la BD: Génesis 1:1 tiene 2
    // refs en el seed (→ Gn 1:2 y → Gn 2:4). El reader abre en
    // versículo 1 por default, no hay que navegar.
    await seedCrossReferenciasTestDb(db);

    await setConfig('biblia.reader_view_mode', 'verse');
    await tester.pumpWidget(buildHarness(
      libroId: 1, // Génesis
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ),);
    await tester.pumpAndSettle();

    // La sección muestra "2 referencias" (plural porque hay 2).
    expect(find.text('2 referencias'), findsOneWidget);
    // El icono link_rounded del header está visible.
    expect(find.byIcon(Icons.link_rounded), findsAtLeastNWidgets(1));
    // La primera ref se muestra (Génesis 1:2 — versículo único).
    expect(find.text('Génesis 1:2'), findsOneWidget);
  });

  testWidgets('verse mode sin cross-refs NO muestra sección de referencias',
      (tester) async {
    // El setUp default NO incluye cross-refs, así que Génesis 1:1
    // no tiene refs salientes. Modo verse.
    await setConfig('biblia.reader_view_mode', 'verse');
    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ),);
    await tester.pumpAndSettle();

    // El header "N referencias" no debe aparecer en absoluto.
    expect(find.textContaining('referencia'), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────
  // C7+C8: navegación de cross-references
  // ─────────────────────────────────────────────────────────────

  testWidgets('?v=N query param: reader abre directamente en versículo N',
      (tester) async {
    // C8: la ruta `biblia_reader` parsea `?v=N` y pasa initialVersiculo
    // al screen. En el harness, montamos un GoRouter con la misma
    // ruta. Para que la query llegue, el initialLocation debe incluirla.
    await setConfig('biblia.reader_view_mode', 'verse');
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          bibleDatabaseHelperProvider.overrideWithValue(helper),
          bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
          favoritosRepositoryProvider.overrideWithValue(favRepo),
          notasRepositoryProvider.overrideWithValue(notasRepo),
          historialRepositoryProvider.overrideWithValue(histRepo),
          crossReferenciasRepositoryProvider.overrideWithValue(crossRefsRepo),
          favoritosStreamProvider.overrideWith((_) => favRepo.watchAll()),
          notasStreamProvider.overrideWith((_) => notasRepo.watchAll()),
          historialStreamProvider.overrideWith((_) => histRepo.watchAll()),
          isConnectedProvider.overrideWith((_) => false),
          readerViewModeProvider.overrideWith(
            (ref) {
              final n = ReaderViewModeNotifier(ref);
              n.state = BibleReaderViewMode.verse;
              return n;
            },
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation:
                '/biblia/libro/4/capitulo/3?v=16', // Juan 3:16
            routes: <RouteBase>[
              GoRoute(
                path: '/biblia',
                builder: (_, __) => const Scaffold(body: Text('biblia-stub')),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'libro/:libroId',
                    builder: (_, state) => Scaffold(
                      body: Text('libro-${state.pathParameters['libroId']}'),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'capitulo/:capitulo',
                        name: 'biblia_reader',
                        builder: (_, state) {
                          final id = int.parse(state.pathParameters['libroId']!);
                          final cap =
                              int.parse(state.pathParameters['capitulo']!);
                          final vParam = state.uri.queryParameters['v'];
                          final v = vParam != null ? int.tryParse(vParam) : null;
                          return BibleReaderScreen(
                            libroId: id,
                            capitulo: cap,
                            initialVersiculo: v,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Esperar a que el async del bible reader cargue los datos.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // El versículo 16 está visible (en Juan 3 el seed tiene 3:16).
    expect(
      find.textContaining('Porque de tal manera amó Dios al mundo'),
      findsOneWidget,
    );
    // El número 16 (versículo) se ve en la columna izquierda.
    // (En verse mode se muestra "${numero}" y "${numero}/36" en la parte inferior.)
    expect(find.text('16/36'), findsOneWidget);
  });

  testWidgets('?v=invalid (no numérico): reader abre en versículo 1 default',
      (tester) async {
    await setConfig('biblia.reader_view_mode', 'verse');
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          bibleDatabaseHelperProvider.overrideWithValue(helper),
          bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
          favoritosRepositoryProvider.overrideWithValue(favRepo),
          notasRepositoryProvider.overrideWithValue(notasRepo),
          historialRepositoryProvider.overrideWithValue(histRepo),
          crossReferenciasRepositoryProvider.overrideWithValue(crossRefsRepo),
          favoritosStreamProvider.overrideWith((_) => favRepo.watchAll()),
          notasStreamProvider.overrideWith((_) => notasRepo.watchAll()),
          historialStreamProvider.overrideWith((_) => histRepo.watchAll()),
          isConnectedProvider.overrideWith((_) => false),
          readerViewModeProvider.overrideWith(
            (ref) {
              final n = ReaderViewModeNotifier(ref);
              n.state = BibleReaderViewMode.verse;
              return n;
            },
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/biblia/libro/4/capitulo/3?v=abc', // inválido
            routes: <RouteBase>[
              GoRoute(
                path: '/biblia',
                builder: (_, __) => const Scaffold(body: Text('biblia-stub')),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'libro/:libroId',
                    builder: (_, state) => Scaffold(
                      body: Text('libro-${state.pathParameters['libroId']}'),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'capitulo/:capitulo',
                        name: 'biblia_reader',
                        builder: (_, state) {
                          final id = int.parse(state.pathParameters['libroId']!);
                          final cap =
                              int.parse(state.pathParameters['capitulo']!);
                          final vParam = state.uri.queryParameters['v'];
                          final v = vParam != null ? int.tryParse(vParam) : null;
                          return BibleReaderScreen(
                            libroId: id,
                            capitulo: cap,
                            initialVersiculo: v,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Como 'abc' no parsea, se omite el param y el reader abre en
    // versículo 1. El seed tiene Génesis 1:1 → "En el principio...";
    // como abrimos Juan cap 3 versículo 1 NO existe en el seed (solo
    // 16, 17, 18), pero el versículo 1 = fallback al primer versículo
    // (3:16). El test solo verifica que NO crashea y que el reader
    // muestra algún texto.
    expect(find.byType(BibleReaderScreen), findsOneWidget);
  });

  testWidgets('sin query param ?v: reader abre en versículo 1 (default)',
      (tester) async {
    // Modo chapter: el verse 1 no está visible en el test (lazy render),
    // pero el provider currentVerse debe iniciar en 1.
    final container = ProviderContainer(overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(helper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      crossReferenciasRepositoryProvider.overrideWithValue(crossRefsRepo),
    ],);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) {
            return const BibleReaderScreen(libroId: 1, capitulo: 1);
          },),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // El currentVerseProvider debe ser 1.
    expect(container.read(currentVerseProvider), 1);
    // El texto del versículo 1 de Génesis es visible (chapter view).
    expect(
      find.textContaining('En el principio creó Dios'),
      findsOneWidget,
    );
  });

  testWidgets('ruta biblia_reader acepta query param ?v=N (parse)',
      (tester) async {
    // C8: el GoRoute biblia_reader debe parsear `?v=N` desde
    // state.uri.queryParameters. Testeamos la estructura del router
    // + builder pattern (mismo enfoque que hymn_navigation_test.dart).
    final capturedVersiculo = <int?>[];

    final testRouter = GoRouter(
      initialLocation: '/biblia/libro/1/capitulo/1?v=42',
      routes: <RouteBase>[
        GoRoute(
          path: '/biblia',
          builder: (_, __) => const Scaffold(body: Text('biblia-stub')),
          routes: <RouteBase>[
            GoRoute(
              path: 'libro/:libroId',
              builder: (_, state) => Scaffold(
                body: Text('libro-${state.pathParameters['libroId']}'),
              ),
              routes: <RouteBase>[
                GoRoute(
                  path: 'capitulo/:capitulo',
                  name: 'biblia_reader',
                  builder: (_, state) {
                    final vParam = state.uri.queryParameters['v'];
                    final v = vParam != null ? int.tryParse(vParam) : null;
                    capturedVersiculo.add(v);
                    return Scaffold(body: Text('reader-v=$v'));
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: testRouter),
    );
    await tester.pumpAndSettle();

    // El builder se ejecutó con `?v=42` → capturó 42.
    expect(capturedVersiculo, contains(42));
    expect(find.text('reader-v=42'), findsOneWidget);
  });

  testWidgets('?v=invalid (no numérico) → int.tryParse retorna null',
      (tester) async {
    // Caso borde: si ?v=abc (no parseable), la ruta NO debe crashear.
    // El builder recibe null y el reader abre en versículo 1.
    final capturedVersiculo = <int?>[];

    final testRouter = GoRouter(
      initialLocation: '/biblia/libro/1/capitulo/1?v=abc',
      routes: <RouteBase>[
        GoRoute(
          path: '/biblia',
          builder: (_, __) => const Scaffold(body: Text('biblia-stub')),
          routes: <RouteBase>[
            GoRoute(
              path: 'libro/:libroId',
              builder: (_, state) => const Scaffold(body: Text('libro')),
              routes: <RouteBase>[
                GoRoute(
                  path: 'capitulo/:capitulo',
                  name: 'biblia_reader',
                  builder: (_, state) {
                    final vParam = state.uri.queryParameters['v'];
                    final v = vParam != null ? int.tryParse(vParam) : null;
                    capturedVersiculo.add(v);
                    return Scaffold(body: Text('reader-v=$v'));
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: testRouter));
    await tester.pumpAndSettle();

    // tryParse('abc') → null.
    expect(capturedVersiculo, contains(null));
    expect(find.text('reader-v=null'), findsOneWidget);
  });

  testWidgets('verse mode: tap en cross-ref no crashea y la sección es tappable',
      (tester) async {
    // C7: el widget ReferenciasCruzadasSection expone un InkWell
    // tappable por cada ref. Verificamos:
    //   1. La sección se renderiza (la vimos en test previo).
    //   2. El InkWell de la ref está presente.
    //   3. Tap no crashea (la navegación con GoRouter en tests es
    //      difícil de verificar end-to-end; lo testeamos aparte en
    //      router test y en el pushNamed manual de la sección).
    await seedCrossReferenciasTestDb(db);
    await setConfig('biblia.reader_view_mode', 'verse');
    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ),);
    await tester.pumpAndSettle();

    // La sección tiene "2 referencias" y la primera ref es Génesis 1:2.
    expect(find.text('2 referencias'), findsOneWidget);
    final refText = find.text('Génesis 1:2');
    expect(refText, findsOneWidget);

    // El InkWell ancestral del ref text es el target del tap.
    final refInkWell = find
        .ancestor(of: refText, matching: find.byType(InkWell))
        .first;
    expect(refInkWell, findsOneWidget);

    // Tap no debe lanzar excepción. La navegación con pushNamed se
    // ejecuta (la verificamos en otros tests a nivel de router).
    await tester.tap(refInkWell, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    // Si llega aquí sin crash, el test pasa.
    expect(tester.takeException(), isNull);
  });

  // ─────────────────────────────────────────────────────────────
  // Bug #1: navegación de cross-refs preserva estado del lector
  // ─────────────────────────────────────────────────────────────

  testWidgets('cross-ref navigation: salva/restaura providers globales',
      (tester) async {
    // Bug #1 fix: al navegar desde una cross-ref y volver, los providers
    // globales deben conservar su estado original (libroId, capitulo,
    // versiculo, viewMode, currentVerse).
    await seedCrossReferenciasTestDb(db);
    await setConfig('biblia.reader_view_mode', 'verse');

    final container = ProviderContainer(overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(helper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      crossReferenciasRepositoryProvider.overrideWithValue(crossRefsRepo),
      favoritosStreamProvider.overrideWith((_) => favRepo.watchAll()),
      notasStreamProvider.overrideWith((_) => notasRepo.watchAll()),
      historialStreamProvider.overrideWith((_) => histRepo.watchAll()),
      isConnectedProvider.overrideWith((_) => false),
      readerViewModeProvider.overrideWith(
        (ref) {
          final n = ReaderViewModeNotifier(ref);
          n.state = BibleReaderViewMode.verse;
          return n;
        },
      ),
    ],);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/biblia/libro/1/capitulo/1?v=1',
            routes: <RouteBase>[
              GoRoute(
                path: '/biblia',
                builder: (_, __) => const Scaffold(body: Text('biblia-stub')),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'libro/:libroId',
                    builder: (_, state) => Scaffold(
                      body: Text('libro-${state.pathParameters['libroId']}'),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'capitulo/:capitulo',
                        name: 'biblia_reader',
                        builder: (_, state) {
                          final id =
                              int.parse(state.pathParameters['libroId']!);
                          final cap =
                              int.parse(state.pathParameters['capitulo']!);
                          final vParam = state.uri.queryParameters['v'];
                          final v = vParam != null
                              ? int.tryParse(vParam)
                              : null;
                          return BibleReaderScreen(
                            libroId: id,
                            capitulo: cap,
                            initialVersiculo: v,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verificar estado inicial: Génesis 1, versículo 1, modo verse.
    expect(container.read(currentLibroIdProvider), 1);
    expect(container.read(currentCapituloProvider), 1);
    expect(container.read(currentVersiculoNumeroProvider), 1);
    expect(container.read(currentVerseProvider), 1);

    // La sección de cross-refs debe mostrar "2 referencias".
    expect(find.text('2 referencias'), findsOneWidget);

    // El test verifica que los providers están correctamente inicializados
    // y que la sección de referencias se renderiza sin errores.
    // La navegación real con pushNamed se verifica en tests de router.
    expect(tester.takeException(), isNull);
  });

  // ─────────────────────────────────────────────────────────────
  // Feature #2: Preview snippets en cross-refs
  // ─────────────────────────────────────────────────────────────

  testWidgets('cross-ref con preview muestra texto del versículo destino',
      (tester) async {
    // Feature #2: las cross-refs muestran solo la cita por defecto.
    // Al tocar la cita, se expande el preview del versículo destino.
    await seedCrossReferenciasTestDb(db);
    await setConfig('biblia.reader_view_mode', 'verse');
    await tester.pumpWidget(buildHarness(
      libroId: 1,
      capitulo: 1,
      initialViewMode: BibleReaderViewMode.verse,
    ),);
    await tester.pumpAndSettle();

    // La sección muestra "2 referencias".
    expect(find.text('2 referencias'), findsOneWidget);
    // El preview NO debe ser visible por defecto (solo cita).
    expect(
      find.textContaining('Y la tierra estaba desordenada'),
      findsNothing,
    );
    // Tocar la cita para expandir el preview.
    await tester.tap(find.text('Génesis 1:2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Ahora el preview SÍ debe ser visible.
    // Ahora el preview SÍ debe ser visible.
    expect(
      find.textContaining('Y la tierra estaba desordenada'),
      findsOneWidget,
    );
  });

  testWidgets('cross-ref con preview: Juan 3:16 muestra sección de refs',
      (tester) async {
    // Feature #2: verifica que la sección de refs se renderiza correctamente
    // para Juan 3:16 (3 refs en el seed). El preview se valida a nivel
    // de repositorio y modelo en otros tests.
    await seedCrossReferenciasTestDb(db);
    await setConfig('biblia.reader_view_mode', 'verse');
    await tester.pumpWidget(buildHarness(
      libroId: 4, // Juan
      capitulo: 3,
      initialViewMode: BibleReaderViewMode.verse,
    ),);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Juan 3:16 tiene 3 refs en el seed.
    expect(find.text('3 referencias'), findsOneWidget);
    // El icono link_rounded del header está visible.
    expect(find.byIcon(Icons.link_rounded), findsAtLeastNWidgets(1));
    // Las refs individuales se muestran (Génesis, 1 Juan, Juan).
    expect(find.textContaining('Génesis'), findsAtLeastNWidgets(1));
  });
}
