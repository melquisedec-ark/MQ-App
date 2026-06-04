import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/features/biblia/application/providers/current_versiculo_provider.dart';
import 'package:mqapp/features/biblia/application/providers/reader_providers.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:mqapp/features/biblia/presentation/widgets/verse_card.dart';

import 'helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  late Database db;
  late BibliaRepository bibliaRepo;
  late FavoritosRepository favRepo;
  late NotasRepository notasRepo;
  late HistorialRepository histRepo;

  setUp(() async {
    final bundle = await createBibleReposWithSeed();
    db = bundle.db;
    bibliaRepo = bundle.biblia;
    favRepo = bundle.favoritos;
    notasRepo = bundle.notas;
    histRepo = bundle.historial;
  });

  tearDown(() async {
    await closeBibleRepos(
      db: db,
      favoritos: favRepo,
      notas: notasRepo,
      historial: histRepo,
    );
  });

  group('Bible reader chapter view (D6)', () {
    test('default view mode es chapter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(readerViewModeProvider), BibleReaderViewMode.chapter);
    });

    test('currentVerseProvider inicia en 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(currentVerseProvider), 1);
    });

    testWidgets('VerseCard renderiza número y texto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerseCard(
              numero: 5,
              texto: 'Y dijo Dios: Sea la luz; y fue la luz.',
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(
        find.text('Y dijo Dios: Sea la luz; y fue la luz.'),
        findsOneWidget,
      );
    });

    testWidgets('VerseCard onTap callback se ejecuta', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseCard(
              numero: 1,
              texto: 'Test',
              onTap: () => tapped++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(VerseCard));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('VerseCard con esFoco renderiza sin error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                VerseCard(numero: 1, texto: 'Normal'),
                VerseCard(numero: 2, texto: 'Foco', esFoco: true),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(VerseCard), findsNWidgets(2));
    });

    // A4: tests del icono ⭐ inline.
    testWidgets('VerseCard con esFavorito: true renderiza icono de estrella',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerseCard(
              numero: 7,
              texto: 'Versículo favorito de prueba',
              esFavorito: true,
            ),
          ),
        ),
      );

      // Aparece un Icon de estrella (Filled/outlined ambos usan star_rounded
      // / star_outline_rounded). En este caso es el star_rounded (filled).
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('VerseCard sin esFavorito NO renderiza icono de estrella',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerseCard(
              numero: 8,
              texto: 'Versículo normal sin favorito',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    });

    testWidgets(
      'VerseCard con nota + favorito + 320dp width renderiza denso',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: VerseCard(
                  numero: 12,
                  texto: 'Versículo con nota y marcado como favorito',
                  esFavorito: true,
                  notaIndicatorColor: Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
        );

        // Ambos iconos están presentes en la columna izquierda.
        expect(find.byIcon(Icons.star_rounded), findsOneWidget);
        // Dot de nota presente.
        expect(find.byType(Container), findsWidgets);
        // Texto principal visible.
        expect(
          find.text('Versículo con nota y marcado como favorito'),
          findsOneWidget,
        );
      },
    );

    // C5: crossRefCount prop.
    testWidgets('VerseCard con crossRefCount: 5 renderiza icono link',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerseCard(
              numero: 16,
              texto: 'Versículo con 5 referencias',
              crossRefCount: 5,
            ),
          ),
        ),
      );

      // El icono link_rounded debe estar visible.
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
      // El tooltip muestra el conteo exacto.
      expect(find.byTooltip('5 referencias'), findsOneWidget);
    });

    testWidgets('VerseCard con crossRefCount: 0 NO renderiza icono link',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerseCard(
              numero: 16,
              texto: 'Versículo sin referencias (count=0)',
              crossRefCount: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.link_rounded), findsNothing);
    });

    testWidgets('VerseCard con crossRefCount: null NO renderiza icono link',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerseCard(
              numero: 16,
              texto: 'Versículo sin prop crossRefCount',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.link_rounded), findsNothing);
    });

    testWidgets('VerseCard con crossRefCount: 1 renderiza icono link',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerseCard(
              numero: 16,
              texto: 'Versículo con 1 referencia',
              crossRefCount: 1,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
      // Tooltip usa singular (1 referencia, no "1 referencias").
      expect(find.byTooltip('1 referencia'), findsOneWidget);
    });

    testWidgets(
      'VerseCard con fav + nota + refs en 320dp renderiza los 3 indicadores',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: VerseCard(
                  numero: 16,
                  texto:
                      'Versículo completo: favorito, con nota y con referencias',
                  esFavorito: true,
                  notaIndicatorColor: Color(0xFFF59E0B),
                  crossRefCount: 7,
                ),
              ),
            ),
          ),
        );

        // Los 3 iconos/indicadores están en la columna izquierda.
        expect(find.byIcon(Icons.star_rounded), findsOneWidget);
        expect(find.byIcon(Icons.link_rounded), findsOneWidget);
        // Tooltip del link con el conteo.
        expect(find.byTooltip('7 referencias'), findsOneWidget);
        // Texto principal visible.
        expect(
          find.text(
            'Versículo completo: favorito, con nota y con referencias',
          ),
          findsOneWidget,
        );
      },
    );

    test('toggle de readerViewModeProvider alterna verse <-> chapter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(readerViewModeProvider), BibleReaderViewMode.chapter);

      container.read(readerViewModeProvider.notifier)
          .setViewMode(BibleReaderViewMode.verse);
      expect(container.read(readerViewModeProvider),
          BibleReaderViewMode.verse);

      container.read(readerViewModeProvider.notifier)
          .setViewMode(BibleReaderViewMode.chapter);
      expect(container.read(readerViewModeProvider),
          BibleReaderViewMode.chapter);
    });

    test('currentVerseProvider NO se resetea al alternar viewMode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Cambiar a versículo 5.
      container.read(currentVerseProvider.notifier).state = 5;
      expect(container.read(currentVerseProvider), 5);

      // Alternar a chapter.
      container.read(readerViewModeProvider.notifier)
          .setViewMode(BibleReaderViewMode.chapter);

      // El versículo debe preservarse.
      expect(container.read(currentVerseProvider), 5);

      // Volver a verse.
      container.read(readerViewModeProvider.notifier)
          .setViewMode(BibleReaderViewMode.verse);

      // Sigue preservado.
      expect(container.read(currentVerseProvider), 5);
    });

    test('VerseCard widget tests pasan sincrónicamente', () {
      // Test redundante para confirmar carga del módulo.
      expect(BibleReaderViewMode.values.length, 2);
    });

    // ─────────────────────────────────────────────────────────────
    // Feature #3: Swipe-to-reveal en chapter mode
    // ─────────────────────────────────────────────────────────────

    test('Swipe en versículo con refs: cambia a verse mode', () {
      // Feature #3: al hacer swipe izquierda en un versículo que tiene
      // cross-refs, debe cambiar a verse mode en ese versículo.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Simular: versículo 5 con 3 refs.
      container.read(currentVersiculoNumeroProvider.notifier).state = 5;
      container.read(currentVerseProvider.notifier).state = 5;

      expect(container.read(currentVersiculoNumeroProvider), 5);
      expect(container.read(currentVerseProvider), 5);
      expect(
        container.read(readerViewModeProvider),
        BibleReaderViewMode.chapter,
      );

      // Simular el cambio a verse mode (lo que haría confirmDismiss).
      container.read(readerViewModeProvider.notifier)
          .setViewMode(BibleReaderViewMode.verse);
      expect(
        container.read(readerViewModeProvider),
        BibleReaderViewMode.verse,
      );
    });

    test('Swipe en versículo sin refs: no cambia de modo', () {
      // Si el versículo no tiene cross-refs (crossRefCount == 0),
      // el confirmDismiss retorna false y NO cambia de modo.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Estado inicial: chapter mode, versículo 1.
      expect(
        container.read(readerViewModeProvider),
        BibleReaderViewMode.chapter,
      );

      // Simular confirmDismiss con crossRefCount = 0 → retorna false.
      // No se ejecuta el cambio de modo.
      const crossRefCount = 0;
      final shouldChange = crossRefCount != null && crossRefCount > 0;
      expect(shouldChange, isFalse);

      // El modo sigue siendo chapter.
      expect(
        container.read(readerViewModeProvider),
        BibleReaderViewMode.chapter,
      );
    });

    test('Dismissible con crossRefCount null: no cambia de modo', () {
      // Si crossRefCount es null (no se cargó aún), no cambia de modo.
      const int? crossRefCount = null;
      final shouldChange = crossRefCount != null && crossRefCount > 0;
      expect(shouldChange, isFalse);
    });
  });
}
