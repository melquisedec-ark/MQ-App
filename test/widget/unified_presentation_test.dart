import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mqapp/core/enums/estrofa_tipo.dart';
import 'package:mqapp/core/enums/himno_tipo.dart';
import 'package:mqapp/core/window_manager/window_service.dart';
import 'package:mqapp/core/window_manager/window_providers.dart';
import 'package:mqapp/domain/entities/categoria.dart';
import 'package:mqapp/domain/entities/estrofa.dart';
import 'package:mqapp/domain/entities/himno.dart';
import 'package:mqapp/domain/entities/projection_slide.dart';
import 'package:mqapp/domain/entities/version_pais.dart';
import 'package:mqapp/domain/repositories/control_repository.dart';
import 'package:mqapp/domain/repositories/fondo_repository.dart';
import 'package:mqapp/presentation/views_projection/controller/live_control_screen.dart';
import 'package:mqapp/presentation/views_projection/display/projection_app.dart';
import 'package:mqapp/presentation/views_projection/display/receptor_binding.dart';
import 'package:mqapp/presentation/views_projection/providers/connection_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/live_control_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/presentation_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/projection_providers.dart';

// ═══════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════

class MockControlRepository extends Mock implements ControlRepository {}
class MockWindowService extends Mock implements WindowService {}
class MockFondoRepository extends Mock implements FondoRepository {}

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

Himno _createTestHimno({
  int id = 1,
  String titulo = 'Santo, Santo, Santo',
  int? numero = 1,
}) {
  return Himno(
    id: id,
    titulo: titulo,
    numero: numero,
    tipo: HimnoTipo.oficial,
    versiones: [
      VersionPais(
        id: 1,
        himnoId: id,
        paisId: 0,
        paisNombre: 'Honduras',
        paisCodigo: 'HN',
        tonalidadOriginal: 'G',
      ),
    ],
    categorias: [
      const Categoria(id: 1, nombre: 'Alabanza'),
    ],
  );
}

List<Estrofa> _createTestStanzas() {
  return [
    const Estrofa(
      id: 1,
      versionPaisId: 1,
      tipo: EstrofaTipo.estrofa,
      orden: 1,
      contenido: 'Primera estrofa del himno',
    ),
    const Estrofa(
      id: 2,
      versionPaisId: 1,
      tipo: EstrofaTipo.coro,
      orden: 2,
      contenido: 'Coro del himno',
    ),
    const Estrofa(
      id: 3,
      versionPaisId: 1,
      tipo: EstrofaTipo.estrofa,
      orden: 3,
      contenido: 'Segunda estrofa del himno',
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════
// Test suite: LiveControlNotifier — switchToModule
// ═══════════════════════════════════════════════════════════════

void main() {
  group('LiveControlNotifier — switchToModule', () {
    test('Cambia de himnario a biblia y limpia estado de himno', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      // Verificar estado inicial en himnario
      expect(container.read(liveControlProvider).module, ProjectionModule.hymnal);
      expect(container.read(liveControlProvider).hymn, isNotNull);
      expect(container.read(liveControlProvider).slides.isNotEmpty, true);

      // Cambiar a biblia
      notifier.switchToModule(ProjectionModule.bible);

      final state = container.read(liveControlProvider);
      expect(state.module, ProjectionModule.bible);
      expect(state.hymn, isNull); // Himno limpiado
      expect(state.slides, isEmpty); // Slides limpiados
      expect(state.currentSlideIndex, 0);
      expect(state.isBlackout, false);
    });

    test('Cambia de biblia a himnario y limpia estado bíblico', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1', 'Verso 2'],
      );

      // Verificar estado inicial en biblia
      expect(container.read(liveControlProvider).module, ProjectionModule.bible);
      expect(container.read(liveControlProvider).libroNombre, 'Génesis');
      expect(container.read(liveControlProvider).capitulo, 1);
      expect(container.read(liveControlProvider).versiculos.isNotEmpty, true);

      // Cambiar a himnario
      notifier.switchToModule(ProjectionModule.hymnal);

      final state = container.read(liveControlProvider);
      expect(state.module, ProjectionModule.hymnal);
      expect(state.libroNombre, ''); // Libro limpiado
      expect(state.capitulo, 0); // Capítulo limpiado
      expect(state.versiculos, isEmpty); // Versículos limpiados
      expect(state.versiculoActual, 0);
      expect(state.slides, isEmpty);
    });

    test('No-op al cambiar al mismo módulo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());
      notifier.nextSlide(); // Avanzar para cambiar el índice

      final beforeState = container.read(liveControlProvider);
      expect(beforeState.currentSlideIndex, 1);

      // Intentar cambiar al mismo módulo (hymnal)
      notifier.switchToModule(ProjectionModule.hymnal);

      final afterState = container.read(liveControlProvider);
      // El estado no debe cambiar
      expect(afterState.currentSlideIndex, 1);
      expect(afterState.hymn, isNotNull);
    });

    test('Después de switch, currentSlide es null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());
      expect(container.read(liveControlProvider).currentSlide, isNotNull);

      notifier.switchToModule(ProjectionModule.bible);
      expect(container.read(liveControlProvider).currentSlide, isNull);
    });

    test('Después de switch, hasNextSlide es false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadBibleChapter(
        libroNombre: 'Juan',
        capitulo: 3,
        versiculos: ['Verso 1', 'Verso 2', 'Verso 3'],
      );
      expect(container.read(liveControlProvider).hasNextSlide, true);

      notifier.switchToModule(ProjectionModule.hymnal);
      expect(container.read(liveControlProvider).hasNextSlide, false);
    });

    test('Después de switch, slideCount es 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());
      expect(container.read(liveControlProvider).slideCount, greaterThan(0));

      notifier.switchToModule(ProjectionModule.bible);
      expect(container.read(liveControlProvider).slideCount, 0);
    });

    test('Blackout se resetea al cambiar de módulo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());
      notifier.blackout();
      expect(container.read(liveControlProvider).isBlackout, true);

      notifier.switchToModule(ProjectionModule.bible);
      expect(container.read(liveControlProvider).isBlackout, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Test suite: ProjectionApp — SWITCH_MODULE handler
  // ═══════════════════════════════════════════════════════════════

  group('ProjectionApp — SWITCH_MODULE handler', () {
    Widget buildTestApp({Stream<String>? stdinOverride}) {
      return ProviderScope(
        overrides: [
          controlRepositoryProvider.overrideWith(
            (ref) => MockControlRepository(),
          ),
          receptorInfoProvider.overrideWith(
            (ref) => const ReceptorInfo(
              isRunning: false,
              port: 50051,
              displayName: 'Test',
            ),
          ),
          fondoRepositoryProvider.overrideWith(
            (ref) => MockFondoRepository(),
          ),
        ],
        child: MaterialApp(
          home: ProjectionApp(stdinOverride: stdinOverride),
        ),
      );
    }

    testWidgets('SWITCH_MODULE a bible limpia slides y cambia módulo',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Primero cargar un himno
      stdinCtrl.add(jsonEncode({
        'type': 'LOAD_HYMN',
        'himno_id': 1,
        'titulo': 'Test',
        'numero': 1,
        'tipo': 'oficial',
        'estrofas': [
          {
            'id': 1,
            'version_pais_id': 1,
            'tipo': 'estrofa',
            'orden': 1,
            'contenido': 'Estrofa 1',
          },
        ],
      }),);
      await tester.pumpAndSettle();

      final container =
          ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
      expect(container.read(liveControlProvider).module, ProjectionModule.hymnal);
      expect(container.read(liveControlProvider).hymn, isNotNull);

      // Enviar SWITCH_MODULE a bible
      stdinCtrl.add(jsonEncode({
        'type': 'SWITCH_MODULE',
        'module': 'bible',
      }),);
      await tester.pumpAndSettle();

      final state = container.read(liveControlProvider);
      expect(state.module, ProjectionModule.bible);
      expect(state.hymn, isNull); // Himno limpiado
      expect(state.slides, isEmpty); // Slides limpiados

      await stdinCtrl.close();
    });

    testWidgets('SWITCH_MODULE a hymnal limpia estado bíblico',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Primero cargar un capítulo bíblico
      stdinCtrl.add(jsonEncode({
        'type': 'LOAD_VERSE',
        'libroNombre': 'Génesis',
        'capitulo': 1,
        'versiculos': ['Verso 1', 'Verso 2'],
      }),);
      await tester.pumpAndSettle();

      final container =
          ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
      expect(container.read(liveControlProvider).module, ProjectionModule.bible);
      expect(container.read(liveControlProvider).libroNombre, 'Génesis');

      // Enviar SWITCH_MODULE a hymnal
      stdinCtrl.add(jsonEncode({
        'type': 'SWITCH_MODULE',
        'module': 'hymnal',
      }),);
      await tester.pumpAndSettle();

      final state = container.read(liveControlProvider);
      expect(state.module, ProjectionModule.hymnal);
      expect(state.libroNombre, ''); // Libro limpiado
      expect(state.capitulo, 0); // Capítulo limpiado
      expect(state.versiculos, isEmpty); // Versículos limpiados

      await stdinCtrl.close();
    });

    testWidgets('SWITCH_MODULE seguido de NEXT_SLIDE no crashea',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cambiar a biblia
      stdinCtrl.add(jsonEncode({
        'type': 'SWITCH_MODULE',
        'module': 'bible',
      }),);
      await tester.pumpAndSettle();

      // Intentar avanzar (no hay slides, debe ser no-op)
      stdinCtrl.add(jsonEncode({'type': 'NEXT_SLIDE'}));
      await tester.pumpAndSettle();

      // La app no debe crashear
      expect(tester.takeException(), isNull);

      await stdinCtrl.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Test suite: LiveControlScreen — module switch button
  // ═══════════════════════════════════════════════════════════════

  group('LiveControlScreen — module switch button', () {
    Widget buildTestApp({
      List<Override> overrides = const [],
    }) {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      return ProviderScope(
        overrides: [
          liveControlProvider.overrideWith((ref) => notifier),
          isConnectedProvider.overrideWith((ref) => false),
          controlRepositoryProvider.overrideWith(
            (ref) => MockControlRepository(),
          ),
          projectionConfigProvider.overrideWith((ref) {
            final repo = ref.read(controlRepositoryProvider);
            return ProjectionConfigNotifier(repo);
          }),
          windowServiceProvider.overrideWith((ref) => MockWindowService()),
          ...overrides,
        ],
        child: const MaterialApp(
          home: LiveControlScreen(),
        ),
      );
    }

    testWidgets('Botón de cambio de módulo muestra icono de himnario en modo himnario',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // El botón debe mostrar el icono music_note_outlined (himnario)
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    });

    testWidgets('Botón de cambio de módulo muestra icono de biblia en modo biblia',
        (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            liveControlProvider.overrideWith((ref) => notifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // El botón debe mostrar el icono menu_book_outlined (biblia)
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    });

    testWidgets('Tooltip correcto en modo himnario', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Buscar el tooltip "Cambiar a Biblia"
      expect(find.byTooltip('Cambiar a Biblia'), findsOneWidget);
    });

    testWidgets('Tooltip correcto en modo biblia', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            liveControlProvider.overrideWith((ref) => notifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Cambiar a Himnario'), findsOneWidget);
    });

    testWidgets('AppBar title cambia después de switch de módulo', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Título inicial: nombre del himno
      expect(find.text('Santo, Santo, Santo'), findsOneWidget);

      // Tocar el botón de cambio de módulo
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle();

      // El título debe cambiar a "Biblia" (sin contenido cargado)
      expect(find.text('Biblia'), findsOneWidget);
    });

    testWidgets('Controles cambian después de switch de módulo', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // En modo himnario: botón "SIGUIENTE" grande
      expect(find.text('SIGUIENTE'), findsOneWidget);
      expect(find.text('Ir al Coro'), findsOneWidget);

      // Cambiar a biblia
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle();

      // En modo biblia: botones diferentes
      expect(find.text('ANTERIOR'), findsOneWidget);
      expect(find.text('Ir a Versículo'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Test suite: Module switching flow — end-to-end
  // ═══════════════════════════════════════════════════════════════

  group('Module switching flow — end-to-end', () {
    testWidgets('Himnario → cargar himno → cambiar a Biblia → himno limpiado',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            controlRepositoryProvider.overrideWith(
              (ref) => MockControlRepository(),
            ),
            receptorInfoProvider.overrideWith(
              (ref) => const ReceptorInfo(
                isRunning: false,
                port: 50051,
                displayName: 'Test',
              ),
            ),
            fondoRepositoryProvider.overrideWith(
              (ref) => MockFondoRepository(),
            ),
          ],
          child: MaterialApp(
            home: ProjectionApp(stdinOverride: stdinCtrl.stream),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cargar himno
      stdinCtrl.add(jsonEncode({
        'type': 'LOAD_HYMN',
        'himno_id': 1,
        'titulo': 'Alabanza',
        'numero': 5,
        'tipo': 'oficial',
        'estrofas': [
          {
            'id': 1,
            'version_pais_id': 1,
            'tipo': 'estrofa',
            'orden': 1,
            'contenido': 'Alabanza al Señor',
          },
        ],
      }),);
      await tester.pumpAndSettle();

      final container =
          ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
      expect(container.read(liveControlProvider).hymn?.titulo, 'Alabanza');

      // Cambiar a Biblia
      stdinCtrl.add(jsonEncode({
        'type': 'SWITCH_MODULE',
        'module': 'bible',
      }),);
      await tester.pumpAndSettle();

      final state = container.read(liveControlProvider);
      expect(state.module, ProjectionModule.bible);
      expect(state.hymn, isNull);
      expect(state.slides, isEmpty);

      await stdinCtrl.close();
    });

    testWidgets('Biblia → cargar capítulo → cambiar a Himnario → biblia limpiada',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            controlRepositoryProvider.overrideWith(
              (ref) => MockControlRepository(),
            ),
            receptorInfoProvider.overrideWith(
              (ref) => const ReceptorInfo(
                isRunning: false,
                port: 50051,
                displayName: 'Test',
              ),
            ),
            fondoRepositoryProvider.overrideWith(
              (ref) => MockFondoRepository(),
            ),
          ],
          child: MaterialApp(
            home: ProjectionApp(stdinOverride: stdinCtrl.stream),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cargar capítulo bíblico
      stdinCtrl.add(jsonEncode({
        'type': 'LOAD_VERSE',
        'libroNombre': 'Éxodo',
        'capitulo': 20,
        'versiculos': [
          'Yo soy el Señor tu Dios',
          'No tendrás dioses ajenos',
        ],
      }),);
      await tester.pumpAndSettle();

      final container =
          ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
      expect(container.read(liveControlProvider).libroNombre, 'Éxodo');
      expect(container.read(liveControlProvider).capitulo, 20);

      // Cambiar a Himnario
      stdinCtrl.add(jsonEncode({
        'type': 'SWITCH_MODULE',
        'module': 'hymnal',
      }),);
      await tester.pumpAndSettle();

      final state = container.read(liveControlProvider);
      expect(state.module, ProjectionModule.hymnal);
      expect(state.libroNombre, '');
      expect(state.capitulo, 0);
      expect(state.versiculos, isEmpty);

      await stdinCtrl.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Test suite: gRPC integration with module switching
  // ═══════════════════════════════════════════════════════════════

  group('gRPC integration with module switching', () {
    test('SWITCH_TO_BIBLE followed by NEXT_VERSE works', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);

      // Simular recepción de SWITCH_MODULE a bible
      notifier.switchToModule(ProjectionModule.bible);

      // Simular carga de capítulo bíblico (como si viniera de LOAD_VERSE)
      notifier.loadBibleChapter(
        libroNombre: 'Salmos',
        capitulo: 23,
        versiculos: ['El Señor es mi pastor', 'Nada me faltará'],
      );

      // Ahora NEXT_VERSE debe funcionar
      notifier.nextSlide();

      final state = container.read(liveControlProvider);
      expect(state.currentSlideIndex, 1);
      expect(state.currentSlide, isA<VerseSlide>());
    });

    test('SWITCH_TO_HIMNAL clears Bible context cache', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);

      // Cargar contexto bíblico
      notifier.loadBibleChapter(
        libroNombre: 'Proverbios',
        capitulo: 3,
        versiculos: ['Confía en el Señor', 'Reconócelo en todos tus caminos'],
      );

      expect(container.read(liveControlProvider).libroNombre, 'Proverbios');
      expect(container.read(liveControlProvider).capitulo, 3);
      expect(container.read(liveControlProvider).versiculos.length, 2);

      // Cambiar a himnario
      notifier.switchToModule(ProjectionModule.hymnal);

      final state = container.read(liveControlProvider);
      expect(state.libroNombre, '');
      expect(state.capitulo, 0);
      expect(state.versiculos, isEmpty);
      expect(state.module, ProjectionModule.hymnal);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Test suite: ProjectionSlide types after module switch
  // ═══════════════════════════════════════════════════════════════

  group('ProjectionSlide types after module switch', () {
    test('Bible slides are correct type after loadBibleChapter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadBibleChapter(
        libroNombre: 'Isaías',
        capitulo: 53,
        versiculos: ['Despreciado y desechado', 'Ciertamente llevó él nuestras enfermedades'],
      );

      final slides = container.read(liveControlProvider).slides;
      expect(slides.length, 2); // 2 versículos (sin portada ni Fin)
      expect(slides[0], isA<VerseSlide>());
      expect(slides[1], isA<VerseSlide>());
    });

    test('Hymnal slides are correct type after loadHymn', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      final slides = container.read(liveControlProvider).slides;
      expect(slides.length, 5); // Título + 3 estrofas + Amén
      expect(slides[0], isA<TitleSlide>());
      expect(slides[1], isA<LyricsSlide>());
      expect(slides[2], isA<LyricsSlide>());
      expect(slides[3], isA<LyricsSlide>());
      expect(slides[4], isA<AmenSlide>());
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Test suite: State consistency after module switch
  // ═══════════════════════════════════════════════════════════════

  group('State consistency after module switch', () {
    test('versionPaisId preserved when switching to Bible', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());
      expect(container.read(liveControlProvider).versionPaisId, 1);

      notifier.switchToModule(ProjectionModule.bible);
      // versionPaisId se mantiene (no se resetea explícitamente)
      expect(container.read(liveControlProvider).versionPaisId, 1);
    });

    test('bibleTheme and bibleFontScale preserved when switching to Hymnal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(liveControlProvider.notifier);
      notifier.loadBibleChapter(
        libroNombre: 'Daniel',
        capitulo: 7,
        versiculos: ['Verso 1'],
      );
      notifier.setBibleTheme('noche');
      notifier.setBibleFontScale(2.0);

      expect(container.read(liveControlProvider).bibleTheme, 'noche');
      expect(container.read(liveControlProvider).bibleFontScale, 2.0);

      notifier.switchToModule(ProjectionModule.hymnal);

      final state = container.read(liveControlProvider);
      // Los campos bíblicos de apariencia se preservan
      expect(state.bibleTheme, 'noche');
      expect(state.bibleFontScale, 2.0);
    });
  });
}
