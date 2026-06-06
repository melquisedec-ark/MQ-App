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
import 'package:mqapp/domain/entities/version_pais.dart';
import 'package:mqapp/presentation/views_projection/controller/present_control_bar.dart';
import 'package:mqapp/presentation/views_projection/providers/live_control_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/presentation_providers.dart';

// ═══════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════

class MockWindowService extends Mock implements WindowService {}

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

Himno _createTestHimno({int id = 1, String titulo = 'Santo, Santo, Santo'}) {
  return Himno(
    id: id,
    titulo: titulo,
    numero: id,
    tipo: HimnoTipo.oficial,
    versiones: [
      VersionPais(
        id: 1,
        himnoId: id,
        paisId: 0,
        paisNombre: 'HN',
        paisCodigo: 'HN',
        tonalidadOriginal: 'G',
      ),
    ],
    categorias: [const Categoria(id: 1, nombre: 'Alabanza')],
  );
}

List<Estrofa> _createTestStanzas() {
  return [
    const Estrofa(
      id: 1,
      versionPaisId: 1,
      tipo: EstrofaTipo.estrofa,
      orden: 1,
      contenido: 'Estrofa 1',
    ),
    const Estrofa(
      id: 2,
      versionPaisId: 1,
      tipo: EstrofaTipo.coro,
      orden: 2,
      contenido: 'Coro',
    ),
  ];
}

Widget _buildTestApp({
  required LiveControlNotifier notifier,
  List<Override> overrides = const [],
}) {
  final mockWindowService = MockWindowService();
  registerFallbackValue(<String, dynamic>{});
  when(() => mockWindowService.sendMessage(any())).thenAnswer((_) async {});
  when(() => mockWindowService.openProjectionWindow(any()))
      .thenAnswer((_) async => true);
  when(() => mockWindowService.closeProjectionWindow())
      .thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      liveControlProvider.overrideWith((ref) => notifier),
      windowServiceProvider.overrideWithValue(mockWindowService),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: PresentControlBar(),
      ),
    ),
  );
}

void main() {
  group('PresentControlBar - Module switch button', () {
    testWidgets(
        'Botón de módulo muestra label "Himnario" cuando módulo es Bible (para cambiar)',
        (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(notifier.state.module, ProjectionModule.bible);
      // El botón muestra el módulo al que CAMBIARÁS ("Himnario")
      expect(find.text('Himnario'), findsOneWidget);
    });

    testWidgets(
        'Botón de módulo muestra label "Biblia" cuando módulo es Hymnal (para cambiar)',
        (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(notifier.state.module, ProjectionModule.hymnal);
      // El botón muestra el módulo al que CAMBIARÁS ("Biblia")
      expect(find.text('Biblia'), findsOneWidget);
    });

    testWidgets('switchToModule cambia correctamente de Hymnal a Bible', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      expect(notifier.state.module, ProjectionModule.hymnal);
      expect(notifier.state.hymn, isNotNull);

      notifier.switchToModule(ProjectionModule.bible);

      expect(notifier.state.module, ProjectionModule.bible);
      expect(notifier.state.hymn, isNull);
    });

    testWidgets('switchToModule cambia correctamente de Bible a Hymnal', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      expect(notifier.state.module, ProjectionModule.bible);
      expect(notifier.state.libroNombre, 'Génesis');

      notifier.switchToModule(ProjectionModule.hymnal);

      expect(notifier.state.module, ProjectionModule.hymnal);
      expect(notifier.state.libroNombre, '');
    });
  });

  group('PresentControlBar - Bible-specific controls', () {
    testWidgets('En modo Bible NO muestra botón Solfa', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Solfa'), findsNothing);
    });

    testWidgets('En modo Bible NO muestra botón Nota', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Nota'), findsNothing);
    });

    testWidgets('En modo Bible muestra botón Buscar', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Buscar'), findsOneWidget);
    });

    testWidgets('En modo Hymnal muestra botón Solfa', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Solfa'), findsOneWidget);
    });

    testWidgets('En modo Hymnal muestra botón Nota', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Nota'), findsOneWidget);
    });

    testWidgets('En modo Hymnal muestra botón Lupa', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Lupa'), findsOneWidget);
    });
  });

  group('PresentControlBar - Navigation row module-aware', () {
    testWidgets('En modo Bible muestra título bíblico cuando hay slides',
        (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadBibleChapter(
        libroNombre: 'Génesis',
        capitulo: 1,
        versiculos: ['Verso 1'],
      );

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      // Debe mostrar "Génesis 1" en el header
      expect(find.text('Génesis 1'), findsOneWidget);
    });

    testWidgets('En modo Hymnal muestra título de himno', (tester) async {
      final notifier = LiveControlNotifier();
      notifier.loadHymn(_createTestHimno(), _createTestStanzas());

      await tester.pumpWidget(_buildTestApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
    });
  });
}
