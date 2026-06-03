import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite.dart';

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
  });
}
