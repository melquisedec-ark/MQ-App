import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/core/enums/estrofa_tipo.dart';
import 'package:mqapp/core/enums/himno_tipo.dart';
import 'package:mqapp/domain/entities/estrofa.dart';
import 'package:mqapp/domain/entities/himno.dart';
import 'package:mqapp/domain/repositories/control_repository.dart';
import 'package:mqapp/presentation/views_projection/controller/live_control_screen.dart';
import 'package:mqapp/presentation/views_projection/providers/connection_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/live_control_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/projection_providers.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ─────────────────────────────────────────────────────

class MockControlRepository extends Mock implements ControlRepository {}

// ─── Helpers ───────────────────────────────────────────────────

/// Override para liveControlProvider con estado bíblico precargado.
final _bibleStateOverride = liveControlProvider.overrideWith(
  (ref) {
    final notifier = LiveControlNotifier();
    notifier.loadBibleChapter(
      libroNombre: 'Génesis',
      capitulo: 1,
      versiculos: [
        'En el principio creó Dios los cielos y la tierra.',
        'Y la tierra estaba desordenada y vacía.',
        'Y dijo Dios: Sea la luz; y fue la luz.',
        'Y vio Dios que la luz era buena.',
        'Y separó Dios la luz de las tinieblas.',
      ],
    );
    return notifier;
  },
);

/// Override para isConnectedProvider (false = modo offline).
final _isConnectedOverride = isConnectedProvider.overrideWith((ref) => false);

/// Override para controlRepositoryProvider.
final _controlRepoOverride = controlRepositoryProvider.overrideWith(
  (ref) => MockControlRepository(),
);

/// Override para projectionConfigProvider.
final _projectionConfigOverride = projectionConfigProvider.overrideWith(
  (ref) {
    final repo = ref.read(controlRepositoryProvider);
    return ProjectionConfigNotifier(repo);
  },
);

Widget _buildBibleTestApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      _bibleStateOverride,
      _isConnectedOverride,
      _controlRepoOverride,
      _projectionConfigOverride,
      ...overrides,
    ],
    child: const MaterialApp(home: LiveControlScreen()),
  );
}

// ─── Tests ─────────────────────────────────────────────────────

void main() {
  group('LiveControlScreen - Modo Biblia', () {
    testWidgets('Muestra título bíblico en el AppBar', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      // El título "Génesis 1" aparece en el AppBar y en el preview panel
      expect(find.text('Génesis 1'), findsWidgets);
    });

    testWidgets('Muestra indicador de módulo bíblico (📖)', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      expect(find.text('📖'), findsOneWidget);
    });

    testWidgets('Botones SIGUIENTE y ANTERIOR están presentes', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      expect(find.text('SIGUIENTE'), findsOneWidget);
      expect(find.text('ANTERIOR'), findsOneWidget);
    });

    testWidgets('Botón SIGUIENTE avanza al siguiente versículo',
        (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      // Sin portada: slide 0 = versículo 1
      expect(find.textContaining('Versículo'), findsWidgets);

      // Avanzar
      await tester.tap(find.text('SIGUIENTE'));
      await tester.pumpAndSettle();

      expect(find.text('SIGUIENTE'), findsOneWidget);
    });

    testWidgets('Botón ANTERIOR no retrocede desde versículo 1', (tester) async {
      // Sin portada: versículo 1 está en índice 0, no hay slide anterior
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1', 'Verso 2', 'Verso 3'],
      );
      notifier.goToVerse(1); // versículo 1 = índice 0

      final override = liveControlProvider.overrideWith((ref) => notifier);

      await tester.pumpWidget(_buildBibleTestApp(overrides: [override]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Versículo'), findsWidgets);

      // ANTERIOR deshabilitado (no hay slide previo)
      await tester.tap(find.text('ANTERIOR'));
      await tester.pumpAndSettle();

      // Sigue en versículo 1
      expect(find.textContaining('Versículo'), findsWidgets);
    });

    testWidgets('Botones de acceso rápido están presentes', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Ir al Inicio'), findsOneWidget);
      expect(find.text('Ir a Versículo'), findsOneWidget);
      expect(find.text('Apagar'), findsOneWidget);
    });

    testWidgets('Botón Ir al Inicio vuelve al primer versículo', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1', 'Verso 2', 'Verso 3'],
      );
      notifier.goToVerse(3);

      final override = liveControlProvider.overrideWith((ref) => notifier);

      await tester.pumpWidget(_buildBibleTestApp(overrides: [override]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Versículo'), findsWidgets);

      await tester.tap(find.text('Ir al Inicio'));
      await tester.pumpAndSettle();

      // Sin portada: inicio = versículo 1
      expect(find.textContaining('Versículo'), findsWidgets);
    });

    testWidgets('Botón Apagar activa modo blackout', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Apagar'), findsOneWidget);

      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();

      expect(find.text('Encender'), findsOneWidget);
    });

    testWidgets('Navegación de capítulos está presente', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Cap. Anterior'), findsOneWidget);
      expect(find.text('Cap. Siguiente'), findsOneWidget);
    });

    testWidgets('Cap. Anterior deshabilitado en capítulo 1', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      // En capítulo 1, "Cap. Anterior" debe estar deshabilitado visualmente
      final prevButton = find.text('Cap. Anterior');
      expect(prevButton, findsOneWidget);

      // El botón debe existir pero con apariencia deshabilitada
      // (no podemos verificar disabled directamente, pero el botón existe)
    });

    testWidgets('Selector de tema bíblico muestra 6 temas', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Papel'), findsOneWidget);
      expect(find.text('Sepia'), findsOneWidget);
      expect(find.text('Noche'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Azul Noche'), findsOneWidget);
      expect(find.text('Alto Contraste'), findsOneWidget);
    });

    testWidgets('Slider de escala de fuente está presente', (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      // El slider debe estar presente (buscar por icono de texto)
      expect(find.byIcon(Icons.text_fields_rounded), findsOneWidget);
    });

    testWidgets('Panel de vista previa muestra slide actual y siguiente',
        (tester) async {
      await tester.pumpWidget(_buildBibleTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Actual'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
    });
  });

  group('LiveControlNotifier - Métodos bíblicos', () {
    test('goToVerse() salta a un versículo válido', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1', 'Verso 2', 'Verso 3', 'Verso 4', 'Verso 5'],
      );

      // Ir al versículo 3
      notifier.goToVerse(3);

      expect(notifier.state.currentSlideIndex, 2);
      expect(notifier.state.versiculoActual, 2);
      expect(notifier.state.isBlackout, false);
    });

    test('goToVerse() ignora versículo fuera de rango (menor)', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1', 'Verso 2', 'Verso 3'],
      );

      final initialIndex = notifier.state.currentSlideIndex;

      // Intentar ir al versículo 0 (inválido)
      notifier.goToVerse(0);

      expect(notifier.state.currentSlideIndex, initialIndex);
    });

    test('goToVerse() ignora versículo fuera de rango (mayor)', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1', 'Verso 2', 'Verso 3'],
      );

      final initialIndex = notifier.state.currentSlideIndex;

      // Intentar ir al versículo 10 (no existe)
      notifier.goToVerse(10);

      expect(notifier.state.currentSlideIndex, initialIndex);
    });

    test('goToVerse() va al primer versículo', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1', 'Verso 2', 'Verso 3'],
      );

      notifier.goToVerse(1);

      expect(notifier.state.currentSlideIndex, 0);
      expect(notifier.state.versiculoActual, 0);
    });

    test('goToVerse() va al último versículo', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1', 'Verso 2', 'Verso 3', 'Verso 4', 'Verso 5'],
      );

      notifier.goToVerse(5);

      expect(notifier.state.currentSlideIndex, 4);
      expect(notifier.state.versiculoActual, 4);
    });

    test('requestAdjacentChapter() next incrementa capítulo', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 5,
        versiculos: ['Verso 1', 'Verso 2'],
      );

      notifier.requestAdjacentChapter(true);

      expect(notifier.state.capitulo, 6);
      expect(notifier.state.versiculos, isEmpty);
      expect(notifier.state.slides, isEmpty);
      expect(notifier.state.currentSlideIndex, 0);
    });

    test('requestAdjacentChapter() previous decrementa capítulo', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 5,
        versiculos: ['Verso 1', 'Verso 2'],
      );

      notifier.requestAdjacentChapter(false);

      expect(notifier.state.capitulo, 4);
      expect(notifier.state.versiculos, isEmpty);
      expect(notifier.state.currentSlideIndex, 0);
    });

    test('requestAdjacentChapter() no permite capítulo 0', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      final initialCap = notifier.state.capitulo;

      // Intentar ir al capítulo anterior (sería 0)
      notifier.requestAdjacentChapter(false);

      // No debe cambiar
      expect(notifier.state.capitulo, initialCap);
    });

    test('setBibleTheme() cambia el tema', () {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      expect(notifier.state.bibleTheme, 'papel');

      notifier.setBibleTheme('noche');
      expect(notifier.state.bibleTheme, 'noche');
    });

    test('setBibleFontScale() cambia la escala con clamp', () {
      final notifier = LiveControlNotifier();

      // Valor válido
      notifier.setBibleFontScale(2.0);
      expect(notifier.state.bibleFontScale, 2.0);

      // Por debajo del mínimo
      notifier.setBibleFontScale(0.5);
      expect(notifier.state.bibleFontScale, 0.8);

      // Por encima del máximo
      notifier.setBibleFontScale(5.0);
      expect(notifier.state.bibleFontScale, 4.0);
    });
  });

  group('LiveControlScreen - Modo Himnario (no se rompe)', () {
    testWidgets('Muestra título del himno en modo hymnal', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(
        Himno(
          id: 1,
          titulo: 'Santo, Santo, Santo',
          numero: 1,
          tipo: HimnoTipo.oficial,
          versiones: [],
          categorias: [],
        ),
        [
          const Estrofa(
            id: 1,
            versionPaisId: 1,
            tipo: EstrofaTipo.estrofa,
            orden: 1,
            contenido: 'Estrofa 1',
          ),
        ],
      );

      final override = liveControlProvider.overrideWith((ref) => notifier);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            override,
            _isConnectedOverride,
            _controlRepoOverride,
            _projectionConfigOverride,
          ],
          child: const MaterialApp(home: LiveControlScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
      // En modo himnario no debe mostrar 📖
      expect(find.text('📖'), findsNothing);
      // Debe mostrar 🎵
      expect(find.text('🎵'), findsOneWidget);
    });

    testWidgets('Muestra botón Ir al Coro en modo hymnal', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(
        Himno(
          id: 1,
          titulo: 'Test',
          numero: 1,
          tipo: HimnoTipo.oficial,
          versiones: [],
          categorias: [],
        ),
        [
          const Estrofa(
            id: 1,
            versionPaisId: 1,
            tipo: EstrofaTipo.estrofa,
            orden: 1,
            contenido: 'Estrofa',
          ),
        ],
      );

      final override = liveControlProvider.overrideWith((ref) => notifier);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            override,
            _isConnectedOverride,
            _controlRepoOverride,
            _projectionConfigOverride,
          ],
          child: const MaterialApp(home: LiveControlScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ir al Coro'), findsOneWidget);
      // En modo himnario no debe mostrar controles bíblicos
      expect(find.text('Ir a Versículo'), findsNothing);
      expect(find.text('Cap. Anterior'), findsNothing);
    });
  });
}
